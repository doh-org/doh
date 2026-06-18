import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 앱 전역 TextField 커서 색. 커서 서식을 한 곳에서 관리한다.
/// width·radius는 전 TextField가 Flutter 기본값으로 이미 통일돼 색만 함수화.
Color appCursorColor() => AppColors.folderOrange;
