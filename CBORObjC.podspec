Pod::Spec.new do |spec|
  spec.name         = "CBORObjC"
  spec.version      = "1.0.2"
  spec.summary      = "A CBOR implementation in Objective-C"
  spec.description  = <<-DESC
  A CBOR Concise Binary Object Representation decoder and encoder in Objective-C.
                   DESC

  spec.homepage     = "https://github.com/DanielHusx/CBOR"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "danielxing" => "danielxing@163.com" }
 
  spec.platform     = :ios, "10.0"

  spec.ios.deployment_target = "10.0"
  spec.osx.deployment_target = "10.13"

  spec.source       = { :git => "https://github.com/DanielHusx/CBOR.git", :tag => "#{spec.version}" }

  spec.source_files  = "CBOR/CBOR.h", "CBOR/**/*.{h,m}"
  spec.public_header_files = "CBOR/CBOR.h", "CBOR/Public/*.h"
  spec.private_header_files = 'CBOR/CBORObject/*.h', 'CBOR/Decode/*.h', 'CBOR/Encode/*.h', 'CBOR/Model/*.h'
  
  
  spec.requires_arc = true
end
