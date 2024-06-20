import 'dart:mirrors';

import 'package:chat_color/chat_color.dart';
import 'package:curse/curse.dart';
import 'package:phantom/node/trait.dart';
import 'package:phantom/util/logger.dart';

mixin class Node {
  PLogger? _logger;
  Set<Type>? _traits;
  Map<String, dynamic> $metadata = {};

  /// Whether this node is a root node. If true, it will not be destroyed when depending nodes are destroyed.
  bool $rootNode = false;

  /// The tag of the node.
  Object? $tag;

  int $referenceCount = 0;

  bool get $hasReferences => $referenceCount > 0;

  /// The name of the node. You can use &4chat &(#FF00FF)colors here.
  String get nodeName => "$runtimeType";

  /// Returns the logger for this node.
  PLogger get logger => _logger ??=
      PLogger("$nodeName${$tag != null ? ":${$tag}" : ""}".chatColor);

  /// Returns the traits implemented by this node.
  Set<Type> get $traits => _traits ??= cursed.$class.superinterfaces
      .where((i) => i.superinterfaces.any((j) => j.reflectedType == Trait))
      .map((i) => i.reflectedType)
      .toSet();

  static Set<Type> $traitsOf(Type t) => Curse.clazz(t)
      .$class
      .superinterfaces
      .where((i) => i.superinterfaces.any((j) => j.reflectedType == Trait))
      .map((i) => i.reflectedType)
      .toSet();

  static T? $nodeAnnotation<T>(Type nodeType) =>
      Curse.clazz(nodeType).getAnnotation<T>();

  static bool $hasTraitOf(Type t, Type trait) => $traitsOf(t).contains(trait);

  Iterable<CursedField> $dependencyFields() => cursed.fields
      .where((f) => reflectType(f.type).isAssignableTo(reflectType(Node)));

  /// Returns whether this node has the given trait.
  bool $hasTrait(Type trait) => $traits.contains(trait);

  /// Returns the identity hash code of this node.
  int get $id => identityHashCode(this);
}
