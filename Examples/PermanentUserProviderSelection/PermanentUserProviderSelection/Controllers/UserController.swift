import TinkLinkSDK
import SwiftUI

final class UserController: ObservableObject {
    var user: User?
    
    private var userContext = UserContext()

    func authenticateUser(authorizationCode: AuthorizationCode, completion: @escaping (Result<User, Error>) -> Void) {
        userContext.authenticateUser(authorizationCode: authorizationCode) { [weak self] result in
            do {
                self?.user = try result.get()
            } catch {
                // error
            }
            completion(result)
        }
    }

    func authenticateUser(accessToken: AccessToken, completion: @escaping (Result<User, Error>) -> Void) {
        userContext.authenticateUser(accessToken: accessToken) { [weak self] result in
            do {
                self?.user = try result.get()
            } catch {
                // error
            }
            completion(result)
        }
    }
}
