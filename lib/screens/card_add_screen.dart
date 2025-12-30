// screens/card_add_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/card_model.dart';

class CardAddScreen extends StatefulWidget {
  final CardModel? card;
  const CardAddScreen({super.key, this.card});

  @override
  State<CardAddScreen> createState() => _CardAddScreenState();
}

class _CardAddScreenState extends State<CardAddScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _sourceController;
  late TextEditingController _tagController;

  bool _isWishList = false;
  DateTime? _selectedDate;
  File? _imageFile;
  List<String> _tags = [];

  // =====================
  // Init / Dispose
  // =====================
  @override
  void initState() {
    super.initState();
    final c = widget.card;

    _nameController = TextEditingController(text: c?.name ?? '');
    _descriptionController = TextEditingController(text: c?.description ?? '');
    _priceController =
        TextEditingController(text: c?.price?.toString() ?? '');
    _sourceController = TextEditingController(text: c?.source ?? '');
    _tagController = TextEditingController();

    _isWishList = c?.isWishList ?? false;
    _selectedDate = c?.date;
    _tags = List<String>.from(c?.tags ?? []);

    if (c?.imagePath != null) {
      _loadExistingImage(c!.imagePath!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _sourceController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // =====================
  // Image
  // =====================
  Future<void> _loadExistingImage(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(path.join(dir.path, 'images', fileName));
    if (await file.exists()) {
      setState(() => _imageFile = file);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String?> _saveImage(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final imgDir = Directory(path.join(dir.path, 'images'));
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }

    final fileName = path.basename(file.path);
    await file.copy(path.join(imgDir.path, fileName));
    return fileName;
  }

  // =====================
  // Save
  // =====================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final imagePath = _imageFile != null
        ? await _saveImage(_imageFile!)
        : widget.card?.imagePath;

    final updated = CardModel(
      id: widget.card?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: int.tryParse(_priceController.text),
      source: _sourceController.text.trim().isEmpty
          ? null
          : _sourceController.text.trim(),
      date: _selectedDate,
      tags: List<String>.from(_tags),
      imagePath: imagePath,
      isWishList: _isWishList,
    );

    Navigator.pop(context, updated); // ★ 保存しない、返すだけ
  }

  // =====================
  // UI
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card == null ? 'カード追加' : 'カード編集'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== Image =====
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220,
                alignment: Alignment.center,
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.contain)
                    : Image.asset('assets/images/no_image.png', fit: BoxFit.contain),
              ),
            ),

            const SizedBox(height: 24),

            // 🟨 基本情報
            _section(
              title: '基本情報',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'カード名'),
                  validator: (v) =>
                  v == null || v.isEmpty ? '必須項目です' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: '説明'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: '価格'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),

            // 🟦 付加情報
            _section(
              title: '付加情報',
              children: [
                TextFormField(
                  controller: _sourceController,
                  decoration: const InputDecoration(labelText: '入手元'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _selectedDate == null
                        ? '取得日を選択'
                        : '取得日: ${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ウィッシュリスト'),
                  value: _isWishList,
                  onChanged: (v) =>
                      setState(() => _isWishList = v ?? false),
                ),
              ],
            ),

            // 🟪 分類
            _section(
              title: 'タグ',
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _tags
                      .map(
                        (t) => Chip(
                      label: Text(t),
                      onDeleted: () =>
                          setState(() => _tags.remove(t)),
                    ),
                  )
                      .toList(),
                ),
                TextField(
                  controller: _tagController,
                  decoration:
                  const InputDecoration(labelText: 'タグ追加（Enter）'),
                  onSubmitted: (v) {
                    final value = v.trim();
                    if (value.isEmpty || _tags.contains(value)) return;
                    setState(() {
                      _tags.add(value);
                      _tagController.clear();
                    });
                  },
                ),
              ],
            ),

            // ✅ 保存前の「余白」
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37), // ゴールド
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '保存',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}