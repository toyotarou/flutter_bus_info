import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StationBusRouteMapAlert extends ConsumerStatefulWidget {
  const StationBusRouteMapAlert({super.key, this.lineBusRoute});

  final List<Map<String, String>>? lineBusRoute;

  @override
  ConsumerState<StationBusRouteMapAlert> createState() => _StationBusRouteMapAlertState();
}

class _StationBusRouteMapAlertState extends ConsumerState<StationBusRouteMapAlert> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
