import Foundation
#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

/// A task that handles opening third party apps.
///
/// This task is provided when an `AddCredentialsTask`'s status changes to `awaitingThirdPartyAppAuthentication`.
///
/// When a credentials' status is `awaitingThirdPartyAppAuthentication` the user needs to authenticate in a third party app to finish adding the credentials.
///
/// When you receive a `awaitingThirdPartyAppAuthentication` status, you should let the `ThirdPartyAppAuthenticationTask` object to handle the updates like this:
///
/// ```swift
/// thirdPartyAppAuthenticationTask.handle()
/// ```
/// If the third party authentication couldn't be handled by the `ThirdPartyAppAuthenticationTask`, you need to handle the `AddCredentialsTask` completion result and check for a `ThirdPartyAppAuthenticationTask.Error`. This error can tell you if the user needs to download the thirdparty authentication app.
///
/// Here's how you can ask the user to download the third party app via an alert:
///
/// ```swift
/// let alertController = UIAlertController(title: thirdPartyAppAuthentication.downloadTitle, message: thirdPartyAppAuthentication.downloadMessage, preferredStyle: .alert)
///
/// if let appStoreURL = thirdPartyAppAuthentication.appStoreURL, UIApplication.shared.canOpenURL(appStoreURL) {
///     let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
///     let downloadAction = UIAlertAction(title: "Download", style: .default, handler: { _ in
///         UIApplication.shared.open(appStoreURL)
///     })
///     alertController.addAction(cancelAction)
///     alertController.addAction(downloadAction)
/// } else {
///     let okAction = UIAlertAction(title: "OK", style: .default)
///     alertController.addAction(okAction)
/// }
///
/// present(alertController, animated: true)
/// ```
///
/// After the redirect to the third party app, some providers requires additional information to be sent to Tink after the user authenticates with the third party app for the credential to be added successfully. This information is passed to your app via the redirect URI. Use the open method in your `UIApplicationDelegate` to let TinkLink send the information to Tink if needed.
/// ```swift
/// func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
///     return TinkLink.shared.open(url)
/// }
/// ```
///
/// - Note: If the app couldn't be opened you need to handle the `AddCredentialsTask` completion result and check for a `ThirdPartyAppAuthenticationTask.Error`.
/// This error can tell you if the user needs to download the app.
public class ThirdPartyAppAuthenticationTask: Identifiable {
    /// Error associated with the `ThirdPartyAppAuthenticationTask`.
    public typealias Error = TinkLinkError

    /// Indicates a user action required for the third party app authentication task to succeed.
    public enum Status {
        #if os(iOS)
            /// Indicates that a QR image needs to be scanned by the user to authenticate with the third party app.
            case qrImage(UIImage)
        #elseif os(macOS)
            /// Indicates that a QR image needs to be scanned by the user to authenticate with the third party app.
            case qrImage(NSImage)
        #endif
        /// Indicates that the task will wait for the user to authenticate with the third party app on another device.
        case awaitAuthenticationOnAnotherDevice
    }

    /// Information about how to open or download the third party application app.
    public private(set) var thirdPartyAppAuthentication: Credentials.ThirdPartyAppAuthentication

    /// Indicates whether the task should fail if a third party app could not be opened for authentication.
    public private(set) var shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Bool
    private let appUri: URL
    internal let completionHandler: (Result<Void, Swift.Error>) -> Void
    private var hasBankIDQRCode: Bool {
        // TODO: Double check the logic.
        // Not sure about this part, but maybe because of grpc, the supplemental info is always empty for bankid credential kind, so has to check the deeplink URL instead.
        // Also maybe this is not even the case, for the bank that does not have autostart token, seems it will just trigger the bankID on another device with personal number
        if case .mobileBankID = credentials.kind {
            return thirdPartyAppAuthentication.hasAutoStartToken
        }
        return false
    }

    private let credentials: Credentials
    private let credentialsService: CredentialsService
    private var callRetryCancellable: RetryCancellable?

    init(credentials: Credentials,
         thirdPartyAppAuthentication: Credentials.ThirdPartyAppAuthentication,
         appUri: URL,
         credentialsService: CredentialsService,
         shouldFailOnThirdPartyAppAuthenticationDownloadRequired: Bool,
         completionHandler: @escaping (Result<Void, Swift.Error>) -> Void)
    {
        self.credentials = credentials
        self.credentialsService = credentialsService
        self.appUri = appUri
        self.thirdPartyAppAuthentication = thirdPartyAppAuthentication
        self.shouldFailOnThirdPartyAppAuthenticationDownloadRequired = shouldFailOnThirdPartyAppAuthenticationDownloadRequired
        self.completionHandler = completionHandler
    }

    // MARK: - Opening an App

