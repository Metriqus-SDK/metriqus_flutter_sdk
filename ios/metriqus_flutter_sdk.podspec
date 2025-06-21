Pod::Spec.new do |s|
  s.name             = 'metriqus_flutter_sdk'
  s.version          = '1.0.0'
  s.summary          = 'Metriqus Flutter SDK'
  s.description      = 'Metriqus Flutter SDK for analytics and tracking'
  s.homepage         = 'https://metriqus.com'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Metriqus' => 'support@metriqus.com' }
  s.source           = { :git => 'https://github.com/metriqus/flutter-sdk.git', :tag => s.version.to_s }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  
  # Add required frameworks with version guards
  s.frameworks = 'Metal', 'MetalKit', 'AdSupport', 'StoreKit'
  
  # Conditional frameworks based on iOS version
  s.weak_frameworks = 'AppTrackingTransparency', 'AdServices'
end 