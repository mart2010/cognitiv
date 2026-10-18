import 'dart:convert';
import 'dart:io';

import 'package:cartographer/cartographer.dart';

/// La vraie Carte de base générée (Amérique du Sud), pour des tests sur des faits connus.
BaseMap loadSouthAmerica() => BaseMapCodec.fromJson(
      jsonDecode(File('data/south_america.json').readAsStringSync()) as Map<String, dynamic>,
    );
