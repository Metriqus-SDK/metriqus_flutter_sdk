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


## Integrate the SDK

The Metriqus SDK initialization is handled in your `main.dart` file. To set up the Metriqus SDK:

```dart
import 'package:metriqus_flutter_sdk/metriqus_flutter_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup SDK listeners
  Metriqus.onLog.listen((logMessage) {
    print('🔵 Metriqus Log: $logMessage');
  });

  Metriqus.onSdkInitialize.listen((isInitialized) {
    print('🔧 SDK Initialization: ${isInitialized ? 'SUCCESS' : 'FAILED'}');
  });

  // Initialize SDK
  final settings = MetriqusSettings(
    clientKey: 'your_client_key',
    clientSecret: 'your_client_secret',
    environment: Environment.sandbox,
    logLevel: LogLevel.verbose,
  );

  Metriqus.initSdk(settings);
  runApp(MyApp());
}
```

To set up the Metriqus SDK, enter the following information:

- **Client Key**: Check your credentials to find your client key.
- **Client Secret**: Check your credentials to find your client secret.
- **Environment**:
  - Choose `Environment.sandbox` if you are testing your app and want to send test data. You need to enable sandbox mode in the dashboard to see test data.
  - Choose `Environment.production` when you have finished testing and are ready to release your app.
- **Log Level**: This controls what logs you receive.

The Metriqus SDK starts automatically when `initSdk()` is called. You can also initialize manually by calling:

```dart
Metriqus.initSdk(metriqusSettings);
```

## Metriqus SDK Tracking API

The following functions allow you to track user events, ad revenue, and other analytics-related actions within your Flutter project.

### Event Tracking Functions

- **`trackIAPEvent(MetriqusInAppRevenue metriqusEvent)`**  
  Tracks in-app purchase (IAP) events.

- **`trackCustomEvent(MetriqusCustomEvent customEvent)`**  
  Tracks custom events with user-defined parameters.

- **`trackPerformance(double fps)`**  
  Tracks FPS and other performance-related metrics.

- **`trackItemUsed(MetriqusItemUsedEvent itemEvent)`**  
  Tracks when an item (currency, equipment, etc.) is used.

- **`trackLevelStarted(MetriqusLevelStartedEvent levelEvent)`**  
  Tracks when a level starts.

- **`trackLevelCompleted(MetriqusLevelCompletedEvent levelEvent)`**  
  Tracks when a level is completed.

- **`trackCampaignAction(MetriqusCampaignActionEvent campaignEvent)`**  
  Tracks campaign-related actions such as "Showed", "Clicked", "Closed", or "Purchased".

- **`trackScreenView(String screenName)`**  
  Tracks when a user views a specific screen in the app.

- **`trackButtonClick(String buttonName)`**  
  Tracks button click events.

### Ad Revenue Tracking Functions

- **`trackAdRevenue(MetriqusAdRevenue adRevenue)`**  
  Tracks general ad revenue.

- **`trackAdmobAdRevenue(MetriqusAdmobAdRevenue admobRevenue)`**  
  Tracks ad revenue from AdMob.

- **`trackApplovinAdRevenue(MetriqusApplovinAdRevenue applovinRevenue)`**  
  Tracks ad revenue from AppLovin.

### User Attribute Functions

- **`setUserAttribute(TypedParameter parameter)`**  
  Sets a user attribute.

- **`getUserAttributes()`**  
  Retrieves all user attributes.

- **`removeUserAttribute(String key)`**  
  Removes a specific user attribute by key.

### Device and System Information Functions

- **`getAdid()`**  
  Retrieves the Advertising ID (AdID) of the user.

- **`getDeviceInfo()`**  
  Retrieves device information.

- **`getUserId()`**  
  Retrieves the unique user identifier.

- **`getSessionId()`**  
  Retrieves the current session ID.

- **`getGeolocation()`**  
  Retrieves geolocation data.

- **`isFirstLaunch()`**  
  Checks if this is the first app launch.

- **`getUserFirstTouchTimestamp()`**  
  Retrieves the user's first touch timestamp.

### SDK State and Control Functions

- **`isInitialized`**  
  Checks whether the Metriqus SDK is initialized.

- **`isTrackingEnabled`**  
  Checks whether tracking is enabled.

- **`getMetriqusSettings()`**  
  Retrieves the Metriqus SDK settings.

- **`verboseLog(String message)`**  
  Sends a manual debug log.

- **`updateIOSConversionValue(int value)`** (iOS Only)  
  Updates iOS conversion value.

- **`clearStorage()`**  
  Clears all cached data (for debugging).

