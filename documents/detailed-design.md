# 駅・バス情報ビューア 詳細設計書

> **この設計書について**
>
> 詳細設計書とは「プログラムをどう作るか」を書いたドキュメントです。
> 基本設計書（何を作るか）の次のステップにあたり、
> 開発者がコードを書くために必要な情報をすべて記載します。
>
> | セクション | 書く内容 | なぜ必要か |
> |---|---|---|
> | 1. システム概要 | アプリ全体の目的と構成 | 新メンバーが全体像を把握するため |
> | 2. アーキテクチャ | 技術選定と設計方針 | 「なぜこう作ったか」を残すため |
> | 3. ディレクトリ構成 | ファイルの配置ルール | どこに何があるか迷わないため |
> | 4. データ構造 | 変数の型と役割 | APIとの整合性を保つため |
> | 5. 画面設計 | 各画面のUI構成と動作 | 実装の仕様を明確にするため |
> | 6. データ加工処理 | マップの構築ロジック | 複雑な処理の流れを明確にするため |
> | 7. API連携 | GraphQLクエリと通信仕様 | サーバーとの契約を明文化するため |

---

## 1. システム概要

### 1.1 アプリの目的

東京都の鉄道駅・バス路線・鉄道路線の3種類のデータをGraphQLサーバーから取得し、
路線別グループ化・バス接続展開・電車情報ダイアログ・スクロールジャンプ機能を提供する情報閲覧アプリ。

### 1.2 主な機能

| 機能 | 概要 |
|---|---|
| 路線別駅一覧表示 | GraphQLから取得した駅を路線ごとにグループ化して表示 |
| 路線ナビゲーター | 上部の CircleAvatar をタップするとその路線の先頭駅へスクロール |
| バス接続展開 | バス路線がある駅を ExpansionTile で展開し、終点駅を表示 |
| 電車情報ダイアログ | バス終点駅を通る電車の一覧を AlertDialog で表示 |
| ダイアログからジャンプ | ダイアログの電車をタップして先頭駅へスクロール |
| Pull to Refresh | RefreshIndicator で最新データを再取得 |

### 1.3 動作環境

| 項目 | 値 |
|---|---|
| フレームワーク | Flutter 3.x (Dart 3.x) |
| 対応OS | Android / iOS |
| 外部APIサーバー | http://49.212.175.205:8081/graphql (GraphQL POST通信) |

---

## 2. アーキテクチャ（設計方針）

### 2.1 技術スタック

```
┌──────────────────────────────────────────────────────────────┐
│                         UI層                                  │
│  StatefulWidget (HomeScreen)                                  │
│  Query builder パターン (graphql_flutter)                     │
├──────────────────────────────────────────────────────────────┤
│                       データ加工層                             │
│  build() メソッド内でインライン処理                             │
│  busMap / trainMap / stationTrainMap / firstIndexByTrainNumber │
├──────────────────────────────────────────────────────────────┤
│                       通信層                                   │
│  graphql_flutter (Query ウィジェット + GraphQLClient)          │
│  HiveStore (レスポンスキャッシュ)                              │
├──────────────────────────────────────────────────────────────┤
│                    スクロール制御層                              │
│  scrollable_positioned_list (ItemScrollController)            │
└──────────────────────────────────────────────────────────────┘
              ↕ HTTP POST (GraphQL JSON)
┌──────────────────────────────────────────────────────────────┐
│          外部GraphQLサーバー (49.212.175.205:8081)             │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 設計ルール

| ルール | 説明 |
|---|---|
| 状態管理 | `StatefulWidget` は使用しない。データ加工・描画は `Query` ウィジェットの `builder` 内で完結させる |
| スクロール制御 | `ItemScrollController` を State に保持し、`_jumpToIndex()` 経由でスクロールする |
| データ加工 | `builder` 内で毎回計算する。再取得時も最新データが反映される |
| テーマ | ダークテーマ統一。`themeMode: ThemeMode.dark` を `MaterialApp` に設定 |
| エラー処理 | `result.hasException` が true のとき `_ErrorView` を表示する |

### 2.3 カラーパレット

| 用途 | 値 | 説明 |
|---|---|---|
| 背景 | `Colors.black` (#000000) | Scaffold 背景 |
| AppBar 背景 | `Color(0xFF111111)` | ほぼ黒 |
| カード背景 | `Color(0xFF1C1C1C)` | ダークグレー |
| ダイアログ背景 | `Color(0xFF1C1C1C)` | ダークグレー |
| 主色（seed） | `Colors.blueGrey` | `ColorScheme.fromSeed` のシードカラー |
| テキスト | `Colors.white` | ListTile などの本文 |
| サブテキスト・アイコン | `Colors.white60` | 補足情報 |
| Divider | `Colors.white12` | リスト区切り線 |

---

## 3. ディレクトリ構成

```
lib/
├── main.dart                    … アプリのエントリーポイント・テーマ設定
└── screens/
    └── home_screen.dart         … ホーム画面（データ取得・加工・表示をすべて担当）