    #if os(iOS)
        func openThirdPartyApp<URLResourceOpener: URLResourceOpening>(with urlResourceOpener: URLResourceOpener, completion: @escaping (Result<Void, Swift.Error>) -> Void) {
            guard let url = thirdPartyAppAuthentication.deepLinkURL else {
                let reason = Error.ThirdPartyAppAuthenticationFailureReason(code: .deeplinkURLNotFound)
                let error = Error.thirdPartyAppAuthenticationFailed(reason: reason)
                completion(.failure(error))
                return
            }

            let deepLinkURL = sanitizeDeeplink(url, redirectUri: appUri)
            DispatchQueue.main.async {
                urlResourceOpener.open(deepLinkURL, options: [urlResourceOpener.universalLinksOnlyOptionKey: NSNumber(value: true)]) { didOpenUniversalLink in
                    if didOpenUniversalLink {
                        completion(.success)
                    } else {
                        // Don't open bankID universal link in Browser
                        if case .mobileBankID = self.credentials.kind, deepLinkURL.scheme != "bankid" {
                            let downloadRequiredReason = Error.ThirdPartyAppAuthenticationFailureReason.downloadRequired(
                                title: self.thirdPartyAppAuthentication.downloadTitle,
                                message: self.thirdPartyAppAuthentication.downloadMessage,
                                appStoreURL: self.thirdPartyAppAuthentication.appStoreURL
                            )
                            let downloadRequiredError = Error.thirdPartyAppAuthenticationFailed(reason: downloadRequiredReason)

                            completion(.failure(downloadRequiredError))
                        } else {
                            urlResourceOpener.open(deepLinkURL, options: [:], completionHandler: { didOpen in
                                if didOpen {
                                    completion(.success)
                                } else {
                                    let downloadRequiredReason = Error.ThirdPartyAppAuthenticationFailureReason.downloadRequired(
                                        title: self.thirdPartyAppAuthentication.downloadTitle,
                                        message: self.thirdPartyAppAuthentication.downloadMessage,
                                        appStoreURL: self.thirdPartyAppAuthentication.appStoreURL
                                    )
                                    let downloadRequiredError = Error.thirdPartyAppAuthenticationFailed(reason: downloadRequiredReason)

                                    completion(.failure(downloadRequiredError))
                                }
                            })
                        }
                    }
                }
            }
        }

        /// Will try to open the third party app. If it fails then the add credentials task will be aborted.
        public func handle() {
            openThirdPartyApp(with: UIApplication.shared) { [weak self] result in
                self?.completionHandler(result)
            }
        }
    #endif

    /// Will try to open the third party app.
    /// - Parameter statusHandler: A closure that handles statuses that require actions.
    /// - Parameter status: The specific status that require an action.
    public func handle(statusHandler: @escaping (_ status: Status) -> Void) {
        #if os(iOS)
            if shouldFailOnThirdPartyAppAuthenticationDownloadRequired {
                openThirdPartyApp(with: UIApplication.shared) { [weak self] result in
                    self?.completionHandler(result)
                }
                return
            }

            openThirdPartyApp(with: UIApplication.shared) { [weak self] result in
                guard let self = self else { return }
                do {
                    try result.get()
                    self.completionHandler(.success)
                } catch {
                    if self.hasBankIDQRCode {
                        self.qr { result in
                            do {
                                let qrImage = try result.get()
                                statusHandler(.qrImage(qrImage))
                                self.completionHandler(.success)
                            } catch {
                                self.completionHandler(.failure(error))
                            }
                        }
                    } else if self.credentials.kind == .mobileBankID {
                        statusHandler(.awaitAuthenticationOnAnotherDevice)
                        self.completionHandler(.success)
                    } else {
                        self.completionHandler(.failure(error))
                    }
                }
            }
        #elseif os(macOS)
            if hasBankIDQRCode {
                qr { [weak self, credentialsKind = credentials.kind] result in
                    do {
                        let qrImage = try result.get()
                        statusHandler(.qrImage(qrImage))
                        self?.completionHandler(.success)
                    } catch Error.doesNotSupportAuthenticatingOnAnotherDevice {
                        if credentialsKind == .mobileBankID {
                            statusHandler(.awaitAuthenticationOnAnotherDevice)
                            self?.completionHandler(.success)
                        } else {
                            self?.completionHandler(.failure(Error.doesNotSupportAuthenticatingOnAnotherDevice))
                        }
                    } catch {
                        self?.completionHandler(.failure(error))
                    }
                }
            } else {
                completionHandler(.failure(Error.doesNotSupportAuthenticatingOnAnotherDevice))
            }
        #endif
    }

    #if os(iOS)
        typealias Image = UIImage
    #elseif os(macOS)
        typealias Image = NSImage
    #endif

    private func qr(completion: @escaping (Result<Image, Swift.Error>) -> Void) {
        callRetryCancellable = credentialsService.qrCode(id: credentials.id) { [weak self] result in
            do {
                let qrData = try result.get()
                guard let qrImage = Image(data: qrData) else {
                    let reason = Error.ThirdPartyAppAuthenticationFailureReason(code: .decodingQRCodeImageFailed)
                    throw Error.thirdPartyAppAuthenticationFailed(reason: reason)
                }
                completion(.success(qrImage))
            } catch ServiceError.cancelled {
                completion(.failure(TinkLinkError(code: .cancelled)))
            } catch {
                completion(.failure(error))
            }
            self?.callRetryCancellable = nil
        }
    }

    // MARK: - Controlling the Task

    /// Tells the task to stop waiting for third party app authentication.
    ///
    /// Call this method if you have a UI that lets the user choose to open the third party app and the user cancels.
    public func cancel() {
        if let cancellable = callRetryCancellable {
            cancellable.cancel()
            callRetryCancellable = nil
        } else {
            completionHandler(.failure(TinkLinkError(code: .cancelled)))
        }
    }

    private func sanitizeDeeplink(_ url: URL, redirectUri: URL) -> URL {
        // Only replace bankID redirect with tink scheme
        let tinkBankIDRedirect = "tink://bankid"
        let bankIDredirect = redirectUri.appendingPathComponent("bankid").absoluteString
        let updatedUrl = url.absoluteString.replacingOccurrences(of: tinkBankIDRedirect, with: bankIDredirect)
        return URL(string: updatedUrl)!
    }
}
