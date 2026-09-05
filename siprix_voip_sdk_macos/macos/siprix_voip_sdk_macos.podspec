#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint siprix_voip_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'siprix_voip_sdk_macos'
  s.version          = '1.1.0'
  s.summary          = 'Siprix VoIP SDK plugin for embedding voice and video communication.'
  s.description      = <<-DESC
Siprix VoIP SDK plugin for embedding voice and video communication (based on SIP/RTP protocols) into Flutter applications.
                       DESC
  s.homepage         = 'https://siprix-voip.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Siprix' => 'developers@siprix-voip.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'siprix_voip_sdk_macos/Sources/siprix_voip_sdk_macos/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  
  # telling CocoaPods not to remove framework
  s.preserve_paths = 'siprix_voip_sdk_macos/**/*'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework siprix -framework siprixMedia' }  # including siprix framework
  s.vendored_frameworks = 'siprix_voip_sdk_macos/Frameworks/siprix.xcframework', 'siprix_voip_sdk_macos/Frameworks/siprixMedia.xcframework'
  s.prepare_command = <<-CMD
   [ -d siprix_voip_sdk_macos/Frameworks/siprix.xcframework ] || unzip siprix_voip_sdk_macos/Frameworks/siprix.xcframework.zip -d siprix_voip_sdk_macos/Frameworks/
   [ -d siprix_voip_sdk_macos/Frameworks/siprixMedia.xcframework ] || unzip siprix_voip_sdk_macos/Frameworks/siprixMedia.xcframework.zip -d siprix_voip_sdk_macos/Frameworks/
  CMD
end
