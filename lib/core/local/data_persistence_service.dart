import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dollar_bills/core/local/hive_boxes.dart';

class DataPersistenceService {
  static Future<void> init() async {
    try {
      final path = (await getApplicationDocumentsDirectory()).path;
      Hive.init(path);
      await Hive.openBoxes();
      log('Dollar bills: Hive boxes opened successfully at $path');
    } catch (e, st) {
      debugPrint('Error initializing Hive: $e\n$st');
      rethrow;
    }
  }

  static Box get metadataBox => Hive.box('metadata');
  static Box get movementsBox => Hive.box('movements');
  static Box get accountsBox => Hive.box('accounts');
  static Box get categoriesBox => Hive.box('categories');
  static Box get settingsBox => Hive.box('settings');

  static Future<void> clearAll() async => await Hive.clearAllBoxes();
}
