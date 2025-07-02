import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String title;
  final String description;
  final String videoUrl; // link direto para o .mp4
  final String thumbnailUrl;
  final bool ativo;
  final Timestamp date;
  final List<String> categorias;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.ativo,
    required this.date,
    required this.categorias,
  });

  factory VideoModel.fromMap(Map<String, dynamic> data, String id) {
    return VideoModel(
      id: id,
      title: data['titulo'] ?? '',
      description: data['descricao'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnail'] ?? '',
      ativo: data['ativo'] ?? false,
      date: data['data'] ?? Timestamp.now(),
      categorias: List<String>.from(data['categorias'] ?? []),
    );
  }
}
