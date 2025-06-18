import 'dart:collection';
import 'dart:convert';
import '../Storage/IStorage.dart';
import 'Event.dart';
import 'EventQueue.dart';
import 'IEventQueueController.dart';
import 'EventRequestSender.dart';
import '../Utilities/Backoff.dart';
import '../Utilities/MetriqusUtils.dart';
import '../Metriqus.dart';
import '../MetriqusRemoteSettings.dart';
import '../ThirdParty/SimpleJSON.dart';

/// Stores event in a queue. Responsible for storing and flushing queue when conditions are met.
class EventQueueController implements IEventQueueController {
  static const String _lastFlushTimeKey = "metriqus_event_last_flush_time";
  static const String _currentEventsKey = "metriqus_current_events";
  static const String _eventsToSendKey = "metriqus_events_to_send";

  final IStorage _storage;
  bool _isFlushing = false;

  final Queue<EventQueue> _eventsToSend = Queue<EventQueue>();
  late EventQueue _eventQueue;

  EventQueue get events => _eventQueue;

  EventQueueController(this._storage) {
    _loadEventsToSend();

    try {
      // get saved events if any
      String eventsData = _storage.loadData(_currentEventsKey);
      if (eventsData.isNotEmpty) {
        _eventQueue = EventQueue.fromJson(eventsData);
      } else {
        _eventQueue = EventQueue();
      }
    } catch (e) {
      _eventQueue = EventQueue();
    }
  }

  /// Add event to queue
  @override
  void addEvent(Event event, {bool sendImmediately = false}) {
    Metriqus.verboseLog("🔥 [EVENTQUEUE] Starting addEvent process...");
    Metriqus.verboseLog(
        "🔥 [EVENTQUEUE] Event details: name='${event.eventName}', id='${event.eventId}', sendImmediately=$sendImmediately");

    Metriqus.eventQueueLog("EVENT_ADDED", details: {
      "event_name": event.eventName,
      "event_id": event.eventId,
      "send_immediately": sendImmediately,
      "event_timestamp": event.eventTimestamp,
      "session_id": event.sessionId,
      "user_id": event.userId
    });

    int beforeCount = _eventQueue.events.length;
    _eventQueue.add(event);
    int afterCount = _eventQueue.events.length;

    Metriqus.infoLog(
        "🔥 [EVENTQUEUE] Event added to queue. Before: $beforeCount, After: $afterCount");

    String json = _eventQueue.serialize();
    int jsonSize = json.length;

    Metriqus.eventQueueLog("QUEUE_STATUS_DETAILED", details: {
      "total_events": _eventQueue.events.length,
      "queue_size_bytes": jsonSize,
      "queue_size_kb": (jsonSize / 1024).toStringAsFixed(2),
      "last_event_name": event.eventName,
      "queue_events": _eventQueue.events.map((e) => e.eventName).toList()
    });

    Metriqus.verboseLog(
        "🔥 [EVENTQUEUE] Converting queue to JSON... Size: ${jsonSize} bytes (${(jsonSize / 1024).toStringAsFixed(2)} KB)");

    // save new json to local
    Metriqus.verboseLog(
        "🔧 [STORAGE] Saving current events: ${json.length > 100 ? json.substring(0, 100) + '...' : json}");
    _storage.saveData(_currentEventsKey, json);
    Metriqus.verboseLog(
        "🔥 [EVENTQUEUE] EventQueue serialized and saved to storage successfully");

    Metriqus.verboseLog(
        "🔥 [EVENTQUEUE] Checking queue status for sending conditions...");
    _checkQueueStatus(sendImmediately);
  }

