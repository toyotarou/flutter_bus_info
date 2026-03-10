import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

///////////////////////////////////////////

class CachedTileProvider extends TileProvider {
  CachedTileProvider({BaseCacheManager? cacheManager}) : cacheManager = cacheManager ?? DefaultCacheManager();

  final BaseCacheManager cacheManager;

  ///
  /// flutter_map が Tile を描画するための ImageProvider を返す
  ///
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final String url = getTileUrl(coordinates, options);

    final Map<String, String> headers = _buildHeaders();

    return CachedNetworkImage(url, cacheManager: cacheManager, headers: headers);
  }

  ///
  /// urlTemplate から実URLを組み立て
  ///
  @override
  String getTileUrl(TileCoordinates coordinates, TileLayer options) {
    final String? template = options.urlTemplate;
    if (template == null || template.isEmpty) {
      throw StateError('TileLayer.urlTemplate is null/empty.');
    }

    // {s} や {r} が混ざっていても最低限動くようにしておく
    // - {s}: サブドメイン指定。使わない場合は空 or 適当値で置換
    // - {r}: retina 用。使わない場合は空でOK
    return template
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString())
        .replaceAll('{s}', 'a')
        .replaceAll('{r}', '');
  }

  Map<String, String> _buildHeaders() {
    // 固定User-Agent（flutter_map旧バージョン対応）
    final String ua = 'com.example.app (flutter_map; ${kIsWeb ? "web" : Platform.operatingSystem})';

    return <String, String>{'User-Agent': ua};
  }
}

///////////////////////////////////////////

class CachedNetworkImage extends ImageProvider<CachedNetworkImage> {
  CachedNetworkImage(this.url, {required this.cacheManager, this.headers = const <String, String>{}});

  final String url;
  final BaseCacheManager cacheManager;
  final Map<String, String> headers;

  ///
  @override
  Future<CachedNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CachedNetworkImage>(this);
  }

  ///
  /// Flutter 3.x 系で一般的なパス（loadImage）
  ///
  @override
  ImageStreamCompleter loadImage(CachedNetworkImage key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(_loadAsync(key, decode));
  }

  ///
  /// 互換用（古いSDKで呼ばれることがある）
  ///
  @override
  ImageStreamCompleter loadBuffer(
    CachedNetworkImage key,
    Future<ui.Codec> Function(ui.ImmutableBuffer buffer, {int? cacheWidth, int? cacheHeight}) decode,
  ) {
    return OneFrameImageStreamCompleter(_loadAsyncOldDecode(key, decode));
  }

  ///
  Future<ImageInfo> _loadAsync(CachedNetworkImage key, ImageDecoderCallback decode) async {
    try {
      // headers 付きでキャッシュ取得（なければDL）
      final File file = await cacheManager.getSingleFile(key.url, headers: headers);
      final Uint8List bytes = await file.readAsBytes();

      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final ui.Codec codec = await decode(buffer);
      final ui.FrameInfo frame = await codec.getNextFrame();

      return ImageInfo(image: frame.image);
    } catch (e, st) {
      Error.throwWithStackTrace(Exception('Failed to load tile image: url=$url, error=$e'), st);
    }
  }

  ///
  Future<ImageInfo> _loadAsyncOldDecode(
    CachedNetworkImage key,
    Future<ui.Codec> Function(ui.ImmutableBuffer buffer, {int? cacheWidth, int? cacheHeight}) decode,
  ) async {
    try {
      final File file = await cacheManager.getSingleFile(key.url, headers: headers);
      final Uint8List bytes = await file.readAsBytes();

      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final ui.Codec codec = await decode(buffer);
      final ui.FrameInfo frame = await codec.getNextFrame();

      return ImageInfo(image: frame.image);
    } catch (e, st) {
      Error.throwWithStackTrace(Exception('Failed to load tile image: url=$url, error=$e'), st);
    }
  }

  ///
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    return other is CachedNetworkImage && other.url == url;
  }

  ///
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => url.hashCode;
}
