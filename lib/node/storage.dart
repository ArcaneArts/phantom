import 'package:phantom/node/traits/stateful.dart';
import 'package:phantom/util/logger.dart';

abstract class NodeStorage {
  Future<void> write(Stateful node, Map<String, dynamic> data);

  Future<Map<String, dynamic>> read(Stateful node);
}

class DummyNodeStorage extends NodeStorage {
  final PLogger logger = PLogger("&eDummyStorage");

  DummyNodeStorage();

  @override
  Future<Map<String, dynamic>> read(Stateful node) async {
    logger.verbose("&mReading ${node.storageKey} as {}");
    return {};
  }

  @override
  Future<void> write(Stateful node, Map<String, dynamic> data) async {
    logger.verbose("&mWriting ${node.storageKey} as $data");
  }
}
