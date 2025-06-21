import 'dart:convert';
import '../../EventLogger/Parameters/TypedParameter.dart';
import '../../Utilities/MetriqusUtils.dart';
import '../../ThirdParty/SimpleJSON.dart';

/// Represents attribution data for tracking ad performance, supporting both iOS and Android platforms.
class MetriqusAttribution {
  /// Raw attribution data
  String? raw;

  // iOS specific properties
  bool? attribution;
  int? orgId;
  int? campaignId;
  String? conversionType;
  String? clickDate;
  String? claimType;
  int? adGroupId;
  String? countryOrRegion;
  int? keywordId;
  int? adId;

  // Android specific properties
  String? source;
  String? medium;
  String? campaign;
  String? term;
  String? content;
  List<TypedParameter>? params;

  /// Default constructor
  MetriqusAttribution();

  /// Constructor with referrer URL (Android)
  MetriqusAttribution.fromReferrerUrl(String referrerUrl) {
    final queryDict = MetriqusUtils.parseAndSanitize(referrerUrl);
    _parseDict(queryDict, referrerUrl);
  }

  /// Constructor with attribution data dictionary (Android)
  MetriqusAttribution.fromDict(
      Map<String, String> dictAttributionData, String referrerUrl) {
    _parseDict(dictAttributionData, referrerUrl);
  }

  /// Parses a JSON string into a MetriqusAttribution object (iOS)
  static MetriqusAttribution? parse(String attributionJsonString) {
    try {
      final jsonNode = JSONNode.parse(attributionJsonString);
      if (jsonNode == null) return null;

      final attribution = MetriqusAttribution();
      attribution.raw = attributionJsonString.replaceAll('"', ' ');

      // Parse iOS attribution data
      // Use jsonNode.data directly since it's already parsed JSON
      final jsonData = jsonNode.data;

      if (jsonData is Map<String, dynamic>) {
        attribution.attribution =
            _tryParseBool(jsonData["attribution"]?.toString());
        attribution.orgId = _tryParseInt(jsonData["orgId"]?.toString());
        attribution.campaignId =
            _tryParseInt(jsonData["campaignId"]?.toString());
        attribution.conversionType = jsonData["conversionType"]?.toString();
        attribution.clickDate = jsonData["clickDate"]?.toString();
        attribution.claimType = jsonData["claimType"]?.toString();
        attribution.adGroupId = _tryParseInt(jsonData["adGroupId"]?.toString());
        attribution.countryOrRegion = jsonData["countryOrRegion"]?.toString();
        attribution.keywordId = _tryParseInt(jsonData["keywordId"]?.toString());
        attribution.adId = _tryParseInt(jsonData["adId"]?.toString());
      }
      return attribution;
    } catch (e) {
      return null;
    }
  }

  /// Parses and assigns values from a dictionary of attribution data (Android)
  void _parseDict(
      Map<String, String>? dictAttributionData, String referrerUrl) {
    if (dictAttributionData == null || referrerUrl.isEmpty) {
      return;
    }

    raw = referrerUrl.replaceAll('"', ' ');

    source =
        MetriqusUtils.tryGetValue(dictAttributionData, MetriqusUtils.keySource);

    medium =
        MetriqusUtils.tryGetValue(dictAttributionData, MetriqusUtils.keyMedium);

    campaign = MetriqusUtils.tryGetValue(
        dictAttributionData, MetriqusUtils.keyCampaign);

    term =
        MetriqusUtils.tryGetValue(dictAttributionData, MetriqusUtils.keyTerm);

    content = MetriqusUtils.tryGetValue(
        dictAttributionData, MetriqusUtils.keyContent);

    for (final entry in dictAttributionData.entries) {
      if (entry.key == MetriqusUtils.keySource ||
          entry.key == MetriqusUtils.keyMedium ||
          entry.key == MetriqusUtils.keyCampaign ||
          entry.key == MetriqusUtils.keyTerm ||
          entry.key == MetriqusUtils.keyContent) {
        continue;
      }

      params ??= <TypedParameter>[];
      params!.add(TypedParameter.string(entry.key, entry.value));
    }
  }

  /// Helper method to parse boolean values
  static bool? _tryParseBool(String? value) {
    if (value == null || value.isEmpty) return null;
    return value.toLowerCase() == 'true';
  }

  /// Helper method to parse integer values
  static int? _tryParseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  /// Check if attribution data contains test/placeholder values
  static bool _isTestData(MetriqusAttribution attribution) {
    // Common test/placeholder values to detect
    const testValues = [
      1234567890, // Most common test value
      123456789,
      999999999,
      111111111,
      1111111111,
      0, // Zero values can also indicate test data
    ];

    // Check if multiple critical fields contain test values
    final hasTestOrgId = testValues.contains(attribution.orgId);
    final hasTestCampaignId = testValues.contains(attribution.campaignId);
    final hasTestAdGroupId = testValues.contains(attribution.adGroupId);
    final hasTestAdId = testValues.contains(attribution.adId);

    // If 2 or more fields contain the same test value, consider it test data
    if (hasTestOrgId && hasTestCampaignId) return true;
    if (hasTestOrgId && hasTestAdGroupId) return true;
    if (hasTestCampaignId && hasTestAdGroupId) return true;

    // Special case: if orgId is 1234567890 (very obvious test value)
    if (attribution.orgId == 1234567890) return true;

    return false;
  }

  /// Converts the attribution data to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'raw': raw,
      'attribution': attribution,
      'orgId': orgId,
      'campaignId': campaignId,
      'conversionType': conversionType,
      'clickDate': clickDate,
      'claimType': claimType,
      'adGroupId': adGroupId,
      'countryOrRegion': countryOrRegion,
      'keywordId': keywordId,
      'adId': adId,
      'source': source,
      'medium': medium,
      'campaign': campaign,
      'term': term,
      'content': content,
      'params': params?.length ?? 0,
    };
  }

  /// Creates an instance from a JSON map
  factory MetriqusAttribution.fromJson(Map<String, dynamic> json) {
    final attribution = MetriqusAttribution();
    attribution.raw = json['raw'];
    attribution.attribution = json['attribution'];
    attribution.orgId = json['orgId'];
    attribution.campaignId = json['campaignId'];
    attribution.conversionType = json['conversionType'];
    attribution.clickDate = json['clickDate'];
    attribution.claimType = json['claimType'];
    attribution.adGroupId = json['adGroupId'];
    attribution.countryOrRegion = json['countryOrRegion'];
    attribution.keywordId = json['keywordId'];
    attribution.adId = json['adId'];
    attribution.source = json['source'];
    attribution.medium = json['medium'];
    attribution.campaign = json['campaign'];
    attribution.term = json['term'];
    attribution.content = json['content'];
    // params will be handled separately when TypedParameter.fromJson is available
    return attribution;
  }
}
