import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/card_model.dart';
import 'card_add_screen.dart';
import 'card_detail_screen.dart';
import 'allowance_screen.dart';
import 'stats_home_screen.dart';
import 'card_bulk_add_screen.dart' as bulk;

// =====================
// 並び順
// =====================
enum CardSort {
  newest,
  oldest,
  priceHigh,
  priceLow,
  nameAZ,
}

class CardListScreen extends StatefulWidget {
  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  late Box<CardModel> _cardBox;

  List<CardModel> _cards = [];
  List<CardModel> _filteredCards = [];

  bool _isSearching = false;
  bool _showWishlistOnly = false;

  final TextEditingController _searchController = TextEditingController();
  CardSort _sort = CardSort.newest;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  // =====================
  // Hive
  // =====================
  Future<void> _openBox() async {
    _cardBox = await Hive.openBox<CardModel>('cards');
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _cards = _cardBox.values.toList();
      _applyFilters();
    });
  }

  // =====================
  // Image
  // =====================
  Future<File?> _getImageFile(String? fileName) async {
    if (fileName == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(path.join(dir.path, 'images', fileName));
    return await file.exists() ? file : null;
  }

  // =====================
  // Add / Edit
  // =====================
  Future<void> _navigateToAddOrEdit(CardModel? card) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CardAddScreen(card: card)),
    );

    if (result == null || result is! CardModel) return;

    if (card != null && card.isInBox) {
      card
        ..name = result.name
        ..description = result.description
        ..price = result.price
        ..imagePath = result.imagePath
        ..isWishList = result.isWishList
        ..source = result.source
        ..tags = result.tags
        ..date = result.date;
      await card.save();
    } else {
      await _cardBox.put(result.id, result);
    }

    await _refresh();
  }

  // =====================
  // Filter & Sort
  // =====================
  void _applyFilters() {
    List<CardModel> temp = List.from(_cards);

    if (_showWishlistOnly) {
      temp = temp.where((c) => c.isWishList).toList();
    }

    if (_isSearching && _searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      temp = temp.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            (c.tags?.any((t) => t.toLowerCase().contains(q)) ?? false) ||
            (c.source?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    temp.sort((a, b) {
      final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final aPrice = a.price ?? 0;
      final bPrice = b.price ?? 0;

      switch (_sort) {
        case CardSort.newest:
          return bDate.compareTo(aDate);
        case CardSort.oldest:
          return aDate.compareTo(bDate);
        case CardSort.priceHigh:
          return bPrice.compareTo(aPrice);
        case CardSort.priceLow:
          return aPrice.compareTo(bPrice);
        case CardSort.nameAZ:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });

    _filteredCards = temp;
  }

  // =====================
  // AppBar
  // =====================
  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              _applyFilters();
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'カードを検索...',
            border: InputBorder.none,
          ),
          onChanged: (_) => setState(_applyFilters),
        ),
      );
    }

    return AppBar(
      title: const Text('カード一覧'),
      actions: [
        IconButton(
          icon: Image.asset('assets/images/search_loop.png', width: 32),
          onPressed: () => setState(() => _isSearching = true),
        ),
        IconButton(
          icon: Image.asset('assets/images/add_card.png', width: 32),
          onPressed: () => _navigateToAddOrEdit(null),
        ),
        IconButton(
          icon: Image.asset('assets/images/multi_add_cards.png', width: 32),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => bulk.CardBulkAddWithImageScreen(),
              ),
            );
            if (result is List<CardModel>) {
              for (final c in result) {
                await _cardBox.put(c.id, c);
              }
              await _refresh();
            }
          },
        ),
        IconButton(
          icon: Image.asset('assets/images/wish_star.png', width: 32),
          color: _showWishlistOnly ? Colors.yellow : null,
          onPressed: () {
            setState(() {
              _showWishlistOnly = !_showWishlistOnly;
              _applyFilters();
            });
          },
        ),
        IconButton(
          icon: Image.asset('assets/images/statistics.png', width: 32),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StatsHomeScreen(cards: _cards),
              ),
            );
          },
        ),
        IconButton(
          icon: Image.asset('assets/images/wallet.png', width: 32),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AllowanceScreen()),
            );
          },
        ),
      ],
    );
  }

  // =====================
  // Sort Chips
  // =====================
  Widget _buildSortChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _sortChip('新しい順', CardSort.newest),
          _sortChip('古い順', CardSort.oldest),
          _sortChip('高い', CardSort.priceHigh),
          _sortChip('安い', CardSort.priceLow),
          _sortChip('A→Z', CardSort.nameAZ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, CardSort value) {
    final selected = _sort == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xFFD4AF37),
        backgroundColor: Colors.grey[800],
        labelStyle: TextStyle(
          color: selected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        onSelected: (_) {
          setState(() {
            _sort = value;
            _applyFilters();
          });
        },
      ),
    );
  }

  // =====================
  // UI
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSortChips()),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final card = _filteredCards[index];
                  return FutureBuilder<File?>(
                    future: _getImageFile(card.imagePath),
                    builder: (context, snapshot) {
                      final imageFile = snapshot.data;

                      return Dismissible(
                        key: ValueKey(card.id),
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          color: Colors.blueGrey,
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            _navigateToAddOrEdit(card);
                            return false;
                          }
                          return await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('削除確認'),
                              content: const Text('このカードを削除しますか？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('キャンセル'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('削除'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) async {
                          await _cardBox.delete(card.id);
                          await _refresh();
                        },
                        child: _buildCardTile(card, imageFile),
                      );
                    },
                  );
                },
                childCount: _filteredCards.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTile(CardModel card, File? imageFile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageFile != null
              ? Image.file(imageFile, width: 56, height: 56, fit: BoxFit.contain)
              : Image.asset('assets/images/no_image.png',
              width: 56, height: 56, fit: BoxFit.contain),
        ),
        title: Text(card.name),
        subtitle: card.source != null
            ? Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Chip(
            label: Text(card.source!, style: const TextStyle(fontSize: 11)),
          ),
        )
            : null,
        trailing: card.price != null ? Text('¥${card.price}') : null,
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
          );
          if (updated == true) await _refresh();
        },
      ),
    );
  }
}