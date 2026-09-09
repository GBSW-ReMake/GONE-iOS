import Foundation

struct SignupRequest: Equatable {
    let identifier: String
    let password: String
    let phoneNumber: String
    let verificationCode: String
    let studentNumber: String
    let name: String
}
