import Foundation
@testable import TinkLink

class MockedSuccessCredentialsService: CredentialsService {
    var credentials = [Credentials]()

    @discardableResult
    func credentialsList(completion: @escaping (Result<[Credentials], Error>) -> Void) -> RetryCancellable? {
        credentials = credentials.map { Credentials(credentials: $0, status: $0.nextCredentialsStatus()) }
        completion(.success(credentials))
        return TestRetryCanceller { [weak self] in
            guard let self = self else { return }
            self.credentialsList(completion: completion)
        }
    }

    @discardableResult
    func credentials(id: Credentials.ID, completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        credentials = credentials.map { Credentials(credentials: $0, status: $0.nextCredentialsStatus()) }
        if let credentials = credentials.first(where: { $0.id == id }) {
            completion(.success(credentials))
        } else {
            fatalError()
        }
        return TestRetryCanceller { [weak self] in
            guard let self = self else { return }
            self.credentials(id: id, completion: completion)
        }
    }

    func create(providerName: Provider.Name, refreshableItems: RefreshableItems, fields: [String: String], appURI: URL?, callbackURI: URL?, completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        create(providerName: providerName, refreshableItems: refreshableItems, fields: fields, appURI: appURI, callbackURI: callbackURI, products: [], completion: completion)
    }

    func create(providerName: Provider.Name, refreshableItems: RefreshableItems, fields: [String: String], appURI: URL?, callbackURI: URL?, products: [Product], completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        let addedCredential = Credentials.makeTestCredentials(
            providerName: providerName,
            kind: .password,
            status: .created,
            fields: fields
        )
        credentials.append(addedCredential)
        completion(.success(addedCredential))
        return nil
    }

    func delete(id: Credentials.ID, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        credentials.removeAll { $0.id == id }
        completion(.success)
        return nil
    }

    func update(id: Credentials.ID, providerName: Provider.Name, appURI: URL?, callbackURI: URL?, fields: [String: String], completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        update(id: id, providerName: providerName, appURI: appURI, callbackURI: callbackURI, fields: fields, products: [], completion: completion)
    }

    func update(id: Credentials.ID, providerName: Provider.Name, appURI: URL?, callbackURI: URL?, fields: [String: String], products: [Product], completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        if let index = credentials.firstIndex(where: { $0.id == id }) {
            credentials[index].modify(fields: fields, status: .updated)
            completion(.success(credentials[index]))
        }
        return nil
    }

    func refresh(id: Credentials.ID, authenticate: Bool, refreshableItems: RefreshableItems, optIn: Bool, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.success)
        return nil
    }

    func refresh(id: Credentials.ID, authenticate: Bool, refreshableItems: RefreshableItems, appURI: URL?, callbackURI: URL?, optIn: Bool, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.success)
        return nil
    }

    func refresh(id: Credentials.ID, authenticate: Bool, appURI: URL?, callbackURI: URL?, refreshableItems: RefreshableItems, optIn: Bool, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.success)
        return nil
    }

    func refresh(id: Credentials.ID, authenticate: Bool, refreshableItems: RefreshableItems, appURI: URL?, callbackURI: URL?, optIn: Bool, products: [Product], completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.success)
        return nil
    }

    @discardableResult
    func addSupplementalInformation(id: Credentials.ID, fields: [String: String], completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        if let index = credentials.firstIndex(where: { $0.id == id }) {
            credentials[index].modify(status: .awaitingSupplementalInformation([]))
            completion(.success)
        }
        return TestRetryCanceller { [weak self] in
            guard let self = self else { return }
            self.addSupplementalInformation(id: id, fields: fields, completion: completion)
        }
    }

    func cancelSupplementalInformation(id: Credentials.ID, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        if let index = credentials.firstIndex(where: { $0.id == id }) {
            credentials[index].modify(status: .authenticationError)
            completion(.success)
        }
        return nil
    }

    func enable(id: Credentials.ID, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.success)
        return nil
    }

    func disable(id: Credentials.ID, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.success)
        return nil
    }

    func thirdPartyCallback(state: String, parameters: [String: String], completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.success)
        return nil
    }

    func authenticate(id: Credentials.ID, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.success)
        return nil
    }

    func authenticate(id: Credentials.ID, appURI: URL?, callbackURI: URL?, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.success)
        return nil
    }

    func authenticate(id: Credentials.ID, appURI: URL?, callbackURI: URL?, products: [Product], completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.success)
        return nil
    }

    func qrCode(id: Credentials.ID, completion: @escaping (Result<Data, Error>) -> Void) -> RetryCancellable? {
        return nil
    }
}

class MockedSuccessThirdPartyAuthenticationCredentialsService: MockedSuccessCredentialsService {
    override func create(providerName: Provider.Name, refreshableItems: RefreshableItems, fields: [String: String], appURI: URL?, callbackURI: URL?, completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        let addedCredential = Credentials.makeTestCredentials(
            providerName: providerName,
            kind: .thirdPartyAuthentication,
            status: .created,
            fields: fields
        )
        credentials.append(addedCredential)
        completion(.success(addedCredential))
        return nil
    }

    override func create(providerName: Provider.Name, refreshableItems: RefreshableItems, fields: [String: String], appURI: URL?, callbackURI: URL?, products: [Product], completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        let addedCredential = Credentials.makeTestCredentials(
            providerName: providerName,
            kind: .thirdPartyAuthentication,
            status: .created,
            fields: fields
        )
        credentials.append(addedCredential)
        completion(.success(addedCredential))
        return nil
    }
}

