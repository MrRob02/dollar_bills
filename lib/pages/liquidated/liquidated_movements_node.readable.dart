// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// NodeGenerator
// **************************************************************************

part of 'liquidated_movements_node.dart';

class ReadableLiquidatedMovementsNode {
  final LiquidatedMovementsNode _node;
  const ReadableLiquidatedMovementsNode(this._node);

  List<MovementModel> get liquidatedMovements =>
      _node.liquidatedMovements.value;
  bool get isUnliquidatedSuccess => _node.isUnliquidatedSuccess.value;
  Object? get error => _node.error.value;
  bool get hasError => error != null;
  bool get isLoading => _node.isLoading.value;
  bool get fullScreenLoading => _node.fullScreenLoading.value;
}
