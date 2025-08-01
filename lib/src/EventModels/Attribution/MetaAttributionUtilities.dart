import 'dart:convert';
import '../../Package/PackageModels/AppInfoPackage.dart';
import '../../WebRequest/RequestSender.dart';
import '../../Metriqus.dart';
import '../../ThirdParty/SimpleJSON.dart';

class MetaUtmDecryptionRequest {
  String? data;
  String? nonce;
  String? bundle;
  String? uid;

  MetaUtmDecryptionRequest({this.data, this.nonce, this.bundle, this.uid});

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'nonce': nonce,
      'bundle': bundle,
      'uid': uid,
    };
  }
}

class MetaAttributionUtilities {
  static const String facebookUtmSource = "apps.facebook.com";
  static const String instagramUtmSource = "apps.instagram.com";
  static const String metaUtmDecryptionUrl = "https://mtrqs.com/meta/decrypt";

  static bool isMetaUtm(String? utmSource) {
    if (utmSource == null || utmSource.isEmpty) {
      return false;
    }
    return utmSource == facebookUtmSource || utmSource == instagramUtmSource;
  }

  static Future<String?> decryptMetaUtm(String? utmContent) async {
    if (utmContent == null) return null;

    try {
      final jsonNode = JSONNode.parse(utmContent);

      if (jsonNode.data == null) {
        return null;
      }

      final source = jsonNode["source"];

      if (source.data == null) return null;

      final data = source["data"];
      final nonce = source["nonce"];

      if (data.data == null || nonce.data == null) return null;

      final appInfo = await AppInfoPackage.getCurrentAppInfo();
      final bundleId = appInfo?.packageName;

      final userId = Metriqus.getUniqueUserId();
      if (userId == null) return null;

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final req = MetaUtmDecryptionRequest(
        data: data.value,
        nonce: nonce.value,
        bundle: bundleId,
        uid: userId,
      );

      final response = await RequestSender.postAsync(
        metaUtmDecryptionUrl,
        jsonEncode(req.toJson()),
        headers: headers,
      );

      if (response.isSuccess) {
        return response.data;
      } else {
        Metriqus.errorLog(
          'DecryptMetaUtm failed, status code: ${response.statusCode} error: ${response.errors?.isNotEmpty == true ? response.errors![0] : "Unknown error"}',
        );
        return null;
      }
    } catch (e) {
      Metriqus.errorLog('Error in decryptMetaUtm: $e');
      return null;
    }
  }
}
