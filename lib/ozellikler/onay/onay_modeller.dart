// ignore_for_file: public_member_api_docs
class OnayIstek {
  final String id;
  final String requesterUid;
  final String requestedRole;
  final String approverUid;
  final DateTime createdAt;
  String status; // "pending" | "approved" | "rejected"
  String? reason;

  OnayIstek({
    required this.id,
    required this.requesterUid,
    required this.requestedRole,
    required this.approverUid,
    required this.createdAt,
    this.status = 'pending',
    this.reason,
  });
}

class Bildirim {
  final String id;
  final String userUid; // kime gidecek
  final String title;
  final String message;
  final DateTime createdAt;
  bool read;

  Bildirim({
    required this.id,
    required this.userUid,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
  });
}


