Pod::Spec.new do |spec|
  spec.name         = "TinkLinkUI"
  spec.summary      = "Tink Link UI iOS SDK"
  spec.description  = <<-DESC
                    With TinkLink you can connect to banks across Europe and easily access a wide range of financial data.
                    DESC
  spec.version      = "0.14.0"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.authors      = { "Tink AB" => "mobile@tink.se" }
  spec.homepage     = "https://tink.com"
  spec.source       = { :git => "https://github.com/tink-ab/tink-link-ios.git", :tag => spec.version }

  spec.platform     = :ios, "11.0"

  spec.source_files = "Sources/TinkLinkUI/**/*.swift"

  spec.resource_bundles = {
    "Translations" => ["Sources/TinkLinkUI/Translations.bundle/*.lproj"],
    "Assets" => ["Sources/TinkLinkUI/Assets.bundle/*.xcassets"]
  }

  spec.test_spec 'TinkLinkUITests' do |test_spec|
    test_spec.source_files = "Tests/TinkLinkUITests/**/*.swift"
  end

  spec.dependency "TinkLink", "0.14.0"
  spec.dependency "Down", "~> 0.9"
  spec.dependency "Kingfisher", "~> 5.13"
end
