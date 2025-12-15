import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'dart:io';
import 'card_add_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:hive/hive.dart';
import 'allowance_screen.dart';
import 'trade_card_screen.dart';
import 'card_bulk_add_screen.dart';
import 'stats_home_screen.dart';
import 'card_detail_screen.dart';
import 'package:flutter/services.dart';

class CardListScreen extends StatefulWidget {
  @override
  _CardListScreenState createState() => _CardListScreenState();
}

//カードの並び順
enum CardSort {
  newest,      // 取得日 新しい順
  oldest,      // 取得日 古い順
  priceHigh,   // 価格 高い順
  priceLow,    // 価格 安い順
  nameAZ,      // 名前 A→Z
}

class _CardListScreenState extends State<CardListScreen> {
  List<CardModel> _cards = [];
  List<CardModel> _filteredCards = [];
  late Box<CardModel> _cardBox;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _showWishlistOnly = false;
  CardModel? _pendingDeletedCard;
  int? _pendingDeletedIndex;
  CardSort _sort = CardSort.newest;

  @override
  void initState() {
    super.initState();
    _openHiveBox();
  }

  Map<String, int> calculateMonthlySumByYear(List<CardModel> cards) {
    // key: "2025-01", value: 合計金額
    final Map<String, int> data = {};

    for (var card in cards) {
      if (card.price != null && card.date != null) { // date プロパティを使う前提
        final yearMonth = "${card.date!.year}-${card.date!.month.toString().padLeft(2, '0')}";
        data[yearMonth] = (data[yearMonth] ?? 0) + card.price!;
      }
    }

    return data;
  }

// 累計計算
  Map<String, int> calculateCumulativeByYear(Map<String, int> monthlyMap) {
    final sortedKeys = monthlyMap.keys.toList()..sort();
    int sum = 0;
    final Map<String, int> cumulative = {};
    for (var key in sortedKeys) {
      sum += monthlyMap[key]!;
      cumulative[key] = sum;
    }
    return cumulative;
  }

  Future<void> _openHiveBox() async {
    final exists = await Hive.boxExists('cards');
    _cardBox = await Hive.openBox<CardModel>('cards');
    await _migrateOldCards();
    _refreshCards();
  }

