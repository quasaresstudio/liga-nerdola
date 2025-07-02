import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';

class VideoService {
  final _db = FirebaseFirestore.instance;

  Future<List<VideoModel>> fetchVideos() async {
    final snapshot = await _db.collection('videos').get();
    return snapshot.docs
        .map((doc) => VideoModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
