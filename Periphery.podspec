Pod::Spec.new do |spec|
  spec.name             = "Periphery"
  spec.version          = "2.14.1"
  spec.summary          = "Eliminate Unused Swift Code."
  spec.homepage         = "https://github.com/peripheryapp/periphery"
  spec.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.author           = { "Ian Leitch" => "ian@leitch.io" }
  spec.source           = { :http => "#{spec.homepage}/releases/download/#{spec.version}/periphery-#{spec.version}.zip" }
  spec.preserve_paths   = '*'
end