```

### 配置ルール

| ファイル | 役割 |
|---|---|
| `main.dart` | `MyApp` / `GraphQLProvider` / `MaterialApp` の定義。テーマ設定のみを行い、ビジネスロジックは持たない |
| `screens/home_screen.dart` | `HomeScreen` / `_HomeScreenState` / `_ErrorView` の定義。データ取得・加工・描画をすべて担当 |

---

## 4. データ構造

### 4.1 GraphQL レスポンスの型

**stations（駅情報）:**

| フィールド | 型 | 説明 |
|---|---|---|
| id | String | 駅の一意識別子 |
| stationName | String | 駅名 |
| prefecture | String | 都道府県名（例: "東京都"） |
| trainNumber | String | 路線番号（例: "T-01"） |

**buses（バス情報）:**

| フィールド | 型 | 説明 |
|---|---|---|
| id | String | バス路線の一意識別子 |
| endA | String | バス路線の一端の駅名 |
| endB | String | バス路線の他端の駅名 |

**trains（路線情報）:**

| フィールド | 型 | 説明 |
|---|---|---|
| trainNumber | String | 路線番号（stations の trainNumber と対応） |
| trainName | String | 路線名（例: "山手線"） |

### 4.2 アプリ内の計算済みデータ構造

> **補足：** GraphQL レスポンスをそのまま使うのではなく、描画・検索の効率化のために各種マップを事前に計算する。これらはすべて `Query` の `builder` 内で毎回再計算される。

| 変数名 | 型 | 構築元 | 用途 |
|---|---|---|---|
| `busMap` | `Map<String, List<String>>` | buses | 駅名 → 接続するバス終点駅名のリスト |
| `trainMap` | `Map<String, String>` | trains | 路線番号 → 路線名 |
| `stationTrainMap` | `Map<String, List<String>>` | stationsRaw | 駅名 → その駅を通る路線番号のリスト（ダイアログ用） |
| `stationsByTrain` | `Map<String, List<Map<String, dynamic>>>` | stationsRaw | 路線番号 → 駅データのリスト（グループ化用） |
| `trainNumbersForHeader` | `List<String>` | trains + stationsByTrain | 上部ナビゲーターの路線番号リスト（表示順） |
| `firstIndexByTrainNumber` | `Map<String, int>` | stations（整列後） | 路線番号 → 整列済み駅リスト内の先頭インデックス |
| `stations` | `List<Map<String, dynamic>>` | stationsByTrain + stationsNoTrain | 整列済み・フラット化された最終的な駅リスト |

---

## 5. 画面設計

### 5.1 エントリーポイント (main.dart)

```dart
// 初期化処理
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter();  // HiveStoreの初期化
  runApp(const MyApp());
}
```

**MyApp の構成:**

```
MyApp (StatelessWidget)
  └── GraphQLProvider
        client: GraphQLClient(
          link: HttpLink('http://49.212.175.205:8081/graphql'),
          cache: GraphQLCache(store: HiveStore()),
        )
        └── MaterialApp
              debugShowCheckedModeBanner: false
              themeMode: ThemeMode.dark
              darkTheme: ThemeData(...)  ← 下記参照
              home: HomeScreen
