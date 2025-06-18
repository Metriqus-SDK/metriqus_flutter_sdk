import '../MetriqusCustomEvent.dart';
import '../../../EventLogger/Parameters/TypedParameter.dart';
import '../../../Utilities/MetriqusEventKeys.dart';

/// Represents a level completed event with detailed level information
class MetriqusLevelCompletedEvent extends MetriqusCustomEvent {
  int? levelNumber;
  String? levelName;
  String? map;
  double? duration;
  double? levelProgress;
  int? levelReward;
  int? levelReward1;
  int? levelReward2;

  /// Default constructor
  MetriqusLevelCompletedEvent() : super(MetriqusEventKeys.eventLevelCompleted);

  /// Constructor with parameters
  MetriqusLevelCompletedEvent.withParameters(List<TypedParameter> parameters)
      : super.withParameters(MetriqusEventKeys.eventLevelCompleted, parameters);

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

    if (duration != null) {
      copiedParams.add(TypedParameter.double(
          MetriqusEventKeys.parameterDuration, duration!));
    }

    if (levelProgress != null) {
      copiedParams.add(TypedParameter.double(
          MetriqusEventKeys.parameterLevelProgress, levelProgress!));
    }

    if (levelReward != null) {
      copiedParams.add(TypedParameter.int(
          MetriqusEventKeys.parameterLevelReward, levelReward!));
    }

    if (levelReward1 != null) {
      copiedParams.add(TypedParameter.int(
          MetriqusEventKeys.parameterLevelReward1, levelReward1!));
    }

    if (levelReward2 != null) {
      copiedParams.add(TypedParameter.int(
          MetriqusEventKeys.parameterLevelReward2, levelReward2!));
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
      'duration': duration,
      'levelProgress': levelProgress,
      'levelReward': levelReward,
      'levelReward1': levelReward1,
      'levelReward2': levelReward2,
    });
    return json;
  }

  /// Creates instance from JSON map
  factory MetriqusLevelCompletedEvent.fromJson(Map<String, dynamic> json) {
    final event = MetriqusLevelCompletedEvent();
    event.levelNumber = json['levelNumber'];
    event.levelName = json['levelName'];
    event.map = json['map'];
    event.duration = json['duration']?.toDouble();
    event.levelProgress = json['levelProgress']?.toDouble();
    event.levelReward = json['levelReward'];
    event.levelReward1 = json['levelReward1'];
    event.levelReward2 = json['levelReward2'];
    return event;
  }
}