### Notes

- These functions are designed for Flutter Android/iOS platforms.
- Ensure the SDK is initialized before calling any tracking functions.
- Use `Environment.sandbox` for testing and `Environment.production` for live apps.
- All tracking functions are designed to work seamlessly across app sessions.

## Usage Guide

### Initialization

```dart
import 'package:metriqus_flutter_sdk/metriqus_flutter_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final settings = MetriqusSettings(
    clientKey: 'your_client_key',
    clientSecret: 'your_client_secret',
    environment: Environment.sandbox,
    logLevel: LogLevel.verbose,
  );
  
  Metriqus.initSdk(settings);
  runApp(MyApp());
}
```

### App Lifecycle Management

```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        Metriqus.onResume();
        break;
      case AppLifecycleState.paused:
        Metriqus.onPause();
        break;
      case AppLifecycleState.detached:
        Metriqus.onQuit();
        break;
    }
  }
}
```

### Event Tracking

#### Track Custom Events

```dart
void trackCustomEvent() {
  final customEvent = MetriqusCustomEvent('button_clicked');
  customEvent.addParameter(TypedParameter.string('button_name', 'play_button'));
  customEvent.addParameter(TypedParameter.string('screen', 'main_menu'));
  customEvent.addParameter(TypedParameter.int('timestamp', MetriqusUtils.getCurrentUtcTimestampSeconds()));
  customEvent.addParameter(TypedParameter.int('user_level', 5));
  customEvent.addParameter(TypedParameter.string('test', 'test'));
  customEvent.addParameter(TypedParameter.bool('test', true));
  customEvent.addParameter(TypedParameter.int('test', 1));
  customEvent.addParameter(TypedParameter.double('test', 1.0));
  
  Metriqus.trackCustomEvent(customEvent);
}
```

#### Track In-App Purchases (IAP)

```dart
void trackIAPEvent() {
  final iapRevenue = MetriqusInAppRevenue.withRevenue(4.99, 'USD');
  iapRevenue.brand = 'metriqus';
  iapRevenue.variant = 'premium';
  iapRevenue.productId = 'premium_upgrade';
  iapRevenue.name = 'Premium Upgrade';
  iapRevenue.category = 'upgrade';
  iapRevenue.category2 = 'upgrade';
  iapRevenue.category3 = 'upgrade';
  iapRevenue.category4 = 'upgrade';
  iapRevenue.category5 = 'upgrade';
  iapRevenue.price = 4.99;
  iapRevenue.quantity = 1;
  iapRevenue.refund = 0;
  iapRevenue.coupon = 'TEST2025';
  iapRevenue.affiliation = 'metriqus';
  iapRevenue.locationId = 'location_123';
  iapRevenue.listId = 'list_123';
  iapRevenue.listName = 'list_123';
  iapRevenue.listIndex = 1;
  iapRevenue.promotionId = 'promo_123';
  iapRevenue.promotionName = 'promo_123';
  iapRevenue.creativeName = 'creative_123';
  iapRevenue.creativeSlot = 'slot_123';
  
  // Item parameters
  iapRevenue.itemParams = [
    TypedParameter.string('test', 'test'),
    TypedParameter.bool('test', true),
    TypedParameter.int('test', 1),
    TypedParameter.double('test', 1.0),
  ];

  iapRevenue.setTransactionId('txn_${MetriqusUtils.getCurrentUtcTimestampSeconds()}');
  Metriqus.trackIAPEvent(iapRevenue);
}
```

#### Track Performance (FPS)

```dart
Metriqus.trackPerformance(60);
```

#### Track Item Usage

```dart
void trackItemUsed() {
  final itemUsedEvent = MetriqusItemUsedEvent();
  itemUsedEvent.itemName = 'health_potion';
  itemUsedEvent.amount = 1.0;
  itemUsedEvent.itemType = 'consumable';
  itemUsedEvent.itemRarity = 'common';
  itemUsedEvent.itemClass = 'healing';
  itemUsedEvent.itemCategory = 'potion';
  itemUsedEvent.reason = 'battle';

  Metriqus.trackItemUsed(itemUsedEvent);
}
```

#### Track Level Start

```dart
void trackLevelStarted() {
  final levelStartEvent = MetriqusLevelStartedEvent();
  levelStartEvent.levelNumber = 5;
  levelStartEvent.levelName = 'Dragon Valley';
  levelStartEvent.map = 'fantasy_world';

  Metriqus.trackLevelStarted(levelStartEvent);
}
```

#### Track Level Completion