```

**darkTheme の設定:**

| 設定 | 値 |
|---|---|
| `useMaterial3` | `true` |
| `colorScheme` | `ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark)` |
| `scaffoldBackgroundColor` | `Colors.black` |
| `appBarTheme.backgroundColor` | `Color(0xFF111111)` |
| `appBarTheme.foregroundColor` | `Colors.white` |
| `appBarTheme.elevation` | `0` |
| `cardTheme.color` | `Color(0xFF1C1C1C)` |
| `dividerTheme.color` | `Colors.white12` |
| `listTileTheme.textColor` | `Colors.white` |
| `listTileTheme.iconColor` | `Colors.white60` |
| `expansionTileTheme.textColor` | `Colors.white` |
| `expansionTileTheme.iconColor` | `Colors.white60` |
| `dialogTheme.backgroundColor` | `Color(0xFF1C1C1C)` |

### 5.2 ホーム画面 (HomeScreen)

**ウィジェットの種別:** `StatefulWidget`（`ItemScrollController` の保持のため）

**Stateが保持するもの:**

| フィールド | 型 | 説明 |
|---|---|---|
| `_itemScrollController` | `ItemScrollController` | `ScrollablePositionedList` のスクロール制御 |

**`_jumpToIndex(int index)` メソッド:**

```dart
void _jumpToIndex(int index) {
  if (!_itemScrollController.isAttached) return;  // リストが未表示なら何もしない

  _itemScrollController.scrollTo(
    index: index,
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeInOut,
    alignment: 0.0,  // アイテムをリスト先頭に揃える
  );
}
```

**画面の全体ウィジェットツリー:**

```
Scaffold
  appBar: AppBar(title: 'Stations + Bus children')
  body: Query(options: QueryOptions(document: gql(_query), fetchPolicy: networkOnly))
    builder: (result, {refetch, fetchMore})
      [ローディング中] → CircularProgressIndicator
      [エラー]        → _ErrorView(message, onRetry: refetch)
      [正常]          → Column
                          ├── SizedBox(height: 100)  ← 上部ナビゲーター
                          │     ListView.separated(scrollDirection: horizontal)
                          │       itemBuilder: InkWell + Column(CircleAvatar + Text)
                          ├── Divider(height: 1)
                          └── Expanded
                                RefreshIndicator(onRefresh: refetch)
                                  ScrollablePositionedList.builder
                                    itemBuilder: Column(tile + Divider)
