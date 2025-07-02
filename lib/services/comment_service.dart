import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentService {
  final _db = FirebaseFirestore.instance;

  Future<List<CommentModel>> getComments(String videoId) async {
    final snapshot = await _db
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> addComment(String videoId, CommentModel comment) async {
    await _db
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .add(comment.toMap());
  }

  Future<void> deleteComment(String videoId, String commentId) async {
    await _db
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}
