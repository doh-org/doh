class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  // 지도 SDK(렌더링) 전용 클라이언트 키 — 공개 가능, NCP 콘솔에서 패키지명 제한.
  // 시크릿(검색·역지오코딩)은 전부 Go 백엔드 프록시가 보관한다.
  static const naverMapClientId = String.fromEnvironment('NAVER_MAP_CLIENT_ID');
}
