import Foundation
import Alamofire
import Moya

enum AuthTarget: TargetType {
    case login(LoginRequestDTO)
    case signup(SignupRequestDTO)

    var baseURL: URL {
        APIConfiguration.baseURL
    }

    var path: String {
        switch self {
        case .login:
            "/api/v1/auth/login"
        case .signup:
            "/api/v1/auth/signup"
        }
    }

    var method: Moya.Method {
        .post
    }

    var task: Moya.Task {
        switch self {
        case let .login(request):
            .requestJSONEncodable(request)
        case let .signup(request):
            .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json", "Accept": "application/json"]
    }

    var sampleData: Data { Data() }
}