```

**上部ナビゲーター（路線アイコン）の実装仕様:**

```dart
// 各路線アイコンのWidget
InkWell(
  borderRadius: BorderRadius.circular(40),
  onTap: () {
    final int? targetIndex = firstIndexByTrainNumber[tn];
    if (targetIndex == null) return;
    _jumpToIndex(targetIndex);
  },
  child: Column(
    children: [
      CircleAvatar(
        radius: 28,
        child: Padding(
          padding: EdgeInsets.all(6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(name, textAlign: TextAlign.center, maxLines: 2),
          ),
        ),
      ),
      SizedBox(height: 6),
      Text(tn, style: Theme.of(context).textTheme.labelSmall),  // 路線番号
    ],
  ),
)
```

**駅リストアイテムの実装仕様:**

バス接続なしの駅:
```dart
ListTile(
  title: Text(stationName),
  subtitle: Text(baseSubtitle),  // 都道府県 / 路線名
)
```

バス接続ありの駅:
```dart
Card(
  elevation: 0,
  child: ExpansionTile(
    leading: Icon(Icons.directions_bus),
    title: Text(stationName),
    subtitle: Text('$baseSubtitle  /  ${children.length} 件'),
    children: [
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          children: children.map((endB) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.subdirectory_arrow_right),
            title: Text(endB),
            trailing: IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () => /* 電車情報ダイアログを表示 */,
            ),
          )).toList(),
        ),
      ),
    ],
  ),
)
```

**subtitle の構築ルール (`makeSubtitleBase()`):**

| 条件 | 表示内容 |
|---|---|
| prefecture が空でない | 都道府県名を追加 |
| trainName が存在する | `路線: {trainName}` を追加 |
| trainName がなく trainNumber が空でない | `路線番号: {trainNumber}` を追加 |
| 複数項目がある場合 | ` / ` で結合 |

### 5.3 電車情報ダイアログ

**表示トリガー:** `IconButton(Icons.info_outline)` の `onPressed`

**実装仕様:**

```dart
onPressed: () {
  final List<String> trainNumbers = stationTrainMap[endB] ?? const [];

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
                      Navigator.pop(ctx);  // 1. ダイアログを閉じる
                      final int? targetIndex = firstIndexByTrainNumber[tn];
                      if (targetIndex != null) {
                        _jumpToIndex(targetIndex);  // 2. 先頭駅へスクロール
                      }
                    },
                  );
                },
              ),
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      );
    },
  );
}
```

**ダイアログの仕様まとめ:**

| 要素 | 値 |
|---|---|
| タイトル | `'{endB} の電車'` |
| 電車あり | `ListView.builder` で電車一覧を表示 |
| 電車なし | `'電車情報がありません'` のテキストを表示 |
| 電車タップ | `Navigator.pop(ctx)` → `_jumpToIndex(firstIndexByTrainNumber[tn])` |
| 閉じるボタン | `Navigator.pop(ctx)` のみ（スクロールなし） |

### 5.4 エラービュー (_ErrorView)

```dart
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  // 表示内容:
  // Icons.error_outline (size: 40)
  // エラーメッセージテキスト (fontSize: 12)
  // ElevatedButton('再試行', onPressed: onRetry)
}
```

---

## 6. データ加工処理

> **このセクションの目的：** `Query` の `builder` 内で行われる複雑なデータ加工の流れを明確にする。処理の順番が重要なため、ステップ番号付きで記述する。

### 6.1 全体の処理フロー

```
GraphQL レスポンス (result.data)
    │
    ├── 1. busMap の構築
    │
    ├── 2. trainMap の構築
    │
    ├── 3. stationsByTrain の構築 + stationTrainMap の構築
    │
    ├── 4. trainNumbersForHeader の構築（表示順の確定）
    │
    ├── 5. stations（整列済みフラットリスト）と firstIndexByTrainNumber の構築
    │
    └── 6. Column の描画
```

### 6.2 ステップ1: busMap の構築

**目的:** 駅名から接続するバス終点駅のリストを引けるようにする

```dart
final Map<String, List<String>> busMap = {};
for (final b in buses) {
  final String? endA = bm['endA'];
  final String? endB = bm['endB'];
  if (endA == null || endA.trim().isEmpty) continue;
  if (endB == null || endB.trim().isEmpty) continue;

  // 双方向で登録
  busMap.putIfAbsent(endA, () => []).add(endB);
  busMap.putIfAbsent(endB, () => []).add(endA);
}
```

> **補足：** 双方向で登録することで、どちらの駅からも相手側の駅を検索できる。

### 6.3 ステップ2: trainMap の構築

**目的:** 路線番号から路線名を素早く引けるようにする

```dart
final Map<String, String> trainMap = {};
for (final t in trains) {
  final String? num = tm['trainNumber'];
  final String? name = tm['trainName'];
  if (num == null || name == null) continue;
  trainMap[num] = name;
}
```

### 6.4 ステップ3: stationsByTrain と stationTrainMap の構築

**目的1 (stationsByTrain):** 路線番号ごとに駅をグループ化する（路線ブロック表示用）

**目的2 (stationTrainMap):** 駅名からその駅を通る路線番号リストを引く（ダイアログ用）

```dart
final Map<String, List<Map<String, dynamic>>> stationsByTrain = {};
final List<Map<String, dynamic>> stationsNoTrain = [];  // 路線番号なしの駅
final Map<String, List<String>> stationTrainMap = {};