```dart
void trackLevelCompleted() {
  final levelCompletedEvent = MetriqusLevelCompletedEvent();
  levelCompletedEvent.levelNumber = 5;
  levelCompletedEvent.levelName = 'Dragon Valley';
  levelCompletedEvent.map = 'fantasy_world';
  levelCompletedEvent.duration = 240.0; // 4 minutes
  levelCompletedEvent.levelProgress = 100.0;
  levelCompletedEvent.levelReward = 15000;
  levelCompletedEvent.levelReward1 = 500; // experience
  levelCompletedEvent.levelReward2 = 200; // coins

  Metriqus.trackLevelCompleted(levelCompletedEvent);
}
```

#### Track Campaign Actions

```dart
void trackCampaignAction() {
  final campaignEvent = MetriqusCampaignActionEvent(
    'summer_2024', 
    'variant_a', 
    MetriqusCampaignActionType.click
  );
  
  Metriqus.trackCampaignAction(campaignEvent);
}
```

#### Track Screen View

```dart
Metriqus.trackScreenView('MainMenu');
```

#### Track Button Click

```dart
Metriqus.trackButtonClick('PlayButton');
```

#### Track Ad Revenue (Generic, AdMob, AppLovin)

```dart
// General Ad Revenue
void trackAdRevenue() {
  final adRevenue = MetriqusAdRevenue.withRevenue(0.15, 'USD');
  adRevenue.source = 'metriqus';
  adRevenue.adRevenueUnit = 'banner_main_001';
  adRevenue.adRevenueNetwork = 'AdMob';
  adRevenue.adRevenuePlacement = 'main_screen';
  adRevenue.adImpressionsCount = 1;
  
  Metriqus.trackAdRevenue(adRevenue);
}

// AdMob Ad Revenue
void trackAdmobRevenue() {
  final admobRevenue = MetriqusAdmobAdRevenue.withRevenue(0.22, 'EUR');
  admobRevenue.adRevenueUnit = 'ca-app-pub-123456789/987654321';
  admobRevenue.adRevenueNetwork = 'AdMob';
  admobRevenue.adRevenuePlacement = 'interstitial';
  admobRevenue.adImpressionsCount = 1;
  
  Metriqus.trackAdmobAdRevenue(admobRevenue);
}

// AppLovin Ad Revenue
void trackApplovinRevenue() {
  final applovinRevenue = MetriqusApplovinAdRevenue.withRevenue(0.18, 'USD');
  applovinRevenue.adRevenueUnit = 'applovin_rewarded_001';
  applovinRevenue.adRevenueNetwork = 'AppLovin MAX';
  applovinRevenue.adRevenuePlacement = 'level_complete';
  applovinRevenue.adImpressionsCount = 1;
  
  Metriqus.trackApplovinAdRevenue(applovinRevenue);
}
```

### User Attributes

#### Set User Attribute

```dart
Metriqus.setUserAttribute(TypedParameter.string('user_type', 'premium'));
Metriqus.setUserAttribute(TypedParameter.int('user_level', 25));
Metriqus.setUserAttribute(TypedParameter.bool('is_premium', true));
```

#### Get All User Attributes

```dart
final attributes = Metriqus.getUserAttributes();
```

#### Remove a User Attribute

```dart
Metriqus.removeUserAttribute('user_type');
```

### User & Session Info

#### Get Advertising ID

```dart
final adid = Metriqus.getAdid();
```

#### Get Device Info

```dart
final deviceInfo = Metriqus.getDeviceInfo();
```

#### Get Unique User ID

```dart
final userId = Metriqus.getUserId();
```

#### Get Session ID

```dart
final sessionId = Metriqus.getSessionId();
```

#### Get Geolocation

```dart
final geolocation = Metriqus.getGeolocation();
```

#### Check if First Launch

```dart
final isFirstLaunch = Metriqus.isFirstLaunch();
```

#### Get First Touch Timestamp

```dart
final timestamp = Metriqus.getUserFirstTouchTimestamp();
```

### SDK Settings & Debugging

#### Check Initialization

```dart
final isInitialized = Metriqus.isInitialized;
```

#### Check Tracking Enabled

```dart
final isTrackingEnabled = Metriqus.isTrackingEnabled;
```

#### Get Metriqus Settings

```dart
final settings = Metriqus.getMetriqusSettings();
```

#### Manual Debug Log

```dart
Metriqus.verboseLog('Hello Metriqus!');
```

#### iOS Conversion Value Update

(Only available on iOS builds)

```dart
Metriqus.updateIOSConversionValue(5);
```

#### Clear Storage (Debug)

```dart
Metriqus.clearStorage();
```

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

## License

MIT