// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// NodeGenerator
// **************************************************************************

part of 'movements_node.dart';

class ReadableMovementsNode {
  final MovementsNode _node;
  const ReadableMovementsNode(this._node);

  List<MovementModel> get movements => _node.movements.value;
  double get balance => _node.balance.value;
  bool get isInitialSetupDone => _node.isInitialSetupDone.value;
  bool get isLiquidatedSuccess => _node.isLiquidatedSuccess.value;
  bool get isDeletedSuccess => _node.isDeletedSuccess.value;
  bool get isUpdatedSuccess => _node.isUpdatedSuccess.value;
  DateTime get selectedMonth => _node.selectedMonth.value;
  Object? get error => _node.error.value;
  bool get hasError => error != null;
  bool get isLoading => _node.isLoading.value;
  bool get fullScreenLoading => _node.fullScreenLoading.value;
}
