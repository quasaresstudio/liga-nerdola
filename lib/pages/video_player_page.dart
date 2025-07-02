import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/video_model.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';

class VideoPlayerPage extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerPage({super.key, required this.video});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  final commentService = CommentService();
  final _commentController = TextEditingController();
  late Future<List<CommentModel>> _commentsFuture;

  @override
  void initState() {
    super.initState();

    _videoPlayerController =
        VideoPlayerController.network(widget.video.videoUrl)
          ..initialize().then((_) {
            _chewieController = ChewieController(
              videoPlayerController: _videoPlayerController,
              autoPlay: true,
              looping: false,
              allowMuting: true,
              allowPlaybackSpeedChanging: true,
            );
            setState(() {});
          });

    _commentsFuture = commentService.getComments(widget.video.id);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final comment = CommentModel(
      id: '',
      userId: user.email ?? 'Anônimo',
      userName: user.displayName ?? user.email ?? 'Anônimo',
      uid: user.uid,
      content: text,
      timestamp: Timestamp.now(),
    );

    await commentService.addComment(widget.video.id, comment);

    setState(() {
      _commentController.clear();
      _commentsFuture = commentService.getComments(widget.video.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    final videoWidget =
        _chewieController != null && _videoPlayerController.value.isInitialized
        ? Chewie(controller: _chewieController!)
        : const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Colors.purple),
            ),
          );

    final commentsWidget = Column(
      children: [
        const Divider(color: Colors.white24),
        Expanded(
          child: FutureBuilder<List<CommentModel>>(
            future: _commentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.purple),
                );
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Erro ao carregar comentários',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final comments = snapshot.data ?? [];

              return ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return ListTile(
                    title: Text(
                      comment.userName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      comment.content,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat(
                            'dd/MM HH:mm',
                          ).format(comment.timestamp.toDate()),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (FirebaseAuth.instance.currentUser?.uid ==
                            comment.uid)
                          GestureDetector(
                            onTap: () async {
                              await commentService.deleteComment(
                                widget.video.id,
                                comment.id,
                              );
                              setState(() {
                                _commentsFuture = commentService.getComments(
                                  widget.video.id,
                                );
                              });
                            },
                            child: const Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Escreva um comentário...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.purple),
                onPressed: _submitComment,
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Center(child: Image.asset('assets/logo.png', height: 40)),
        actions: const [SizedBox(width: 48)],
      ),
      body: isWide
          ? Row(
              children: [
                Expanded(flex: 2, child: videoWidget),
                const VerticalDivider(color: Colors.white24, width: 1),
                Expanded(flex: 1, child: commentsWidget),
              ],
            )
          : Column(
              children: [
                AspectRatio(
                  aspectRatio: _videoPlayerController.value.isInitialized
                      ? _videoPlayerController.value.aspectRatio
                      : 16 / 9,
                  child: videoWidget,
                ),
                Expanded(child: commentsWidget),
              ],
            ),
    );
  }
}
