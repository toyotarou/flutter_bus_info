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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[Text(widget.stationName), const SizedBox.shrink()],
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
        final String rank = (element2['busStopOrderNum'] == null)
            ? ''
            : element2['busStopOrderNum'].toString().padLeft(2, '0');

        list2.add(
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.3))),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(width: 30, child: Text(rank)),

                Text(element2['name'] ?? ''),
              ],
            ),
          ),
        );
      });

      String start = '';
      String end = '';

      if (widget.lineBusTotalInfoMap[element] != null) {
        start = widget.lineBusTotalInfoMap[element]!.first.values.first;
        end = widget.lineBusTotalInfoMap[element]!.last.values.first;
      }

      list.add(
        DefaultTextStyle(
          style: const TextStyle(fontSize: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(color: Colors.yellowAccent.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(element.replaceAll('|', '\n'))),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[Text(start), Text(end)],
                      ),
                    ),

                    const SizedBox(width: 10),

                    const Icon(Icons.map),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Column(crossAxisAlignment: CrossAxisAlignment.start, children: list2),

              const SizedBox(height: 20),
            ],
          ),
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
