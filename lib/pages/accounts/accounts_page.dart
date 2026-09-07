import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:dollar_bills/models/account_model.dart';
import 'package:dollar_bills/models/category_model.dart';
import 'package:dollar_bills/pages/accounts/accounts_node.dart';
import 'package:dollar_bills/pages/accounts/add_account_dialog.dart';
import 'package:dollar_bills/pages/accounts/add_category_dialog.dart';
import 'package:dollar_bills/pages/shared/dialogs/app_snackbar.dart';
import 'package:dollar_bills/pages/shared/theme/app_icons.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';
import 'package:dollar_bills/pages/shared/widgets/custom_card.dart';
import 'package:dollar_bills/pages/shared/widgets/custom_scaffold.dart';
import 'package:trinity/widgets/node_provider.dart';
import 'package:trinity/widgets/signal_builder.dart';
import 'package:trinity/widgets/signal_listener.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openAddAccount(
    BuildContext context,
    AccountsNode node,
    List<CategoryModel> categories,
  ) async {
    final account = await showDialog<AccountModel>(
      context: context,
      builder: (_) => AddAccountDialog(
        categories: categories,
        onCategoryCreated: (cat) => node.saveCategory(cat),
      ),
    );
    if (account != null) {
      await node.saveAccount(account);
    }
  }

  Future<void> _openAddCategory(BuildContext context, AccountsNode node) async {
    final category = await showDialog<CategoryModel>(
      context: context,
      builder: (_) => const AddCategoryDialog(),
    );
    if (category != null) {
      await node.saveCategory(category);
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    AccountsNode node,
    AccountModel account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatusDialog(
        type: CustomSnackBarType.warning,
        title: 'Eliminar Cuenta',
        subtitle: '¿Estás seguro de eliminar la cuenta "${account.name}"?',
        continueText: 'Eliminar',
        cancelText: 'Cancelar',
        onContinue: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );

    if (confirmed == true) {
      await node.deleteAccount(account.id);
    }
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    AccountsNode node,
    CategoryModel category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatusDialog(
        type: CustomSnackBarType.warning,
        title: 'Eliminar Categoría',
        subtitle: '¿Deseas eliminar la categoría "${category.name}"?',
        continueText: 'Eliminar',
        cancelText: 'Cancelar',
        onContinue: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );

    if (confirmed == true) {
      await node.deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return NodeProvider.builder(
      create: () => AccountsNode(),
      builder: (context, node) {
        return SignalListenerMany(
          listeners: [
            SignalListenerItem.of(
              signal: node.error,
              listener: (previous, next) {
                if (next != null) {
                  node.clearError();
                  AppSnackBarWith(context).show(message: next);
                }
              },
            ),
            SignalListenerItem.of(
              signal: node.isSavedSuccess,
              listener: (previous, next) {
                if (next) {
                  node.isSavedSuccess.value = false;
                  AppSnackBarWith(context).show(
                    message: 'Guardado correctamente',
                    type: CustomSnackBarType.success,
                  );
                }
              },
            ),
            SignalListenerItem.of(
              signal: node.isDeletedSuccess,
              listener: (previous, next) {
                if (next) {
                  node.isDeletedSuccess.value = false;
                  AppSnackBarWith(context).show(
                    message: 'Eliminado correctamente',
                    type: CustomSnackBarType.success,
                  );
                }
              },
            ),
          ],
          child: SignalBuilderMany<ReadableAccountsNode>(
            signals: {
              node.accounts,
              node.categories,
              node.isLoading,
              node.fullScreenLoading,
            },
            builder: (context, readable) {
              final debts = readable.accounts.where((a) => a.isDebt).toList();
              final debtors = readable.accounts
                  .where((a) => a.isDebtor)
                  .toList();

              double totalDebt = debts.fold(
                0.0,
                (sum, a) => sum + a.currentAmount,
              );
              double totalDebtor = debtors.fold(
                0.0,
                (sum, a) => sum + a.currentAmount,
              );

              return CustomScaffold(
                title: 'Deudas y Deudores',
                showBackButton: false,
                fullScreenLoading: readable.fullScreenLoading,
                isLoading: readable.isLoading,
                onRefresh: node.fetchData,
                floatingActionButton: FloatingActionButton.extended(
                  heroTag: 'fab_accounts',
                  onPressed: () {
                    if (_tabController.index == 2) {
                      _openAddCategory(context, node);
                    } else {
                      _openAddAccount(context, node, readable.categories);
                    }
                  },
                  backgroundColor: HexColor.mintPrimary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    _tabController.index == 2 ? 'Categoría' : 'Nueva Cuenta',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                body: Column(
                  children: [
                    // Info banner regarding main balance independence
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: HexColor.mintLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: HexColor.mintPrimaryDark,
                            size: 18,
                          ),
                          const Gap(10),
                          Expanded(
                            child: Text(
                              'Estas cuentas registran lo que debes o te deben y no alteran tu balance de débito.',
                              style: TextStyle(
                                fontSize: 12,
                                color: HexColor.mintPrimaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: HexColor.backgroundGrey200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          labelColor: HexColor.mintPrimaryDark,
                          unselectedLabelColor: HexColor.textMuted,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          tabs: [
                            Tab(text: 'Deudas (${debts.length})'),
                            Tab(text: 'Deudores (${debtors.length})'),
                            Tab(
                              text:
                                  'Categorías (${readable.categories.length})',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tab View
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Deudas
                          _buildAccountsList(
                            context: context,
                            node: node,
                            accounts: debts,
                            totalAmount: totalDebt,
                            isDebt: true,
                            emptyTitle: 'No tienes deudas registradas',
                            currency: currency,
                          ),

                          // Tab 2: Deudores
                          _buildAccountsList(
                            context: context,
                            node: node,
                            accounts: debtors,
                            totalAmount: totalDebtor,
                            isDebt: false,
                            emptyTitle: 'No tienes deudores registrados',
                            currency: currency,
                          ),

                          // Tab 3: Categorías
                          _buildCategoriesList(
                            context: context,
                            node: node,
                            categories: readable.categories,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAccountsList({
    required BuildContext context,
    required AccountsNode node,
    required List<AccountModel> accounts,
    required double totalAmount,
    required bool isDebt,
    required String emptyTitle,
    required NumberFormat currency,
  }) {
    final color = isDebt ? HexColor.debtOrange : HexColor.debtorBlue;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Total Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDebt ? 'Total que debes' : 'Total que te deben',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    currency.format(totalAmount),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ],
              ),
              Icon(
                isDebt
                    ? Icons.money_off_csred_rounded
                    : Icons.attach_money_rounded,
                size: 36,
                color: color.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        const Gap(12),

        if (accounts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: HexColor.textMuted.withValues(alpha: 0.5),
                  ),
                  const Gap(12),
                  Text(
                    emptyTitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: HexColor.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...accounts.map(
            (account) => CustomCard(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: HexColor(account.colorHex).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppIcons.getIcon(account.iconCodePoint),
                      color: HexColor(account.colorHex),
                      size: 22,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: HexColor.textPrimary,
                          ),
                        ),
                        const Gap(4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: HexColor.mintLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            account.categoryName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: HexColor.mintPrimaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currency.format(account.currentAmount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      if (account.initialAmount != account.currentAmount) ...[
                        const Gap(2),
                        Text(
                          'Inicial: ${currency.format(account.initialAmount)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: HexColor.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Gap(6),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: HexColor.textMuted,
                    ),
                    onPressed: () =>
                        _confirmDeleteAccount(context, node, account),
                  ),
                ],
              ),
            ),
          ),
        const Gap(60),
      ],
    );
  }

  Widget _buildCategoriesList({
    required BuildContext context,
    required AccountsNode node,
    required List<CategoryModel> categories,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        ...categories.map(
          (cat) => CustomCard(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: HexColor(cat.colorHex).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.getIcon(cat.iconCodePoint),
                    color: HexColor(cat.colorHex),
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: HexColor.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: HexColor.textMuted,
                  ),
                  onPressed: () => _confirmDeleteCategory(context, node, cat),
                ),
              ],
            ),
          ),
        ),
        const Gap(60),
      ],
    );
  }
}
