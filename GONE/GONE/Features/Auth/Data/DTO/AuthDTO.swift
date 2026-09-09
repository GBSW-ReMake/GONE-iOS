import Foundation

struct LoginRequestDTO: Encodable {
    let identifier: String
    let password: String
    let role: String
}

struct SignupRequestDTO: Encodable {
    let identifier: String
    let password: String
    let phoneNumber: String
    let verificationCode: String
    let studentNumber: String
    let name: String
}

struct AuthResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String?
}
