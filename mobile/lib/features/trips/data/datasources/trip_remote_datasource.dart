import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../models/trip_model.dart';

part 'trip_remote_datasource.g.dart';

@riverpod
TripRemoteDatasource tripRemoteDatasource(Ref ref) =>
    TripRemoteDatasource(ref.watch(apiClientProvider));

class TripRemoteDatasource {
  const TripRemoteDatasource(this._dio);
  final Dio _dio;

  Future<List<TripModel>> getTrips() async {
    final response = await _dio.get('/api/v1/trips');
    return (response.data as List)
        .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TripModel> getTrip(String tripId) async {
    final response = await _dio.get('/api/v1/trips/$tripId');
    return TripModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TripModel> createTrip(Map<String, dynamic> body) async {
    final response = await _dio.post('/api/v1/trips/add', data: body);
    return TripModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TripModel> updateTrip(String tripId, Map<String, dynamic> body) async {
    final response = await _dio.patch('/api/v1/trips/$tripId', data: body);
    return TripModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTrip(String tripId) async {
    await _dio.delete('/api/v1/trips/$tripId');
  }
}
