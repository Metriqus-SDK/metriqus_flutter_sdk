import 'Event.dart';

/// Interface for event queue controller
abstract class IEventQueueController {
  void addEvent(Event event, {bool sendImmediately = false});
}
