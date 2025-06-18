import '../../EventLogger/Parameters/TypedParameter.dart';

/// Represents a custom event with a unique key and a list of associated parameters.
class MetriqusCustomEvent {
  /// The unique identifier for the event.
  String? _key;

  /// A list of parameters associated with the event.
  List<TypedParameter>? _parameters;

  // Getters
  String? get key => _key;
  List<TypedParameter>? get parameters => _parameters;

  /// Initializes a new instance with a specified event key.
  MetriqusCustomEvent(String key) {
    _key = key;
    _parameters = <TypedParameter>[];
  }

  /// Initializes a new instance with a specified event key and parameters.
  MetriqusCustomEvent.withParameters(
      String key, List<TypedParameter>? parameters) {
    _key = key;
    _parameters = parameters ?? <TypedParameter>[];
  }

  /// Adds a parameter to the event.
  void addParameter(TypedParameter parameter) {
    _parameters ??= <TypedParameter>[];
    _parameters!.add(parameter);
  }

  /// Gets the parameters associated with the event.
  List<TypedParameter>? getParameters() {
    return _parameters;
  }

  /// Converts the custom event to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'key': _key,
      'parameters': _parameters?.length ?? 0,
    };
  }

  /// Creates an instance from a JSON map.
  factory MetriqusCustomEvent.fromJson(Map<String, dynamic> json) {
    final event = MetriqusCustomEvent(json['key'] ?? '');
    // Parameters will be handled separately when TypedParameter.fromJson is available
    return event;
  }
}
