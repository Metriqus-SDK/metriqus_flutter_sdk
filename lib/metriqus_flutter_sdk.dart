/// Metriqus Flutter SDK
///
/// A comprehensive analytics and tracking SDK for Flutter applications.
///
/// This SDK provides:
/// - Event tracking and analytics
/// - User attribute management
/// - Performance monitoring
/// - Ad revenue tracking
/// - Custom event logging
/// - Encrypted storage system
/// - Network request handling
/// - Device information collection
///
/// Example usage:
/// ```dart
/// import 'package:metriqus_flutter_sdk/metriqus_flutter_sdk.dart';
///
/// // Initialize the SDK
/// final settings = MetriqusSettings(
///   clientKey: 'your_client_key',
///   clientSecret: 'your_client_secret',
///   environment: MetriqusEnvironment.development,
///   logLevel: LogLevel.debug,
/// );
///
/// await Metriqus.initSdk(settings);
///
/// // Track events
/// Metriqus.trackCustomEvent('user_action', parameters: {'action': 'button_click'});
///
/// // Track ad revenue
/// Metriqus.trackAdRevenue(
///   adUnit: 'ca-app-pub-xxx/xxx',
///   revenue: 0.05,
///   currency: 'USD',
///   adNetwork: 'AdMob',
///   adType: 'banner',
/// );
///
/// // Set user attributes
/// Metriqus.setUserAttribute('user_id', '12345');
/// ```
library metriqus_flutter_sdk;

// Core SDK
export 'src/Metriqus.dart';
export 'src/MetriqusSettings.dart';
export 'src/MetriqusRemoteSettings.dart';

// Event Logging
export 'src/EventLogger/Event.dart' hide Package;
export 'src/EventLogger/EventQueue.dart';
export 'src/EventLogger/MetriqusLogger.dart';
export 'src/EventLogger/Parameters/IParameter.dart';
export 'src/EventLogger/Parameters/TypedParameter.dart';
export 'src/EventLogger/Parameters/DynamicParameter.dart';

// Event Models
export 'src/EventModels/AdRevenue/MetriqusAdRevenue.dart';
export 'src/EventModels/AdRevenue/MetriqusAdmobAdRevenue.dart';
export 'src/EventModels/AdRevenue/MetriqusApplovinAdRevenue.dart';
export 'src/EventModels/Attribution/MetriqusAttribution.dart';
export 'src/EventModels/CustomEvents/MetriqusCustomEvent.dart';
export 'src/EventModels/MetriqusInAppRevenue.dart';
export 'src/EventModels/CustomEvents/MetriqusItemUsedEvent.dart';
export 'src/EventModels/CustomEvents/LevelProgression/MetriqusLevelStartedEvent.dart';
export 'src/EventModels/CustomEvents/LevelProgression/MetriqusLevelCompletedEvent.dart';
export 'src/EventModels/CustomEvents/MetriqusCampaignActionEvent.dart';

// Utilities
export 'src/Utilities/DeviceInfo.dart';
export 'src/Utilities/MetriqusUtils.dart';
export 'src/Utilities/MetriqusEnvironment.dart';
export 'src/Utilities/UniqueUserIdentifier.dart';
export 'src/Utilities/Backoff.dart';
export 'src/Utilities/InternetConnectionChecker.dart';
export 'src/Utilities/IPGeolocation.dart';

// Storage
export 'src/Storage/IStorage.dart';
export 'src/Storage/Storage.dart';

// Native
export 'src/Native/UserAttributes.dart';
export 'src/Native/MetriqusNative.dart';
export 'src/Native/Android/MetriqusAndroid.dart';
export 'src/Native/iOS/MetriqusIOS.dart';

// Package
export 'src/Package/PackageBuilder.dart';
export 'src/Package/PackageModels/AppInfoPackage.dart';

// Web Request
export 'src/WebRequest/Response.dart';
export 'src/WebRequest/RequestSender.dart';
export 'src/WebRequest/MetriqusResponseObject.dart';
