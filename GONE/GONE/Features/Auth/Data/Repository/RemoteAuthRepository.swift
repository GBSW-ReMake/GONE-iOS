import Foundation

final class RemoteAuthRepository: AuthRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func login(with credentials: LoginCredentials) async throws -> AuthSession {
        let request = LoginRequestDTO(
            identifier: credentials.identifier,
            password: credentials.password,
            role: credentials.role.rawValue
        )
        let response: AuthResponseDTO = try await client.request(
            AuthTarget.login(request),
            responseType: AuthResponseDTO.self
        )
        return AuthSession(accessToken: response.accessToken, refreshToken: response.refreshToken)
    }

    func signup(with request: SignupRequest) async throws -> AuthSession {
        let dto = SignupRequestDTO(
            identifier: request.identifier,
            password: request.password,
            phoneNumber: request.phoneNumber,
            verificationCode: request.verificationCode,
            studentNumber: request.studentNumber,
            name: request.name
        )
        let response: AuthResponseDTO = try await client.request(
            AuthTarget.signup(dto),
            responseType: AuthResponseDTO.self
        )
        return AuthSession(accessToken: response.accessToken, refreshToken: response.refreshToken)
    }
}