  /// Check is event queue ready to send server
  void _checkQueueStatus(bool sendImmediately) {
    try {
      Metriqus.verboseLog("🔥 [EVENTQUEUE] _checkQueueStatus started");

      DateTime currentTime = DateTime.now().toUtc();
      DateTime lastFlushTime = MetriqusUtils.getUtcStartTime();

      String lastFlushTimeStr = _storage.loadData(_lastFlushTimeKey);
      Metriqus.verboseLog(
          "🔥 [EVENTQUEUE] Last flush time data: ${lastFlushTimeStr.isNotEmpty ? 'EXISTS' : 'EMPTY'}");

      if (lastFlushTimeStr.isNotEmpty) {
        lastFlushTime = MetriqusUtils.parseDate(lastFlushTimeStr);
        Metriqus.verboseLog(
            "🔥 [EVENTQUEUE] Last flush time loaded: $lastFlushTime");
      } else {
        Metriqus.verboseLog(
            "🔥 [EVENTQUEUE] No previous flush time found, using UTC start time: $lastFlushTime");
      }

      var remoteSettings = Metriqus.getMetriqusRemoteSettings();
      Metriqus.verboseLog(
          "🔥 [EVENTQUEUE] Remote settings loaded: ${remoteSettings != null ? 'SUCCESS' : 'NULL'}");

      int timeSinceLastFlush = currentTime.difference(lastFlushTime).inSeconds;
      int currentEventCount = _eventQueue.events.length;

      Metriqus.eventQueueLog("QUEUE_CHECK_DETAILED", details: {
        "current_event_count": currentEventCount,
        "time_since_last_flush_seconds": timeSinceLastFlush,
        "send_immediately": sendImmediately,
        "max_batch_count": remoteSettings?.maxEventBatchCount,
        "max_store_seconds": remoteSettings?.maxEventStoreSeconds,
        "current_time": currentTime.toIso8601String(),
        "last_flush_time": lastFlushTime.toIso8601String(),
        "pending_batches": _eventsToSend.length,
        "is_flushing": _isFlushing
      });

      Metriqus.verboseLog("🔥 [EVENTQUEUE] Checking sending conditions:");
      Metriqus.verboseLog(
          "🔥 [EVENTQUEUE] - Current events: $currentEventCount");
      Metriqus.verboseLog(
          "🔥 [EVENTQUEUE] - Max batch count: ${remoteSettings?.maxEventBatchCount}");
      Metriqus.verboseLog(
          "🔥 [EVENTQUEUE] - Time since last flush: ${timeSinceLastFlush}s");
      Metriqus.verboseLog(
          "🔥 [EVENTQUEUE] - Max store seconds: ${remoteSettings?.maxEventStoreSeconds}");
      Metriqus.verboseLog(
          "🔥 [EVENTQUEUE] - Send immediately: $sendImmediately");

      bool batchLimitReached = _eventQueue.events.length >=
          (remoteSettings?.maxEventBatchCount ?? 50);
      bool timeLimitReached = currentTime.difference(lastFlushTime).inSeconds >
          (remoteSettings?.maxEventStoreSeconds ?? 300);
      bool shouldSend = remoteSettings != null &&
          (batchLimitReached || timeLimitReached || sendImmediately);

      Metriqus.infoLog("🔥 [EVENTQUEUE] Condition evaluation:");
      Metriqus.infoLog(
          "🔥 [EVENTQUEUE] - Batch limit reached: $batchLimitReached");
      Metriqus.infoLog(
          "🔥 [EVENTQUEUE] - Time limit reached: $timeLimitReached");
      Metriqus.infoLog("🔥 [EVENTQUEUE] - Should send: $shouldSend");

      if (shouldSend) {
        String reason = "";
        if (sendImmediately) {
          reason = "IMMEDIATE_SEND_REQUESTED";
          Metriqus.infoLog(
              "🔥 [EVENTQUEUE] 🚀 SENDING IMMEDIATELY! EventQueue count: ${_eventQueue.events.length}");
        } else if (batchLimitReached) {
          reason = "BATCH_LIMIT_EXCEEDED";
          Metriqus.infoLog(
              "🔥 [EVENTQUEUE] 📦 BATCH LIMIT exceeded! EventQueue count: ${_eventQueue.events.length}/${remoteSettings!.maxEventBatchCount}");
        } else if (timeLimitReached) {
          reason = "TIME_LIMIT_EXCEEDED";
          Metriqus.infoLog(
              "🔥 [EVENTQUEUE] ⏰ TIME LIMIT exceeded! Elapsed time: ${currentTime.difference(lastFlushTime).inSeconds}/${remoteSettings!.maxEventStoreSeconds} seconds");
        }

        Metriqus.eventQueueLog("FLUSH_TRIGGERED", details: {
          "reason": reason,
          "event_count": _eventQueue.events.length,
          "time_elapsed": currentTime.difference(lastFlushTime).inSeconds,
          "batch_limit": remoteSettings?.maxEventBatchCount,
          "time_limit": remoteSettings?.maxEventStoreSeconds
        });

        Metriqus.verboseLog(
            "🔥 [EVENTQUEUE] Saving last flush time: ${currentTime.toIso8601String()}");
        _storage.saveData(
            _lastFlushTimeKey, MetriqusUtils.convertDateToString(currentTime));

        Metriqus.verboseLog(
            "🔥 [EVENTQUEUE] Adding current queue to send queue...");
        int queueSizeBefore = _eventsToSend.length;
        _eventsToSend.add(_eventQueue);
        int queueSizeAfter = _eventsToSend.length;

        Metriqus.infoLog(
            "🔥 [EVENTQUEUE] 📤 EventQueue added to send queue. Before: $queueSizeBefore, After: $queueSizeAfter");
        Metriqus.eventQueueLog("QUEUE_ADDED_TO_SEND", details: {
          "pending_batches_before": queueSizeBefore,
          "pending_batches_after": queueSizeAfter,
          "events_in_batch": _eventQueue.events.length
        });

        Metriqus.verboseLog(
            "🔥 [EVENTQUEUE] Saving events to send queue to storage...");
        _saveEventsToSend();

        Metriqus.verboseLog(
            "🔥 [EVENTQUEUE] Resetting current events queue...");
        _storage.saveData(_currentEventsKey, "[]");

        Metriqus.verboseLog("🔥 [EVENTQUEUE] Creating new empty EventQueue...");
        _eventQueue = EventQueue();
        Metriqus.infoLog(
            "🔥 [EVENTQUEUE] 🔄 New EventQueue created successfully");

        if (!_isFlushing) {
          Metriqus.infoLog(
              "🔥 [EVENTQUEUE] 🚀 Starting event sending process...");
          _processEvents();
        } else {
          Metriqus.infoLog(
              "🔥 [EVENTQUEUE] ⏳ A sending process is already in progress, waiting...");
        }
      } else {
        Metriqus.infoLog(
            "🔥 [EVENTQUEUE] ⏸️ EventQueue does not yet meet sending conditions");
        Metriqus.eventQueueLog("FLUSH_NOT_TRIGGERED", details: {
          "current_events": _eventQueue.events.length,
          "batch_limit": remoteSettings?.maxEventBatchCount,
          "time_elapsed": currentTime.difference(lastFlushTime).inSeconds,
          "time_limit": remoteSettings?.maxEventStoreSeconds,
          "send_immediately": sendImmediately
        });
      }
    } catch (e) {
      Metriqus.errorLog("❌ EventQueue check error: ${e.toString()}");
    }
  }

