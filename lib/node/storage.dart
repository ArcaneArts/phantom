import 'dart:convert';
import 'dart:io';

import 'package:phantom/node/node.dart';
import 'package:phantom/node/traits/lifecycle.dart';
import 'package:phantom/node/traits/stateful.dart';
import 'package:phantom/util/logger.dart';
import 'package:precision_stopwatch/precision_stopwatch.dart';
import 'package:watcher/watcher.dart';

abstract class NodeStorage {
  Future<void> write(Stateful node, Map<String, dynamic> data);

  Future<Map<String, dynamic>> read(Stateful node);
}

class FileConfigJSONNodeSettings extends ReloadableNodeStorage {
  final PLogger logger = PLogger("&eFSJ");
  late final Directory configDirectory;
  late final Watcher watcher;
  final List<String> ignore = [];

  FileConfigJSONNodeSettings({Directory? directory}) {
    configDirectory =
        directory ?? Directory("${Directory.current.path}/config");
    logger.info("Using config directory ${configDirectory.path}");
    if (!configDirectory.existsSync()) {
      configDirectory.createSync(recursive: true);
      logger.verbose("Created config directory ${configDirectory.path}");
    }
    watcher = Watcher(configDirectory.path);
    watcher.events.listen((event) {
      String path = event.path.replaceAll("\\", "/");
      if (event.type == ChangeType.MODIFY) {
        if (ignore.contains(path)) {
          ignore.remove(path);
          return;
        }

        logger.verbose("Config Change detected at $path");
        onChangeAt(path);
      } else if (event.type == ChangeType.REMOVE) {
        logger.verbose("Config removed at $path");
      }
    });
  }

  File _fileFor(Stateful node) =>
      File("${configDirectory.path}/${node.storageKey}.json");

  @override
  Future<Map<String, dynamic>> onRead(Stateful node) async {
    File file = _fileFor(node);
    if (!file.existsSync()) {
      return Future.value({});
    }

    String c = await file.readAsString();

    try {
      return Future.value(jsonDecode(c));
    } catch (e, es) {
      logger.warn(
          "Failed to decode JSON for ${node.storageKey} at ${file.path}. Returning empty map. $e");
      logger.warn(es);
    }

    return Future.value({});
  }

  @override
  Future<void> onWrite(Stateful node, Map<String, dynamic> data) async {
    File file = _fileFor(node);

    try {
      ignore.add(file.path.replaceAll("\\", "/"));
      await file.writeAsString(jsonEncode(data));
    } catch (e, es) {
      logger.warn(
          "Failed to write JSON for ${node.storageKey} at ${file.path}. $e");
      logger.warn(es);
    }

    return Future.value();
  }
}

abstract class ReloadableNodeStorage extends NodeStorage {
  final Map<String, List<Stateful>> _listeners = {};

  void onChangeAt(String path) {
    for (List<Stateful> l in _listeners.values) {
      for (Stateful n in l) {
        Stateful.$callLoad(n as Node, this, PrecisionStopwatch.start(),
            hotload: true);
      }
    }

    $cleanupListeners();
  }

  void $cleanupListeners() {
    for (List<Stateful> l in _listeners.values) {
      l.removeWhere((i) =>
          !(i as Node).$isActive ||
          ((i as Node).$hasTrait(Lifecycle) && !(i as Lifecycle).$isRunning));
    }
  }

  Future<Map<String, dynamic>> onRead(Stateful node);

  Future<void> onWrite(Stateful node, Map<String, dynamic> data);

  @override
  Future<Map<String, dynamic>> read(Stateful node) {
    List<Stateful> l = _listeners[node.storageKey] ??= [];
    if (!l.any((i) => identical(i, node))) {
      l.add(node);
    }
    return onRead(node);
  }

  @override
  Future<void> write(Stateful node, Map<String, dynamic> data) =>
      onWrite(node, data);
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
