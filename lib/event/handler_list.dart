import 'package:phantom/event/listener.dart';
import 'package:phantom/event/priority.dart';
import 'package:toxic/toxic.dart';

class HandlerList {
  static List<HandlerList> allLists = [];
  List<RegisteredListener>? handlers;
  final Map<EventPriority, List<RegisteredListener>> handlerSlots = {};

  void bake() {
    if (handlers != null) {
      return;
    }

    List<RegisteredListener> entries = [];
    for (MapEntry<EventPriority, List<RegisteredListener>> entry in handlerSlots
        .entries
        .sorted((a, b) => a.key.index.compareTo(b.key.index))) {
      entries.addAll(entry.value);
    }

    handlers = entries;
  }

  static void bakeAll() {
    for (HandlerList h in allLists) {
      h.bake();
    }
  }

  static void unregisterAllListeners() {
    for (HandlerList h in allLists) {
      for (List<RegisteredListener> list in h.handlerSlots.values) {
        list.clear();
      }
      h.handlers = null;
    }
  }

  static void unregisterAllListener(Object listener) {
    for (HandlerList h in allLists) {
      h.unregister(listener);
    }
  }

  void register(RegisteredListener listener) {
    if (handlerSlots[listener.priority]?.contains(listener) ?? false) {
      throw ArgumentError(
          "This listener is already registered to priority ${listener.priority.name}");
    }

    handlers = null;
    handlerSlots[listener.priority] ??= [];
    handlerSlots[listener.priority]!.add(listener);
  }

  List<RegisteredListener> getRegisteredListeners() {
    List<RegisteredListener>? handlers;
    while ((handlers = this.handlers) == null) {
      bake();
    }
    return handlers!;
  }

  void registerAll(Iterable<RegisteredListener> listeners) {
    for (RegisteredListener i in listeners) {
      register(i);
    }
  }

  void unregisterAll() {
    handlerSlots.clear();
    handlers = null;
  }

  void unregister(Object listener) {
    bool changed = false;
    for (List<RegisteredListener> list in handlerSlots.values) {
      list.removeWhere((i) {
        if (identical(i.listener, listener)) {
          changed = true;
          return true;
        }

        return false;
      });
    }
    if (changed) handlers = null;
  }
}
