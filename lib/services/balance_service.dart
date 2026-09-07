import 'package:dollar_bills/core/local/data_persistence_service.dart';
import 'package:dollar_bills/models/movement_model.dart';
import 'package:dollar_bills/models/user_settings_model.dart';

class BalanceService {
  static const String _settingsKey = 'user_settings';

  UserSettingsModel getSettings() {
    final raw = DataPersistenceService.settingsBox.get(_settingsKey);
    if (raw == null) {
      return const UserSettingsModel();
    }
    return UserSettingsModel.fromMap(Map<dynamic, dynamic>.from(raw));
  }

  Future<void> saveSettings(UserSettingsModel settings) async {
    await DataPersistenceService.settingsBox.put(_settingsKey, settings.toMap());
  }

  Future<UserSettingsModel> setInitialBalance(double balance) async {
    final settings = UserSettingsModel(
      currentBalance: balance,
      initialBalance: balance,
      isInitialSetupDone: true,
    );
    await saveSettings(settings);
    return settings;
  }

  Future<UserSettingsModel> updateCurrentBalance(double newBalance) async {
    final current = getSettings();
    final updated = current.copyWith(currentBalance: newBalance);
    await saveSettings(updated);
    return updated;
  }

  Future<UserSettingsModel> applyMovement(MovementModel movement) async {
    if (!movement.affectsMainBalance) return getSettings();
    final current = getSettings();
    final double delta = movement.isIncome ? movement.amount : -movement.amount;
    final updated = current.copyWith(
      currentBalance: current.currentBalance + delta,
    );
    await saveSettings(updated);
    return updated;
  }

  Future<UserSettingsModel> revertMovement(MovementModel movement) async {
    if (!movement.affectsMainBalance) return getSettings();
    final current = getSettings();
    final double delta = movement.isIncome ? -movement.amount : movement.amount;
    final updated = current.copyWith(
      currentBalance: current.currentBalance + delta,
    );
    await saveSettings(updated);
    return updated;
  }
}
