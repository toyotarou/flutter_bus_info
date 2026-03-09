import 'package:latlong2/latlong.dart';

class Utility {
  ///
  String stationNameConverter({required String name}) {
    final int idx = name.indexOf('駅');
    if (idx != -1) {
      String name2 = name.substring(0, idx);

      // if (RegExp('千').firstMatch(name2) != null) {
      //   print(name2);
      // }

      name2 = name2.replaceAll('阿佐ヶ谷', '阿佐ケ谷');

      name2 = name2.replaceAll('四谷', '四ツ谷');

      name2 = name2.replaceAll('市ヶ谷', '市ケ谷');

      name2 = name2.replaceAll('千駄ヶ谷', '千駄ケ谷');

      return name2;
    } else {
      return name;
    }
  }

  ///
  double calculateDistance(LatLng p1, LatLng p2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, p1, p2);
  }
}
