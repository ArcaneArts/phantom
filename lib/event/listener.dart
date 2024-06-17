import 'package:phantom/event/event.dart';
import 'package:phantom/event/priority.dart';

typedef EventExecutor = void Function(Event event);

class RegisteredListener {
  final Object listener;
  final EventExecutor executor;
  final EventPriority priority;
  final bool ignoreCancelled;

  RegisteredListener({
    required this.listener,
    required this.executor,
    this.priority = EventPriority.normal,
    this.ignoreCancelled = true,
  });
}
