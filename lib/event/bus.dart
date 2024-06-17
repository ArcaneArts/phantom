import 'dart:mirrors';

import 'package:phantom/event/event.dart';
import 'package:phantom/event/handler.dart';
import 'package:phantom/event/handler_list.dart';
import 'package:phantom/event/listener.dart';

final EventBus _mainBus = EventBus._();

class EventBus {
  final HandlerList handlerList = HandlerList();

  EventBus._();

  static HandlerList getHandlerList() => _mainBus.handlerList;

  static void unregisterAll() => _mainBus.handlerList.unregisterAll();

  static void unregister(Object listener) =>
      _mainBus.handlerList.unregister(listener);

  static void register(Object listener) {
    ClassMirror m = reflectClass(listener.runtimeType);
    InstanceMirror im = reflect(listener);

    for (MethodMirror i in m.instanceMembers.values) {
      if (i.isSetter ||
          i.isGetter ||
          i.isAbstract ||
          i.isFactoryConstructor ||
          i.isConstConstructor ||
          i.isConstructor ||
          i.isOperator ||
          i.isPrivate ||
          i.isStatic ||
          i.isTopLevel ||
          i.isSynthetic) {
        continue;
      }

      EventHandler? h;

      for (InstanceMirror j in i.metadata) {
        if (j.reflectee is EventHandler) {
          if (h != null) {
            throw StateError(
                "You can only use @EventHandler once per method. See method ${i.qualifiedName} in class ${listener.runtimeType}");
          }

          h = j.reflectee;
        }
      }

      if (h != null &&
          i.parameters.length != 1 &&
          i.parameters.first.type.isAssignableTo(reflectType(Event)) &&
          i.parameters.first.type.reflectedType != Event) {
        throw StateError(
            "Methods marked with @EventHandler should only have one parameter with a type that extends the Event class");
      }

      if (h != null) {
        _mainBus.handlerList.register(RegisteredListener(
            listener: listener,
            executor: (event) {
              try {
                im.invoke(i.simpleName, [event]);
              } catch (e, es) {
                print(
                    "Event Error while handling event $event on listener instance $listener");
                print(es);
              }
            }));
      }
    }
  }
}
