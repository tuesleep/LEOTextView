#
# Be sure to run `pod lib lint NCKTextView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NCKTextView'
  s.version          = '0.1.0'
  s.summary          = 'NCKTextView is a simple extension from UITextView.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips

  s.description      = "Want to build a UITextView that have List feature(Rich Text Editor), just look like 'Notes' app on the iPhone with iOS 9."

  s.homepage         = 'https://github.com/chanricle/NCKTextView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Chanricle King' => 'chanricle@icloud.com' }
  s.source           = { :git => 'https://github.com/chanricle/NCKTextView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'NCKTextView/Classes/**/*'
  
  s.resource_bundles = {
    'NCKTextView' => ['NCKTextView/Assets/*']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
