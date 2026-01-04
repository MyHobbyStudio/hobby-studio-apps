import 'dart:io';
import 'package:card_manager/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/card_model.dart';
import 'card_add_screen.dart';
import 'card_detail_screen.dart';
import 'stats_home_screen.dart';
import 'card_bulk_add_screen.dart' as bulk;
import 'trade_card_screen.dart';
import '../models/purchase_model.dart';

// =====================
// 並び順
// =====================
enum CardSort {
  newest,
  oldest,
  priceHigh,
  priceLow,
  nameAZ,
  nameZA,
}

enum ListingFilter {
  all,
  listed,
  unlisted,
  wishlist,
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
  late Box<Purchase> _purchaseBox;

  final TextEditingController _searchController = TextEditingController();
  CardSort _sort = CardSort.newest;
  ListingFilter _listingFilter = ListingFilter.all;
  bool _isListed(CardModel card) {
    return _purchaseBox.values.any(
          (p) => p.cardId == card.id && p.isSold == false,
    );
  }

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
    _purchaseBox = await Hive.openBox<Purchase>('purchases');
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
  // Filter & Sort
  // =====================
  void _applyFilters() {
    List<CardModel> temp = List.from(_cards);

    // ===== フィルタ =====
    if (_listingFilter == ListingFilter.listed) {
      temp = temp.where(_isListed).toList();
    } else if (_listingFilter == ListingFilter.unlisted) {
      temp = temp.where((c) => !_isListed(c)).toList();
    } else if (_listingFilter == ListingFilter.wishlist) {
      temp = temp.where((c) => c.isWishList).toList();
    }

    // ===== 検索 =====
    if (_isSearching && _searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      temp = temp.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            (c.tags?.any((t) => t.toLowerCase().contains(q)) ?? false) ||
            (c.source?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // ===== 並び順 =====
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
        case CardSort.nameZA:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
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
      // title: const Text('カード一覧'),
      actions: [
        IconButton(
          icon: Image.asset('assets/images/search_loop.png', width: 32),
          onPressed: () => setState(() => _isSearching = true),
        ),
        IconButton(
          icon: Image.asset('assets/images/add_card.png', width: 32),
          onPressed: () async {
            final result = await Navigator.push<CardModel>(
              context,
              MaterialPageRoute(
                builder: (_) => const CardAddScreen(card: null),
              ),
            );

            if (!mounted) return;
            if (result != null) {
              await _cardBox.put(result.id, result);
              await _refresh();
            }
          },
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
          icon: Image.asset('assets/images/swap_card.png', width: 32),
          tooltip: 'フリマ管理',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TradeCardScreen(),
              ),
            );
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
          icon: const Icon(Icons.settings),
          tooltip: '設定',
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );

            if (!mounted) return;

            if (result == true) {
              await _refresh();
            }
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
          _sortChip('Z→A', CardSort.nameZA),

          const SizedBox(width: 12),

          // ===== 出品フィルタ =====
          _listingFilterChip('全部', ListingFilter.all),
          _listingFilterChip('出品中', ListingFilter.listed),
          _listingFilterChip('未出品', ListingFilter.unlisted),
          _listingFilterChip('⭐︎', ListingFilter.wishlist),
        ],
      ),
    );
  }

  Widget _listingFilterChip(String label, ListingFilter value) {
    final selected = _listingFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: Colors.orange,
        onSelected: (_) {
          setState(() {
            _listingFilter = value;
            _applyFilters();
          });
        },
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

                        // =====================
                        // 左 → 右：編集
                        // =====================
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          color: Colors.blueGrey,
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),

                        // =====================
                        // 右 → 左：削除
                        // =====================
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),

                        confirmDismiss: (direction) async {
                          // ===== 編集 =====
                          if (direction == DismissDirection.startToEnd) {
                            final result = await Navigator.push<CardModel>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CardAddScreen(card: card),
                              ),
                            );

                            if (!mounted) return false;

                            if (result != null) {
                              await _cardBox.put(result.id, result);
                              await _refresh();
                            }

                            return false; // ← 消さない
                          }

                          // ===== 削除 =====
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

                        onDismissed: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            await _cardBox.delete(card.id);
                            await _refresh();
                          }
                        },

                        // 👇 操作は中で受ける
                        child: InkWell(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CardDetailScreen(card: card),
                              ),
                            );

                            if (!mounted) return;
                            if (result == true || result is CardModel) {
                              await _refresh();
                            }
                          },
                          child: _buildCardTile(card, imageFile),
                        ),
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

  Widget _cardTileContent(CardModel card, File? imageFile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ===== 画像 =====
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 100,
              child: AspectRatio(
                aspectRatio: 2.5 / 3.5,
                child: imageFile != null
                    ? Image.file(imageFile, fit: BoxFit.contain)
                    : Image.asset(
                  'assets/images/no_image.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          /// ===== 右側情報 =====
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                // ===== 価格（ゴールド・主役）=====
                if (card.price != null)
                  Text(
                    '¥${card.price}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37), // ゴールド
                    ),
                  ),

// ===== 補足情報（グレー・脇役）=====
                if (card.source != null && card.source!.isNotEmpty ||
                    card.date != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [
                        if (card.source != null && card.source!.isNotEmpty)
                          '入手先: ${card.source}',
                        if (card.date != null)
                          '${card.date!.year}/${card.date!.month}/${card.date!.day}',
                      ].join(' / '),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),

                if (card.tags != null && card.tags!.isNotEmpty) ...[
                  const SizedBox(height: 8),

                  Builder(
                    builder: (_) {
                      final tags = card.tags!;
                      final visibleTags = tags.take(2).toList();
                      final remainingCount = tags.length - visibleTags.length;

                      return Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // 表示するタグ（最大2）
                          ...visibleTags.map(
                                (t) => Chip(
                              label: Text(
                                t,
                                style: const TextStyle(fontSize: 13),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              visualDensity: const VisualDensity(
                                horizontal: -2,
                                vertical: -4,
                              ),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),

                          // +N 表示
                          if (remainingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD4AF37),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '+$remainingCount',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(CardModel card, File? imageFile) {
    final isListed = _isListed(card);

    return Stack(
      children: [
        // 元のカードUI
        _cardTileContent(card, imageFile),

        // 出品中バッジ
        if (isListed)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '出品中',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }
}