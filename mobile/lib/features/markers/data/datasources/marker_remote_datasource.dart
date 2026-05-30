import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_model.dart';
import '../models/marker_model.dart';

part 'marker_remote_datasource.g.dart';

@riverpod
MarkerRemoteDatasource markerRemoteDatasource(Ref ref) =>
    MarkerRemoteDatasource(Supabase.instance.client);

class MarkerRemoteDatasource {
  const MarkerRemoteDatasource(this._supabase);
  final SupabaseClient _supabase;

  Future<List<MarkerModel>> getMarkers(String tripId) async {
    final data = await _supabase
        .from('markers')
        .select()
        .eq('trip_id', tripId)
        .isFilter('deleted_at', null);
    return (data as List).map((e) => MarkerModel.fromJson(e)).toList();
  }

  Future<MarkerModel> createMarker(Map<String, dynamic> body) async {
    final data = await _supabase.from('markers').insert(body).select().single();
    return MarkerModel.fromJson(data);
  }

  Future<MarkerModel> updateMarker(
      String markerId, Map<String, dynamic> body) async {
    final data = await _supabase
        .from('markers')
        .update(body)
        .eq('id', markerId)
        .select()
        .single();
    return MarkerModel.fromJson(data);
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
    return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
  }
}
