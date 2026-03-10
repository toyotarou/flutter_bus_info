import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../utility/utility.dart';

part 'app_param.freezed.dart';

part 'app_param.g.dart';

@freezed
abstract class AppParamState with _$AppParamState {
  const factory AppParamState({@Default(0) double currentZoom, @Default(5) int currentPaddingIndex}) = _AppParamState;
}

@riverpod
class AppParam extends _$AppParam {
  final Utility utility = Utility();

  ///
  @override
  AppParamState build() => const AppParamState();

  ///
  void setCurrentZoom({required double zoom}) => state = state.copyWith(currentZoom: zoom);
}
