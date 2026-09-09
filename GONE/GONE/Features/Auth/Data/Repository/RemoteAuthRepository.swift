import Foundation

final class RemoteAuthRepository: AuthRepository {
    private let client: APIClient
    private let sessionStore: SessionStore

    init(client: APIClient, sessionStore: SessionStore = KeychainSessionStore()) {
        self.client = client
        self.sessionStore = sessionStore
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

    func fetchMyProfile() async throws -> MyProfileResponseDTO {
        let response: APIResponseDTO<MyProfileResponseDTO> = try await client.request(
            AuthTarget.myProfile(accessToken: try accessToken()),
            responseType: APIResponseDTO<MyProfileResponseDTO>.self
        )
        guard let data = response.data else { throw APIError.decoding }
        return data
    }

    func updateName(_ name: String) async throws {
        let response: APIResponseDTO<EmptyResponseDTO> = try await client.request(
            AuthTarget.updateName(UpdateNameRequestDTO(name: name), accessToken: try accessToken()),
            responseType: APIResponseDTO<EmptyResponseDTO>.self
        )
        guard response.success else { throw APIError.server(statusCode: 400, message: response.message) }
    }

    func uploadProfileImage(_ data: Data) async throws {
        let contentType = "image/jpeg"
        let uploadResponse: APIResponseDTO<ImageUploadURLResponseDTO> = try await client.request(
            AuthTarget.profileImageUploadURL(
                ImageUploadURLRequestDTO(fileName: "profile.jpg", contentType: contentType, fileSize: data.count),
                accessToken: try accessToken()
            ),
            responseType: APIResponseDTO<ImageUploadURLResponseDTO>.self
        )
        guard let uploadData = uploadResponse.data,
              let uploadURL = URL(string: uploadData.uploadUrl) else { throw APIError.decoding }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
        let (_, urlResponse) = try await URLSession.shared.upload(for: request, from: data)
        guard let httpResponse = urlResponse as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.server(statusCode: 400, message: "프로필 사진 업로드에 실패했습니다.")
        }

        let confirmResponse: APIResponseDTO<EmptyResponseDTO> = try await client.request(
            AuthTarget.confirmProfileImage(
                ProfileImageConfirmRequestDTO(key: uploadData.key),
                accessToken: try accessToken()
            ),
            responseType: APIResponseDTO<EmptyResponseDTO>.self
        )
        guard confirmResponse.success else {
            throw APIError.server(statusCode: 400, message: confirmResponse.message)
        }
    }

    private func accessToken() throws -> String {
        guard let session = try sessionStore.load() else { throw APIError.invalidResponse }
        return session.accessToken
    }
}
