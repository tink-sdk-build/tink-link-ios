import UIKit
import TinkLink

final class AddCredentialsSession {
    weak var presenter: CredentialsCoordinatorPresenting?

    private let providerController: ProviderController
    private let credentialsController: CredentialsController
    private let authorizationController: AuthorizationController
    private var addCredentialsMode: CredentialsCoordinator.AddCredentialsMode?
    private let tinkLinkTracker: TinkLinkTracker
    private let notificationCenter: NotificationCenter

    private var task: Cancellable?
    private var supplementInfoTask: SupplementInformationTask?

    private weak var qrImageViewController: QRImageViewController?

    private var authorizationCode: AuthorizationCode?
    private var didCallAuthorize = false
    private var shouldAuthorize: Bool {
        if case .anonymous = addCredentialsMode {
            return true
        } else {
            return false
        }
    }

    private var isPresenterShowingStatusScreen = true
    private var authorizationGroup = DispatchGroup()

    private var providerName: Provider.Name?

    private var addCredentialsTaskStatus: AddCredentialsTask.Status? {
        didSet {
            switch (oldValue, addCredentialsTaskStatus) {
            case (.updating, _):
                break
            case (_, .updating):
                // Only tracking application event when the credentials status changed to updating for the first time
                tinkLinkTracker.track(applicationEvent: .authenticationSuccessful)
            default: break
            }
        }
    }

    private var updateCredentialsTaskStatus: UpdateCredentialsTask.Status? {
        didSet {
            switch (oldValue, updateCredentialsTaskStatus) {
            case (.updating, _):
                break
            case (_, .updating):
                // Only tracking application event when the credentials status changed to updating for the first time
                tinkLinkTracker.track(applicationEvent: .authenticationSuccessful)
            default: break
            }
        }
    }

    init(providerController: ProviderController, credentialsController: CredentialsController, authorizationController: AuthorizationController, tinkLinkTracker: TinkLinkTracker, presenter: CredentialsCoordinatorPresenting?) {
        self.presenter = presenter
        self.providerController = providerController
        self.credentialsController = credentialsController
        self.authorizationController = authorizationController
        self.tinkLinkTracker = tinkLinkTracker
        self.notificationCenter = NotificationCenter.default
    }

    deinit {
        task?.cancel()
    }

