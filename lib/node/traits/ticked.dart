import 'package:phantom/node/node.dart';
import 'package:phantom/node/storage.dart';
import 'package:phantom/node/trait.dart';
import 'package:phantom/node/traits/lifecycle.dart';
import 'package:phantom/node/traits/stateful.dart';
import 'package:precision_stopwatch/precision_stopwatch.dart';

/// Repeatedly calls onTick on the node
abstract class Ticked implements Trait {
  /// Called when the node is ticked. This is where you should update your node.
  /// The return value is how long to wait until the next tick.
  /// If you return a duration of 0, the node will be ticked as fast as possible.
  /// You are provided [time] which is the current time milliseconds
  /// [delta] which is the time since the last tick started in milliseconds
  /// and [ticks] which is the number of ticks that have passed. First tick is 0.
  Future<Duration> onTick(double time, double delta, int ticks);

  static Future<void> $startTicking(
      Node node, NodeStorage storage, PrecisionStopwatch wallClock) async {
    if (node is Ticked) {
      Ticked t = node as Ticked;
      Future.delayed(Duration.zero, () async {
        node.logger
            .verbose("Ticker started at +${wallClock.getMilliseconds()}ms");
        double time = wallClock.getMilliseconds();
        int ticks = 0;
        while (node.$isActive &&
            (node is Stateful && (node as Lifecycle).$isRunning)) {
          double was = time;
          time = wallClock.getMilliseconds();
          await Future.delayed(await t.onTick(time, time - was, ticks++));
        }

        node.logger.verbose("Ticker Shutdown");
      });
    }
  }
}