  Future<void> _migrateOldCards() async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(dir.path, 'images'));
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

    for (var card in _cardBox.values) {
      if (card.imagePath != null && !card.imagePath!.startsWith('/')) {
        final oldFile = File(card.imagePath!);
        if (await oldFile.exists()) {
          final fileName = path.basename(card.imagePath!);
          final newPath = path.join(imagesDir.path, fileName);
          await oldFile.copy(newPath);
          card.imagePath = fileName;
          await _cardBox.put(card.id, card);
        }
      }
    }
  }

  Future<void> _refreshCards() async {
    setState(() {
      _cards = _cardBox.values.toList();
      _applyFilters();
    });
  }

  Future<File?> _getImageFile(String? fileName) async {
    if (fileName == null) return null;
    if (path.isAbsolute(fileName)) {
      final file = File(fileName);
      return await file.exists() ? file : null;
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(path.join(dir.path, 'images', fileName));
    return await file.exists() ? file : null;
  }

  Future<void> _navigateToAddOrEdit(CardModel? card) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CardAddScreen(card: card)),
    );
    if (result != null && result is CardModel) {
      await _cardBox.put(result.id, result);
      await _refreshCards();
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _applyFilters();
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _applyFilters();
    });
  }

  void _handleDeleteWithUndo(CardModel card) {
    // 削除対象を保持
    _pendingDeletedCard = card;
    _pendingDeletedIndex = _cards.indexOf(card);

    // UI上から即削除
    setState(() {
      _cards.remove(card);
      _applyFilters();
    });

    // SnackBar 表示
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('カードを削除しました'),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () {
            // Undo
            if (_pendingDeletedCard != null &&
                _pendingDeletedIndex != null) {
              setState(() {
                _cards.insert(
                  _pendingDeletedIndex!,
                  _pendingDeletedCard!,
                );
                _applyFilters();
              });

              _pendingDeletedCard = null;
              _pendingDeletedIndex = null;
            }
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    ).closed.then((reason) async {
      // SnackBar が消えた時点で本削除
      if (_pendingDeletedCard != null) {
        await _cardBox.delete(_pendingDeletedCard!.id);
        _pendingDeletedCard = null;
        _pendingDeletedIndex = null;
      }
    });
  }

  void _applySearch(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _applyFilters(searchQuery: lowerQuery);
    });
  }

  void _applyFilters({String? searchQuery}) {
    List<CardModel> temp = List.from(_cards);

    if (_showWishlistOnly) {
      temp = temp.where((card) => card.isWishList).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      temp = temp.where((card) {
        final q = searchQuery.toLowerCase();

        final matchesName =
        card.name.toLowerCase().contains(q);

        final matchesDescription =
        card.description.toLowerCase().contains(q);

        final matchesTags =
            card.tags != null &&
                card.tags!.any((tag) => tag.toLowerCase().contains(q));

        return matchesName || matchesDescription || matchesTags;
      }).toList();
    }

    // ★ここから追加：並び替え
    temp.sort((a, b) {
      DateTime aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      DateTime bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      int aPrice = a.price ?? 0;
      int bPrice = b.price ?? 0;

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



  // ★ 月ごとの合計を計算する関数
  List<int> calculateMonthlySum(List<CardModel> cards) {
    // 月を1〜12と想定して初期化
    List<int> monthlySum = List.filled(12, 0);
    for (var card in cards) {
      if (card.price != null && card.source != null && card.source!.isNotEmpty) {
        // 仮に source を "2025-12" 形式の年月文字列とする
        final parts = card.source!.split('-');
        if (parts.length == 2) {
          final month = int.tryParse(parts[1]);
          if (month != null && month >= 1 && month <= 12) {
            monthlySum[month - 1] += card.price!;
          }
        }
      }
    }
    return monthlySum;
  }

  // ★ 累計を計算する関数
  List<int> calculateCumulative(List<int> monthlyData) {
    List<int> cumulative = [];
    int sum = 0;
    for (var value in monthlyData) {
      sum += value;
      cumulative.add(sum);
    }
    return cumulative;
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _stopSearch,
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'カードを検索...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _applySearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _applySearch('');
            },
          ),
        ],
      );
    } else {
      return AppBar(
        title: const Text('カード一覧'),
        actions: [
          IconButton(
            icon: Image.asset("assets/images/search_loop.png", width: 32, height: 32),
            tooltip: '検索',
            onPressed: _startSearch,
          ),
          IconButton(
            icon: Image.asset("assets/images/add_card.png", width: 32, height: 32),
            tooltip: 'カード追加',
            onPressed: () => _navigateToAddOrEdit(null),
          ),
          IconButton(
            icon: Image.asset("assets/images/multi_add_cards.png", width: 32, height: 32),
            tooltip: 'まとめてカード追加',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CardBulkAddWithImageScreen(),
                ),
              );
              if (result != null && result is List<CardModel>) {
                for (var card in result) {
                  await _cardBox.put(card.id, card);
                }
                await _refreshCards();
              }
            },
          ),
          IconButton(
            icon: Image.asset("assets/images/wish_star.png", width: 32, height: 32),
            tooltip: 'ウィッシュリスト表示',
            onPressed: () {
              setState(() {
                _showWishlistOnly = !_showWishlistOnly;
                _applyFilters(
                  searchQuery: _isSearching ? _searchController.text : null,
                );
              });
            },
            color: _showWishlistOnly ? Colors.yellow : null,
          ),
          IconButton(
            icon: Image.asset("assets/images/swap_card.png", width: 32, height: 32),
            tooltip: 'フリマ管理画面',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TradeCardScreen()),
              );
            },
          ),
          IconButton(
            icon: Image.asset("assets/images/statistics.png", width: 32, height: 32),
            tooltip: '統計',
            onPressed: () {
              // 1. Map 型で集計
              final monthlyMap = calculateMonthlySumByYear(_cards);
              final cumulativeMap = calculateCumulativeByYear(monthlyMap);

// 年月の順に並べて List に変換
              final months = monthlyMap.keys.toList()..sort();
              final monthlyData = months.map((m) => monthlyMap[m]!).toList();
              final cumulative = months.map((m) => cumulativeMap[m]!).toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatsHomeScreen(
                    cards: _cards, // ←これだけでOK
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Image.asset("assets/images/wallet.png", width: 32, height: 32),
            tooltip: 'お小遣い機能',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshCards,

        // ✅ 空でも Pull-to-refresh できるように、必ずスクロール可能なWidgetを返す
        child: _filteredCards.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Center(child: Text('カードが登録されていません')),
          ],
        )

        // ✅ ここが「③ build()に組み込む場所」
            : CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ① ここに並び替えトグルを差し込む
            SliverToBoxAdapter(
              child: _buildSortToggle(),
            ),

            // ② その下に、今までのリスト表示（ロジックはそのまま）
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final card = _filteredCards[index];
                    return FutureBuilder<File?>(
                      future: _getImageFile(card.imagePath),
                      builder: (context, snapshot) {
                        final imageFile = snapshot.data;
                        return Dismissible(
                          key: ValueKey(card.id),

                          // 👉 右スワイプ：編集
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            color: Colors.blueGrey,
                            child: const Icon(Icons.edit, color: Colors.white),
                          ),

                          // 👈 左スワイプ：削除
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.redAccent,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),

                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // 編集
                              _navigateToAddOrEdit(card);
                              return false; // 削除しない
                            } else {
                              // 削除確認
                              return await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('削除確認'),
                                  content: const Text('本当にこのカードを削除しますか？'),
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
                            }
                          },

                          onDismissed: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              final deletedCard = card;

                              HapticFeedback.heavyImpact();
                              await _cardBox.delete(card.id);
                              await _refreshCards();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('カードを削除しました'),
                                  duration: const Duration(seconds: 4),
                                  action: SnackBarAction(
                                    label: '元に戻す',
                                    onPressed: () async {
                                      await _cardBox.put(deletedCard.id, deletedCard);
                                      await _refreshCards();
                                    },
                                  ),
                                ),
                              );
                            }
                          },

                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CardDetailScreen(card: card),
                                  ),
                                ).then((updated) {
                                  if (updated == true) _refreshCards();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: imageFile != null
                                          ? Image.file(
                                        imageFile,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      )
                                          : Image.asset(
                                        "assets/images/no_image.png",
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            card.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            card.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (card.price != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                '¥${card.price}',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          if (card.source != null && card.source!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text('入手先: ${card.source}'),
                                            ),
                                          if (card.isWishList)
                                            const Padding(
                                              padding: EdgeInsets.only(top: 4),
                                              child: Text(
                                                'ウィッシュリスト',
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          if (card.tags != null && card.tags!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: card.tags!.map((tag) {
                                                  return InkWell(
                                                    borderRadius: BorderRadius.circular(20),
                                                    onTap: () {
                                                      setState(() {
                                                        _isSearching = true;
                                                        _searchController.text = tag;
                                                        _applySearch(tag);
                                                      });
                                                    },
                                                    child: Chip(
                                                      label: Text(tag),
                                                      backgroundColor: Colors.black,
                                                      labelStyle: const TextStyle(color: Colors.white),
                                                      shape: const StadiumBorder(
                                                        side: BorderSide(color: Colors.white),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: _filteredCards.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortToggle() {
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
    final isSelected = _sort == value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFFD4AF37),
        backgroundColor: Colors.grey[800],
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        onSelected: (_) {
          setState(() {
            _sort = value;
            _applyFilters(
              searchQuery: _isSearching ? _searchController.text : null,
            );
          });
        },
      ),
    );
  }
}