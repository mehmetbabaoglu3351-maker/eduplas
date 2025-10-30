import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

type RoleKey =
  | "bas_admin"
  | "il_admin"
  | "ilce_admin"
  | "koordinator"
  | "ogretmen"
  | "ogrenci"
  | "destekci";

const APPROVAL_GRAPH: Record<RoleKey, RoleKey[]> = {
  bas_admin: ["il_admin", "destekci"],       // Bootstrap / üst onay
  il_admin: ["ilce_admin", "destekci"],
  ilce_admin: ["koordinator", "destekci"],
  koordinator: ["ogretmen", "destekci"],
  ogretmen: ["ogrenci", "destekci"],
  ogrenci: [],            // onay vermez
  destekci: []            // onay vermez
};

// Basit yetki kontrol: approverRole, approvedRole için yetkili mi?
function canApprove(approverRole: RoleKey | undefined, approvedRole: RoleKey): boolean {
  if (!approverRole) return false;
  const allowed = APPROVAL_GRAPH[approverRole] ?? [];
  return allowed.includes(approvedRole);
}

/**
 * approveRoleIntent
 * İstemci: Admin paneli tarafından çağrılır (Callable).
 * İşlev: registrations/{uid} -> status: "approved", users/{uid}.role = approvedRole
 * Audit kaydı: audits/roleAssignments/{id}
 *
 * Güvenlik:
 *  - İşlem backend (Admin SDK) ile yapılır; Firestore rules UI yazımını zaten engeller.
 *  - Approver, kendi rolüne göre yetkilendirilir (APPROVAL_GRAPH).
 */
export const approveRoleIntent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Giriş gerekli.");
  }

  const approverUid = context.auth.uid;
  const targetUid = String(data?.uid ?? "");
  const approvedRole = String(data?.approvedRole ?? "") as RoleKey;

  if (!targetUid || !approvedRole) {
    throw new functions.https.HttpsError("invalid-argument", "uid ve approvedRole zorunludur.");
  }

  // Approver role çek
  const approverSnap = await db.collection("users").doc(approverUid).get();
  const approverRole = approverSnap.get("role") as RoleKey | undefined;

  if (!canApprove(approverRole, approvedRole)) {
    throw new functions.https.HttpsError("permission-denied",
      `Rol (${approverRole ?? "yok"}) ${approvedRole} için onay yetkisine sahip değil.`);
  }

  // Target registration & role intent doğrula
  const regRef = db.collection("registrations").doc(targetUid);
  const userRef = db.collection("users").doc(targetUid);
  const auditRef = db.collection("audits").doc(); // tek koleksiyonda örnek

  await db.runTransaction(async (tx) => {
    const reg = await tx.get(regRef);
    if (!reg.exists) {
      throw new functions.https.HttpsError("failed-precondition", "Registration bulunamadı.");
    }
    const roleIntent = reg.get("roleIntent") as RoleKey | undefined;
    const status = reg.get("status") as string | undefined;

    if (!roleIntent) {
      throw new functions.https.HttpsError("failed-precondition", "roleIntent bulunamadı.");
    }
    if (roleIntent !== approvedRole) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `roleIntent (${roleIntent}) ile approvedRole (${approvedRole}) uyuşmuyor.`);
    }
    if (status === "approved") {
      // Tekrarlı onayı engelle
      return;
    }

    // users/{uid}.role yaz (sadece backend)
    tx.set(userRef, {
      role: approvedRole,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: approverUid
    }, {merge: true});

    // registrations durum güncelle
    tx.set(regRef, {
      status: "approved",
      approvedRole: approvedRole,
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      approvedBy: approverUid
    }, {merge: true});

    // audit yaz
    tx.set(auditRef, {
      type: "roleAssignment",
      uid: targetUid,
      approvedRole,
      approverUid,
      approverRole: approverRole ?? null,
      at: admin.firestore.FieldValue.serverTimestamp()
    });
  });

  return { ok: true, uid: targetUid, approvedRole };
});

/**
 * rejectRoleIntent
 * Registration'ı reddeder; users/{uid} dokunulmaz.
 * Audit kaydı oluşturur.
 */
export const rejectRoleIntent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Giriş gerekli.");
  }
  const approverUid = context.auth.uid;
  const targetUid = String(data?.uid ?? "");
  const reason = String(data?.reason ?? "Belirtilmedi");

  if (!targetUid) {
    throw new functions.https.HttpsError("invalid-argument", "uid zorunludur.");
  }

  // (Basit) yetki: en az bir yönetim rolü olmalı
  const approverRole = (await db.collection("users").doc(approverUid).get()).get("role") as RoleKey | undefined;
  const mgmtRoles: RoleKey[] = ["bas_admin", "il_admin", "ilce_admin", "koordinator", "ogretmen"];
  if (!approverRole || !mgmtRoles.includes(approverRole)) {
    throw new functions.https.HttpsError("permission-denied", "Reddetme yetkiniz yok.");
  }

  const regRef = db.collection("registrations").doc(targetUid);
  const auditRef = db.collection("audits").doc();

  await db.runTransaction(async (tx) => {
    const reg = await tx.get(regRef);
    if (!reg.exists) {
      throw new functions.https.HttpsError("failed-precondition", "Registration bulunamadı.");
    }
    tx.set(regRef, {
      status: "rejected",
      rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
      rejectedBy: approverUid,
      reason
    }, {merge: true});

    tx.set(auditRef, {
      type: "roleRejection",
      uid: targetUid,
      approverUid,
      approverRole: approverRole ?? null,
      reason,
      at: admin.firestore.FieldValue.serverTimestamp()
    });
  });

  return { ok: true, uid: targetUid, status: "rejected" };
});

/**
 * bootstrapBasAdmin
 * İlk kurulumda (sistemde henüz hiçbir bas_admin yokken) belirli bir kullanıcıya bas_admin atar.
 * DİKKAT: Sadece kapalı dev ortamda ya da sınırlı erişimde kullanın.
 */
export const bootstrapBasAdmin = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Giriş gerekli.");
  }

  const requesterUid = context.auth.uid;
  const targetUid = String(data?.uid ?? "");
  if (!targetUid) {
    throw new functions.https.HttpsError("invalid-argument", "uid zorunludur.");
  }

  const anyBasAdmin = await db.collection("users").where("role", "==", "bas_admin").limit(1).get();
  if (!anyBasAdmin.empty) {
    throw new functions.https.HttpsError("failed-precondition", "Sistemde zaten bas_admin var.");
  }

  await db.runTransaction(async (tx) => {
    const userRef = db.collection("users").doc(targetUid);
    tx.set(userRef, {
      role: "bas_admin",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: requesterUid
    }, {merge: true});

    const auditRef = db.collection("audits").doc();
    tx.set(auditRef, {
      type: "bootstrapBasAdmin",
      uid: targetUid,
      requesterUid,
      at: admin.firestore.FieldValue.serverTimestamp()
    });
  });

  return { ok: true, uid: targetUid, role: "bas_admin" };
});
