import 'dart:developer';

import 'package:dollar_bills/models/account_model.dart';
import 'package:dollar_bills/models/category_model.dart';
import 'package:dollar_bills/services/accounts_service.dart';
import 'package:dollar_bills/services/movements_service.dart';
import 'package:trinity/trinity.dart';
import 'package:trinity_generator/trinity_generator.dart';

part 'accounts_node.readable.dart';

@Readable()
class AccountsNode extends NodeInterface {
  late final accounts = registerSignal(ListSignal<AccountModel>([]));
  late final categories = registerSignal(ListSignal<CategoryModel>([]));
  late final isSavedSuccess = registerSignal(Signal<bool>(false));
  late final isDeletedSuccess = registerSignal(Signal<bool>(false));

  final AccountsService _accountsService = AccountsService();
  final MovementsService _movementsService = MovementsService();

  AccountsNode() {
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      await loading(() async {
        final cats = await _accountsService.getCategories();
        final liquidated = await _movementsService.getLiquidatedMovements();
        final accs = await _accountsService.getAccounts(liquidated);
        categories.value = cats;
        accounts.value = accs;
      }, fullScreen: accounts.isEmpty && categories.isEmpty);
    } catch (e, st) {
      log('AccountsNode fetchData error: $e\n$st');
    }
  }

  Future<void> saveAccount(AccountModel account) async {
    try {
      await loading(() async {
        await _accountsService.saveAccount(account);
        isSavedSuccess.value = true;
      });
      await fetchData();
    } catch (e, st) {
      log('AccountsNode saveAccount error: $e\n$st');
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await loading(() async {
        await _accountsService.deleteAccount(id);
        await fetchData();
        isDeletedSuccess.value = true;
      });
    } catch (e, st) {
      log('AccountsNode deleteAccount error: $e\n$st');
    }
  }

  Future<void> saveCategory(CategoryModel category) async {
    try {
      await loading(() async {
        await _accountsService.saveCategory(category);
        await fetchData();
        isSavedSuccess.value = true;
      });
    } catch (e, st) {
      log('AccountsNode saveCategory error: $e\n$st');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await loading(() async {
        await _accountsService.deleteCategory(id);
        await fetchData();
        isDeletedSuccess.value = true;
      });
    } catch (e, st) {
      log('AccountsNode deleteCategory error: $e\n$st');
    }
  }

  @override
  ReadableAccountsNode get readable => ReadableAccountsNode(this);
}
