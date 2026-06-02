class NaverPlace {
  const NaverPlace({
    required this.title,
    required this.category,
    required this.address,
    required this.mapx,
    required this.mapy,
    this.telephone,
  });

  final String title;
  final String category;
  final String address;
  final String mapx;
  final String mapy;
  final String? telephone;

  double get latitude => double.parse(mapy) / 10000000;
  double get longitude => double.parse(mapx) / 10000000;

  Map<String, dynamic> toDetail() => {
        'naver_category': category,
        'naver_address': address,
        'naver_phone': telephone ?? '',
      };

  factory NaverPlace.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] as String? ?? '';
    final category =
        (json['category'] as String? ?? '').split('>').last.trim();
    final roadAddress = json['roadAddress'] as String? ?? '';
    return NaverPlace(
      title: rawTitle.replaceAll(RegExp(r'<[^>]*>'), ''),
      category: category.isEmpty ? '기타' : category,
      address:
          roadAddress.isNotEmpty ? roadAddress : (json['address'] as String? ?? ''),
      mapx: json['mapx'] as String? ?? '0',
      mapy: json['mapy'] as String? ?? '0',
      telephone: json['telephone'] as String?,
    );
  }
}
