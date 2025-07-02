import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId; // email ou identificador de nome
  final String userName; // nome de exibição
  final String uid; // UID do Firebase Auth
  final String content;
  final Timestamp timestamp;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.uid,
    required this.content,
    required this.timestamp,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      uid: map['uid'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'uid': uid,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
