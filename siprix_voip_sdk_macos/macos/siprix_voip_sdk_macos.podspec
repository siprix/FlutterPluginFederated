#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint siprix_voip_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'siprix_voip_sdk_macos'
  s.version          = '1.0.19'
  s.summary          = 'Siprix VoIP SDK plugin for embedding voice and video communication.'
  s.description      = <<-DESC
Siprix VoIP SDK plugin for embedding voice and video communication (based on SIP/RTP protocols) into Flutter applications.
                       DESC
  s.homepage         = 'https://siprix-voip.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Siprix' => 'developers@siprix-voip.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  
  # telling CocoaPods not to remove framework
  s.preserve_paths = 'siprix.framework', 'siprixMedia.framework'  # telling linker to include siprix framework
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework siprix -framework siprixMedia' }  # including siprix framework
  s.vendored_frameworks = 'siprix.framework', 'siprixMedia.framework'  # including native framework
  #s.frameworks = 'AVFoundation', 'Accelerate', 'OpenCL'  # including C++ library
  
end
