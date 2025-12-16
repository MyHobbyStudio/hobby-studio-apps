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
  static const int rows = 5;
  final picker = ImagePicker();

  final List<TextEditingController> nameCtrls = [];
  final List<TextEditingController> descCtrls = [];
  final List<TextEditingController> priceCtrls = [];
  final List<TextEditingController> sourceCtrls = [];
  final List<TextEditingController> tagCtrls = [];

  final List<List<String>> tagsList = [];
  final List<DateTime?> dates = [];
  final List<bool> wishFlags = [];
  final List<File?> images = [];
  final List<String?> imagePaths = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < rows; i++) {
      nameCtrls.add(TextEditingController());
      descCtrls.add(TextEditingController());
      priceCtrls.add(TextEditingController());
      sourceCtrls.add(TextEditingController());
      tagCtrls.add(TextEditingController());
      tagsList.add([]);
      dates.add(null);
      wishFlags.add(false);
      images.add(null);
      imagePaths.add(null);
    }
  }

  @override
  void dispose() {
    for (final c in [
      ...nameCtrls,
      ...descCtrls,
      ...priceCtrls,
      ...sourceCtrls,
      ...tagCtrls
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String> _saveImage(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final imgDir = Directory(path.join(dir.path, 'images'));
    if (!await imgDir.exists()) await imgDir.create(recursive: true);

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    await file.copy(path.join(imgDir.path, fileName));
    return fileName;
  }

  Future<void> _pickImage(int index) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final saved = await _saveImage(file);

    setState(() {
      images[index] = file;
      imagePaths[index] = saved;
    });
  }

  Future<void> _pickDate(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dates[index] ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => dates[index] = picked);
    }
  }

  void _saveAll() {
    final List<CardModel> result = [];

    for (int i = 0; i < rows; i++) {
      final name = nameCtrls[i].text.trim();
      if (name.isEmpty) continue;

      result.add(
        CardModel(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          name: name,
          description: descCtrls[i].text,
          price: int.tryParse(priceCtrls[i].text),
          source: sourceCtrls[i].text,
          tags: tagsList[i],
          date: dates[i],
          isWishList: wishFlags[i],
          imagePath: imagePaths[i],
        ),
      );
    }

    if (result.isEmpty) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('まとめてカード追加')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: rows,
        itemBuilder: (context, i) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _pickImage(i),
                        child: Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey[300],
                          child: images[i] != null
                              ? Image.file(images[i]!, fit: BoxFit.cover)
                              : const Icon(Icons.add_a_photo),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: nameCtrls[i],
                          decoration:
                          const InputDecoration(labelText: 'カード名'),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: descCtrls[i],
                    decoration: const InputDecoration(labelText: '説明'),
                  ),
                  TextField(
                    controller: priceCtrls[i],
                    decoration: const InputDecoration(labelText: '価格'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: sourceCtrls[i],
                    decoration: const InputDecoration(labelText: '入手先'),
                  ),
                  Wrap(
                    spacing: 6,
                    children: tagsList[i]
                        .map((t) => Chip(
                      label: Text(t),
                      onDeleted: () =>
                          setState(() => tagsList[i].remove(t)),
                    ))
                        .toList(),
                  ),
                  TextField(
                    controller: tagCtrls[i],
                    decoration:
                    const InputDecoration(labelText: 'タグ（Enter）'),
                    onSubmitted: (v) {
                      final val = v.trim();
                      if (val.isEmpty) return;
                      setState(() {
                        tagsList[i].add(val);
                        tagCtrls[i].clear();
                      });
                    },
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _pickDate(i),
                        child: Text(dates[i] == null
                            ? '日付未設定'
                            : '${dates[i]!.year}/${dates[i]!.month}/${dates[i]!.day}'),
                      ),
                      const Spacer(),
                      const Text('ウィッシュ'),
                      Checkbox(
                        value: wishFlags[i],
                        onChanged: (v) =>
                            setState(() => wishFlags[i] = v ?? false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: _saveAll,
          child: const Text('まとめて保存'),
        ),
      ),
    );
  }
}