import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidResponse
    case decoding
    case server(statusCode: Int, message: String?)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "서버 응답을 확인할 수 없습니다."
        case .decoding:
            "서버 응답을 처리하지 못했습니다."
        case let .server(statusCode, message):
            message ?? Self.defaultMessage(for: statusCode)
        case let .transport(message):
            message
        }
    }

    private static func defaultMessage(for statusCode: Int) -> String {
        switch statusCode {
        case 400:
            "입력한 정보를 확인해주세요."
        case 401:
            "아이디 또는 비밀번호를 확인해주세요."
        case 403:
            "이 요청을 수행할 권한이 없습니다."
        case 404:
            "로그인 API 경로를 확인해주세요."
        case 409:
            "이미 사용 중인 정보입니다."
        case 500...599:
            "서버에서 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
        default:
            "로그인 요청에 실패했습니다. 잠시 후 다시 시도해주세요."
        }
    }
}
