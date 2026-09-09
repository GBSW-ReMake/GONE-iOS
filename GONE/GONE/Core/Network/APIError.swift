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
        case let .server(_, message):
            message ?? "요청을 처리하지 못했습니다."
        case let .transport(message):
            message
        }
    }
}
