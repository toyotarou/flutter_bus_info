import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _query = r'''
query {
  stations(prefecture: "東京都") {
    id
    stationName
    prefecture
    trainNumber
  }
  buses {
    id
    endA
    endB
  }
  trains {
    trainNumber
    trainName
  }
}
''';

  // ★ index 指定スクロール用（これで確実に飛べる）
  final ItemScrollController _itemScrollController = ItemScrollController();

  final TextEditingController _searchController = TextEditingController();

  ///
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ///
  void _jumpToIndex(int index) {
    if (!_itemScrollController.isAttached) {
      return;
    }

    _itemScrollController.scrollTo(index: index, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
  }

  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TOKYO BUS INFO')),
      // ignore: always_specify_types
      body: SafeArea(
        // ignore: always_specify_types
        child: Query(
          // ignore: always_specify_types
          options: QueryOptions(document: gql(_query), fetchPolicy: FetchPolicy.networkOnly),
          // ignore: always_specify_types
          builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
            if (result.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (result.hasException) {
              return _ErrorView(message: result.exception.toString(), onRetry: refetch);
            }

            /// bus

            final List<dynamic> buses = (result.data?['buses'] as List<dynamic>?) ?? <dynamic>[];

            // endA -> [endB, ...]
            final Map<String, List<String>> busMap = <String, List<String>>{};
            for (final dynamic b in buses) {
              // ignore: always_specify_types
              final Map<String, dynamic> bm = (b as Map).cast<String, dynamic>();
              final String? endA = bm['endA'] as String?;
              final String? endB = bm['endB'] as String?;
              if (endA == null || endA.trim().isEmpty) {
                continue;
              }
              if (endB == null || endB.trim().isEmpty) {
                continue;
              }

              busMap.putIfAbsent(endA, () => <String>[]).add(endB);

              // あなたのコードに合わせて双方向も保持（必要ないなら削ってOK）
              busMap.putIfAbsent(endB, () => <String>[]).add(endA);
            }

            /// bus

            /// train
            final List<dynamic> trains = (result.data?['trains'] as List<dynamic>?) ?? <dynamic>[];

            // trainNumber -> trainName
            final Map<String, String> trainMap = <String, String>{};
            for (final dynamic t in trains) {
              // ignore: always_specify_types
              final Map<String, dynamic> tm = (t as Map).cast<String, dynamic>();
              final String? num = tm['trainNumber'] as String?;
              final String? name = tm['trainName'] as String?;
              if (num == null || num.trim().isEmpty) {
                continue;
              }
              if (name == null || name.trim().isEmpty) {
                continue;
              }
              trainMap[num] = name;
            }

            /// train

            /// station
            final List<dynamic> stationsRaw = (result.data?['stations'] as List<dynamic>?) ?? <dynamic>[];

            if (stationsRaw.isEmpty) {
              return const Center(child: Text('stations が空です'));
            }

            // =========================================================
            // ★ここが修正ポイント：
            // stations を trainNumber ごとにグルーピングして
            // 「路線ブロック順（trainNumbersForHeader）」に並べ直した stations を作る
            // その上で「各路線の先頭 index」を確定させる
            // =========================================================

            // 1) trainNumber -> stations のリスト（元の出現順のまま格納）
            final Map<String, List<Map<String, dynamic>>> stationsByTrain = <String, List<Map<String, dynamic>>>{};

            // trainNumber が空のものも一応保持（最後に回す）
            final List<Map<String, dynamic>> stationsNoTrain = <Map<String, dynamic>>[];

            for (final dynamic row in stationsRaw) {
              // ignore: always_specify_types
              final Map<String, dynamic> s = (row as Map).cast<String, dynamic>();
              final String tn = (s['trainNumber'] as String?) ?? '';
              if (tn.trim().isEmpty) {
                stationsNoTrain.add(s);
              } else {
                stationsByTrain.putIfAbsent(tn, () => <Map<String, dynamic>>[]).add(s);
              }
            }

            // stationName -> trainNumbers のマップ（ダイアログ用）
            final Map<String, List<String>> stationTrainMap = <String, List<String>>{};
            for (final dynamic row in stationsRaw) {
              // ignore: always_specify_types
              final Map<String, dynamic> s = (row as Map).cast<String, dynamic>();
              final String name = (s['stationName'] as String?) ?? '';
              final String tn = (s['trainNumber'] as String?) ?? '';
              if (name.isNotEmpty && tn.isNotEmpty) {
                stationTrainMap.putIfAbsent(name, () => <String>[]).add(tn);
              }
            }

            /// station

            // 2) 上部表示用：trainNumber の順序を作る
            //   - ここは「trainMapに存在する順（trainsの並び）」を優先
            //   - trainMapに無いが stations に居るものは後ろへ
            final List<String> trainNumbersForHeader = <String>[];

            // trains の順に並べる（stationsに存在するものだけ）
            for (final dynamic t in trains) {
              // ignore: always_specify_types
              final Map<String, dynamic> tm = (t as Map).cast<String, dynamic>();
              final String tn = (tm['trainNumber'] as String?) ?? '';
              if (tn.trim().isEmpty) {
                continue;
              }
              if (stationsByTrain.containsKey(tn)) {
                trainNumbersForHeader.add(tn);
              }
            }

            // trains に無い trainNumber も stations にいるなら追加
            for (final String tn in stationsByTrain.keys) {
              if (!trainNumbersForHeader.contains(tn)) {
                trainNumbersForHeader.add(tn);
              }
            }

            // 3) ヘッダー付きの混合リストを作る
            final List<_ListItem> items = <_ListItem>[];
            final Map<String, int> firstIndexByTrainNumber = <String, int>{};

            for (final String tn in trainNumbersForHeader) {
              final List<Map<String, dynamic>> list = stationsByTrain[tn] ?? <Map<String, dynamic>>[];
              if (list.isEmpty) {
                continue;
              }
              firstIndexByTrainNumber[tn] = items.length; // ★ヘッダー行のindex
              items.add(_TrainHeader(trainNumber: tn, trainName: trainMap[tn] ?? '路線 $tn'));
              for (final Map<String, dynamic> s in list) {
                items.add(_StationRow(data: s));
              }
            }

            // trainNumber が無い駅は最後に足す（ジャンプ対象にしない）
            for (final Map<String, dynamic> s in stationsNoTrain) {
              items.add(_StationRow(data: s));
            }

            // =========================================================

            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: '検索',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _searchController,
                              builder: (_, TextEditingValue value, __) {
                                if (value.text.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => _searchController.clear(),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (BuildContext ctx) {
                              final String query = _searchController.text;

                              // 前方一致で駅名を絞り込む
                              final List<MapEntry<String, List<String>>> results = stationTrainMap.entries
                                  .where((MapEntry<String, List<String>> e) => e.key.startsWith(query))
                                  .toList();

                              // station名 + 路線 を1本のフラットリストに展開
                              // [_SearchHeader(stationName), _SearchTrain(tn), ...]
                              final List<({bool isHeader, String stationName, String tn})> flatItems =
                                  <({bool isHeader, String stationName, String tn})>[];
                              for (final MapEntry<String, List<String>> entry in results) {
                                flatItems.add((isHeader: true, stationName: entry.key, tn: ''));
                                for (final String tn in entry.value) {
                                  flatItems.add((isHeader: false, stationName: entry.key, tn: tn));
                                }
                              }

                              return AlertDialog(
                                title: Text(query.isEmpty ? '検索結果' : '"$query" の検索結果'),
                                content: query.isEmpty
                                    ? const Text('（未入力）')
                                    : results.isEmpty
                                    ? const Text('該当する駅が見つかりませんでした')
                                    : SizedBox(
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: flatItems.length,
                                          itemBuilder: (_, int i) {
                                            final ({bool isHeader, String stationName, String tn}) item = flatItems[i];
                                            if (item.isHeader) {
                                              return Container(
                                                padding: const EdgeInsets.all(3),

                                                decoration: BoxDecoration(
                                                  color: Colors.yellowAccent.withValues(alpha: 0.1),
                                                ),
                                                child: Text(
                                                  item.stationName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              );
                                            }
                                            final String tn = item.tn;
                                            final String name = trainMap[tn] ?? '路線 $tn';
                                            return ListTile(
                                              dense: true,
                                              contentPadding: const EdgeInsets.only(left: 16),
                                              leading: const Icon(Icons.train),
                                              title: Text(name),
                                              subtitle: Text(tn),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                final int? targetIndex = firstIndexByTrainNumber[tn];
                                                if (targetIndex != null) {
                                                  _jumpToIndex(targetIndex);
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ),
                              );
                            },
                          );
                        },
                        child: const Text('検索'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ===== 上部：横向き CircleAvatar リスト =====
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    itemCount: trainNumbersForHeader.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final String tn = trainNumbersForHeader[index];
                      final String name = trainMap[tn] ?? '路線 $tn';

                      return InkWell(
                        borderRadius: BorderRadius.circular(40),
                        onTap: () {
                          final int? targetIndex = firstIndexByTrainNumber[tn];
                          if (targetIndex == null) {
                            return;
                          }
                          _jumpToIndex(targetIndex);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 28,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(name, textAlign: TextAlign.center, maxLines: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(tn, style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),

                // ===== 下：stationリスト（構造維持）=====
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      refetch?.call();
                    },
                    child: ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final _ListItem item = items[index];

                        // ヘッダーアイテム
                        if (item is _TrainHeader) {
                          return Container(
                            padding: const EdgeInsets.all(3),

                            margin: const EdgeInsets.only(top: 20),
                            decoration: BoxDecoration(color: Colors.yellowAccent.withValues(alpha: 0.2)),
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.train, size: 16, color: Colors.white70),
                                const SizedBox(width: 8),
                                Text(
                                  item.trainName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.trainNumber,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white38),
                                ),
                              ],
                            ),
                          );
                        }

                        final Map<String, dynamic> s = (item as _StationRow).data;

                        final String stationName = (s['stationName'] as String?) ?? '';
                        final String prefecture = (s['prefecture'] as String?) ?? '';
                        final String trainNumber = (s['trainNumber'] as String?) ?? '';
                        final String? trainName = trainNumber.isEmpty ? null : trainMap[trainNumber];

                        final List<String> children = busMap[stationName] ?? const <String>[];

                        String makeSubtitleBase() {
                          final List<String> parts = <String>[];
                          if (prefecture.isNotEmpty) {
                            parts.add(prefecture);
                          }
                          if (trainName != null && trainName.trim().isNotEmpty) {
                            parts.add('路線: $trainName');
                          } else if (trainNumber.trim().isNotEmpty) {
                            parts.add('路線番号: $trainNumber');
                          }
                          return parts.join(' / ');
                        }

                        final String baseSubtitle = makeSubtitleBase();

                        Widget tile;

                        if (children.isEmpty) {
                          tile = ListTile(
                            title: Text(stationName),
                            subtitle: baseSubtitle.isEmpty ? null : Text(baseSubtitle),
                          );
                        } else {
                          tile = Card(
                            elevation: 0,
                            child: ExpansionTile(
                              leading: const Icon(Icons.directions_bus),
                              title: Text(stationName),
                              subtitle: Text(
                                <String>[
                                  if (baseSubtitle.isNotEmpty) baseSubtitle,
                                  '${children.length} 件',
                                ].join('  /  '),
                              ),
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: Column(
                                    children: children
                                        .map(
                                          (String endB) => ListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            leading: const Icon(Icons.subdirectory_arrow_right),
                                            title: Text(endB),

                                            trailing: IconButton(
                                              icon: const Icon(Icons.info_outline),
                                              onPressed: () {
                                                final List<String> trainNumbers =
                                                    stationTrainMap[endB] ?? const <String>[];
                                                showDialog<void>(
                                                  context: context,
                                                  builder: (BuildContext ctx) {
                                                    return AlertDialog(
                                                      title: Text('$endB の電車'),
                                                      content: trainNumbers.isEmpty
                                                          ? const Text('電車情報がありません')
                                                          : SizedBox(
                                                              width: double.maxFinite,
                                                              child: ListView.builder(
                                                                shrinkWrap: true,
                                                                itemCount: trainNumbers.length,
                                                                itemBuilder: (_, int i) {
                                                                  final String tn = trainNumbers[i];
                                                                  final String name = trainMap[tn] ?? '路線 $tn';
                                                                  return ListTile(
                                                                    leading: const Icon(Icons.train),
                                                                    title: Text(name),
                                                                    subtitle: Text(tn),
                                                                    onTap: () {
                                                                      Navigator.pop(ctx);
                                                                      final int? targetIndex =
                                                                          firstIndexByTrainNumber[tn];
                                                                      if (targetIndex != null) {
                                                                        _jumpToIndex(targetIndex);
                                                                      }
                                                                    },
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: <Widget>[tile, if (index != items.length - 1) const Divider(height: 1)],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////

sealed class _ListItem {}

final class _TrainHeader extends _ListItem {
  _TrainHeader({required this.trainNumber, required this.trainName});

  final String trainNumber;
  final String trainName;
}

final class _StationRow extends _ListItem {
  _StationRow({required this.data});

  final Map<String, dynamic> data;
}

//////////////////////////////////////////////////////////////////

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  ///
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('再試行')),
        ],
      ),
    );
  }
}