  /// Flush next event with backoff in queue if any
  Future<void> _processEvents() async {
    Metriqus.verboseLog("🔥 [EVENTQUEUE] _processEvents called");

    if (_eventsToSend.isEmpty) {
      Metriqus.infoLog(
          "🔥 [EVENTQUEUE] 📭 No event batch to send - queue is empty");
      Metriqus.eventQueueLog("PROCESS_EVENTS_EMPTY",
          details: {"pending_batches": 0, "is_flushing": _isFlushing});
      return;
    }

    if (_isFlushing) {
      Metriqus.infoLog(
          "🔥 [EVENTQUEUE] ⏳ Flush operation already in progress - skipping");
      Metriqus.eventQueueLog("PROCESS_EVENTS_BUSY", details: {
        "pending_batches": _eventsToSend.length,
        "is_flushing": _isFlushing
      });
      return;
    }

    try {
      Metriqus.verboseLog("🔥 [EVENTQUEUE] Setting flush flag to true");
      _isFlushing = true;

      Metriqus.infoLog(
          "🔥 [EVENTQUEUE] 🔄 Event flush operation started. Pending batch count: ${_eventsToSend.length}");
      Metriqus.eventQueueLog("FLUSH_OPERATION_STARTED", details: {
        "pending_batches": _eventsToSend.length,
        "is_flushing": _isFlushing,
        "first_batch_event_count":
            _eventsToSend.isNotEmpty ? _eventsToSend.first.events.length : 0
      });

      // queue is ready to send
      // flush with back off 3 times
      Metriqus.verboseLog(
          "🔥 [EVENTQUEUE] Starting Backoff.doAsync with retry mechanism");
      Metriqus.eventQueueLog("BACKOFF_STARTED",
          details: {"max_retries": 4, "max_delay_ms": 4000, "delay_ms": 1000});

      final result = await Backoff.doAsync(
        _flush,
        maxRetries: 4,
        initialDelay: const Duration(milliseconds: 1000),
        maxDelay: const Duration(milliseconds: 4000),
      );

      Metriqus.verboseLog("🔥 [EVENTQUEUE] Backoff operation completed");
      Metriqus.verboseLog("🔥 [EVENTQUEUE] Result: $result");

      _isFlushing = false;
      Metriqus.verboseLog("🔥 [EVENTQUEUE] Flush flag reset to false");

      if (result == true) {
        Metriqus.infoLog("🔥 [EVENTQUEUE] ✅ Event batch sent successfully");
        Metriqus.eventQueueLog("BACKOFF_SUCCESS", details: {
          "result": result,
          "remaining_batches": _eventsToSend.length
        });
      } else {
        Metriqus.errorLog("🔥 [EVENTQUEUE] ❌ Event batch sending failed");
        Metriqus.eventQueueLog("BACKOFF_FAILED", details: {
          "result": result,
          "remaining_batches": _eventsToSend.length
        });
      }
    } catch (ex) {
      _isFlushing = false; // Make sure to reset the flag
      Metriqus.errorLog(
          "🔥 [EVENTQUEUE] ❌ Event sending operation failed: ${ex.toString()}");
      Metriqus.eventQueueLog("PROCESS_EVENTS_EXCEPTION", details: {
        "error": ex.toString(),
        "remaining_batches": _eventsToSend.length,
        "is_flushing": _isFlushing
      });
    }
  }

