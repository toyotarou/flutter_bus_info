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
      appBar: AppBar(title: const Text('Stations + Bus children')),
      // ignore: always_specify_types
      body: Query(
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

          // 3) 並べ替え後の stations を作る
          final List<Map<String, dynamic>> stations = <Map<String, dynamic>>[];
          final Map<String, int> firstIndexByTrainNumber = <String, int>{};

          for (final String tn in trainNumbersForHeader) {
            final List<Map<String, dynamic>> list = stationsByTrain[tn] ?? <Map<String, dynamic>>[];
            if (list.isEmpty) {
              continue;
            }
            firstIndexByTrainNumber[tn] = stations.length; // ★ここが「路線ブロックの頭」
            stations.addAll(list);
          }

          // trainNumber が無い駅は最後に足す（ジャンプ対象にしない）
          stations.addAll(stationsNoTrain);

          // =========================================================

          return Column(
            children: <Widget>[
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
                    itemCount: stations.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> s = stations[index];

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
                              <String>[if (baseSubtitle.isNotEmpty) baseSubtitle, '${children.length} 件'].join('  /  '),
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
                                                    actions: <Widget>[
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(ctx),
                                                        child: const Text('閉じる'),
                                                      ),
                                                    ],
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
                        children: <Widget>[tile, if (index != stations.length - 1) const Divider(height: 1)],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
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