for (final row in stationsRaw) {
  final String tn = s['trainNumber'] ?? '';
  if (tn.trim().isEmpty) {
    stationsNoTrain.add(s);  // 路線番号なし → 末尾グループへ
  } else {
    stationsByTrain.putIfAbsent(tn, () => []).add(s);
  }

  // stationTrainMap の構築
  final String name = s['stationName'] ?? '';
  if (name.isNotEmpty && tn.isNotEmpty) {
    stationTrainMap.putIfAbsent(name, () => []).add(tn);
  }
}
```

### 6.5 ステップ4: trainNumbersForHeader の構築

**目的:** 上部ナビゲーターと駅リストの表示順を確定する

**優先順位:**
1. `trains` 配列の順番（APIが返す路線の並び順）を優先
2. `trains` に存在しないが `stations` にある路線番号を末尾に追加

```dart
final List<String> trainNumbersForHeader = [];

// trains の順に並べる（stationsに存在するものだけ）
for (final t in trains) {
  final String tn = tm['trainNumber'] ?? '';
  if (stationsByTrain.containsKey(tn)) {
    trainNumbersForHeader.add(tn);
  }
}

// trains に無いが stations に存在する路線番号を末尾に追加
for (final String tn in stationsByTrain.keys) {
  if (!trainNumbersForHeader.contains(tn)) {
    trainNumbersForHeader.add(tn);
  }
}
```

### 6.6 ステップ5: stations（整列済みリスト）と firstIndexByTrainNumber の構築

**目的:** `ScrollablePositionedList` に渡すフラットな駅リストを作りながら、各路線の先頭インデックスを記録する

```dart
final List<Map<String, dynamic>> stations = [];
final Map<String, int> firstIndexByTrainNumber = {};

for (final String tn in trainNumbersForHeader) {
  final list = stationsByTrain[tn] ?? [];
  if (list.isEmpty) continue;

  firstIndexByTrainNumber[tn] = stations.length;  // ★ この時点の長さが先頭インデックス
  stations.addAll(list);
}

// 路線番号なし駅は最後（ジャンプ対象にしない）
stations.addAll(stationsNoTrain);
```

> **補足：** `firstIndexByTrainNumber[tn] = stations.length` を `addAll` の前に記録することがポイント。`addAll` 後だと次の路線の先頭インデックスになってしまう。

---

## 7. API連携仕様

### 7.1 共通仕様

| 項目 | 値 |
|---|---|
| エンドポイント | `http://49.212.175.205:8081/graphql` |
| 通信方式 | HTTP POST |
| データ形式 | GraphQL (JSON) |
| フェッチポリシー | `FetchPolicy.networkOnly` |
| キャッシュ | `GraphQLCache(store: HiveStore())` |

### 7.2 GraphQL クエリ

```graphql
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
```

### 7.3 Query ウィジェットの使用方法

```dart
Query(
  options: QueryOptions(
    document: gql(_query),
    fetchPolicy: FetchPolicy.networkOnly,
  ),
  builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
    if (result.isLoading) return CircularProgressIndicator();
    if (result.hasException) return _ErrorView(message: ..., onRetry: refetch);

    final List<dynamic> buses = result.data?['buses'] ?? [];
    final List<dynamic> trains = result.data?['trains'] ?? [];
    final List<dynamic> stationsRaw = result.data?['stations'] ?? [];
    // ... データ加工・描画
  },
)
```