  /// Post events to server as json
  Future<bool> _flush() async {
    Metriqus.verboseLog("🔥 [EVENTQUEUE] _flush() method called");

    if (_eventsToSend.isEmpty) {
      Metriqus.infoLog(
          "🔥 [EVENTQUEUE] 📭 No events to flush - send queue is empty");
      Metriqus.eventQueueLog("FLUSH_EMPTY_QUEUE",
          details: {"pending_batches": 0});
      return false;
    }

    var selectedEventQueue = _eventsToSend.first;
    int eventCount = selectedEventQueue.events.length;
    String serializedData = selectedEventQueue.serialize();
    int dataSize = serializedData.length;

    Metriqus.infoLog(
        "🔥 [EVENTQUEUE] 📤 Sending event batch. Event count: $eventCount, Data size: ${dataSize} bytes");
    Metriqus.eventQueueLog("FLUSH_BATCH_SENDING", details: {
      "event_count": eventCount,
      "data_size_bytes": dataSize,
      "data_size_kb": (dataSize / 1024).toStringAsFixed(2),
      "batch_index": 0,
      "total_pending_batches": _eventsToSend.length,
      "event_names": selectedEventQueue.events.map((e) => e.eventName).toList()
    });

    Metriqus.verboseLog(
        "🔥 [EVENTQUEUE] Calling EventRequestSender.postEventBatch...");
    bool result = await EventRequestSender.postEventBatch(serializedData);
    Metriqus.verboseLog(
        "🔥 [EVENTQUEUE] EventRequestSender.postEventBatch returned: $result");

    // if post request successful clear existing events
    if (result) {
      Metriqus.infoLog(
          "🔥 [EVENTQUEUE] ✅ Event batch successfully sent to server");
      Metriqus.eventQueueLog("FLUSH_BATCH_SUCCESS", details: {
        "event_count": eventCount,
        "data_size_bytes": dataSize,
        "remaining_batches": _eventsToSend.length - 1
      });

      Metriqus.verboseLog("🔥 [EVENTQUEUE] Enqueueing cleanup callback...");
      Metriqus.enqueueCallback(() async {
        Metriqus.verboseLog("🔥 [EVENTQUEUE] Cleanup callback started");

        int batchesBefore = _eventsToSend.length;
        _eventsToSend.removeFirst();
        int batchesAfter = _eventsToSend.length;

        Metriqus.verboseLog(
            "🔥 [EVENTQUEUE] Batch removed from queue. Before: $batchesBefore, After: $batchesAfter");

        _saveEventsToSend(); // delete sent batch from queue and save it
        Metriqus.verboseLog(
            "🔥 [EVENTQUEUE] Updated send queue saved to storage");

        Metriqus.infoLog(
            "🔥 [EVENTQUEUE] 🗑️ Sent batch removed from queue. Remaining batches: $batchesAfter");

        var remoteSettings = Metriqus.getMetriqusRemoteSettings();
        int delaySeconds = remoteSettings?.sendEventIntervalSeconds ?? 1;
        Metriqus.verboseLog(
            "🔥 [EVENTQUEUE] ⏰ Waiting $delaySeconds seconds for next batch...");

        Metriqus.eventQueueLog("FLUSH_DELAY_STARTED", details: {
          "delay_seconds": delaySeconds,
          "remaining_batches": batchesAfter
        });

        await Future.delayed(Duration(seconds: delaySeconds));
        Metriqus.verboseLog("🔥 [EVENTQUEUE] Delay completed");

        // sending events successful send next batch if any
        if (_eventsToSend.isNotEmpty) {
          Metriqus.infoLog(
              "🔥 [EVENTQUEUE] 🔄 Sending next batch... (${_eventsToSend.length} remaining)");
        } else {
          Metriqus.infoLog("🔥 [EVENTQUEUE] All batches sent successfully");
        }
        _processEvents();
      });
    } else {
      Metriqus.errorLog(
          "🔥 [EVENTQUEUE] ❌ Event batch sending failed, will retry");
      Metriqus.eventQueueLog("FLUSH_BATCH_FAILED", details: {
        "event_count": eventCount,
        "data_size_bytes": dataSize,
        "remaining_batches": _eventsToSend.length
      });
    }

    return result;
  }

