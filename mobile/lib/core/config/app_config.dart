class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const naverMapClientId = String.fromEnvironment('NAVER_MAP_CLIENT_ID');
  static const naverMapClientSecret =
      String.fromEnvironment('NAVER_MAP_CLIENT_SECRET');
}
