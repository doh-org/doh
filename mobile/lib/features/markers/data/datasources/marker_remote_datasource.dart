import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_model.dart';
import '../models/marker_model.dart';

part 'marker_remote_datasource.g.dart';

// DB는 geometry(POINT, 4326)로 저장 — 변환은 data layer 경계에서 처리
const _kMarkerSelect =
    'id, trip_id, category_id, created_by, name, '
    'location, '
    'address, memo, source, detail, visit_time, deleted_at, created_at';

// PostgREST가 반환하는 hex-encoded EWKB → lat/lng
({double lat, double lng}) _parseEwkbPoint(String hex) {
  final bytes = Uint8List.fromList(
    List.generate(
      hex.length ~/ 2,
      (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
    ),
  );
  final bd = ByteData.view(bytes.buffer);
  final isLE = bytes[0] == 1;
  final end = isLE ? Endian.little : Endian.big;
  final type = bd.getUint32(1, end);
  final hasSrid = (type & 0x20000000) != 0;
  final offset = hasSrid ? 9 : 5;
  return (
    lng: bd.getFloat64(offset, end),      // X = 경도
    lat: bd.getFloat64(offset + 8, end),  // Y = 위도
  );
}

// location(geometry hex)을 latitude/longitude로 변환해서 fromJson에 주입
Map<String, dynamic> _injectLatLng(Map<String, dynamic> json) {
  final hex = json['location'] as String? ?? '';
  final coords = _parseEwkbPoint(hex);
  return {...json, 'latitude': coords.lat, 'longitude': coords.lng};
}

@riverpod
MarkerRemoteDatasource markerRemoteDatasource(Ref ref) =>
    MarkerRemoteDatasource(Supabase.instance.client);

class MarkerRemoteDatasource {
  const MarkerRemoteDatasource(this._supabase);
  final SupabaseClient _supabase;

  Future<List<MarkerModel>> getMarkers(String tripId) async {
    final data = await _supabase
        .from('markers')
        .select(_kMarkerSelect)
        .eq('trip_id', tripId)
        .isFilter('deleted_at', null);
    return (data as List)
        .map((e) => MarkerModel.fromJson(_injectLatLng(e as Map<String, dynamic>)))
        .toList();
  }

  Future<MarkerModel> createMarker(Map<String, dynamic> body) async {
    final data = await _supabase
        .from('markers')
        .insert(body)
        .select(_kMarkerSelect)
        .single();
    return MarkerModel.fromJson(_injectLatLng(data));
  }

  Future<MarkerModel> updateMarker(
      String markerId, Map<String, dynamic> body) async {
    final data = await _supabase
        .from('markers')
        .update(body)
        .eq('id', markerId)
        .select(_kMarkerSelect)
        .single();
    return MarkerModel.fromJson(_injectLatLng(data));
  }

  Future<void> deleteMarker(String markerId) async {
    await _supabase
        .from('markers')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', markerId);
  }

  Future<List<CategoryModel>> getCategories(String tripId) async {
    final data = await _supabase
        .from('categories')
        .select()
        .eq('trip_id', tripId);
    return (data as List).map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
