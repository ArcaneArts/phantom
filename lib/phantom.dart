library phantom;

import 'package:phantom/node/node.dart';
import 'package:phantom/node/pool.dart';
import 'package:phantom/node/storage.dart';
import 'package:phantom/node/traits/hotloadable.dart';
import 'package:phantom/node/traits/lifecycle.dart';
import 'package:phantom/node/traits/stateful.dart';
import 'package:phantom/node/traits/ticked.dart';

void main() async {
  NodePool n = NodePool(storage: FileConfigJSONNodeSettings());
  await n.start(Main);
}

class Main with Node implements Lifecycle, Stateful, Hotloadable, Ticked {
  int specialCode = 0;

  Main();

  @override
  Future<void> onStart() async {
    logger.noticeAnnouncement("Main has Started special code $specialCode");
  }

  @override
  Future<void> onStop() async {}

  @override
  Future<void> onLoad(Map<String, dynamic> state) async {
    specialCode = state["specialCode"] ?? specialCode;
  }

  @override
  Future<Map<String, dynamic>> onSave() async => {"specialCode": specialCode};

  @override
  Future<void> onHotload(Map<String, dynamic> newConfig) async {
    await onLoad(newConfig);
    await shallowRestart();
  }

  @override
  Future<Duration> onTick(double time, double delta, int ticks) async {
    logger.verbose("Main Tick $ticks, delta $delta, tick #$ticks");

    if (ticks > 10) {
      destroy();
    }

    return Duration(milliseconds: 250);
  }
}
