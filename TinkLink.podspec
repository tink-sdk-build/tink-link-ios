Pod::Spec.new do |spec|
  spec.name         = "TinkLink"
  spec.summary      = "Tink Link iOS SDK"
  spec.description  = <<-DESC
                    With TinkLink you can connect to banks across Europe and easily access a wide range of financial data.
                    DESC
  spec.version      = "0.18.0"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.authors      = { "Tink AB" => "mobile@tink.se" }
  spec.homepage     = "https://tink.com"
  spec.source       = { :git => "https://github.com/tink-ab/tink-link-ios.git", :tag => spec.version }

  spec.platform     = :ios, "11.0"

  spec.source_files = "Sources/TinkLink/**/*.swift"

  spec.swift_version = ["5.1", "5.2", "5.3"]

  spec.test_spec 'TinkLinkTests' do |test_spec|
      test_spec.source_files = "Tests/TinkLinkTests/**/*.swift"
  end

  spec.dependency "TinkCore", "~> 0.6.0"

  spec.static_framework = true
end
