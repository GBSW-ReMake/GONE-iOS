import Foundation

struct SignupUseCase {
    private let repository: AuthRepository
    private let sessionStore: SessionStore

    init(repository: AuthRepository, sessionStore: SessionStore) {
        self.repository = repository
        self.sessionStore = sessionStore
    }

    func requestPhoneVerificationCode(for phoneNumber: String) async throws -> Int {
        try await repository.sendPhoneVerificationCode(to: phoneNumber)
    }

    func verifyPhoneCode(_ code: String, for phoneNumber: String) async throws -> String {
        try await repository.verifyPhoneCode(code, for: phoneNumber)
    }

    func signup(with request: SignupRequest) async throws {
        let session = try await repository.signup(with: request)
        try sessionStore.save(session)
    }
}
