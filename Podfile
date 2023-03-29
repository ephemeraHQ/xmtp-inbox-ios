# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'

target 'xmtp-inbox-ios' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for xmtp-inbox-ios
	pod 'GRDB.swift/SQLCipher'
	pod 'SQLCipher', '~> 4.0'

	target 'NotificationExtension' do
		inherit! :search_paths
	end

  target 'xmtp-inbox-iosTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'xmtp-inbox-iosUITests' do
    # Pods for testing
  end
end
#
#post_install do |installer|
#	installer.generated_projects.each do |project|
#		project.targets.each do |target|
#			target.build_configurations.each do |config|
#				config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
#			end
#		end
#	end
#end
