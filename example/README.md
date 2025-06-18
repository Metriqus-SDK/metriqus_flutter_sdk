# Metriqus SDK for Flutter

This is the Metriqus SDK for Flutter. Metriqus is a data analytic platform for web and mobile.

## Compatibility

- This SDK supports iOS 12 or later and Android API level 21 (Lollipop) or later.
- The SDK is compatible with Flutter 3.0.0 or later.

## Installation

To install the Metriqus SDK, choose one of the following methods.

### 1. Install via pub.dev

To use the Metriqus SDK in your Flutter app, add it to your `pubspec.yaml`:

```yaml
dependencies:
  metriqus_flutter_sdk: ^1.0.0
```

Then run:
```bash
flutter pub get
```

### 2. Install from Git Repository

To install the Metriqus SDK from Git repository, add this to your `pubspec.yaml`:

```yaml
dependencies:
  metriqus_flutter_sdk:
    git:
      url: https://github.com/Metriqus-SDK/flutter_sdk.git
```

## Integrate the SDK

The Metriqus SDK initialization is handled in your `main.dart` file. To set up the Metriqus SDK:

```dart
import 'package:metriqus_flutter_sdk/metriqus_flutter_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final settings = MetriqusSettings();
  settings.clientKey = 'your_client_key';        // Check your dashboard for instructions
  settings.clientSecret = 'your_client_secret';  // Check your dashboard for instructions
  settings.environment = MetriqusEnvironment.sandbox; // Choose environment
  settings.logLevel = LogLevel.verbose;           // Control log output
  
  await Metriqus.initSdk(settings);
  
  runApp(MyApp());
}
```

To set up the Metriqus SDK, enter the following information:

- **Client Key**: Check your dashboard for instructions to find your client key.
- **Client Secret**: Check your dashboard for instructions to find your client secret.
- **Environment**:
  - Choose `MetriqusEnvironment.sandbox` if you are testing your app and want to send test data. You need to enable sandbox mode in the dashboard to see test data.
  - Choose `MetriqusEnvironment.production` when you have finished testing and are ready to release your app.
- **Log Level**: This controls what logs you receive.

The Metriqus SDK starts automatically when `initSdk()` is called. You can also initialize manually by calling:

```dart
Metriqus.initSdk(metriqusSettings);
```

## Metriqus SDK Tracking API

The following functions allow you to track user events, ad revenue, and other analytics-related actions within your Flutter project.

### Event Tracking Functions

#### `trackIAPEvent(MetriqusInAppRevenue metriqusEvent)`
Tracks in-app purchase (IAP) events.

```dart
final iapRevenue = MetriqusInAppRevenue.withRevenue(4.99, 'USD');
iapRevenue.productId = 'premium_upgrade';
iapRevenue.setTransactionId('txn_12345');
Metriqus.trackIAPEvent(iapRevenue);
```

#### `trackCustomEvent(String eventName, {Map<String, dynamic>? parameters})`
Tracks custom events with optional parameters.

```dart
Metriqus.trackCustomEvent('button_clicked', parameters: {
  'button_name': 'play_button',
  'screen': 'main_menu',
});
```

#### `trackLevelStarted(MetriqusLevelStartedEvent levelEvent)`
Tracks when a level is started.

```dart
final levelStartEvent = MetriqusLevelStartedEvent();
levelStartEvent.levelNumber = 5;
levelStartEvent.levelName = 'Dragon Valley';
levelStartEvent.map = 'fantasy_world';

Metriqus.trackLevelStarted(levelStartEvent);
```

#### `trackLevelCompleted(MetriqusLevelCompletedEvent levelEvent)`
Tracks when a level is completed.

```dart
final levelCompletedEvent = MetriqusLevelCompletedEvent();
levelCompletedEvent.levelNumber = 5;
levelCompletedEvent.levelName = 'Dragon Valley';
levelCompletedEvent.map = 'fantasy_world';
levelCompletedEvent.duration = 240.0;
levelCompletedEvent.levelProgress = 100.0;
levelCompletedEvent.levelReward = 15000;

Metriqus.trackLevelCompleted(levelCompletedEvent);
```

#### `trackItemUsed(MetriqusItemUsedEvent itemEvent)`
Tracks when an item is used.

```dart
final itemUsedEvent = MetriqusItemUsedEvent();
itemUsedEvent.itemName = 'health_potion';
itemUsedEvent.amount = 1.0;
itemUsedEvent.itemType = 'consumable';
itemUsedEvent.itemRarity = 'common';
itemUsedEvent.itemClass = 'healing';
itemUsedEvent.itemCategory = 'potion';
itemUsedEvent.reason = 'battle';

Metriqus.trackItemUsed(itemUsedEvent);
```

#### `trackCampaignAction(MetriqusCampaignActionEvent campaignEvent)`
Tracks campaign action events.

```dart
final campaignEvent = MetriqusCampaignActionEvent(
  'summer_2024',
  'variant_a', 
  MetriqusCampaignActionType.click
);

Metriqus.trackCampaignAction(campaignEvent);
```

#### `trackPerformance(double fps, {Map<String, dynamic>? parameters})`
Tracks performance metrics like FPS.

```dart
Metriqus.trackPerformance(60);
```

#### `trackScreenView(String screenName, {Map<String, dynamic>? parameters})`
Tracks screen view events.

```dart
Metriqus.trackScreenView('MainMenu');
```

#### `trackButtonClick(String buttonName, {Map<String, dynamic>? parameters})`
Tracks button click events.

