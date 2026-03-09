import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../extensions/extensions.dart';
import '../../utility/utility.dart';
import '../parts/bus_info_dialog.dart';
import 'station_bus_route_map_alert.dart';

class StationBusRouteDisplayAlert extends StatefulWidget {
  const StationBusRouteDisplayAlert({
    super.key,
    required this.stationName,
    required this.stationLineListMap,
    required this.lineBusTotalInfoMap,
    required this.stationNameMap,
  });

  final String stationName;
  final Map<String, List<Map<String, String>>> lineBusTotalInfoMap;
  final Map<String, List<String>> stationLineListMap;
  final Map<String, String> stationNameMap;

  @override
  State<StationBusRouteDisplayAlert> createState() => _StationBusRouteDisplayAlertState();
}

class _StationBusRouteDisplayAlertState extends State<StationBusRouteDisplayAlert> {
  Utility utility = Utility();

  ///
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

      LatLng? p1;
      LatLng? p2;

      if (widget.lineBusTotalInfoMap[element] != null) {
        if (widget.lineBusTotalInfoMap[element]!.first['lat'] != null &&
            widget.lineBusTotalInfoMap[element]!.first['lon'] != null &&
            widget.lineBusTotalInfoMap[element]!.last['lat'] != null &&
            widget.lineBusTotalInfoMap[element]!.last['lon'] != null) {
          p1 = LatLng(
            widget.lineBusTotalInfoMap[element]!.first['lat']!.toDouble(),
            widget.lineBusTotalInfoMap[element]!.first['lon']!.toDouble(),
          );

          p2 = LatLng(
            widget.lineBusTotalInfoMap[element]!.last['lat']!.toDouble(),
            widget.lineBusTotalInfoMap[element]!.last['lon']!.toDouble(),
          );
        }
      }

      widget.lineBusTotalInfoMap[element]?.forEach((Map<String, String> element2) {
        final String rank = (element2['busStopOrderNum'] == null)
            ? ''
            : element2['busStopOrderNum'].toString().padLeft(2, '0');

        final String stationName = (element2['name'] == null)
            ? ''
            : utility.stationNameConverter(name: element2['name']!);

        // if (element2['name'] != null) {
        //   if (RegExp('駅').firstMatch(element2['name']!) != null) {
        //     print(element2['name']!);
        //
        //     print(utility.stationNameConverter(name: element2['name']!));
        //   }
        // }
        //
        //
        //

        list2.add(
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.3))),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Row(
                    children: <Widget>[
                      SizedBox(width: 30, child: Text(rank)),

                      Text(
                        element2['name'] ?? '',

                        style: TextStyle(
                          color: (widget.stationNameMap[stationName] != null) ? const Color(0xFFFBB6CE) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[Text(element2['lat'] ?? ''), Text(element2['lon'] ?? '')],
                  ),
                ),
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
              Stack(
                children: <Widget>[
                  if (p1 != null && p2 != null) ...<Widget>[
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Text(
                        '${utility.calculateDistance(p1, p2).toInt().toString().toCurrency().replaceAll(',', '.')} Km',
                      ),
                    ),
                  ],

                  Container(
                    decoration: BoxDecoration(color: Colors.yellowAccent.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.only(right: 10, left: 10, top: 5, bottom: 5),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(element.replaceAll('|', '\n')),

                              Row(
                                children: <Widget>[
                                  const Icon(Icons.arrow_downward, color: Colors.white60),
                                  const SizedBox(width: 10),
                                  Text(start),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  const Icon(Icons.arrow_upward, color: Colors.white60),
                                  const SizedBox(width: 10),
                                  Text(end),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        IconButton(
                          onPressed: () {
                            BusInfoDialog(
                              context: context,
                              widget: StationBusRouteMapAlert(lineBusRoute: widget.lineBusTotalInfoMap[element]),
                            );
                          },
                          icon: const Icon(Icons.map),
                        ),
                      ],
                    ),
                  ),
                ],
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
