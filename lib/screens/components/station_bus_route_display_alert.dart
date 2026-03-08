import 'package:flutter/material.dart';

class StationBusRouteDisplayAlert extends StatefulWidget {
  const StationBusRouteDisplayAlert({
    super.key,
    required this.stationName,
    required this.stationLineListMap,
    required this.lineBusTotalInfoMap,
  });

  final String stationName;
  final Map<String, List<Map<String, String>>> lineBusTotalInfoMap;
  final Map<String, List<String>> stationLineListMap;

  @override
  State<StationBusRouteDisplayAlert> createState() => _StationBusRouteDisplayAlertState();
}

class _StationBusRouteDisplayAlertState extends State<StationBusRouteDisplayAlert> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: SafeArea(
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),

          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[Text('bus stop list'), SizedBox.shrink()],
                ),

                Divider(color: Colors.white.withOpacity(0.4), thickness: 5),

                Expanded(child: displayBusStopList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///
  Widget displayBusStopList() {
    final List<Widget> list = <Widget>[];

    List<String>? stationLineList = widget.stationLineListMap[widget.stationName];

    stationLineList = stationLineList?.toSet().toList();

    stationLineList?.sort();

    stationLineList?.forEach((String element) {
      final List<Widget> list2 = <Widget>[];
      widget.lineBusTotalInfoMap[element]?.forEach((Map<String, String> element2) {
        list2.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[Text(element2['name'] ?? ''), Text(element2['busStopOrderNum'] ?? '')],
          ),
        );
      });

      list.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(element),

            Column(crossAxisAlignment: CrossAxisAlignment.start, children: list2),
          ],
        ),
      );
    });

    return CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) => list[index],
            childCount: list.length,
          ),
        ),
      ],
    );
  }
}
