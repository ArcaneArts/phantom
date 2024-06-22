import 'dart:async';

import 'package:curse/curse.dart';
import 'package:phantom/node/annotations/instanced.dart';
import 'package:phantom/node/annotations/tag.dart';
import 'package:phantom/node/node.dart';
import 'package:phantom/node/storage.dart';
import 'package:phantom/node/traits/lifecycle.dart';
import 'package:phantom/node/traits/stateful.dart';
import 'package:phantom/node/traits/ticked.dart';
import 'package:phantom/util/logger.dart';
import 'package:precision_stopwatch/precision_stopwatch.dart';
import 'package:synchronized/synchronized.dart';

Future<Map<String, dynamic>?> _defaultStorageReader(String key) async {
  print("_defaultStorageReader Reading $key as null");
  return null;
}

Future<void> _defaultStorageWriter(
    String key, Map<String, dynamic>? data) async {
  print("_defaultStorageWriter Writing $key as $data");
}

class NodePool {
  PLogger? logger;
  final NodeStorage storage;
  final List<Future<void> Function(Node, NodeStorage, PrecisionStopwatch)>
      onStartPipeline = [
    Stateful.$callLoad,
    Lifecycle.$callStart,
    Stateful.$callSave,
    Ticked.$startTicking
  ];

  final List<Future<void> Function(Node, NodeStorage, PrecisionStopwatch)>
      onStopPipeline = [Lifecycle.$callStop, Stateful.$callSave];

  Map<String, Lock> locks = {};
  List<Node> nodes = [];

  NodePool({required this.storage});

  Node? getNode(Type type, {Object? tag}) => nodes
      .where((i) => i.runtimeType == type)
      .where((i) => identical(tag, i.$tag))
      .firstOrNull;

  Future<int> gc([bool nested = false]) async {
    Iterable<Node> c = nodes.where((i) => !i.$rootNode && !i.$hasReferences);
    List<Future<void>> work = [];

    while (c.isNotEmpty) {
      for (Node n in c.toList()) {
        work.add(removeNode(n.runtimeType, tag: n.$tag));
      }

      await Future.wait(work);
      c = nodes.where((i) => !i.$rootNode && !i.$hasReferences);
    }

    return work.length;
  }

  Future<void> removeNodeExplicit(Node n) =>
      _lockFor(n.runtimeType, tag: n.$tag).synchronized(() async {
        PrecisionStopwatch p = PrecisionStopwatch.start();
        nodes.removeWhere((i) => identical(i, n));
        for (CursedField f in n.$dependencyFields()) {
          f.value.$referenceCount--;
        }

        for (Future<void> Function(Node, NodeStorage, PrecisionStopwatch) f
            in onStopPipeline) {
          await f(n, storage, p);
        }
      }).then((_) => gc());

  Future<void> removeNode(Type node, {Object? tag}) =>
      _lockFor(node, tag: tag).synchronized(() async {
        Node? n = getNode(node, tag: tag);
        if (n != null) {
          PrecisionStopwatch p = PrecisionStopwatch.start();
          nodes.removeWhere((i) => identical(i, n));
          for (CursedField f in n.$dependencyFields()) {
            f.value.$referenceCount--;
          }

          for (Future<void> Function(Node, NodeStorage, PrecisionStopwatch) f
              in onStopPipeline) {
            await f(n, storage, p);
          }
        }
      }).then((_) => gc());

  Future<Node> addOrGetNode(Type nodeType,
          {Object? tag,
          bool root = false,
          int depth = 0,
          bool locking = true}) =>
      _lockFor(nodeType, tag: tag).synchronized(() async {
        Node? existing = getNode(nodeType, tag: tag);
        bool instanced = Node.$nodeAnnotation<Instanced>(nodeType) != null;

        if (instanced || existing == null) {
          PrecisionStopwatch p = PrecisionStopwatch.start();
          existing = Curse.clazz(nodeType).constructors.first.construct();

          nodes.add(existing!);
          existing.$pool = this;

          if (root) {
            logger ??= existing.logger;
          }

          existing.$tag = tag;
          existing.$rootNode = root;
          List<Future> work = [];

          for (CursedField f in existing.$dependencyFields()) {
            Object? tag = f.getAnnotation<Tag>()?.value;
            work.add(addOrGetNode(f.type, tag: tag, depth: depth + 1).then((d) {
              d.$referenceCount++;
              f.value = d;
            }));
          }

          await Future.wait(work);

          for (Future<void> Function(Node, NodeStorage, PrecisionStopwatch) f
              in onStartPipeline) {
            await f(existing, storage, p);
          }
        }

        return existing;
      });

  Lock _lockFor(Type nodeType, {Object? tag}) =>
      locks["$nodeType:${identityHashCode(tag)}"] ??= Lock();

  Future<void> start(Type nodeType) async {
    await addOrGetNode(nodeType, root: true);
  }
}

extension XLock on Lock {
  static final Map<int, Completer<void>> _inLocks = {};

  void unlock() => _inLocks.remove(identityHashCode(this))?.complete();

  Future<void> lock({bool reentrant = false}) => synchronized(() {
        Completer<void> c = Completer();
        _inLocks[identityHashCode(this)] = c;
        return c.future;
      });
}
