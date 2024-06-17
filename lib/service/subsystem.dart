import 'package:phantom/service/graph.dart';
import 'package:phantom/service/service.dart';

@Node()
class Phantom {
  @OnStop()
  Future<void> onStart() async {}

  @OnStop()
  Future<void> onStop() async {}

  static Future<void> start(Type rootNodeType) async {
    await NodeGraph.addOrGet(Phantom, root: true);
    await NodeGraph.addOrGet(rootNodeType, root: true);
  }
}