### 7.4 エラーハンドリング

| 状態 | 処理 |
|---|---|
| `result.isLoading == true` | `CircularProgressIndicator()` を表示 |
| `result.hasException == true` | `_ErrorView` を表示。`onRetry: refetch` でリトライ可能 |
| `stationsRaw.isEmpty` | `'stations が空です'` のテキストを表示 |
| endA または endB が空文字 | `busMap` への登録をスキップ（`continue`） |
| trainNumber または trainName が空文字 | `trainMap` への登録をスキップ（`continue`） |

---

## 8. スクロール制御仕様

### 8.1 ItemScrollController の初期化

```dart
// State クラスのフィールドとして宣言
final ItemScrollController _itemScrollController = ItemScrollController();

// ScrollablePositionedList に渡す
ScrollablePositionedList.builder(
  itemScrollController: _itemScrollController,
  // ...
)
```

> **補足：** `_itemScrollController.isAttached` は `ScrollablePositionedList` が画面に表示された後に `true` になる。表示前にスクロールを試みると例外が発生するため、`isAttached` チェックが必要。

### 8.2 _jumpToIndex の仕様

```
引数:    index (int) - 移動先の駅リストインデックス
処理:
  1. _itemScrollController.isAttached が false なら即座にreturn
  2. scrollTo() を呼び出す
      - index: 引数のindex
      - duration: 450ms
      - curve: Curves.easeInOut
      - alignment: 0.0 (アイテムをビューポートの先頭に揃える)
```

### 8.3 alignment の意味

| alignment | 動作 |
|---|---|
| `0.0` | アイテムをリストビューの **先頭** に揃える |
| `0.5` | アイテムをリストビューの **中央** に揃える |
| `1.0` | アイテムをリストビューの **末尾** に揃える |

本アプリでは `0.0` を使用し、路線の先頭駅が画面の一番上に表示される。

---

## 9. ビルド手順

### 9.1 前提条件

```
- Flutter SDK: 3.x 以上（Dart SDK 3.x を含む）
- Android Studio または Xcode（実機テスト用）
```

### 9.2 依存パッケージ

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  graphql_flutter: ^5.2.1
  scrollable_positioned_list: ^0.3.8
```

> **補足：** `graphql_flutter` は内部的に `hive` を使用するため、`initHiveForFlutter()` を `main()` で呼び出す必要がある。

### 9.3 実行コマンド

```bash
cd test_flutter_bus_info

# パッケージインストール
flutter pub get

# デバッグビルド＆実行
flutter run

# APK生成 (Android)
flutter build apk

# IPA生成 (iOS) ※要Xcodeと証明書
flutter build ipa
```

### 9.4 動作確認チェックリスト

| # | 確認内容 | 確認方法 |
|---|---|---|
| 1 | 起動後に駅一覧が表示される | 目視確認 |
| 2 | 上部の路線アイコンをタップするとスクロールされる | 各アイコンをタップして確認 |
| 3 | バスアイコン付きの駅をタップすると展開される | 展開・折りたたみを確認 |
| 4 | ℹ️ボタンをタップするとダイアログが表示される | 複数の駅で確認 |
| 5 | ダイアログの電車をタップするとジャンプする | スクロール先が正しいか確認 |
| 6 | 「閉じる」でダイアログが閉じるだけ（スクロールなし） | 目視確認 |
| 7 | Pull to Refresh でリロードされる | 下に引っ張って確認 |
| 8 | APIエラー時にリトライボタンが表示される | サーバー停止または不正URLで確認 |
| 9 | ダークテーマで表示される | 目視確認 |

---

## 改訂履歴

| 版 | 日付 | 内容 |
|---|---|---|
| 1.0 | 2026-03-03 | 初版作成 |
