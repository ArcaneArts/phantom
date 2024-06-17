import 'dart:mirrors';

import 'package:phantom/event/bus.dart';
import 'package:phantom/event/cancellable.dart';
import 'package:phantom/event/listener.dart';
import 'package:toxic/toxic.dart';

abstract class Event {
  void call() {
    CancellableEvent? c =
        this is CancellableEvent ? this as CancellableEvent : null;

    for (RegisteredListener i
        in EventBus.getHandlerList().getRegisteredListeners()) {
      if ((c?.cancelled ?? false) && i.ignoreCancelled) {
        continue;
      }

      i.executor(this);
    }
  }
}
