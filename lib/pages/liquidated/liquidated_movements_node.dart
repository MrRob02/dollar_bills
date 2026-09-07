import 'dart:developer';
import 'package:dollar_bills/models/movement_model.dart';
import 'package:dollar_bills/services/movements_service.dart';
import 'package:trinity/trinity.dart';
import 'package:trinity_generator/trinity_generator.dart';

part 'liquidated_movements_node.readable.dart';

@Readable()
class LiquidatedMovementsNode extends NodeInterface {
  late final liquidatedMovements = registerSignal(ListSignal<MovementModel>([]));
  late final isUnliquidatedSuccess = registerSignal(Signal<bool>(false));

  final MovementsService _movementsService = MovementsService();

  LiquidatedMovementsNode() {
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      await loading(
        () async {
          final list = await _movementsService.getLiquidatedMovements();
          liquidatedMovements.value = list;
        },
        fullScreen: liquidatedMovements.isEmpty,
      );
    } catch (e, st) {
      log('LiquidatedMovementsNode fetchData error: $e\n$st');
    }
  }

  Future<void> unliquidateMovement(String id) async {
    try {
      await loading(() async {
        await _movementsService.unliquidateMovement(id);
        await fetchData();
        isUnliquidatedSuccess.value = true;
      });
    } catch (e, st) {
      log('LiquidatedMovementsNode unliquidateMovement error: $e\n$st');
    }
  }

  @override
  ReadableLiquidatedMovementsNode get readable =>
      ReadableLiquidatedMovementsNode(this);
}
