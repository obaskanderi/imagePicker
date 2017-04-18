#
# Be sure to run `pod lib lint ImagePicker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ImagePicker'
  s.version          = '1.0.0'
  s.summary          = 'Photo and Video picker for iOS'
  s.homepage         = 'https://github.com/obaskanderi/ImagePicker'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'obaskanderi' => 'obaskanderi@topologyinc.com' }
  s.source           = { :git => 'https://github.com/obaskanderi/ImagePicker.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.source_files = 'ImagePicker/Source/**/*'
  s.resource_bundles = {
     'ImagePicker' => ['ImagePicker/Resources/*']
  }
  s.frameworks = 'Photos'
  s.dependency 'ABVideoRangeSlider'
  s.dependency 'TGPControls', '~> 4.0.0'
end
