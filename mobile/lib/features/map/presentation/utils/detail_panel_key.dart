import 'package:flutter/widgets.dart';

ValueKey<String> detailPanelKey(String markerId, int session) =>
    ValueKey<String>('$markerId#$session');