    func addCredential(provider: Provider, form: Form, mode: CredentialsCoordinator.AddCredentialsMode, onCompletion: @escaping ((Result<(Credentials, AuthorizationCode?), Error>) -> Void)) {
        let refreshableItems: RefreshableItems
        switch mode {
        case .anonymous(scopes: let scopes):
            refreshableItems = RefreshableItems.makeRefreshableItems(scopes: scopes, provider: provider)
        case .user(let items):
            refreshableItems = items
        }

        task = credentialsController.addCredentials(
            provider,
            form: form,
            refreshableItems: refreshableItems,
            progressHandler: { [weak self] status in
                DispatchQueue.main.async {
                    self?.handleAddCredentialStatus(status) {
                        [weak self] error in
                            DispatchQueue.main.async {
                                // FIXME: This triggers two onCompletion calls.
                                onCompletion(.failure(error))
                                self?.task?.cancel()
                                self?.task = nil
                            }
                    }
                }
            }, authenticationHandler: { [weak self] authentication in
                DispatchQueue.main.async {
                    self?.handleAuthenticationTask(authentication: authentication)
                }
            },
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleCompletion(result, onCompletion: onCompletion)
                }
            }
        )
        isPresenterShowingStatusScreen = false
        providerName = provider.name
        addCredentialsMode = mode

        DispatchQueue.main.async {
            self.showUpdating(status: Strings.CredentialsStatus.authorizing)
        }
    }

    func updateCredentials(credentials: Credentials, form: Form, completion: @escaping (Result<Credentials, Error>) -> Void) {
        task = credentialsController.update(credentials, form: form, shouldFailOnThirdPartyAppAuthenticationDownloadRequired: false, progressHandler: { [weak self] status in
            DispatchQueue.main.async {
                self?.handleUpdateTaskStatus(status)
            }
        }, authenticationHandler: { [weak self] authentication in
            DispatchQueue.main.async {
                self?.handleAuthenticationTask(authentication: authentication)
            }
        }, completion: { [weak self] result in
            DispatchQueue.main.async {
                self?.handleCompletion(result) { result in
                    completion(result.map { $0.0 })
                }
            }
        })

        isPresenterShowingStatusScreen = false
        providerName = credentials.providerName

        DispatchQueue.main.async {
            self.showUpdating(status: Strings.CredentialsStatus.authorizing)
        }
    }

    func refreshCredentials(credentials: Credentials, forceAuthenticate: Bool, refreshableItems: RefreshableItems, completion: @escaping (Result<Credentials, Error>) -> Void) {
        var authenticate: Bool {
            if let sessionExpiryDate = credentials.sessionExpiryDate, sessionExpiryDate <= Date() {
                return true
            }
            return forceAuthenticate
        }

        task = credentialsController.refresh(credentials, authenticate: authenticate, refreshableItems: refreshableItems, shouldFailOnThirdPartyAppAuthenticationDownloadRequired: false, progressHandler: { [weak self] status in
            DispatchQueue.main.async {
                self?.handleUpdateTaskStatus(status)
            }
        }, authenticationHandler: { [weak self] authentication in
            DispatchQueue.main.async {
                self?.handleAuthenticationTask(authentication: authentication)
            }
        }, completion: { [weak self] result in
            DispatchQueue.main.async {
                self?.handleCompletion(result) { result in
                    completion(result.map { $0.0 })
                }
            }
        })

        providerName = credentials.providerName

        DispatchQueue.main.async {
            self.showUpdating(status: Strings.CredentialsStatus.authorizing)
        }
    }

    func authenticateCredentials(credentials: Credentials, completion: @escaping (Result<Credentials, Error>) -> Void) {
        task = credentialsController.authenticate(credentials, shouldFailOnThirdPartyAppAuthenticationDownloadRequired: false, progressHandler: { [weak self] status in
            DispatchQueue.main.async {
                self?.handleUpdateTaskStatus(status)
            }
        }, authenticationHandler: { [weak self] authentication in
            DispatchQueue.main.async {
                self?.handleAuthenticationTask(authentication: authentication)
            }
        }, completion: { [weak self] result in
            DispatchQueue.main.async {
                self?.handleCompletion(result) { result in
                    completion(result.map { $0.0 })
                }
            }
        })

        providerName = credentials.providerName

        DispatchQueue.main.async {
            self.showUpdating(status: Strings.CredentialsStatus.authorizing)
        }
    }

    private func handleAddCredentialStatus(_ status: AddCredentialsTask.Status, onError: @escaping (Error) -> Void) {
        tinkLinkTracker.credentialsID = (task as? AddCredentialsTask)?.credentials?.id.value
        addCredentialsTaskStatus = status
        switch status {
        case .created:
            notificationCenter.post(name: .credentialsCreatedNotification, object: (task as? AddCredentialsTask)?.credentials?.id)
        case .authenticating(let payload):
            showUpdating(status: payload ?? Strings.CredentialsStatus.authorizing)
        case .updating:
            let status: String
            if let providerName = providerName, let bankName = providerController.provider(providerName: providerName)?.displayName {
                let statusFormatText = Strings.CredentialsStatus.updating
                status = String(format: statusFormatText, bankName)
            } else {
                status = Strings.CredentialsStatus.updatingFallback
            }
            showUpdating(status: status)
            authorizeIfNeeded(onError: onError)
        }
    }

    private func handleUpdateTaskStatus(_ status: UpdateCredentialsTask.Status) {
        updateCredentialsTaskStatus = status
        switch status {
        case .authenticating(let payload):
            showUpdating(status: payload ?? Strings.CredentialsStatus.authorizing)
        case .updating:
            let status: String
            if let providerName = providerName, let bankName = providerController.provider(providerName: providerName)?.displayName {
                let statusFormatText = Strings.CredentialsStatus.updating
                status = String(format: statusFormatText, bankName)
            } else {
                status = Strings.CredentialsStatus.updatingFallback
            }
            showUpdating(status: status)
        }
    }

    private func handleAuthenticationTask(authentication: AuthenticationTask) {
        switch authentication {
        case .awaitingSupplementalInformation(let supplementInformationTask):
            showSupplementalInformation(for: supplementInformationTask)
        case .awaitingThirdPartyAppAuthentication(let thirdPartyAppAuthenticationTask):
            handleThirdPartyAppAuthentication(task: thirdPartyAppAuthenticationTask)
        }
    }

    private func handleThirdPartyAppAuthentication(task: ThirdPartyAppAuthenticationTask) {
        task.handle { [weak self] result in
            switch result {
            case .qrImage(let image):
                DispatchQueue.main.async {
                    self?.showQRCodeView(qrImage: image)
                }
            case .awaitAuthenticationOnAnotherDevice:
                DispatchQueue.main.async {
                    self?.showUpdating(status: Strings.CredentialsStatus.waitingForAuthenticationOnAnotherDevice)
                }
            }
        }
    }

    private func handleCompletion(_ result: Result<Credentials, Error>, onCompletion: @escaping ((Result<(Credentials, AuthorizationCode?), Error>) -> Void)) {
        do {
            let credentials = try result.get()
            credentialsController.newlyAddedFailedCredentialsID[credentials.id] = nil
            authorizeIfNeeded(onError: { error in
                DispatchQueue.main.async {
                    // FIXME: This triggers two onCompletion calls.
                    onCompletion(.failure(error))
                }
            })
            authorizationGroup.notify(queue: .main) { [weak self] in
                onCompletion(.success((credentials, self?.authorizationCode)))
            }
        } catch {
            let addCredentialsTask = task as? AddCredentialsTask
            if let credentialsID = addCredentialsTask?.credentials?.id {
                credentialsController.newlyAddedFailedCredentialsID[credentialsID] = error
            }
            onCompletion(.failure(error))
        }
        task = nil
    }

    private func authorizeIfNeeded(onError: @escaping (Error) -> Void) {
        if didCallAuthorize { return }
        guard shouldAuthorize else { return }

        guard case .anonymous(let scopes) = addCredentialsMode else { return }

        didCallAuthorize = true
        authorizationGroup.enter()
        authorizationController.authorize(scopes: scopes) { [weak self] result in
            do {
                let authorizationCode = try result.get()
                self?.authorizationCode = authorizationCode
            } catch {
                self?.didCallAuthorize = false
                onError(error)
            }
            self?.authorizationGroup.leave()
        }
    }

    private func cancel() {
        task?.cancel()
    }
}

