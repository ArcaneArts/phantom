import 'package:phantom/node/node.dart';
import 'package:phantom/node/traits/lifecycle.dart';
import 'package:phantom/node/traits/stateful.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

class Main with Node implements Lifecycle, Stateful {
  int specialCode = 0;

  Main();

  @override
  Future<void> onStart() async {
    logger.info("Source File: ${$sourceCodeFile}");
  }

  @override
  Future<void> onStop() async {}

  @override
  Future<void> onLoad(Map<String, dynamic> state,
      {bool hotloaded = false}) async {
    specialCode = state["specialCode"] ?? specialCode;
  }

  @override
  Future<Map<String, dynamic>> onSave() async =>
      toJson() as Map<String, dynamic>;
}
