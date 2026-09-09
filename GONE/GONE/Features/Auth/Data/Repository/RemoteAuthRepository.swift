import Foundation

final class RemoteAuthRepository: AuthRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func login(with credentials: LoginCredentials) async throws -> AuthSession {
        let request = LoginRequestDTO(
            identifier: credentials.identifier,
            password: credentials.password
        )
        let envelope: APIResponseDTO<AuthResponseDTO> = try await client.request(
            AuthTarget.login(request),
            responseType: APIResponseDTO<AuthResponseDTO>.self
        )
        guard envelope.success else {
            throw APIError.server(statusCode: 400, message: envelope.message)
        }
        guard let response = envelope.data else { throw APIError.decoding }
        return AuthSession(accessToken: response.accessToken, refreshToken: response.refreshToken)
    }

    func signup(with request: SignupRequest) async throws -> AuthSession {
        let dto = SignupRequestDTO(
            loginId: request.identifier,
            password: request.password,
            ticket: request.verificationCode,
            phoneNumber: request.phoneNumber,
            studentNumber: request.studentNumber,
            name: request.name
        )
        let envelope: APIResponseDTO<AuthResponseDTO> = try await client.request(
            AuthTarget.signup(dto),
            responseType: APIResponseDTO<AuthResponseDTO>.self
        )
        guard envelope.success else {
            throw APIError.server(statusCode: 400, message: envelope.message)
        }
        guard let response = envelope.data else { throw APIError.decoding }
        return AuthSession(accessToken: response.accessToken, refreshToken: response.refreshToken)
    }
}
