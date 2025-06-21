# Metriqus Flutter SDK Example

This is a comprehensive example application for the Metriqus Flutter SDK. Metriqus is a data analytics platform for web and mobile.

## 🚀 Features

- ✅ **Complete Event Tracking**: Custom events, level progression, item usage
- ✅ **Revenue Tracking**: IAP events, Ad revenue (AdMob, AppLovin)
- ✅ **User Management**: User attributes, device info
- ✅ **SDK Control**: Initialization, settings, debug
- ✅ **Lifecycle Management**: App state tracking
- ✅ **Real-time Logs**: SDK event monitoring

## 📋 Requirements

- **iOS**: 12.0 or later
- **Android**: API level 21 (Lollipop) or later  
- **Flutter**: 3.0.0 or later

## 📦 Installation

### Method 1: Install from pub.dev

Add to your `pubspec.yaml`:

```yaml
dependencies:
  metriqus_flutter_sdk: ^1.0.0
```

Then run:
```bash
flutter pub get
```

### Method 2: Install from Git Repository

```yaml
dependencies:
  metriqus_flutter_sdk:
    git:
      url: https://github.com/Metriqus-SDK/flutter_sdk.git
```

## 🔧 SDK Integration

### Basic Setup

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

## 📊 Event Tracking

### In-App Purchase Events

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

### Custom Events

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

### Level Progression

```dart
void trackLevelStarted() {
  final levelStartEvent = MetriqusLevelStartedEvent();
  levelStartEvent.levelNumber = 5;
  levelStartEvent.levelName = 'Dragon Valley';
  levelStartEvent.map = 'fantasy_world';

  Metriqus.trackLevelStarted(levelStartEvent);
}

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

### Item Usage

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

### Screen & Performance Tracking

```dart
// Track screen views
Metriqus.trackScreenView('MainMenu');

// Track performance metrics
Metriqus.trackPerformance(60); // 60 FPS

// Track button clicks
Metriqus.trackButtonClick('PlayButton');
```

## 💰 Ad Revenue Tracking

### General Ad Revenue

```dart
void trackAdRevenue() {
  final adRevenue = MetriqusAdRevenue.withRevenue(0.15, 'USD');
  adRevenue.source = 'metriqus';
  adRevenue.adRevenueUnit = 'banner_main_001';
  adRevenue.adRevenueNetwork = 'AdMob';
  adRevenue.adRevenuePlacement = 'main_screen';
  adRevenue.adImpressionsCount = 1;
  
  Metriqus.trackAdRevenue(adRevenue);
}
```

### AdMob Specific

```dart
void trackAdmobRevenue() {
  final admobRevenue = MetriqusAdmobAdRevenue.withRevenue(0.22, 'EUR');
  admobRevenue.adRevenueUnit = 'ca-app-pub-123456789/987654321';
  admobRevenue.adRevenueNetwork = 'AdMob';
  admobRevenue.adRevenuePlacement = 'interstitial';
  admobRevenue.adImpressionsCount = 1;
  
  Metriqus.trackAdmobAdRevenue(admobRevenue);
}
```

### AppLovin Specific

```dart
void trackApplovinRevenue() {
  final applovinRevenue = MetriqusApplovinAdRevenue.withRevenue(0.18, 'USD');
  applovinRevenue.adRevenueUnit = 'applovin_rewarded_001';
  applovinRevenue.adRevenueNetwork = 'AppLovin MAX';
  applovinRevenue.adRevenuePlacement = 'level_complete';
  applovinRevenue.adImpressionsCount = 1;
  
  Metriqus.trackApplovinAdRevenue(applovinRevenue);
}
```

## 📢 Campaign & Action Tracking

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

## 👤 User Management

### User Attributes

```dart
// Set user attributes
Metriqus.setUserAttribute(TypedParameter.int('user_level', 25));
Metriqus.setUserAttribute(TypedParameter.bool('is_premium', true));
Metriqus.setUserAttribute(TypedParameter.string('user_type', 'premium'));

// Get user attributes
final attributes = Metriqus.getUserAttributes();

// Remove user attribute
Metriqus.removeUserAttribute('user_type');
```

## 📱 Device Information

```dart
// Get various device information
final adid = Metriqus.getAdid();
final deviceInfo = Metriqus.getDeviceInfo();
final userId = Metriqus.getUserId();
final sessionId = Metriqus.getSessionId();
final geolocation = Metriqus.getGeolocation();

// Check first launch
final isFirstLaunch = Metriqus.isFirstLaunch();
final firstTouchTime = Metriqus.getUserFirstTouchTimestamp();
```

## 🔧 SDK Control

```dart
// Check SDK status
final isInitialized = Metriqus.isInitialized;
final isTrackingEnabled = Metriqus.isTrackingEnabled;

// Get current settings
final settings = Metriqus.getMetriqusSettings();

// Debug logging
Metriqus.verboseLog("Debug message");

// iOS conversion value (iOS only)
Metriqus.updateIOSConversionValue(3);

// Clear storage (for debugging)
Metriqus.clearStorage();
```

## 🚀 Running the Example

```bash
cd example
flutter pub get
flutter run
```

## 📝 Configuration

### Environment Settings

```dart
// For testing
environment: Environment.sandbox

// For production
environment: Environment.production
```

### Log Levels

```dart
logLevel: LogLevel.verbose    // All logs
logLevel: LogLevel.error      // Error logs only
logLevel: LogLevel.noLog      // No logs
```

### Parameter Types

```dart
TypedParameter.string('key', 'value')
TypedParameter.int('key', 123)
TypedParameter.double('key', 12.34)
TypedParameter.bool('key', true)
```

## 🛠️ Troubleshooting

### SDK Initialization Issues

```dart
Metriqus.onSdkInitialize.listen((isInitialized) {
  if (!isInitialized) {
    print('❌ SDK initialization failed');
  }
});
```

### Tracking Issues

```dart
if (Metriqus.isInitialized) {
  // Your tracking code here
} else {
  print('⚠️ SDK not initialized yet');
}
```