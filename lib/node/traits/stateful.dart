import 'package:phantom/node/node.dart';
import 'package:phantom/node/storage.dart';
import 'package:phantom/node/trait.dart';
import 'package:precision_stopwatch/precision_stopwatch.dart';

/// Designates a node as Stateful, meaning it can save and load its state.
/// You are responsible for implementing load / save state methods.
abstract class Stateful implements Trait {
  /// Called when the node needs to save its state to storage.
  Future<Map<String, dynamic>> onSave();

  /// Called when the node needs to load its state from storage.
  /// After startup, your state will be saved again so feel free to
  /// modify your node for assuming defaults if needed.
  Future<void> onLoad(Map<String, dynamic> state);

  static Future<void> $callSave(
      Node node, NodeStorage storage, PrecisionStopwatch wallClock) async {
    if (node is Stateful) {
      Stateful s = node as Stateful;
      s._storage = storage;
      PrecisionStopwatch p = PrecisionStopwatch.start();
      await storage.write(s, await s.onSave());
      node.logger.verbose(
          "Saved State in ${p.getMilliseconds().toStringAsFixed(0)}ms");
    }
  }

  static Future<void> $callLoad(
      Node node, NodeStorage storage, PrecisionStopwatch wallClock) async {
    if (node is Stateful) {
      Stateful s = node as Stateful;
      s._storage = storage;
      PrecisionStopwatch p = PrecisionStopwatch.start();
      await s.onLoad(await storage.read(s));
      node.logger.verbose(
          "Loaded State in ${p.getMilliseconds().toStringAsFixed(0)}ms");
    }
  }
}

extension XStateful on Stateful {
  /// The storage key for this node, expects a tag to be included in the key if you want regular tag support.
  String get storageKey =>
      "$runtimeType${(this as Node).$tag != null ? "-${(this as Node).$tag}" : ""}";

  set _storage(NodeStorage storage) =>
      (this as Node).$metadata["storage"] = storage;

  NodeStorage? get $storage =>
      (this as Node).$metadata["storage"] as NodeStorage;

  Future<void> saveState() =>
      Stateful.$callSave(this as Node, $storage!, PrecisionStopwatch());

  Future<void> reloadState() =>
      Stateful.$callLoad(this as Node, $storage!, PrecisionStopwatch());
}
