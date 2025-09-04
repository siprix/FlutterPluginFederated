#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint siprix_voip_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'siprix_voip_sdk_ios'
  s.version          = '1.0.23'
  s.summary          = 'Siprix VoIP SDK plugin for embedding voice and video communication.'
  s.description      = <<-DESC
Siprix VoIP SDK plugin for embedding voice and video communication (based on SIP/RTP protocols) into Flutter applications.
                       DESC
  s.homepage         = 'https://siprix-voip.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Siprix' => 'developers@siprix-voip.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  
  # telling CocoaPods not to remove framework
  s.preserve_paths = 'siprix.xcframework', 'siprixMedia.xcframework'  # telling linker to include siprix framework
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework siprix -framework siprixMedia' }  # including siprix framework
  s.vendored_frameworks = 'siprix.xcframework', 'siprixMedia.xcframework'  # including native framework
  s.frameworks = 'siprix', 'siprixMedia'
  s.library = 'c++'
end
