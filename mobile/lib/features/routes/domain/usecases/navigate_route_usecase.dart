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
      _ => _buildKakaoMapUrl(mode, waypoints),
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

  // 카카오맵 도보/대중교통
  Uri _buildKakaoMapUrl(TransportMode mode, List<TripMarker> waypoints) {
    final dest = waypoints.last;
    final modeParam = switch (mode) {
      TransportMode.foot => 'FOOT',
      TransportMode.publictransit => 'PUBLIC',
      TransportMode.bicycle => 'BICYCLE',
      _ => 'FOOT',
    };

    return Uri.parse(
      'kakaomap://route?ep=${dest.latitude},${dest.longitude}'
      '&by=$modeParam',
    );
  }
}
