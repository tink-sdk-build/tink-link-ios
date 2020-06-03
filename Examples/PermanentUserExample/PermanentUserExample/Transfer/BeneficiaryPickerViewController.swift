import UIKit
import TinkLink

protocol BeneficiaryPickerViewControllerDelegate: AnyObject {
    func beneficiaryPickerViewController(_ viewController: BeneficiaryPickerViewController, didSelectBeneficiary beneficiary: Beneficiary)
    func beneficiaryPickerViewController(_ viewController: BeneficiaryPickerViewController, didEnterBeneficiaryURI beneficiaryURI: Beneficiary.URI)
}

class BeneficiaryPickerViewController: UITableViewController {
    private let transferContext = TransferContext()

    weak var delegate: BeneficiaryPickerViewControllerDelegate?

    private let sourceAccount: Account
    private var beneficiaries: [Beneficiary]
    private let selectedBeneficiary: Beneficiary?
    private var canceller: RetryCancellable?
    private var addBeneficiaryTask: AddBeneficiaryTask?

    private var statusViewController: AddCredentialsStatusViewController?

    init(sourceAccount: Account, selectedBeneficiary: Beneficiary? = nil) {
        self.sourceAccount = sourceAccount
        self.beneficiaries = []
        self.selectedBeneficiary = selectedBeneficiary
        super.init(style: .plain)
        title = "Select Beneficiary"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        addBeneficiaryTask?.cancel()
    }
}

// MARK: - View Lifecycle

extension BeneficiaryPickerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(enterBeneficiary)),
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addBeneficiary(_:))),
        ]

        canceller = transferContext.fetchBeneficiaries(for: sourceAccount) { [weak self] result in
            DispatchQueue.main.async {
                do {
                    self?.beneficiaries = try result.get()
                    self?.tableView.reloadData()
                } catch {
                    self?.showAlert(for: error)
                }
            }
        }

        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "Cell")
    }
}

// MARK: - Actions

extension BeneficiaryPickerViewController {
    @objc private func enterBeneficiary(_ sender: Any) {
        let alert = UIAlertController(title: "Enter Beneficiary URI", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Type"
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Account Number"
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
            guard let type = alert.textFields?[0].text,
                let accountNumber = alert.textFields?[1].text,
                let uri = Beneficiary.URI(kind: .init(type), accountNumber: accountNumber)
                else { return }
            self.delegate?.beneficiaryPickerViewController(self, didEnterBeneficiaryURI: uri)
        }))
        present(alert, animated: true)
    }

    @objc private func addBeneficiary(_ sender: Any) {
        let alert = UIAlertController(title: "Add Beneficiary", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Name"
            textField.autocapitalizationType = .words
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Type"
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Account Number"
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
            guard let name = alert.textFields?[0].text,
                let accountNumberType = alert.textFields?[1].text,
                let accountNumber = alert.textFields?[2].text
                else { return }
            self.addBeneficiary(name: name, accountNumberType: accountNumberType, accountNumber: accountNumber)
        }))
        present(alert, animated: true)
    }
}

// MARK: - Adding a Beneficiary

extension BeneficiaryPickerViewController {
    private func addBeneficiary(name: String, accountNumberType: String, accountNumber: String) {
        addBeneficiaryTask = transferContext.addBeneficiary(
            to: sourceAccount,
            name: name,
            accountNumberType: accountNumberType,
            accountNumber: accountNumber,
            authentication: { [weak self] task in
                DispatchQueue.main.async {
                    self?.handleAddBeneficiaryAuthentication(task)
                }
            },
            progress: { [weak self] status in
                DispatchQueue.main.async {
                    self?.handleAddBeneficiaryProgress(status)
                }
            },
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    self?.hideStatus(animated: true) {
                        do {
                            let beneficiary = try result.get()
                            self?.beneficiaries.append(beneficiary)
                            self?.tableView.reloadData()
                        } catch {
                            self?.showAlert(for: error)
                        }
                    }
                }
            }
        )
    }

    private func handleAddBeneficiaryAuthentication(_ authenticationTask: AddBeneficiaryTask.AuthenticationTask) {
        switch authenticationTask {
        case .awaitingSupplementalInformation(let task):
            hideStatus(animated: false) {
                self.showSupplementalInformation(for: task)
            }
        case .awaitingThirdPartyAppAuthentication(let task):
            task.handle()
        }
    }

    private func handleAddBeneficiaryProgress(_ status: AddBeneficiaryTask.Status) {
        switch status {
        case .requestSent:
            showStatus("Request sent")
        case .authenticating:
            showStatus("Authenticating…")
        }
    }

    private func showSupplementalInformation(for supplementInformationTask: SupplementInformationTask) {
        let supplementalInformationViewController = SupplementalInformationViewController(supplementInformationTask: supplementInformationTask)
        supplementalInformationViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: supplementalInformationViewController)
        show(navigationController, sender: nil)
    }

    private func showStatus(_ status: String) {
        if statusViewController == nil {
            let statusViewController = AddCredentialsStatusViewController()
            statusViewController.modalTransitionStyle = .crossDissolve
            statusViewController.modalPresentationStyle = .overFullScreen
            present(statusViewController, animated: true)
            UIView.animate(withDuration: 0.3) {
                self.view.tintAdjustmentMode = .dimmed
            }
            self.statusViewController = statusViewController
        }
        statusViewController?.status = status
    }

    private func hideStatus(animated: Bool, completion: (() -> Void)? = nil) {
        guard statusViewController != nil else {
            completion?()
            return
        }
        UIView.animate(withDuration: 0.3) {
            self.view.tintAdjustmentMode = .automatic
        }
        dismiss(animated: animated, completion: completion)
        statusViewController = nil
    }
}

// MARK: - UITableViewDataSource

extension BeneficiaryPickerViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return beneficiaries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let beneficiary = beneficiaries[indexPath.row]
        cell.textLabel?.text = beneficiary.name
        cell.detailTextLabel?.text = "\(beneficiary.accountNumberType): \(beneficiary.accountNumber ?? "")"
        cell.accessoryType = beneficiary == selectedBeneficiary ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let beneficiary = beneficiaries[indexPath.row]
        delegate?.beneficiaryPickerViewController(self, didSelectBeneficiary: beneficiary)
    }
}

// MARK: - SupplementalInformationViewControllerDelegate

extension BeneficiaryPickerViewController: SupplementalInformationViewControllerDelegate {
    func supplementalInformationViewControllerDidCancel(_ viewController: SupplementalInformationViewController) {
        dismiss(animated: true)
    }

    func supplementalInformationViewController(_ viewController: SupplementalInformationViewController, didSupplementInformationForCredential credential: Credentials) {
        dismiss(animated: true)
    }
}
