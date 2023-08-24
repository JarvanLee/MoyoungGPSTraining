#
# Be sure to run `pod lib lint MoyoungGPSTraining.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MoyoungGPSTraining'
  s.version          = '0.1.0'
  s.summary          = 'A short description of MoyoungGPSTraining.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/李然/MoyoungGPSTraining'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '李然' => 'zoro@moyoung.com' }
  s.source           = { :git => 'https://github.com/李然/MoyoungGPSTraining.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'

  s.source_files = 'MoyoungGPSTraining/Classes/**/*'

  s.frameworks = 'CoreLocation'
end
