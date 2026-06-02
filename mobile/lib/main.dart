import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart' show FlutterNaverMap;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  await FlutterNaverMap().init(
    clientId: const String.fromEnvironment('NAVER_MAP_CLIENT_ID'),
  );

  runApp(const ProviderScope(child: App()));
}
