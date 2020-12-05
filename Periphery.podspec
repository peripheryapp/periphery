Pod::Spec.new do |spec|
  spec.name             = "Periphery"
  spec.version          = "2.3.0"
  spec.summary          = "Eliminate Unused Swift Code."
  spec.homepage         = "https://github.com/peripheryapp/periphery"
  spec.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.author           = { "Ian Leitch" => "port001@gmail.com" }
  spec.social_media_url = "https://twitter.com/peripheryswift"
  spec.source           = { :http => "#{spec.homepage}/releases/download/#{spec.version}/periphery-v#{spec.version}.zip" }
  spec.preserve_paths   = '*'
end