```dart
Metriqus.trackButtonClick('PlayButton');
```

### Ad Revenue Tracking Functions

#### `trackAdRevenue(Map<String, dynamic> adRevenueData)`
Tracks general ad revenue.

```dart
final adRevenue = MetriqusAdRevenue.withRevenue('metriqus', 0.15, 'USD');
adRevenue.adRevenueUnit = 'banner_main';
adRevenue.adRevenueNetwork = 'AdMob';
Metriqus.trackAdRevenue(adRevenue.toJson());
```

#### AdMob Ad Revenue Tracking
Tracks AdMob-specific ad revenue.

```dart
final admobRevenue = MetriqusAdmobAdRevenue.withRevenue(0.22, 'EUR');
admobRevenue.adRevenueUnit = 'ca-app-pub-xxx/xxx';
Metriqus.trackAdRevenue(admobRevenue.toJson());
```

#### AppLovin Ad Revenue Tracking
Tracks AppLovin-specific ad revenue.

```dart
final applovinRevenue = MetriqusApplovinAdRevenue.withRevenue(0.18, 'USD');
applovinRevenue.adRevenueUnit = 'applovin_banner_1';
Metriqus.trackAdRevenue(applovinRevenue.toJson());
```

### User Attribute Functions

#### `setUserAttribute(String key, dynamic value)`
Sets a user attribute.

```dart
Metriqus.setUserAttribute('user_level', 25);
Metriqus.setUserAttribute('is_premium', true);
Metriqus.setUserAttribute('user_type', 'premium');
```

#### `getUserAttributes()`
Gets all user attributes.

```dart
final attributes = Metriqus.getUserAttributes();
print('User attributes: $attributes');
```

#### `removeUserAttribute(String key)`
Removes a user attribute.

```dart
Metriqus.removeUserAttribute('user_type');
```

### Device and System Information Functions

#### `getAdid()`
Gets the advertising ID.

```dart
final adid = await Metriqus.getAdid();
print('Advertising ID: $adid');
```

#### `getDeviceInfo()`
Gets device information.

```dart
final deviceInfo = await Metriqus.getDeviceInfo();
print('Device Info: $deviceInfo');
```

#### `getUserId()`
Gets the unique user ID.

```dart
final userId = await Metriqus.getUserId();
print('User ID: $userId');
```

#### `getSessionId()`
Gets the current session ID.

```dart
final sessionId = await Metriqus.getSessionId();
print('Session ID: $sessionId');
```

#### `getGeolocation()`
Gets geolocation information.

```dart
final geolocation = await Metriqus.getGeolocation();
print('Geolocation: $geolocation');
```

#### `isFirstLaunch()`
Checks if this is the first app launch.

```dart
final isFirstLaunch = await Metriqus.isFirstLaunch();
print('Is First Launch: $isFirstLaunch');
```

#### `getUserFirstTouchTimestamp()`
Gets the user's first touch timestamp.

```dart
final timestamp = await Metriqus.getUserFirstTouchTimestamp();
print('First Touch: $timestamp');
```

### SDK State and Control Functions

#### `isInitialized`
Checks if the SDK is initialized.

```dart
final isInitialized = Metriqus.isInitialized;
print('SDK Initialized: $isInitialized');
```

#### `isTrackingEnabled`
Checks if tracking is enabled.

```dart
final isTrackingEnabled = Metriqus.isTrackingEnabled;
print('Tracking Enabled: $isTrackingEnabled');
```

#### `getMetriqusSettings()`
Gets the current SDK settings.

```dart
final settings = await Metriqus.getMetriqusSettings();
print('SDK Settings: $settings');
```

#### `debugLog(String message, LogLevel logLevel)`
Sends a manual debug log.

```dart
Metriqus.debugLog("Hello Metriqus!", LogLevel.debug);
```

#### `updateIOSConversionValue(int value)` (iOS Only)
Updates iOS conversion value.

```dart
Metriqus.updateIOSConversionValue(5); // Only works on iOS
```

### Campaign Action Tracking

#### Campaign Action Events
Tracks campaign-related actions using event objects.

```dart
final campaignEvent = MetriqusCampaignActionEvent(
  'summer_2024',
  'variant_a', 
  MetriqusCampaignActionType.click
);

Metriqus.trackCampaignAction(campaignEvent);
```

## Example Implementation

This example demonstrates all Metriqus SDK features in a complete Flutter application. The example includes:

- **Event Tracking**: Custom events, level progression, item usage
- **Revenue Tracking**: IAP events, ad revenue from multiple networks
- **User Management**: Setting, getting, and removing user attributes
- **Device Information**: Accessing device and system information
- **SDK Control**: Managing SDK state and settings

## Usage Notes

- Ensure the SDK is initialized before calling any tracking functions
- Use `MetriqusEnvironment.sandbox` for testing and `MetriqusEnvironment.production` for live apps
- All tracking functions are designed for Flutter Android/iOS platforms
- User attributes are automatically persisted and loaded across app sessions
- Performance tracking helps monitor app performance metrics
- Ad revenue tracking supports multiple ad networks (AdMob, AppLovin, etc.)

## Support

- 📧 Email: support@metriqus.com
- 📖 Documentation: [https://docs.metriqus.com](https://docs.metriqus.com)
- 🐛 Bug Reports: [GitHub Issues](https://github.com/metriqus/flutter-sdk/issues)

---

**Complete Metriqus Flutter SDK with all features!** 🚀 