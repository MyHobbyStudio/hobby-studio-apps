import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/purchase_model.dart';
import 'trade_card_screen.dart';


class TradeCardAddScreen extends StatefulWidget {
  final Purchase? purchase;      // 既存出品の編集用
  final String? initialCardName; // ← 追加
  final String? initialImagePath;
  final int? initialPrice;
  final String? initialCardId;

  const TradeCardAddScreen({
    Key? key,
    this.purchase,
    this.initialCardName,
    this.initialImagePath,
    this.initialPrice,
    this.initialCardId,
  }) : super(key: key);

  @override
  _TradeCardAddScreenState createState() => _TradeCardAddScreenState();
}

class _TradeCardAddScreenState extends State<TradeCardAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  List<String> _listingTags = [];
  final _descriptionController = TextEditingController();

  late Box<Purchase> _purchaseBox;

  File? _imageFile;
  String _listingSite = '';
  bool _isSold = false;

  @override
  void initState() {
    super.initState();
    _openBox();

    if (widget.purchase != null) {
      // ===== 既存出品の編集 =====
      final p = widget.purchase!;
      _nameController.text = p.cardName;
      _priceController.text = p.price.toString();
      _isSold = p.isSold;
      _descriptionController.text = p.listingDescription ?? '';
      _listingTags = p.listingSite
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (p.imagePath != null) {
        _imageFile = File(p.imagePath!);
      }
    } else {
      // ===== カード一覧 → 新規出品 =====
      if (widget.initialCardName != null) {
        _nameController.text = widget.initialCardName!;
      }
      if (widget.initialPrice != null) {
        _priceController.text = widget.initialPrice.toString();
      }
      if (widget.initialImagePath != null) {
        _imageFile = File(widget.initialImagePath!);
      }
    }
  }

  Future<void> _openBox() async {
    _purchaseBox = await Hive.openBox<Purchase>('purchases');
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _saveImage(File image) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(dir.path, 'purchase_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
    final savedFile = await image.copy(path.join(imagesDir.path, fileName));
    return savedFile.path;
  }

  void _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;

    String? imagePath = widget.purchase?.imagePath;

    if (_imageFile != null && _imageFile!.path != imagePath) {
      imagePath = await _saveImage(_imageFile!);
    }

    final purchase = Purchase(
      id: widget.purchase?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      cardName: _nameController.text,
      price: int.parse(_priceController.text),
      date: widget.purchase?.date ?? DateTime.now(),
      imagePath: imagePath,
      listingDescription: _descriptionController.text,
      // 👇 タグをカンマ区切りで保存
      listingSite: _listingTags.join(','),
      isSold: _isSold,
      cardId: widget.purchase?.cardId ?? widget.initialCardId,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${purchase.cardName}」を出品管理しました'),
        duration: const Duration(seconds: 2),
      ),
    );
    await _purchaseBox.put(purchase.id, purchase);
    Navigator.pop(context, purchase);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('フリマ出品カード追加')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // カード名
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'カード名'),
                  validator: (value) =>
                      value == null || value.isEmpty ? '必須項目です' : null,
                ),
                const SizedBox(height: 12),
                // 仕入れ価格
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: '仕入れ価格'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '必須項目です';
                    if (int.tryParse(value) == null) return '数字で入力してください';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // 画像選択
                Row(
                  children: [
                    _imageFile != null
                        ? Image.file(
                      _imageFile!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      'assets/images/no_image.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => _pickImage(ImageSource.camera),
                          child: const Text('カメラ'),
                        ),
                        ElevatedButton(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          child: const Text('ギャラリー'),
                        ),
                      ],
                    ),
                  ],
                ),
                // ===== 出品先タグ入力 =====
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '出品先（タグ）',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: '出品文章',
                    hintText: 'フリマに貼る説明文を入力',
                    alignLabelWithHint: true,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tagController,
                        decoration: const InputDecoration(
                          hintText: '例：メルカリ、ヤフオク',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final tag = _tagController.text.trim();
                        if (tag.isNotEmpty && !_listingTags.contains(tag)) {
                          setState(() {
                            _listingTags.add(tag);
                            _tagController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 6,
                  children: _listingTags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _listingTags.remove(tag);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // 売却済み
                CheckboxListTile(
                  value: _isSold,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _isSold = value;
                      });
                    }
                  },
                  title: const Text('売却済み'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _savePurchase,
                  child: const Text('保存'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