  void _saveEventsToSend() {
    List<List<Map<String, dynamic>>> eventQueuesList = [];

    for (var item in _eventsToSend) {
      // Convert each EventQueue to a list of event maps
      List<Map<String, dynamic>> eventMaps = [];
      for (var event in item.events) {
        eventMaps.add(event.toMap());
      }
      eventQueuesList.add(eventMaps);
    }

    String json = jsonEncode(eventQueuesList);
    Metriqus.verboseLog(
        "🔧 [STORAGE] Saving events to send: ${json.length > 100 ? json.substring(0, 100) + '...' : json}");
    _storage.saveData(_eventsToSendKey, json);
  }

  void _loadEventsToSend() {
    try {
      String data = _storage.loadData(_eventsToSendKey);
      if (data.isNotEmpty) {
        var jsonNode = JSONNode.parse(data);

        if (!jsonNode.exists) return;

        if (jsonNode.data is List) {
          List<dynamic> eventQueuesArray = jsonNode.data;

          for (var eventQueueData in eventQueuesArray) {
            // eventQueueData is already a List of event maps, not a JSON string
            var result = EventQueue.fromArray(eventQueueData);
            _eventsToSend.add(result);
          }
        }
      }
    } catch (ex) {
      Metriqus.errorLog("LoadEventsToSend failed : ${ex.toString()}");
      _eventsToSend.clear();
    }
  }
}
