import 'package:phantom/event/event.dart';
import 'package:phantom/event/priority.dart';

class EventHandler {
  final EventPriority priority;
  final bool ignoreCancelled;

  const EventHandler(
      {this.priority = EventPriority.normal, this.ignoreCancelled = true});
}
