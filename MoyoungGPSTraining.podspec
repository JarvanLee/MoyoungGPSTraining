#
# Be sure to run `pod lib lint MoyoungGPSTraining.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MoyoungGPSTraining'
  s.version          = '0.1.5'
  s.summary          = 'A short description of MoyoungGPSTraining.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://codeup.aliyun.com/5f53a99c6207a1a8b17fadc3/MoyoungGPSTraining'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'JarvanLee' => 'zoro@moyoung.com' }
  s.source           = { :git => 'https://codeup.aliyun.com/5f53a99c6207a1a8b17fadc3/MoyoungGPSTraining.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'

  s.source_files = 'MoyoungGPSTraining/Classes/**/*'

  s.frameworks = 'CoreLocation'
  s.dependency 'TQLocationConverter'
  
end
