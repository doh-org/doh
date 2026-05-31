import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/route_model.dart';

part 'route_remote_datasource.g.dart';

@riverpod
RouteRemoteDatasource routeRemoteDatasource(Ref ref) =>
    RouteRemoteDatasource(Supabase.instance.client);

class RouteRemoteDatasource {
  const RouteRemoteDatasource(this._supabase);
  final SupabaseClient _supabase;

  Future<List<RouteModel>> getRoutes(String tripId) async {
    final data = await _supabase
        .from('routes')
        .select()
        .eq('trip_id', tripId);
    return (data as List).map((e) => RouteModel.fromJson(e)).toList();
  }

  Future<RouteModel> createRoute(Map<String, dynamic> body) async {
    final data = await _supabase.from('routes').insert(body).select().single();
    return RouteModel.fromJson(data);
  }

  Future<void> deleteRoute(String routeId) async {
    await _supabase.from('routes').delete().eq('id', routeId);
  }

  Future<List<Map<String, dynamic>>> getWaypoints(String routeId) async {
    final data = await _supabase
        .from('route_waypoints')
        .select()
        .eq('route_id', routeId)
        .order('order');
    return List<Map<String, dynamic>>.from(data);
  }
}
