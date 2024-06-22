import 'package:phantom/node/node.dart';
import 'package:phantom/node/storage.dart';
import 'package:phantom/node/trait.dart';
import 'package:precision_stopwatch/precision_stopwatch.dart';

/// Designates a node as a Lifecycle node, meaning it has onStart and onStop methods.
/// If you only need light construction without futures, it's better to just use the constructor.
abstract class Lifecycle implements Trait {
  /// Called when the node is started. This is where you should initialize your node.
  /// If you are using a stateful node, your state was already loaded by this point
  Future<void> onStart();

  /// Called when the node is stopped. You may still write to your state as
  /// the node will save its state after this method is called.
  Future<void> onStop();

  static Future<void> $callStart(
      Node node, NodeStorage storage, PrecisionStopwatch wallClock) async {
    if (node is Lifecycle) {
      if ((node as Lifecycle).$isRunning == true) {
        node.logger
            .warn("Node is already running? Call start was called twice?");
      }

      await (node as Lifecycle).onStart();
      node.$metadata["lifecycle.running"] = true;
      node.logger.info(
          "Started in ${wallClock.getMilliseconds().toStringAsFixed(0)}ms");
    }
  }

  static Future<void> $callStop(
      Node node, NodeStorage storage, PrecisionStopwatch wallClock) async {
    if (node is Lifecycle) {
      if (!(node as Lifecycle).$isRunning) {
        node.logger
            .warn("Node is already stopped? Call stop was called twice?");
      }

      PrecisionStopwatch p = PrecisionStopwatch.start();
      await (node as Lifecycle).onStop();
      node.$metadata["lifecycle.running"] = false;
      node.logger
          .info("Stopped in ${p.getMilliseconds().toStringAsFixed(0)}ms");
    }
  }
}

extension XLifecycle on Lifecycle {
  Future<void> shallowRestart() async {
    NodeStorage storage = (this as Node).$pool?.storage ?? DummyNodeStorage();
    PrecisionStopwatch p = PrecisionStopwatch.start();
    await Lifecycle.$callStop(this as Node, storage, p);
    await Lifecycle.$callStart(
        this as Node, storage, PrecisionStopwatch.start());
    (this as Node).logger.success(
        "Shallow Restarted in ${p.getMilliseconds().toStringAsFixed(0)}ms");
  }

  bool get $isRunning => (this as Node).$metadata["lifecycle.running"] ?? false;
}
