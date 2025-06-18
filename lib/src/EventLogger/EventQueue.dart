import 'dart:collection';
import 'dart:convert';
import 'Event.dart';
import '../ThirdParty/SimpleJSON.dart';
import '../Metriqus.dart';

/// Event queue for storing and managing events
class EventQueue {
  final Queue<Event> _events = Queue<Event>();

  Queue<Event> get events => _events;

  EventQueue();

  EventQueue.fromJson(String jsonString) {
    try {
      Metriqus.verboseLog(
          "🔧 [STORAGE] Reading current events from cache: ${jsonString.length > 100 ? jsonString.substring(0, 100) + '...' : jsonString}");

      // Clean up the JSON string first
      String cleanedJson = jsonString.trim();

      // Check for malformed JSON (like "[]event_name...")
      if (cleanedJson.startsWith('[]') && cleanedJson.length > 2) {
        Metriqus.errorLog(
            "Detected malformed JSON starting with '[]', resetting to empty array. Original: ${jsonString.length > 200 ? jsonString.substring(0, 200) + '...' : jsonString}");
        cleanedJson = '[]';
      }

      // Check for other malformed patterns
      if (cleanedJson.contains('"event_name"') &&
          !cleanedJson.startsWith('[')) {
        Metriqus.errorLog(
            "Detected malformed JSON with event data but wrong format, resetting to empty array");
        cleanedJson = '[]';
      }

      var jsonNode = JSONNode.parse(cleanedJson);

      if (!jsonNode.exists) {
        // events already initialized as empty queue
        Metriqus.verboseLog(
            "🔧 [EVENTQUEUE] JSON node doesn't exist, using empty queue");
      } else {
        if (jsonNode.data is List) {
          _events.addAll(_parse(jsonNode.data));
          Metriqus.verboseLog(
              "🔧 [EVENTQUEUE] Successfully parsed ${_events.length} events from JSON");
        } else {
          Metriqus.errorLog(
              "🔧 [EVENTQUEUE] JSON data is not a List, using empty queue");
        }
      }
    } catch (e) {
      Metriqus.errorLog("JSON Parse Error: ${e.toString()}");
      Metriqus.errorLog(
          "Problematic JSON: ${jsonString.length > 100 ? jsonString.substring(0, 100) + '...' : jsonString}");
      // events already initialized as empty queue, so we're good
    }
  }

  EventQueue.fromArray(List<dynamic> array) {
    _events.addAll(_parse(array));
  }

  /// Add event to queue
  void add(Event event) {
    _events.add(event);
  }

  /// Serialize queue to JSON string using standard Dart jsonEncode
  String serialize() {
    List<Map<String, dynamic>> eventMapList = [];

    for (var event in _events) {
      // Use toMap() to avoid double encoding
      Map<String, dynamic> eventMap = event.toMap();
      eventMapList.add(eventMap);
    }

    // Use standard Dart jsonEncode
    String result = jsonEncode(eventMapList);

    Metriqus.verboseLog(
      "🔧 [EVENTQUEUE] Serialized ${_events.length} events using standard jsonEncode",
    );

    return result;
  }

  /// Parse JSON array to queue of events
  static List<Event> _parse(List<dynamic> array) {
    try {
      List<Event> eventList = [];

      for (var eventData in array) {
        var jsonNode = JSONNode(eventData);
        var result = Event.parseJson(jsonNode);

        if (result != null) {
          eventList.add(result);
        }
      }

      return eventList;
    } catch (e) {
      Metriqus.errorLog("Parsing Event Queue failed: ${e.toString()}");
      return [];
    }
  }
}
