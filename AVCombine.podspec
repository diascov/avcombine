Pod::Spec.new do |spec|
  spec.name          = 'AVCombine'
  spec.version       = '0.1.1'
  spec.license       = { :type => 'GNU', :file => 'LICENSE.md' }
  spec.homepage      = 'https://github.com/diascov'
  spec.author        = { "Dmitrii Iascov" => "dmitrii.iascov@gmail.com" }
  spec.summary       = 'Video/audio management library'
  spec.source        = { :git => 'https://github.com/diascov/avcombine.git', :tag => "#{spec.version}" }
  spec.source_files  = 'Sources/AVCombine/**/*.swift'
  spec.platform      = :ios, '11.0'
  spec.requires_arc  = true
  spec.swift_version = '5'
end
