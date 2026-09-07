import 'package:dollar_bills/core/local/data_persistence_service.dart';
import 'package:dollar_bills/models/account_model.dart';
import 'package:dollar_bills/models/category_model.dart';
import 'package:dollar_bills/models/movement_model.dart';

class AccountsService {
  Future<List<CategoryModel>> getCategories() async {
    final box = DataPersistenceService.categoriesBox;
    if (box.isEmpty) {
      await _seedDefaultCategories();
    }
    final List<CategoryModel> list = [];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        list.add(CategoryModel.fromMap(Map<dynamic, dynamic>.from(raw)));
      }
    }
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<void> saveCategory(CategoryModel category) async {
    await DataPersistenceService.categoriesBox.put(category.id, category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await DataPersistenceService.categoriesBox.delete(id);
  }

  static String _cleanStr(String s) {
    return s
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  Future<List<AccountModel>> getAccounts([
    List<MovementModel>? liquidatedMovements,
  ]) async {
    final box = DataPersistenceService.accountsBox;
    final List<AccountModel> list = [];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        list.add(AccountModel.fromMap(Map<dynamic, dynamic>.from(raw)));
      }
    }

    // Auto-reconcile account currentAmount with all liquidated movements
    if (liquidatedMovements != null) {
      for (int i = 0; i < list.length; i++) {
        final acc = list[i];
        final accCleanName = _cleanStr(acc.name);

        double totalExpensePayments = 0.0;
        double totalIncomePayments = 0.0;

        for (final m in liquidatedMovements) {
          final matches = (acc.id.isNotEmpty && m.accountId == acc.id) ||
              (m.accountName != null &&
                  _cleanStr(m.accountName!) == accCleanName) ||
              _cleanStr(m.title) == accCleanName;

          if (matches) {
            if (m.isExpense) {
              totalExpensePayments += m.amount;
            } else if (m.isIncome) {
              totalIncomePayments += m.amount;
            }
          }
        }

        double reconciledAmount = acc.initialAmount;
        if (acc.isDebt) {
          // Deuda se reduce cuando pagamos una salida (gasto), y aumenta con entradas
          reconciledAmount = (acc.initialAmount - totalExpensePayments + totalIncomePayments)
              .clamp(0.0, double.infinity);
        } else {
          // Deudor se reduce cuando nos pagan (entrada), y aumenta si prestamos más (salida)
          reconciledAmount = (acc.initialAmount - totalIncomePayments + totalExpensePayments)
              .clamp(0.0, double.infinity);
        }

        if ((reconciledAmount - acc.currentAmount).abs() > 0.001) {
          final updated = acc.copyWith(currentAmount: reconciledAmount);
          await box.put(updated.id, updated.toMap());
          list[i] = updated;
        }
      }
    }

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<AccountModel?> getAccountById(String id) async {
    final raw = DataPersistenceService.accountsBox.get(id);
    if (raw == null) return null;
    return AccountModel.fromMap(Map<dynamic, dynamic>.from(raw));
  }

  Future<void> saveAccount(AccountModel account) async {
    await DataPersistenceService.accountsBox.put(account.id, account.toMap());
  }

  Future<void> deleteAccount(String id) async {
    await DataPersistenceService.accountsBox.delete(id);
  }

  Future<void> adjustAccountForMovement({
    String? accountId,
    String? accountName,
    required MovementType type,
    required double amount,
    bool isRevert = false,
  }) async {
    AccountModel? account;
    if (accountId != null && accountId.isNotEmpty && accountId != 'main') {
      account = await getAccountById(accountId);
    }
    if (account == null && accountName != null && accountName.trim().isNotEmpty) {
      final all = await getAccounts();
      final target = _cleanStr(accountName);
      try {
        account = all.firstWhere(
          (a) => _cleanStr(a.name) == target,
        );
      } catch (_) {}
    }
    if (account == null) return;

    final double sign = isRevert ? -1.0 : 1.0;
    double netChange = 0.0;
    if (account.isDebt) {
      // Deuda: salida reduce lo que debo (-), entrada aumenta lo que debo (+)
      netChange = (type == MovementType.expense ? -amount : amount) * sign;
    } else {
      // Deudor: entrada reduce lo que me deben (-), salida aumenta lo que me deben (+)
      netChange = (type == MovementType.income ? -amount : amount) * sign;
    }

    final updated = account.copyWith(
      currentAmount:
          (account.currentAmount + netChange).clamp(0.0, double.infinity),
    );
    await saveAccount(updated);
  }

  Future<void> adjustAccountAmount(
    String? accountId,
    double delta, {
    String? accountName,
  }) async {
    AccountModel? account;
    if (accountId != null && accountId.isNotEmpty && accountId != 'main') {
      account = await getAccountById(accountId);
    }
    if (account == null && accountName != null && accountName.trim().isNotEmpty) {
      final all = await getAccounts();
      final target = _cleanStr(accountName);
      try {
        account = all.firstWhere(
          (a) => _cleanStr(a.name) == target,
        );
      } catch (_) {}
    }
    if (account == null) return;

    final updated = account.copyWith(
      currentAmount:
          (account.currentAmount + delta).clamp(0.0, double.infinity),
    );
    await saveAccount(updated);
  }

  Future<void> _seedDefaultCategories() async {
    final defaults = [
      const CategoryModel(
        id: 'cat_banks',
        name: 'Tarjetas y Bancos',
        iconCodePoint: 0xe19f, // credit_card
        colorHex: 'FF3EB489',
      ),
      const CategoryModel(
        id: 'cat_loans',
        name: 'Préstamos Personales',
        iconCodePoint: 0xe49e, // payments
        colorHex: 'FFF59E0B',
      ),
      const CategoryModel(
        id: 'cat_family',
        name: 'Familia y Amigos',
        iconCodePoint: 0xe491, // people
        colorHex: 'FF3B82F6',
      ),
      const CategoryModel(
        id: 'cat_services',
        name: 'Servicios e Impuestos',
        iconCodePoint: 0xe518, // receipt_long
        colorHex: 'FF8B5CF6',
      ),
    ];
    for (final cat in defaults) {
      await saveCategory(cat);
    }
  }
}
