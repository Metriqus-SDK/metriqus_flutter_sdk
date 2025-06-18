import '../MetriqusCustomEvent.dart';
import '../../../EventLogger/Parameters/TypedParameter.dart';
import '../../../Utilities/MetriqusEventKeys.dart';

/// Represents a level started event with level information
class MetriqusLevelStartedEvent extends MetriqusCustomEvent {
  int? levelNumber;
  String? levelName;
  String? map;

  /// Default constructor
  MetriqusLevelStartedEvent() : super(MetriqusEventKeys.eventLevelStart);

  /// Constructor with parameters
  MetriqusLevelStartedEvent.withParameters(List<TypedParameter> parameters)
      : super.withParameters(MetriqusEventKeys.eventLevelStart, parameters);

  /// Gets all parameters including level-specific ones
  @override
  List<TypedParameter>? getParameters() {
    final copiedParams = List<TypedParameter>.from(parameters ?? []);

    if (levelNumber != null) {
      copiedParams.add(TypedParameter.int(
          MetriqusEventKeys.parameterLevelNumber, levelNumber!));
    }

    if (levelName != null && levelName!.isNotEmpty) {
      copiedParams.add(TypedParameter.string(
          MetriqusEventKeys.parameterLevelName, levelName!));
    }

    if (map != null && map!.isNotEmpty) {
      copiedParams
          .add(TypedParameter.string(MetriqusEventKeys.parameterMap, map!));
    }

    return copiedParams;
  }

  /// Converts to JSON map
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'levelNumber': levelNumber,
      'levelName': levelName,
      'map': map,
    });
    return json;
  }

  /// Creates instance from JSON map
  factory MetriqusLevelStartedEvent.fromJson(Map<String, dynamic> json) {
    final event = MetriqusLevelStartedEvent();
    event.levelNumber = json['levelNumber'];
    event.levelName = json['levelName'];
    event.map = json['map'];
    return event;
  }
}
