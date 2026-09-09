import Foundation

struct LoginUseCase {
    private let repository: AuthRepository
    private let sessionStore: SessionStore

    init(repository: AuthRepository, sessionStore: SessionStore) {
        self.repository = repository
        self.sessionStore = sessionStore
    }

    func execute(with credentials: LoginCredentials) async throws {
        let session = try await repository.login(with: credentials)
        try sessionStore.save(session)
    }
}
