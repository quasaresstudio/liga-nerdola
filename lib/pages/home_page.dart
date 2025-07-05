import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';
import 'video_player_page.dart';
import '../widgets/favorite_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final videoService = VideoService();
  List<VideoModel> _videos = [];
  List<String> _categorias = [];
  String _categoriaSelecionada = '';

  @override
  void initState() {
    super.initState();
    _carregarVideos();
    _carregarCategorias();
  }

  Future<void> _carregarVideos() async {
    final videos = await videoService.fetchVideos();
    setState(() {
      _videos = videos;
    });
  }

  Future<void> _carregarCategorias() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categorias')
        .orderBy('nome')
        .get();

    setState(() {
      _categorias = snapshot.docs.map((doc) => doc['nome'] as String).toList();
    });
  }

  List<VideoModel> get _videosFiltrados {
    if (_categoriaSelecionada.isEmpty) return _videos;
    return _videos
        .where((video) => video.categorias.contains(_categoriaSelecionada))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF1E1E1E),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) {
                return ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text(
                        'Todos os vídeos',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        setState(() {
                          _categoriaSelecionada = '';
                        });
                        Navigator.pop(context);
                      },
                    ),
                    for (final categoria in _categorias)
                      ListTile(
                        title: Text(
                          categoria,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          setState(() {
                            _categoriaSelecionada = categoria;
                          });
                          Navigator.pop(context);
                        },
                      ),
                  ],
                );
              },
            );
          },
        ),
        title: Center(child: Image.asset('assets/logo.png', height: 40)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1E1E1E),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) {
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      const ListTile(
                        title: Text(
                          'Minha conta',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                        ),
                        title: const Text(
                          'Sair',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, '/');
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _videos.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _videosFiltrados.isEmpty
          ? const Center(
              child: Text(
                'Nenhum vídeo nesta categoria',
                style: TextStyle(color: Colors.white),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final crossAxisCount = isMobile
                    ? 1
                    : (constraints.maxWidth ~/ 450).clamp(1, 6);

                return Row(
                  children: [
                    if (!isMobile)
                      Container(
                        width: 220,
                        color: const Color(0xFF1E1E1E),
                        child: ListView(
                          children: [
                            ListTile(
                              title: const Text(
                                'Todos os vídeos',
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                setState(() => _categoriaSelecionada = '');
                              },
                            ),
                            for (final categoria in _categorias)
                              ListTile(
                                title: Text(
                                  categoria,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  setState(
                                    () => _categoriaSelecionada = categoria,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 16 / 9,
                        ),
                        itemCount: _videosFiltrados.length,
                        itemBuilder: (context, index) {
                          final video = _videosFiltrados[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            builder: (context, value, child) =>
                                Opacity(opacity: value, child: child),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, animation, __) =>
                                        VideoPlayerPage(video: video),
                                    transitionsBuilder:
                                        (_, animation, __, child) =>
                                            FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(10),
                                    ),
                                    child: Stack(
                                      children: [
                                        Image.network(
                                          video.thumbnailUrl,
                                          width: double.infinity,
                                          fit: BoxFit.fitWidth,
                                        ),
                                        const Positioned(
                                          top: 4,
                                          right: 4,
                                          child: FavoriteButton(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: isMobile ? 8 : 16,
                                      left: 8,
                                      right: 8,
                                      bottom: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          video.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(video.date.toDate()),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
