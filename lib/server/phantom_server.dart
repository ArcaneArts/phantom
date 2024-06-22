import 'package:hotreloader/hotreloader.dart';
import 'package:phantom/node/node.dart';
import 'package:phantom/node/pool.dart';
import 'package:phantom/node/storage.dart';
import 'package:phantom/util/logger.dart';
import 'package:precision_stopwatch/precision_stopwatch.dart';

const String _sk = "@(#03fc6b) &r ";

class PhantomServer {
  final Type root;
  late final PrecisionStopwatch clock;
  late final PLogger logger;
  late final NodeStorage? storage;
  late final NodePool pool;
  late HotReloader? _reloader;
  late PLogger _reloadLogger;

  PhantomServer({required this.root, NodeStorage? storage}) {
    clock = PrecisionStopwatch.start();
    logger = PLogger("&(#03fc6b)PhantomServer");
    logger.info("Starting PhantomServer with root node $root");
    PLogger.modifiers.add(_sk);
    storage ??= FileConfigJSONNodeSettings();
    pool = NodePool(storage: storage);
    _reloadLogger = PLogger("&(#db03fc)HotReload");
  }

  Future<void> start() async {
    PrecisionStopwatch hotloadClock = PrecisionStopwatch.start();
    List<Node>? hotloadNodes;
    await pool.start(root);
    String hlk = "@(#db03fc) &r ";
    _reloader = await HotReloader.create(
        automaticReload: true,
        debounceInterval: Duration(milliseconds: 250),
        watchDependencies: false,
        onBeforeReload: (v) {
          String? p = v.event?.path;
          hotloadNodes =
              pool.nodes.where((i) => i.$sourceCodeFile == p).toList();

          if (hotloadNodes!.isNotEmpty) {
            hotloadClock = PrecisionStopwatch.start();
            String names = hotloadNodes!.map((i) => i.nodeName).join(", ");
            _reloadLogger
                .info("HotReloading ${hotloadNodes!.length} nodes: $names");
            PLogger.modifiers.add(hlk);

            return true;
          }

          return false;
        },
        onAfterReload: (v) async {
          switch (v.result) {
            case HotReloadResult.Skipped:
              PLogger.modifiers.remove(hlk);
              _reloadLogger.verbose("HotReload skipped.");
            case HotReloadResult.Failed:
              PLogger.modifiers.remove(hlk);
              _reloadLogger.error("HotReload failed.");
            case HotReloadResult.PartiallySucceeded:
              PLogger.modifiers.remove(hlk);
              _reloadLogger.warn(
                  "HotReload partially succeeded. Some nodes may not have been reloaded.");
            case HotReloadResult.Succeeded:
              await Future.wait(hotloadNodes!.map((i) => i.restart()))
                  .then((v) {});
              PLogger.modifiers.remove(hlk);
              _reloadLogger.success(
                  "HotReload succeeded in ${hotloadClock.getMilliseconds().toStringAsFixed(0)}ms.");
              hotloadNodes = null;
          }
        });
    PLogger.modifiers.remove(_sk);
    logger.success(
        "PhantomServer started in ${clock.getMilliseconds().toStringAsFixed(0)}ms.");
  }

  Future<void> reloadCode() async {
    await _reloader!.reloadCode();
  }

  Future<void> stop() async {
    await _reloader?.stop();
    await pool.shutdown();
  }
}
