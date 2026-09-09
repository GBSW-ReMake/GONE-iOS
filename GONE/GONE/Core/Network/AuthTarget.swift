import Foundation
import Alamofire
import Moya

enum AuthTarget: TargetType {
    case login(LoginRequestDTO)
    case signup(SignupRequestDTO)

    var baseURL: URL {
        // 서버 base URL 확정 후 AppDependencies에서 주입하는 방식으로 교체합니다.
        URL(string: "http://localhost:8080")!
    }

    var path: String {
        switch self {
        case .login:
            "/api/auth/login"
        case .signup:
            "/api/auth/signup"
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
