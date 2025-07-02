import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authService = AdminAuthService();

  final _titleController = TextEditingController();
  final _thumbController = TextEditingController();
  final _urlController = TextEditingController();
  final _descController = TextEditingController();
  final _newCategoryController = TextEditingController();

  List<String> _selectedCategories = [];
  List<String> _allCategories = [];
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    final snap = await FirebaseFirestore.instance
        .collection('categorias')
        .get();
    setState(() {
      _allCategories = snap.docs.map((doc) => doc['nome'] as String).toList();
    });
  }

  Future<void> _addCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;

    await FirebaseFirestore.instance.collection('categorias').add({
      'nome': name,
    });
    _newCategoryController.clear();
    _loadCategories();
  }

  Future<void> _deleteCategory(String name) async {
    final docs = await FirebaseFirestore.instance
        .collection('categorias')
        .where('nome', isEqualTo: name)
        .get();
    for (var doc in docs.docs) {
      await doc.reference.delete();
    }
    _loadCategories();
  }

  Future<void> _addOrUpdateVideo() async {
    final title = _titleController.text.trim();
    final thumb = _thumbController.text.trim();
    final rawInput = _urlController.text.trim();
    final url = rawInput.contains('http')
        ? rawInput
        : 'https://vz-b44dce26-d74.b-cdn.net/$rawInput/play_720p.mp4';

    final desc = _descController.text.trim();

    if (title.isEmpty || thumb.isEmpty || url.isEmpty || desc.isEmpty) return;

    final data = {
      'titulo': title,
      'thumbnail': thumb,
      'videoUrl': url,
      'descricao': desc,
      'categorias': _selectedCategories,
      'data': Timestamp.now(),
      'ativo': true,
    };

    if (_editingId != null) {
      await FirebaseFirestore.instance
          .collection('videos')
          .doc(_editingId)
          .update(data);
    } else {
      await FirebaseFirestore.instance.collection('videos').add(data);
    }

    _clearForm();
  }

  void _clearForm() {
    _titleController.clear();
    _thumbController.clear();
    _urlController.clear();
    _descController.clear();
    _editingId = null;
    _selectedCategories = [];
    setState(() {});
  }

  void _editVideo(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    _titleController.text = data['titulo'] ?? '';
    _thumbController.text = data['thumbnail'] ?? '';
    _urlController.text = data['videoUrl'] ?? '';
    _descController.text = data['descricao'] ?? '';
    _selectedCategories = List<String>.from(data['categorias'] ?? []);
    _editingId = doc.id;

    setState(() {});
  }

  Future<void> _deleteVideo(String id) async {
    await FirebaseFirestore.instance.collection('videos').doc(id).delete();
    if (_editingId == id) {
      _clearForm();
    } else {
      setState(() {});
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF2A2C31),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Painel de Administração",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/admin');
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Formulário
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Adicionar Novo Vídeo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(_titleController, 'Título'),
                          const SizedBox(height: 12),
                          _buildTextField(_thumbController, 'URL do Thumbnail'),
                          const SizedBox(height: 12),
                          _buildTextField(
                            _urlController,
                            'Código do Vídeo Bunny (sem o link completo)',
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            _descController,
                            'Descrição',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),

                          // Categorias (checkbox list)
                          const Text(
                            'Categorias',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Wrap(
                            spacing: 6,
                            children: _allCategories.map((cat) {
                              final selected = _selectedCategories.contains(
                                cat,
                              );
                              return FilterChip(
                                label: Text(cat),
                                selected: selected,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      _selectedCategories.add(cat);
                                    } else {
                                      _selectedCategories.remove(cat);
                                    }
                                  });
                                },
                                selectedColor: Colors.deepPurple,
                                backgroundColor: Colors.grey[800],
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9B5CF6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  onPressed: _addOrUpdateVideo,
                                  child: Text(
                                    _editingId == null
                                        ? 'Adicionar Vídeo'
                                        : 'Salvar Alterações',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              if (_editingId != null) ...[
                                const SizedBox(width: 12),
                                IconButton(
                                  onPressed: _clearForm,
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.white70,
                                  ),
                                  tooltip: 'Cancelar edição',
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 16),

                          const Text(
                            'Gerenciar Categorias',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _newCategoryController,
                                  'Nova Categoria',
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _addCategory,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text(
                                  'Adicionar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            children: _allCategories.map((cat) {
                              return Chip(
                                label: Text(
                                  cat,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.deepPurple[700],
                                deleteIcon: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                ),
                                onDeleted: () => _deleteCategory(cat),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Lista de vídeos
                Expanded(
                  flex: 3,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('videos')
                        .orderBy('data', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.purple,
                          ),
                        );
                      }

                      final videos = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final doc = videos[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final List<String> categorias = List<String>.from(
                            data['categorias'] ?? [],
                          );

                          return Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: Image.network(
                                data['thumbnail'],
                                width: 90,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                              title: Text(
                                data['titulo'],
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${data['descricao'] ?? ''}\nCategorias: ${categorias.join(', ')}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.amber,
                                    ),
                                    onPressed: () => _editVideo(doc),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _deleteVideo(doc.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
