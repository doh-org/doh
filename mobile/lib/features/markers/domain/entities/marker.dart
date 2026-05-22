import 'package:freezed_annotation/freezed_annotation.dart';

part 'marker.freezed.dart';

enum MarkerSource { search, longpress, share }

@freezed
abstract class TripMarker with _$TripMarker {
  const factory TripMarker({
    required String id,
    required String tripId,
    String? categoryId,
    String? createdBy,
    required String name,
    required double latitude,
    required double longitude,
    String? address,
    String? memo,
    required MarkerSource source,
    required Map<String, dynamic> detail,
    DateTime? visitTime,
    DateTime? deletedAt,
    required DateTime createdAt,
  }) = _TripMarker;
}
