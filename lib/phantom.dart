library phantom;

import 'package:phantom/node/node.dart';
import 'package:phantom/node/pool.dart';
import 'package:phantom/node/storage.dart';
import 'package:phantom/node/traits/lifecycle.dart';
import 'package:phantom/node/traits/stateful.dart';

void main() async {
  NodePool n = NodePool(storage: DummyNodeStorage());
  await n.start(Main);

  Node secondNode = await n.addOrGetNode(Main, tag: "secondary", root: true);

  print(
      "NNN: ${n.nodes.map((i) => "${i.logger.nodeName}#${i.$rootNode ? "?" : i.$referenceCount}").join(", ")}");

  print("STOPPING SECOND NODE");
  await n.removeNode(Main, tag: "secondary");

  print(
      "NNN: ${n.nodes.map((i) => "${i.logger.nodeName}#${i.$rootNode ? "?" : i.$referenceCount}").join(", ")}");

  print("REMOVING MAIN NODE");
  await n.removeNode(Main);

  print(
      "NNN: ${n.nodes.map((i) => "${i.logger.nodeName}#${i.$rootNode ? "?" : i.$referenceCount}").join(", ")}");
}

class Main with Node implements Lifecycle {
  late final DB database;
  late final Connector connector;
  late final Connector connector2;
  late final Connector connector3;
  late final Connector connector4;

  Main();

  @override
  Future<void> onStart() async {
    logger.noticeAnnouncement("Main has Started");
  }

  @override
  Future<void> onStop() async {}
}

class Connector with Node implements Lifecycle {
  late final DB database;

  Connector();

  @override
  Future<void> onStart() async {}

  @override
  Future<void> onStop() async {}
}

class DB with Node implements Lifecycle, Stateful {
  @override
  Future<void> onStart() async {
    await Future.delayed(Duration(milliseconds: 250), () {});
  }

  @override
  Future<void> onStop() async {}

  @override
  Future<void> onLoad(Map<String, dynamic> state) async {}

  @override
  Future<Map<String, dynamic>> onSave() {
    return Future.value({"key": "value"});
  }
}
