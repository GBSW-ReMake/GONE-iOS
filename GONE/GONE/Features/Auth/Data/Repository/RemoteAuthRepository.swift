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

    func sendPhoneVerificationCode(to phoneNumber: String) async throws -> Int {
        let request = PhoneSendCodeRequestDTO(phoneNumber: phoneNumber)
        let envelope: APIResponseDTO<PhoneSendCodeResponseDTO> = try await client.request(
            AuthTarget.sendPhoneCode(request),
            responseType: APIResponseDTO<PhoneSendCodeResponseDTO>.self
        )
        guard envelope.success, let data = envelope.data else {
            throw APIError.server(statusCode: 400, message: envelope.message)
        }
        return data.expiresIn
    }

    func verifyPhoneCode(_ code: String, for phoneNumber: String) async throws -> String {
        let request = PhoneVerifyCodeRequestDTO(phoneNumber: phoneNumber, code: code)
        let envelope: APIResponseDTO<PhoneVerifyCodeResponseDTO> = try await client.request(
            AuthTarget.verifyPhoneCode(request),
            responseType: APIResponseDTO<PhoneVerifyCodeResponseDTO>.self
        )
        guard envelope.success, let data = envelope.data else {
            throw APIError.server(statusCode: 400, message: envelope.message)
        }
        return data.ticket
    }

    func signup(with request: SignupRequest) async throws -> AuthSession {
        let dto = SignupRequestDTO(
            loginId: request.identifier,
            password: request.password,
            ticket: request.ticket,
            phoneNumber: request.phoneNumber
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
