platform :ios, '13.1'

use_frameworks! :linkage => :static

asyncgl_version_tag = "0.1.17"
mwrequest_version_tag = "1.0.1"
zipfoundation_version_tag = "0.9.18"
appcenter_version = "~> 5.0.4"

target 'MobileCelestia' do
  pod 'AppCenter/Analytics', appcenter_version
  pod 'AppCenter/Crashes', appcenter_version
  pod 'ZIPFoundation', :git => "https://github.com/weichsel/ZIPFoundation.git", :tag => zipfoundation_version_tag

  pod "MWRequest", :git => "https://github.com/levinli303/mwrequest.git", :tag => mwrequest_version_tag
  pod "AsyncGL/OpenGL", :git => "https://github.com/levinli303/AsyncGL.git", :tag => asyncgl_version_tag
end

target 'CelestiaUI' do
  pod 'ZIPFoundation', :git => "https://github.com/weichsel/ZIPFoundation.git", :tag => zipfoundation_version_tag

  pod "MWRequest", :git => "https://github.com/levinli303/mwrequest.git", :tag => mwrequest_version_tag
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
            config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
            config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
            config.build_settings['SUPPORTS_MACCATALYST'] = "YES"
            config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = "10.15"
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = "13.1"
        end
    end
end