extension AddCredentialsSession {
    private func showSupplementalInformation(for supplementInformationTask: SupplementInformationTask) {
        supplementInfoTask = supplementInformationTask
        hideQRCodeViewIfNeeded(animated: true) {
            let supplementalInformationViewController = SupplementalInformationViewController(supplementInformationTask: supplementInformationTask)
            supplementalInformationViewController.delegate = self
            let navigationController = TinkNavigationController(rootViewController: supplementalInformationViewController)
            self.presenter?.forcePresent(navigationController, animated: true, completion: nil)
            self.tinkLinkTracker.track(screen: .supplementalInformation)
        }
    }

    private func showUpdating(status: String) {
        hideQRCodeViewIfNeeded(animated: true) {
            let loadingViewController = LoadingViewController()
            loadingViewController.update(status, onCancel: { [weak self] in
                self?.showActionSheet()
            })
            self.presenter?.show(loadingViewController)
        }
    }

    private func showQRCodeView(qrImage: UIImage) {
        if qrImageViewController != nil {
            qrImageViewController?.qrImage = qrImage
        } else {
            let qrImageViewController = QRImageViewController(qrImage: qrImage)
            self.qrImageViewController = qrImageViewController
            qrImageViewController.delegate = self
            qrImageViewController.qrImage = qrImage
            presenter?.forcePresent(TinkNavigationController(rootViewController: qrImageViewController), animated: true, completion: nil)
        }
    }

    private func hideQRCodeViewIfNeeded(animated: Bool = false, completion: (() -> Void)? = nil) {
        guard qrImageViewController != nil else {
            completion?()
            return
        }
        presenter?.dismiss(animated: animated, completion: completion)
    }

    private func showActionSheet() {
        let alertTitle = Strings.Credentials.Discard.title
        let alertMessage = Strings.Credentials.Discard.message
        let alertStyle: UIAlertController.Style = UIDevice.current.isPad ? .alert : .actionSheet
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: alertStyle)

        let discardActionTitle = Strings.Credentials.Discard.primaryAction
        let discardAction = UIAlertAction(title: discardActionTitle, style: .destructive) { _ in
            self.cancel()
        }
        alert.addAction(discardAction)

        let continueActionTitle = Strings.Credentials.Discard.continueAction
        let continueAction = UIAlertAction(title: continueActionTitle, style: .cancel)
        alert.addAction(continueAction)

        presenter?.forcePresent(alert, animated: true, completion: nil)
    }
}

// MARK: - SupplementalInformationViewControllerDelegate

extension AddCredentialsSession: SupplementalInformationViewControllerDelegate {
    func supplementalInformationViewControllerDidCancel(_ viewController: SupplementalInformationViewController) {
        presenter?.dismiss(animated: true) {
            self.tinkLinkTracker.track(interaction: .back, screen: .supplementalInformation)
            self.supplementInfoTask?.cancel()
            self.showUpdating(status: Strings.CredentialsStatus.cancelling)
        }
    }

    func supplementalInformationViewController(_ viewController: SupplementalInformationViewController, didPressSubmitWithForm form: Form) {
        presenter?.dismiss(animated: true) {
            self.supplementInfoTask?.submit(form)
            self.showUpdating(status: Strings.CredentialsStatus.sending)
        }
    }
}

extension AddCredentialsSession: QRImageViewControllerDelegate {
    func qrImageViewControllerDidCancel(_ viewController: QRImageViewController) {
        presenter?.dismiss(animated: true) {
            self.task?.cancel()
        }
    }
}

extension Notification.Name {
    /// This notification is posted when a Credentials is created.
    ///
    /// The notification object is the optional `Credentials.ID` object that’s been created. This notification doesn’t contain a `userInfo` dictionary.
    public static let credentialsCreatedNotification = Notification.Name("TinkCore.AIS.Credentials.CreatedNotification")
}
