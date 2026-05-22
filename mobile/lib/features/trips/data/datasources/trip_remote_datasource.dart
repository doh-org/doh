import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/trip_model.dart';

part 'trip_remote_datasource.g.dart';

@riverpod
TripRemoteDatasource tripRemoteDatasource(Ref ref) =>
    TripRemoteDatasource(Supabase.instance.client);

class TripRemoteDatasource {
  const TripRemoteDatasource(this._supabase);
  final SupabaseClient _supabase;

  Future<List<TripModel>> getTrips() async {
    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('trip_members')
        .select('trips(*)')
        .eq('user_id', userId);

    return (data as List)
        .map((e) => TripModel.fromJson(e['trips'] as Map<String, dynamic>))
        .toList();
  }

  Future<TripModel> getTrip(String tripId) async {
    final data = await _supabase
        .from('trips')
        .select()
        .eq('id', tripId)
        .single();
    return TripModel.fromJson(data);
  }

  Future<TripModel> createTrip(Map<String, dynamic> body) async {
    final data = await _supabase.from('trips').insert(body).select().single();
    return TripModel.fromJson(data);
  }

  Future<TripModel> updateTrip(String tripId, Map<String, dynamic> body) async {
    final data = await _supabase
        .from('trips')
        .update(body)
        .eq('id', tripId)
        .select()
        .single();
    return TripModel.fromJson(data);
  }

  Future<void> deleteTrip(String tripId) async {
    await _supabase
        .from('trips')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', tripId);
  }
}
