![Platform](https://img.shields.io/badge/platform-iOS-orange.svg)
![Languages](https://img.shields.io/badge/languages-swift-orange.svg)
![CocoaPods](https://img.shields.io/cocoapods/v/TinkLink.svg)
![Swift Package Manager](https://img.shields.io/badge/SPM-supported-DE5C43.svg)
![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)

# Tink Link iOS

![Tink Link](https://images.ctfassets.net/tmqu5vj33f7w/4YdZUwzfmUjvNKO0tHvKVj/ec14ed052771e3ef10156c29ccf004f0/overview.png)

## Prerequisites

1. Follow the [getting started guide](https://docs.tink.com/resources/getting-started/set-up-your-account) to retrieve your `client_id`.
2. Add a deep link to your app with scheme and host (`yourapp://host`) to the [list of redirect URIs under your app's settings](https://console.tink.com/overview).

## Requirements

- iOS 11.0
- Xcode 11.4

## Installation
There are two targets in the package Tink Link.
- `TinkLink` is a framework for aggregating bank credentials, you can build your own UI, suitable for enterprise plan customers that are aggregating with permanent users.
- `TinkLinkUI` is a framework with a predefined flow, a single entrypoint and configurable UI style, you can use this framework to bootstrap your application fast.

Read more about permanent users [here](https://docs.tink.com/resources/tutorials/permanent-users).

#### Using Swift Package Manager

Follow these instructions to [link a target to a package product](https://help.apple.com/xcode/mac/current/#/devb83d64851) and enter this URL `https://github.com/tink-ab/tink-link-ios` when asked for a package repository.

When finished, you should be able to `import TinkLink` and  `import TinkLinkUI` within your project.

#### Using CocoaPods
Refer to their [guide](https://guides.cocoapods.org/using/using-cocoapods.html) for usage and installation instructions.

1. Add TinkLink and TinkLinkUI to your Podfile.
    ```
    pod "TinkLink"
    pod "TinkLinkUI"
    ```

2. Run `pod install` in your project directory.

3. Open your `.xcworkspace` file to see the project in Xcode.

#### Manual installation

1. Download and unzip the `TinkCore.xcframework.zip` from the [latest Tink Core release](https://github.com/tink-ab/tink-core-ios/releases/latest).
2. Drag the `TinkCore.xcframework` into the  _Frameworks, Libraries, and Embedded Content_ section on your application targets’ _General_ tab. 
3. Download and unzip the `Source code.zip` from the [latest Tink Link release](https://github.com/tink-ab/tink-link-ios/releases/latest).
4. Add a new iOS Framework target with the name `TinkLink` to your app.
5. Drag all files except Info.plist from `Sources/TinkLink` folder into the new target.
6. Add a new iOS Framework target with the name `TinkLinkUI` to your app.
7. Drag all files except Info.plist from `Sources/TinkLinkUI` folder into the new target.
8. [Install Down](https://github.com/johnxnguyen/Down#or-manually-install)
9. Add Down to the TinkLinkUI target.

When finished, you should be able to `import TinkLink`  and `import TinkLinkUI` within your project.

## How to display Tink Link

1. Import the SDK and set up a configuration with your client ID and redirect URI.
    ```swift
    import TinkLink
    import TinkLinkUI
    
    let configuration = TinkLinkConfiguration(clientID: <#String#>, appURI: <#URL#>)
    ```

2. Define the list of [scopes](https://docs.tink.com/api/#introduction-authentication-authorization-scopes) based on the type of data you want to fetch. For example, to retrieve accounts and transactions, define these scopes:
    ```swift
    let scopes: [Scope] = [
        .accounts(.read), 
        .transactions(.read)
    ]
    ```

3. Create a `TinkLinkViewController` with your configuration, market, and list of scopes to use.
    ```swift
    let tinkLinkViewController = TinkLinkViewController(configuration: configuration, market: "SE", scopes: scopes) { result in 
        // Handle result
    }
    ```
    
4. Tink Link is designed to be presented modally. Present the view controller by calling `present(_:animated:)` on the presenting view controller. 
    ```swift
    present(tinkLinkViewController, animated: true)
    ```

5. After the user has completed or cancelled the aggregation flow, the completion handler will be called with a result. A successful authentication will return a result that contains an authorization code that you can [exchange for an access token](https://docs.tink.com/resources/getting-started/retrieve-access-token). If something went wrong the result will contain an error.
    ```swift
    do {
        let authorizationCode = try result.get()
        // Exchange the authorization code for a access token.
    } catch {
        // Handle any errors
    }
    ```

## Redirect handling

You will need to add a custom URL scheme or support universal links to handle redirects from a third party authentication flow back into your app.

Follow the instructions in one of these links to learn how to set this up:

- [Defining a Custom URL Scheme for Your App](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app)
- [Allowing Apps and Websites to Link to Your Content](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content)

## Samples
This example shows how to build a complete aggregation flow using TinkLink.
- [Tink Link](Samples/TinkLinkExample)

## Documentation
For more detailed usage and full documentation, please refer to our Tink Link for iOS guide.
- [Tink Link for iOS](https://docs.tink.com/resources/tink-link-ios)

## [Tink](https://tink.com)
Tink was founded in 2012 with the aim of changing the banking industry for the better. We have built Europe’s most robust open banking platform – with the broadest, deepest connectivity and powerful services that create value out of the financial data.

## Support
👋 We are continuously working on improving the developer experience of our API offering. [Contact us](https://support.tink.com) for support, questions or suggestions.
