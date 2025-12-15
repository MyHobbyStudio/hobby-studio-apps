import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/card_model.dart';

class CardBulkAddWithImageScreen extends StatefulWidget {
  const CardBulkAddWithImageScreen({super.key});

  @override
  State<CardBulkAddWithImageScreen> createState() =>
      _CardBulkAddWithImageScreenState();
}

class _CardBulkAddWithImageScreenState
    extends State<CardBulkAddWithImageScreen> {
  final int _rows = 5;
  final ImagePicker _picker = ImagePicker();

  final List<TextEditingController> _name = [];
  final List<TextEditingController> _desc = [];
  final List<TextEditingController> _price = [];
  final List<TextEditingController> _source = [];
  final List<bool> _wish = [];
  final List<String?> _imageNames = [];
  final List<File?> _images = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _rows; i++) {
      _name.add(TextEditingController());
      _desc.add(TextEditingController());
      _price.add(TextEditingController());
      _source.add(TextEditingController());
      _wish.add(false);
      _imageNames.add(null);
      _images.add(null);
    }
  }

  Future<String> _saveImage(XFile picked) async {
    final dir = await getApplicationDocumentsDirectory();
    final imgDir = Directory(path.join(dir.path, 'images'));
    if (!await imgDir.exists()) await imgDir.create(recursive: true);

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(picked.path)}';
    await File(picked.path).copy(path.join(imgDir.path, fileName));
    return fileName;
  }

  Future<void> _pickImage(int i) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final name = await _saveImage(picked);
      setState(() {
        _imageNames[i] = name;
        _images[i] = File(picked.path);
      });
    }
  }

  void _save() {
    final List<CardModel> cards = [];

    for (int i = 0; i < _rows; i++) {
      final name = _name[i].text.trim();
      if (name.isEmpty) continue;

      cards.add(
        CardModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          name: name,
          description: _desc[i].text.trim(),
          price: int.tryParse(_price[i].text),
          imagePath: _imageNames[i],
          source:
          _source[i].text.trim().isEmpty ? null : _source[i].text.trim(),
          isWishList: _wish[i],
        ),
      );
    }

    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カード名を入力してください')),
      );
      return;
    }

    Navigator.pop(context, cards);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('まとめてカード追加')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (int i = 0; i < _rows; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(i),
                      child: SizedBox(
                        height: 80,
                        child: _images[i] != null
                            ? Image.file(_images[i]!, fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo),
                      ),
                    ),
                    TextField(controller: _name[i], decoration: const InputDecoration(labelText: 'カード名')),
                    TextField(controller: _desc[i], decoration: const InputDecoration(labelText: '説明')),
                    TextField(controller: _price[i], decoration: const InputDecoration(labelText: '価格')),
                    TextField(controller: _source[i], decoration: const InputDecoration(labelText: '入手先')),
                    CheckboxListTile(
                      title: const Text('ウィッシュリスト'),
                      value: _wish[i],
                      onChanged: (v) => setState(() => _wish[i] = v ?? false),
                    ),
                  ],
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('まとめて保存'),
          ),
        ],
      ),
    );
  }
}