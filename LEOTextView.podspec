#
# Be sure to run `pod lib lint LEOTextView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LEOTextView'
  s.version          = '0.7.3'
  s.summary          = 'LEOTextView is a high-performance rich editor based on UITextView and code with TextKit.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "LEOTextView is a very high-performance rich editor. Because it's a subclass of UITextView, not UIWebView. All of code by TextKit framework."

  s.homepage         = 'https://github.com/leonardo-hammer/LEOTextView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tuesleep' => 'tuesleep@gmail.com' }
  s.source           = { :git => 'https://github.com/leonardo-hammer/LEOTextView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }

  s.source_files = 'LEOTextView/Classes/**/*'

  s.resource_bundles = {
      'LEOTextView' => ['LEOTextView/Assets/*']
  }
end
