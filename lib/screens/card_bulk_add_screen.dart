import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/card_model.dart';

class CardBulkAddWithImageScreen extends StatefulWidget {
  const CardBulkAddWithImageScreen({Key? key}) : super(key: key);

  @override
  _CardBulkAddWithImageScreenState createState() =>
      _CardBulkAddWithImageScreenState();
}

class _CardBulkAddWithImageScreenState
    extends State<CardBulkAddWithImageScreen> {
  final int _rows = 5;
  final ImagePicker _picker = ImagePicker();

  DateTime? _bulkDate;

  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _descriptionControllers = [];
  final List<TextEditingController> _priceControllers = [];
  final List<TextEditingController> _sourceControllers = [];
  final List<bool> _wishListFlags = [];
  final List<String?> _imageFileNames = [];
  final List<File?> _displayImages = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _rows; i++) {
      _nameControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
      _priceControllers.add(TextEditingController());
      _sourceControllers.add(TextEditingController());
      _wishListFlags.add(false);
      _imageFileNames.add(null);
      _displayImages.add(null);
    }
  }

  @override
  void dispose() {
    for (var c in _nameControllers) c.dispose();
    for (var c in _descriptionControllers) c.dispose();
    for (var c in _priceControllers) c.dispose();
    for (var c in _sourceControllers) c.dispose();
    super.dispose();
  }

  Future<String> _copyPickedImageToApp(XFile pickedFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(dir.path, 'images'));
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
    final savedPath = path.join(imagesDir.path, fileName);
    final savedFile = await File(pickedFile.path).copy(savedPath);
    return path.basename(savedFile.path);
  }

  Future<void> _pickImageMenu(int index) async {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ギャラリーから選択'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 75,
                  );
                  if (picked != null) {
                    final fileName = await _copyPickedImageToApp(picked);
                    setState(() {
                      _imageFileNames[index] = fileName;
                      _displayImages[index] = File(picked.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('カメラで撮影'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 75,
                  );
                  if (picked != null) {
                    final fileName = await _copyPickedImageToApp(picked);
                    setState(() {
                      _imageFileNames[index] = fileName;
                      _displayImages[index] = File(picked.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('画像を削除'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFileNames[index] = null;
                    _displayImages[index] = null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveCards() async {
    List<CardModel> newCards = [];
    for (int i = 0; i < _rows; i++) {
      final name = _nameControllers[i].text.trim();
      if (name.isEmpty) continue;

      final description = _descriptionControllers[i].text.trim();
      final priceText = _priceControllers[i].text.trim();
      final price = priceText.isNotEmpty ? int.tryParse(priceText) : null;
      final source = _sourceControllers[i].text.trim().isNotEmpty
          ? _sourceControllers[i].text.trim()
          : null;
      final isWish = _wishListFlags[i];
      final imageFileName = _imageFileNames[i];
      final id = '${DateTime.now().millisecondsSinceEpoch}_$i';

      newCards.add(
        CardModel(
          id: id,
          name: name,
          description: description,
          imagePath: imageFileName,
          price: price,
          source: source,
          isWishList: isWish,
          date: _bulkDate ?? DateTime.now(),
        ),
      );
    }

    if (newCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('追加するカードがありません。名前を入力してください。')),
      );
      return;
    }

    Navigator.pop(context, newCards);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('まとめてカード追加')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            for (int i = 0; i < _rows; i++)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _pickImageMenu(i),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: _displayImages[i] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _displayImages[i]!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.add_a_photo, size: 26),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.image, size: 18),
                              label: const Text('画像選択'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(100, 40),
                              ),
                              onPressed: () => _pickImageMenu(i),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameControllers[i],
                        decoration: const InputDecoration(labelText: 'カード名'),
                      ),
                      TextField(
                        controller: _descriptionControllers[i],
                        decoration: const InputDecoration(labelText: '説明'),
                        maxLines: 2,
                      ),
                      TextField(
                        controller: _priceControllers[i],
                        decoration: const InputDecoration(labelText: '価格'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: _sourceControllers[i],
                        decoration: const InputDecoration(labelText: '入手先'),
                      ),
                      Row(
                        children: [
                          const Text('ウィッシュリスト'),
                          Checkbox(
                            value: _wishListFlags[i],
                            onChanged: (val) {
                              setState(() => _wishListFlags[i] = val ?? false);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.date_range),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _bulkDate = picked);
                    }
                  },
                  child: Text(
                    _bulkDate == null
                        ? '日付を選択'
                        : _bulkDate!.toLocal().toString().split(' ')[0],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _saveCards,
              icon: const Icon(Icons.save),
              label: const Text('まとめて保存'),
            ),
          ],
        ),
      ),
    );
  }
}
