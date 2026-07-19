// 통합 검색(/places/search) 결과 장소. 네이버·카카오 공통 형식.
class Place {
  const Place({
    required this.title,
    required this.category,
    required this.categoryPath,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.telephone,
  });

  final String title;
  final String category;      // 마지막 세그먼트 (표시용)
  final String categoryPath;  // 전체 경로 (카테고리 분류용)
  final String address;
  final double latitude;
  final double longitude;
  final String telephone;

  Map<String, dynamic> toDetail() => {
        'category': category,
        'category_path': categoryPath,
        'address': address,
        'phone': telephone,
      };

  factory Place.fromJson(Map<String, dynamic> json) {
    final String rawCategory = json['category'] as String? ?? '';
    final String category = rawCategory.split('>').last.trim();
    final String roadAddress = json['roadAddress'] as String? ?? '';
    return Place(
      title: json['title'] as String? ?? '',
      category: category.isEmpty ? '기타' : category,
      categoryPath: rawCategory,
      address: roadAddress.isNotEmpty
          ? roadAddress
          : (json['address'] as String? ?? ''),
      // 백엔드가 WGS84 number 보장 — mapx=경도, mapy=위도
      longitude: (json['mapx'] as num).toDouble(),
      latitude: (json['mapy'] as num).toDouble(),
      telephone: json['telephone'] as String? ?? '',
    );
  }
}
