class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const naverMapClientId = String.fromEnvironment('NAVER_MAP_CLIENT_ID');

  static const devUserId = '00000000-0000-0000-0000-000000000000';
  static const devTripId = '00000000-0000-0000-0000-000000000001';
}
