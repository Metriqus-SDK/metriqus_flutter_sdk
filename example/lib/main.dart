import 'package:flutter/material.dart';
import 'package:metriqus_flutter_sdk/metriqus_flutter_sdk.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const MyApp());
  } catch (e) {
    print('❌ Error in main(): $e');
    runApp(const MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupSDKListeners();
    _initSDK();
  }

  void _setupSDKListeners() {
    Metriqus.onLog.listen((logMessage) {
      print('🔵 Metriqus Log: $logMessage');
    });

    Metriqus.onSdkInitialize.listen((isInitialized) {
      print(
          '🔧 Metriqus SDK Initialization: ${isInitialized ? 'SUCCESS' : 'FAILED'}');
    });
  }

  void _initSDK() {
    print('🚀 Starting Metriqus SDK initialization...');

    final settings = MetriqusSettings(
      clientKey: 'bwwknjmjelo2klmu',
      clientSecret: 'bIrlx2M61pUZ7PzZ0SXTqnFAtIqBT7wM',
      environment: Environment.sandbox,
      logLevel: LogLevel.noLog,
    );

    print('🔧 Settings: ${settings.environment} - ${settings.logLevel}');

    Metriqus.initSdk(settings);

    print('🔄 SDK initialization method called');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        Metriqus.onResume();
        break;
      case AppLifecycleState.inactive:
        Metriqus.onPause();
        break;
      case AppLifecycleState.paused:
        Metriqus.onPause();
        break;
      case AppLifecycleState.detached:
        Metriqus.onQuit();
        break;
      case AppLifecycleState.hidden:
        Metriqus.onPause();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metriqus Flutter SDK Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'Metriqus Flutter SDK Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _statusText = 'Ready to test Metriqus Flutter SDK functions';
  bool _isLoading = false;

  void _updateStatus(String status) {
    setState(() {
      _statusText = status;
      _isLoading = false;
    });
  }

  void _setLoading() {
    setState(() {
      _isLoading = true;
      _statusText = 'Processing...';
    });
  }

  // trackIAPEvent Function
  void _trackIAPEvent() {
    _setLoading();
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
    iapRevenue.itemParams = [
      TypedParameter.string('test', 'test'),
      TypedParameter.bool('test', true),
      TypedParameter.int('test', 1),
      TypedParameter.double('test', 1.0),
    ];

    iapRevenue.setTransactionId(
        'txn_${MetriqusUtils.getCurrentUtcTimestampSeconds()}');
    Metriqus.trackIAPEvent(iapRevenue);
    _updateStatus('✅ IAP Event Tracked: Premium Upgrade \$4.99 USD');
  }

  // trackCustomEvent Function
  void _trackCustomEvent() {
    _setLoading();
    final customEvent = MetriqusCustomEvent('button_clicked');
    customEvent
        .addParameter(TypedParameter.string('button_name', 'play_button'));
    customEvent.addParameter(TypedParameter.string('screen', 'main_menu'));
    customEvent.addParameter(TypedParameter.int(
        'timestamp', MetriqusUtils.getCurrentUtcTimestampSeconds()));
    customEvent.addParameter(TypedParameter.int('user_level', 5));
    customEvent.addParameter(TypedParameter.string('test', 'test'));
    customEvent.addParameter(TypedParameter.bool('test', true));
    customEvent.addParameter(TypedParameter.int('test', 1));
    customEvent.addParameter(TypedParameter.double('test', 1.0));
    Metriqus.trackCustomEvent(customEvent);
    _updateStatus('✅ Custom Event Tracked: button_clicked with 4 parameters');
  }

  // trackLevelStarted Function
  void _trackLevelStarted() {
    _setLoading();
    final levelStartEvent = MetriqusLevelStartedEvent();
    levelStartEvent.levelNumber = 5;
    levelStartEvent.levelName = 'Dragon Valley';
    levelStartEvent.map = 'fantasy_world';

    Metriqus.trackLevelStarted(levelStartEvent);
    _updateStatus('✅ Level Started: Level 5 - Dragon Valley');
  }

  // trackLevelCompleted Function
  void _trackLevelCompleted() {
    _setLoading();
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
    _updateStatus('✅ Level Completed: Level 5 with 15,000 points ⭐⭐⭐');
  }

  // trackItemUsed Function
  void _trackItemUsed() {
    _setLoading();
    final itemUsedEvent = MetriqusItemUsedEvent();
    itemUsedEvent.itemName = 'health_potion';
    itemUsedEvent.amount = 1.0;
    itemUsedEvent.itemType = 'consumable';
    itemUsedEvent.itemRarity = 'common';
    itemUsedEvent.itemClass = 'healing';
    itemUsedEvent.itemCategory = 'potion';
    itemUsedEvent.reason = 'battle';

    Metriqus.trackItemUsed(itemUsedEvent);
    _updateStatus('✅ Item Used: Health Potion (Common) for battle');
  }

  // trackPerformance Function
  void _trackPerformance() {
    _setLoading();
    Metriqus.trackPerformance(60);
    _updateStatus('✅ Performance Tracked: 60 FPS');
  }

  // trackScreenView Function
  void _trackScreenView() {
    _setLoading();
    Metriqus.trackScreenView('MainMenu');
    _updateStatus('✅ Screen View Tracked: MainMenu');
  }

  // trackAdRevenue Function
  void _trackAdRevenue() {
    _setLoading();
    final adRevenue = MetriqusAdRevenue.withRevenue(0.15, 'USD');
    adRevenue.source = 'metriqus';
    adRevenue.adRevenueUnit = 'banner_main_001';
    adRevenue.adRevenueNetwork = 'AdMob';
    adRevenue.adRevenuePlacement = 'main_screen';
    adRevenue.adImpressionsCount = 1;
    Metriqus.trackAdRevenue(adRevenue);
    _updateStatus('✅ Ad Revenue Tracked: \$0.15 USD from AdMob banner');
  }

  // AdMob Ad Revenue Tracking
  void _trackAdmobAdRevenue() {
    _setLoading();
    final admobRevenue = MetriqusAdmobAdRevenue.withRevenue(0.22, 'EUR');
    admobRevenue.adRevenueUnit = 'ca-app-pub-123456789/987654321';
    admobRevenue.adRevenueNetwork = 'AdMob';
    admobRevenue.adRevenuePlacement = 'interstitial';
    admobRevenue.adImpressionsCount = 1;
    Metriqus.trackAdmobAdRevenue(admobRevenue);
    _updateStatus('✅ AdMob Revenue Tracked: €0.22 EUR from interstitial');
  }

  // AppLovin Ad Revenue Tracking
  void _trackApplovinAdRevenue() {
    _setLoading();
    final applovinRevenue = MetriqusApplovinAdRevenue.withRevenue(0.18, 'USD');
    applovinRevenue.adRevenueUnit = 'applovin_rewarded_001';
    applovinRevenue.adRevenueNetwork = 'AppLovin MAX';
    applovinRevenue.adRevenuePlacement = 'level_complete';
    applovinRevenue.adImpressionsCount = 1;
    Metriqus.trackApplovinAdRevenue(applovinRevenue);
    _updateStatus('✅ AppLovin Revenue Tracked: \$0.18 USD from rewarded ad');
  }

  // Campaign Action Events
  void _trackCampaignAction() {
    _setLoading();
    final campaignEvent = MetriqusCampaignActionEvent(
        'summer_2024', 'variant_a', MetriqusCampaignActionType.click);

    Metriqus.trackCampaignAction(campaignEvent);
    _updateStatus('✅ Campaign Action Tracked: Summer 2024 banner clicked');
  }

  // Button Click Tracking
  void _trackButtonClick() {
    _setLoading();
    Metriqus.trackButtonClick('PlayButton');
    _updateStatus('✅ Button Click Tracked: PlayButton');
  }

  // setUserAttribute Function
  void _setUserAttributes() {
    _setLoading();
    // Set multiple user attributes
    Metriqus.setUserAttribute(TypedParameter.int('user_level', 25));
    Metriqus.setUserAttribute(TypedParameter.bool('is_premium', true));
    Metriqus.setUserAttribute(TypedParameter.string('user_type', 'premium'));
    Metriqus.setUserAttribute(TypedParameter.int('total_score', 15000));
    Metriqus.setUserAttribute(
        TypedParameter.string('favorite_character', 'mage'));
    Metriqus.setUserAttribute(TypedParameter.string('guild_id', 'guild_123'));
    _updateStatus('✅ User Attributes Set: 7 attributes (Premium Level 25)');
  }

  // getUserAttributes Function
  void _getUserAttributes() {
    _setLoading();
    final attributes = Metriqus.getUserAttributes();
    final count = attributes?.length ?? 0;
    final hasData = count > 0;
    _updateStatus(
        '✅ User Attributes Retrieved: $count attributes ${hasData ? 'found' : '(none set)'}');
  }

  // removeUserAttribute Function
  void _removeUserAttribute() {
    _setLoading();
    Metriqus.removeUserAttribute('favorite_character');
    _updateStatus('✅ User Attribute Removed: favorite_character deleted');
  }

  // getAdid Function
  void _getAdid() {
    _setLoading();
    final adid = Metriqus.getAdid();
    final shortAdid =
        adid != null ? '${adid.substring(0, 8)}...' : 'Not available';
    _updateStatus('✅ Advertising ID Retrieved: $shortAdid');
  }

  // getDeviceInfo Function
  void _getDeviceInfo() {
    _setLoading();
    final deviceInfo = Metriqus.getDeviceInfo();
    final hasInfo = deviceInfo != null;
    _updateStatus(
        '✅ Device Info Retrieved: ${hasInfo ? 'Device data loaded' : 'No data available'}');
  }

  // getUserId Function
  void _getUniqueUserId() {
    _setLoading();
    final userId = Metriqus.getUserId();
    final shortUserId =
        userId != null ? '${userId.substring(0, 8)}...' : 'Not available';
    _updateStatus('✅ User ID Retrieved: $shortUserId');
  }

  // getSessionId Function
  void _getSessionId() {
    _setLoading();
    final sessionId = Metriqus.getSessionId();
    final shortSessionId =
        sessionId != null ? '${sessionId.substring(0, 8)}...' : 'Not available';
    _updateStatus('✅ Session ID Retrieved: $shortSessionId');
  }

  // getGeolocation Function
  void _getGeolocation() {
    _setLoading();
    final geolocation = Metriqus.getGeolocation();
    final hasLocation = geolocation != null;
    _updateStatus(
        '✅ Geolocation Retrieved: ${hasLocation ? 'Location data loaded' : 'No location data'}');
  }

  // isFirstLaunch Function
  void _getIsFirstLaunch() {
    _setLoading();
    final isFirstLaunch = Metriqus.isFirstLaunch();
    _updateStatus(
        '✅ First Launch Check: ${isFirstLaunch ? 'This is first launch' : 'Not first launch'}');
  }

  // getUserFirstTouchTimestamp Function
  void _getUserFirstTouchTimestamp() {
    _setLoading();
    final timestamp = Metriqus.getUserFirstTouchTimestamp();
    final hasTimestamp = timestamp != null;
    _updateStatus(
        '✅ First Touch Timestamp: ${hasTimestamp ? 'Timestamp retrieved' : 'No timestamp available'}');
  }

  // isInitialized Function
  void _isInitialized() {
    _setLoading();
    final isInitialized = Metriqus.isInitialized;
    print('🔍 SDK Initialization Check: $isInitialized');
    _updateStatus(
        '✅ SDK Initialization Status: ${isInitialized ? 'SDK is initialized' : 'SDK not initialized'}');
  }

  // isTrackingEnabled Function
  void _isTrackingEnabled() {
    _setLoading();
    final isTrackingEnabled = Metriqus.isTrackingEnabled;
    _updateStatus(
        '✅ Tracking Status: ${isTrackingEnabled ? 'Tracking is enabled' : 'Tracking is disabled'}');
  }

  // getMetriqusSettings Function
  void _getMetriqusSettings() {
    _setLoading();
    final settings = Metriqus.getMetriqusSettings();
    final hasSettings = settings != null;
    _updateStatus(
        '✅ SDK Settings Retrieved: ${hasSettings ? 'Settings loaded' : 'No settings available'}');
  }

  // verboseLog Function
  void _debugLog() {
    _setLoading();
    Metriqus.verboseLog("Hello from Metriqus Flutter SDK!");
    _updateStatus('✅ Debug Log Sent: Message logged successfully');
  }

  // updateIOSConversionValue Function
  void _updateIOSConversionValue() {
    _setLoading();
    Metriqus.updateIOSConversionValue(3);
    _updateStatus('✅ iOS Conversion Value Updated: Set to 3 (iOS only)');
  }

  // clearStorage Function
  void _clearStorage() {
    _setLoading();
    Metriqus.clearStorage();
    _updateStatus('✅ Storage Cleared: All cached data removed');
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Function Result:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: _isLoading ? Colors.orange : Colors.green,
                        fontSize: 13,
                      ),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Event Tracking Functions
            _buildSectionTitle('🎯 Event Tracking Functions'),
            _buildButton('trackIAPEvent', _trackIAPEvent),
            _buildButton('trackCustomEvent', _trackCustomEvent),
            _buildButton('trackLevelStarted', _trackLevelStarted),
            _buildButton('trackLevelCompleted', _trackLevelCompleted),
            _buildButton('trackItemUsed', _trackItemUsed),
            _buildButton('trackPerformance', _trackPerformance),
            _buildButton('trackScreenView', _trackScreenView),

            const SizedBox(height: 16),

            // Ad Revenue Tracking Functions
            _buildSectionTitle('💰 Ad Revenue Tracking Functions'),
            _buildButton('trackAdRevenue', _trackAdRevenue),
            _buildButton('AdMob Ad Revenue Tracking', _trackAdmobAdRevenue),
            _buildButton(
                'AppLovin Ad Revenue Tracking', _trackApplovinAdRevenue),

            const SizedBox(height: 16),

            // Campaign and Action Functions
            _buildSectionTitle('📢 Campaign & Action Functions'),
            _buildButton('Campaign Action Events', _trackCampaignAction),
            _buildButton('Button Click Tracking', _trackButtonClick),

            const SizedBox(height: 16),

            // User Attribute Functions
            _buildSectionTitle('👤 User Attribute Functions'),
            _buildButton('setUserAttribute', _setUserAttributes),
            _buildButton('getUserAttributes', _getUserAttributes),
            _buildButton('removeUserAttribute', _removeUserAttribute),

            const SizedBox(height: 16),

            // Device and System Information Functions
            _buildSectionTitle('📱 Device & System Information Functions'),
            _buildButton('getAdid', _getAdid),
            _buildButton('getDeviceInfo', _getDeviceInfo),
            _buildButton('getUserId', _getUniqueUserId),
            _buildButton('getSessionId', _getSessionId),
            _buildButton('getGeolocation', _getGeolocation),
            _buildButton('isFirstLaunch', _getIsFirstLaunch),
            _buildButton(
                'getUserFirstTouchTimestamp', _getUserFirstTouchTimestamp),

            const SizedBox(height: 16),

            // SDK State and Control Functions
            _buildSectionTitle('🔧 SDK State & Control Functions'),
            _buildButton('isInitialized', _isInitialized),
            _buildButton('isTrackingEnabled', _isTrackingEnabled),
            _buildButton('getMetriqusSettings', _getMetriqusSettings),
            _buildButton('verboseLog', _debugLog),
            _buildButton('updateIOSConversionValue', _updateIOSConversionValue),
            _buildButton('clearStorage (Debug)', _clearStorage),

            const SizedBox(height: 32),

            // Footer
            const Center(
              child: Text(
                'Metriqus Flutter SDK Example',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
