#
# Be sure to run `pod lib lint GXAudioPlay.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GXAudioPlay'
  s.version          = '0.8.4'
  s.summary          = 'change：播放音频循环问题'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/gaoguangxiao'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '小修' => 'gaoguangxiao125@sina.com' }
  s.source           = { :git => 'https://github.com/gaoguangxiao/GXAudioPlay.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.swift_version = '5.0'
  
  s.ios.deployment_target = '12.0'

  s.source_files = 'GXAudioPlay/Classes/**/*'
  
  # s.resource_bundles = {
  #   'GXAudioPlay' => ['GXAudioPlay/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'RxCocoa'
  s.dependency 'GGXSwiftExtension'
  
end
