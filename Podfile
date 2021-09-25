platform :ios, '11.0'

use_frameworks! :linkage => :static

target 'MobileCelestia' do
  pod 'AppCenter/Analytics'
  pod 'AppCenter/Crashes'
  pod 'SDWebImage', '~> 5.0'
  pod 'ZIPFoundation', '~> 0.9'

  pod "MWRequest", :git => "https://github.com/levinli303/mwrequest.git", :tag => "0.2.4"
  pod "AsyncGL", :git => "https://github.com/levinli303/AsyncGL.git", :tag => "0.0.7"
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
            config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
            config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
            config.build_settings['SUPPORTS_MACCATALYST'] = "YES"
        end
    end
end
