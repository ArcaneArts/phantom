import 'package:phantom/node/node.dart';
import 'package:phantom/node/trait.dart';
import 'package:phantom/node/traits/stateful.dart';

/// Called when the node is hotloaded. This is where you should update your node.
/// By default this will simply call onLoad if you are stateful
abstract class Hotloadable implements Trait {
  /// Called when the node is hotloaded. This is where you should update your node.
  /// By default this will simply call onLoad if you are stateful
  Future<void> onHotload(Map<String, dynamic> newConfig) =>
      (this as Node).$hasTrait(Stateful)
          ? (this as Stateful).onLoad(newConfig)
          : Future.value();
}
