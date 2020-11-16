# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'

target 'EmojiArt (iOS)' do
  # Pods for Memorize
  pod 'SwiftLint', '~> 0.41.0'
  pod 'SwiftGen', '~> 6.4.0'
  pod 'BartyCrouch', '~> 4.3.1'
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Work around for https://github.com/firebase/firebase-ios-sdk/issues/6533
  # from https://github.com/CocoaPods/CocoaPods/issues/9884#issuecomment-696228403
  # post_install do |pi|
  #    t = pi.pods_project.targets.find { |t| t.name == 'EmojiArt (iOS)' }
  #    t.build_configurations.each do |bc|
  #      bc.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
  #    end
  # end
end
