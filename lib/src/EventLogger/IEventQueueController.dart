import 'Event.dart';

/// Interface for event queue controller
abstract class IEventQueueController {
  void addEvent(Event event, {bool sendImmediately = false});

  /// Dispose the controller and release resources
  void dispose();
}
