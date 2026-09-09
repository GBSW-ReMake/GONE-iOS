import Foundation

struct LoginRequestDTO: Encodable {
    let identifier: String
    let password: String
}

struct SignupRequestDTO: Encodable {
    let loginId: String
    let password: String
    let ticket: String
    let phoneNumber: String
}

struct PhoneSendCodeRequestDTO: Encodable {
    let phoneNumber: String
}

struct PhoneVerifyCodeRequestDTO: Encodable {
    let phoneNumber: String
    let code: String
}

struct PhoneSendCodeResponseDTO: Decodable {
    let expiresIn: Int
}

struct PhoneVerifyCodeResponseDTO: Decodable {
    let ticket: String
    let expiresIn: Int
}

struct UpdateNameRequestDTO: Encodable { let name: String }
struct MyProfileResponseDTO: Decodable {
    let name: String
    let hasProfileImage: Bool
}
struct ImageUploadURLRequestDTO: Encodable {
    let fileName: String
    let contentType: String
    let fileSize: Int
}
struct ImageUploadURLResponseDTO: Decodable {
    let uploadUrl: String
    let key: String
}
struct ProfileImageConfirmRequestDTO: Encodable { let key: String }

struct AuthResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
    }
}

struct APIResponseDTO<Data: Decodable>: Decodable {
    let success: Bool
    let data: Data?
    let message: String?
    let code: String?
}

struct EmptyResponseDTO: Decodable {}
