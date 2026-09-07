// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// NodeGenerator
// **************************************************************************

part of 'accounts_node.dart';

class ReadableAccountsNode {
  final AccountsNode _node;
  const ReadableAccountsNode(this._node);

  List<AccountModel> get accounts => _node.accounts.value;
  List<CategoryModel> get categories => _node.categories.value;
  bool get isSavedSuccess => _node.isSavedSuccess.value;
  bool get isDeletedSuccess => _node.isDeletedSuccess.value;
  Object? get error => _node.error.value;
  bool get hasError => error != null;
  bool get isLoading => _node.isLoading.value;
  bool get fullScreenLoading => _node.fullScreenLoading.value;
}
