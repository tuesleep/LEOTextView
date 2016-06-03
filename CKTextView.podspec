#
# Be sure to run `pod lib lint CKTextView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "CKTextView"
  s.version          = "0.1.1"
  s.summary          = "A TextView with some capacity."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "Want to build a UITextView that have List feature(Rich Text Editor), just look like 'Notes' app on the iPhone with iOS 9."

  s.homepage         = "https://github.com/chanricle/CKTextView"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Chanricle King" => "chanricle@icloud.com" }
  s.source           = { :git => "https://github.com/chanricle/CKTextView.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'CKTextView/Classes/**/*'

  s.resource_bundles = {
    'CKTextView' => ['CKTextView/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
