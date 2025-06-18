import 'MetriqusCustomEvent.dart';
import '../../EventLogger/Parameters/TypedParameter.dart';
import '../../Utilities/MetriqusEventKeys.dart';

/// Represents an item used event with detailed item information
class MetriqusItemUsedEvent extends MetriqusCustomEvent {
  String? itemName;
  double? amount;
  String? itemType;
  String? itemRarity;
  String? itemClass;
  String? itemCategory;
  String? reason;

  /// Default constructor
  MetriqusItemUsedEvent() : super(MetriqusEventKeys.eventItemUsed);

  /// Constructor with parameters
  MetriqusItemUsedEvent.withParameters(List<TypedParameter> parameters)
      : super.withParameters(MetriqusEventKeys.eventItemUsed, parameters);

  /// Gets all parameters including item-specific ones
  @override
  List<TypedParameter>? getParameters() {
    final copiedParams = List<TypedParameter>.from(parameters ?? []);

    if (itemName != null && itemName!.isNotEmpty) {
      copiedParams.add(TypedParameter.string(
          MetriqusEventKeys.parameterItemName, itemName!));
    }

    if (amount != null) {
      copiedParams.add(
          TypedParameter.double(MetriqusEventKeys.parameterAmount, amount!));
    }

    if (itemType != null && itemType!.isNotEmpty) {
      copiedParams.add(TypedParameter.string(
          MetriqusEventKeys.parameterItemType, itemType!));
    }

    if (itemRarity != null && itemRarity!.isNotEmpty) {
      copiedParams.add(TypedParameter.string(
          MetriqusEventKeys.parameterItemRarity, itemRarity!));
    }

    if (itemClass != null && itemClass!.isNotEmpty) {
      copiedParams.add(TypedParameter.string(
          MetriqusEventKeys.parameterItemClass, itemClass!));
    }

    if (itemCategory != null && itemCategory!.isNotEmpty) {
      copiedParams.add(TypedParameter.string(
          MetriqusEventKeys.parameterItemCategory, itemCategory!));
    }

    if (reason != null && reason!.isNotEmpty) {
      copiedParams.add(
          TypedParameter.string(MetriqusEventKeys.parameterReason, reason!));
    }

    return copiedParams;
  }

  /// Converts to JSON map
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'itemName': itemName,
      'amount': amount,
      'itemType': itemType,
      'itemRarity': itemRarity,
      'itemClass': itemClass,
      'itemCategory': itemCategory,
      'reason': reason,
    });
    return json;
  }

  /// Creates instance from JSON map
  factory MetriqusItemUsedEvent.fromJson(Map<String, dynamic> json) {
    final event = MetriqusItemUsedEvent();
    event.itemName = json['itemName'];
    event.amount = json['amount']?.toDouble();
    event.itemType = json['itemType'];
    event.itemRarity = json['itemRarity'];
    event.itemClass = json['itemClass'];
    event.itemCategory = json['itemCategory'];
    event.reason = json['reason'];
    return event;
  }
}
