import 'MetriqusCustomEvent.dart';
import '../../EventLogger/Parameters/TypedParameter.dart';
import '../../Utilities/MetriqusEventKeys.dart';

/// Enum for campaign action types
enum MetriqusCampaignActionType {
  show,
  click,
  close,
  purchase,
  next,
  prev,
  detailsClose
}

/// Represents a campaign action event with campaign details
class MetriqusCampaignActionEvent extends MetriqusCustomEvent {
  String? campaignId;
  String? variantId;
  MetriqusCampaignActionType metriqusCampaignAction =
      MetriqusCampaignActionType.show;

  /// Constructor with campaign details
  MetriqusCampaignActionEvent(
      String campaignId, MetriqusCampaignActionType action,
      {String? variantId})
      : super(MetriqusEventKeys.eventCampaignDetails) {
    this.campaignId = campaignId;
    this.variantId = variantId;
    metriqusCampaignAction = action;
  }

  /// Constructor with campaign details and parameters
  MetriqusCampaignActionEvent.withParameters(String campaignId,
      MetriqusCampaignActionType action, List<TypedParameter> parameters,
      {String? variantId})
      : super.withParameters(
            MetriqusEventKeys.eventCampaignDetails, parameters) {
    this.campaignId = campaignId;
    this.variantId = variantId;
    metriqusCampaignAction = action;
  }

  /// Gets all parameters including campaign-specific ones
  @override
  List<TypedParameter>? getParameters() {
    final copiedParams = List<TypedParameter>.from(parameters ?? []);

    if (campaignId != null && campaignId!.isNotEmpty) {
      copiedParams.add(TypedParameter.string(
          MetriqusEventKeys.parameterCampaignID, campaignId!));
    }

    if (variantId != null && variantId!.isNotEmpty) {
      copiedParams.add(TypedParameter.string(
          MetriqusEventKeys.parameterVariantId, variantId!));
    }

    copiedParams.add(TypedParameter.string(
        MetriqusEventKeys.parameterCampaignAction,
        _getActionString(metriqusCampaignAction)));

    return copiedParams;
  }

  /// Converts action enum to string
  static String _getActionString(MetriqusCampaignActionType action) {
    switch (action) {
      case MetriqusCampaignActionType.show:
        return "show";
      case MetriqusCampaignActionType.click:
        return "click";
      case MetriqusCampaignActionType.close:
        return "close";
      case MetriqusCampaignActionType.purchase:
        return "purchase";
      case MetriqusCampaignActionType.next:
        return "next";
      case MetriqusCampaignActionType.prev:
        return "prev";
      case MetriqusCampaignActionType.detailsClose:
        return "details_close";
    }
  }

  /// Converts to JSON map
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'campaignId': campaignId,
      'variantId': variantId,
      'metriqusCampaignAction': _getActionString(metriqusCampaignAction),
    });
    return json;
  }

  /// Creates instance from JSON map
  factory MetriqusCampaignActionEvent.fromJson(Map<String, dynamic> json) {
    final actionString = json['metriqusCampaignAction'] ?? 'show';
    final action = _parseActionString(actionString);

    final event = MetriqusCampaignActionEvent(
      json['campaignId'] ?? '',
      action,
      variantId: json['variantId'],
    );
    return event;
  }

  /// Parses action string to enum
  static MetriqusCampaignActionType _parseActionString(String actionString) {
    switch (actionString.toLowerCase()) {
      case 'show':
        return MetriqusCampaignActionType.show;
      case 'click':
        return MetriqusCampaignActionType.click;
      case 'close':
        return MetriqusCampaignActionType.close;
      case 'purchase':
        return MetriqusCampaignActionType.purchase;
      case 'next':
        return MetriqusCampaignActionType.next;
      case 'prev':
        return MetriqusCampaignActionType.prev;
      case 'details_close':
        return MetriqusCampaignActionType.detailsClose;
      default:
        return MetriqusCampaignActionType.show;
    }
  }
}
