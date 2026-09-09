import Foundation

protocol AuthRepository {
    func login(with credentials: LoginCredentials) async throws -> AuthSession
    func sendPhoneVerificationCode(to phoneNumber: String) async throws -> Int
    func verifyPhoneCode(_ code: String, for phoneNumber: String) async throws -> String
    func signup(with request: SignupRequest) async throws -> AuthSession
    func fetchMyProfile() async throws -> MyProfileResponseDTO
    func updateName(_ name: String) async throws
    func uploadProfileImage(_ data: Data) async throws
}
