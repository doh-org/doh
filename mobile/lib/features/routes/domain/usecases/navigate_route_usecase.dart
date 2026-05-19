import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/trip_route.dart';
import '../../../markers/domain/entities/marker.dart';

class NavigateRouteUsecase {
  Future<void> call(
    TransportMode mode,
    List<TripMarker> waypoints,
  ) async {
    if (waypoints.isEmpty) return;

    final uri = switch (mode) {
      TransportMode.car => _buildTimapUrl(waypoints),
      _ => _buildNaverMapUrl(mode, waypoints),
    };

    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // 티맵 차량 경로
  Uri _buildTimapUrl(List<TripMarker> waypoints) {
    final dest = waypoints.last;
    final viaPoints = waypoints.sublist(0, waypoints.length - 1);

    final params = {
      'goalname': dest.name,
      'goalx': '${dest.longitude}',
      'goaly': '${dest.latitude}',
      for (var i = 0; i < viaPoints.length && i < 5; i++) ...{
        'via${i}name': viaPoints[i].name,
        'via${i}x': '${viaPoints[i].longitude}',
        'via${i}y': '${viaPoints[i].latitude}',
      },
    };

    return Uri(
      scheme: 'tmap',
      host: 'route',
      queryParameters: params,
    );
  }

  // 네이버맵 도보/대중교통/자전거
  Uri _buildNaverMapUrl(TransportMode mode, List<TripMarker> waypoints) {
    final dest = waypoints.last;
    final routeType = switch (mode) {
      TransportMode.foot => 'foot',
      TransportMode.publictransit => 'public',
      TransportMode.bicycle => 'bicycle',
      _ => 'foot',
    };

    return Uri(
      scheme: 'nmap',
      host: 'route',
      pathSegments: [routeType],
      queryParameters: {
        'dlat': '${dest.latitude}',
        'dlng': '${dest.longitude}',
        'dname': dest.name,
        'appname': 'com.doh.memotrip',
      },
    );
  }
}