class MockedUnauthenticatedErrorCredentialsService: CredentialsService {
    func credentialsList(completion: @escaping (Result<[Credentials], Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func credentials(id: Credentials.ID, completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func create(providerName: Provider.Name, refreshableItems: RefreshableItems, fields: [String: String], appURI: URL?, callbackURI: URL?, completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func create(providerName: Provider.Name, refreshableItems: RefreshableItems, fields: [String: String], appURI: URL?, callbackURI: URL?, products: [Product], completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func delete(id: Credentials.ID, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func update(id: Credentials.ID, providerName: Provider.Name, appURI: URL?, callbackURI: URL?, fields: [String: String], completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func update(id: Credentials.ID, providerName: Provider.Name, appURI: URL?, callbackURI: URL?, fields: [String: String], products: [Product], completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func refresh(id: Credentials.ID, authenticate: Bool, refreshableItems: RefreshableItems, optIn: Bool, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        return nil
    }

    func refresh(id: Credentials.ID, authenticate: Bool, refreshableItems: RefreshableItems, appURI: URL?, callbackURI: URL?, optIn: Bool, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        return nil
    }

    func refresh(id: Credentials.ID, authenticate: Bool, refreshableItems: RefreshableItems, appURI: URL?, callbackURI: URL?, optIn: Bool, products: [Product], completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        return nil
    }

    func addSupplementalInformation(id: Credentials.ID, fields: [String: String], completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func cancelSupplementalInformation(id: Credentials.ID, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func enable(id: Credentials.ID, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func disable(id: Credentials.ID, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func thirdPartyCallback(state: String, parameters: [String: String], completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func authenticate(id: Credentials.ID, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        return nil
    }

    func authenticate(id: Credentials.ID, appURI: URL?, callbackURI: URL?, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func authenticate(id: Credentials.ID, appURI: URL?, callbackURI: URL?, products: [Product], completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    func qrCode(id: Credentials.ID, completion: @escaping (Result<Data, Error>) -> Void) -> RetryCancellable? {
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }
}

class MockedCreatedCredentialsWithErrorService: MockedUnauthenticatedErrorCredentialsService {
    var updateIsCalled = false
    var credentials: Credentials?

    override func credentials(id: Credentials.ID, completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        if var credentials = credentials {
            credentials.modify(status: .authenticationError)
            completion(.success(credentials))
        }
        return nil
    }

    override func create(providerName: Provider.Name, refreshableItems: RefreshableItems, fields: [String: String], appURI: URL?, callbackURI: URL?, completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        credentials = Credentials.makeTestCredentials(
            providerName: providerName,
            kind: .password,
            status: .created,
            fields: fields
        )
        completion(.success(credentials!))
        return nil
    }

    override func create(providerName: Provider.Name, refreshableItems: RefreshableItems, fields: [String: String], appURI: URL?, callbackURI: URL?, products: [Product], completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        credentials = Credentials.makeTestCredentials(
            providerName: providerName,
            kind: .password,
            status: .created,
            fields: fields
        )
        completion(.success(credentials!))
        return nil
    }

    override func update(id: Credentials.ID, providerName: Provider.Name, appURI: URL?, callbackURI: URL?, fields: [String: String], completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        updateIsCalled = true
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    override func update(id: Credentials.ID, providerName: Provider.Name, appURI: URL?, callbackURI: URL?, fields: [String: String], products: [Product], completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        updateIsCalled = true
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }
}

class MockedCreatedCredentialsAwaithingThirdPartyService: MockedUnauthenticatedErrorCredentialsService {
    var refreshIsCalled = false
    var credentials: Credentials?

    override func credentials(id: Credentials.ID, completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        if var credentials = credentials {
            credentials.modify(status: .authenticationError)
            completion(.success(credentials))
        }
        return nil
    }

    override func create(providerName: Provider.Name, refreshableItems: RefreshableItems, fields: [String: String], appURI: URL?, callbackURI: URL?, completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        credentials = Credentials.makeTestCredentials(
            providerName: providerName,
            kind: .password,
            status: .created,
            fields: fields
        )
        completion(.success(credentials!))
        return nil
    }

    override func create(providerName: Provider.Name, refreshableItems: RefreshableItems, fields: [String: String], appURI: URL?, callbackURI: URL?, products: [Product], completion: @escaping (Result<Credentials, Error>) -> Void) -> RetryCancellable? {
        credentials = Credentials.makeTestCredentials(
            providerName: providerName,
            kind: .password,
            status: .created,
            fields: fields
        )
        completion(.success(credentials!))
        return nil
    }

    override func refresh(id: Credentials.ID, authenticate: Bool, refreshableItems: RefreshableItems, optIn: Bool, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        refreshIsCalled = true
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    override func refresh(id: Credentials.ID, authenticate: Bool, refreshableItems: RefreshableItems, appURI: URL?, callbackURI: URL?, optIn: Bool, completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        refreshIsCalled = true
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }

    override func refresh(id: Credentials.ID, authenticate: Bool, refreshableItems: RefreshableItems, appURI: URL?, callbackURI: URL?, optIn: Bool, products: [Product], completion: @escaping (Result<Void, Error>) -> Void) -> RetryCancellable? {
        refreshIsCalled = true
        completion(.failure(ServiceError.unauthenticatedError))
        return nil
    }
}
