import Foundation

protocol AuthRepository {
    func login(with credentials: LoginCredentials) async throws -> AuthSession
    func signup(with request: SignupRequest) async throws -> AuthSession
}
