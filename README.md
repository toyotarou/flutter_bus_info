# TOKYO BUS INFO

東京都内のバス・鉄道路線情報を GraphQL API から取得し、路線別に駅を一覧表示する Flutter 製アプリ。駅に紐づくバス路線の確認や地図表示も行える。

---

## 主な機能

- **路線別駅一覧**：鉄道路線ごとに駅をグループ化し、ExpansionTile で折り畳み/展開表示
- **横スクロール路線ナビ**：上部の路線アイコンをタップすると該当グループへスムーズスクロール
- **全グループ折りたたみ**：閉じるボタン一発で全路線グループを折りたたむ
- **駅名検索**：前方一致で駅名を検索し、結果から路線グループへジャンプ
- **バス路線表示**：バス接続がある駅は行き先一覧を表示（双方向対応）
- **目的地の電車情報**：バス行き先をタップすると、その駅に乗り入れる鉄道路線を確認可能
- **バスルート詳細**：バス路線の全停留所一覧をダイアログ表示
- **バスルート地図表示**：OpenStreetMap (flutter_map) で停留所を地図上にプロット
- **プルリフレッシュ**：画面を引き下げてデータを再取得
- **GraphQL キャッシュ**：HiveStore によるオフラインキャッシュ対応
- **ダークテーマ**：Material 3 ダークテーマ固定

---

## 技術スタック

| 分類 | 技術 |
|------|------|
| フレームワーク | Flutter / Dart |
| API 通信 | graphql_flutter（GraphQL + HiveStore キャッシュ） |
| 状態管理 | Riverpod (hooks_riverpod / flutter_riverpod / riverpod_annotation) |
| コード生成 | Freezed / json_serializable / build_runner |
| 地図 | flutter_map + latlong2 (OpenStreetMap) |
| スクロール | scrollable_positioned_list / scroll_to_index |
| HTTP | http / cached_network_image / flutter_cache_manager |
| アイコン | font_awesome_flutter |
| ユーティリティ | url_launcher / equatable / intl |
| テーマ | Material 3 ダークテーマ固定 |
| 向き | 縦向き固定（portraitUp / portraitDown） |

---

## アーキテクチャ

```
lib/
├── main.dart                                      # エントリーポイント・GraphQLProvider 設定
├── const/                                         # 定数定義
├── controllers/
│   ├── controllers_mixin.dart                     # コントローラー統合 Mixin
│   └── app_param/
│       └── app_param.dart                         # アプリ状態管理 Riverpod ノーティファイア
├── extensions/                                    # 拡張メソッド
├── screens/
│   ├── home_screen.dart                           # メイン画面（路線・駅・バス一覧）
│   ├── components/
│   │   ├── station_bus_route_display_alert.dart   # バスルート詳細ダイアログ
│   │   └── station_bus_route_map_alert.dart       # バスルート地図ダイアログ
│   └── parts/
│       └── bus_info_dialog.dart                   # バス情報ダイアログラッパー
└── utility/
    └── utility.dart                               # ユーティリティ（駅名変換など）
```

---

## GraphQL クエリ

GraphQL エンドポイント：`http://<サーバー>/graphql`

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
  busTotalInfo {
    operator
    line
    stops {
      orderNum
      name
      lat
      lon
      busStopOrderNum
    }
  }
}
```

| フィールド | 説明 |
|-----------|------|
| stations | 東京都内の駅一覧（路線番号付き） |
| buses | バス路線の起終点ペア（endA ↔ endB 双方向） |
| trains | 路線番号と路線名のマスタ |
| busTotalInfo | バス事業者・路線・全停留所情報（緯度経度付き） |

---

## アプリ状態管理 (AppParamState)

| 状態 | 型 | 説明 |
|------|-----|------|
| currentZoom | double | 地図の現在ズームレベル |
| currentPaddingIndex | int | 現在のパディングインデックス |

---

## セットアップ

### 前提条件
- Flutter SDK 3.x 以上
- Dart SDK ^3.10.8

### インストール

```bash
git clone https://github.com/toyotarou/flutter_bus_info.git
cd flutter_bus_info
flutter pub get
```

### コード生成

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 実行

```bash
flutter run
```

> GraphQL サーバーへの接続が必要です。`lib/main.dart` 内の `endpoint` を環境に合わせて変更してください。
