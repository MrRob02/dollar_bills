import 'package:hive_ce/hive.dart';

extension HiveBoxes on HiveInterface {
  Future<void> openBoxes() async {
    await Future.wait([
      Hive.openBox('metadata'),
      Hive.openBox('movements'),
      Hive.openBox('accounts'),
      Hive.openBox('categories'),
      Hive.openBox('settings'),
    ]);
  }

  Future<void> clearAllBoxes() async {
    await Future.wait([
      Hive.box('metadata').clear(),
      Hive.box('movements').clear(),
      Hive.box('accounts').clear(),
      Hive.box('categories').clear(),
      Hive.box('settings').clear(),
    ]);
  }
}
