import Foundation
import Alamofire
import Moya

enum AuthTarget: TargetType {
    case login(LoginRequestDTO)
    case signup(SignupRequestDTO)
    case sendPhoneCode(PhoneSendCodeRequestDTO)
    case verifyPhoneCode(PhoneVerifyCodeRequestDTO)
    case myProfile(accessToken: String)
    case updateName(UpdateNameRequestDTO, accessToken: String)
    case profileImageUploadURL(ImageUploadURLRequestDTO, accessToken: String)
    case confirmProfileImage(ProfileImageConfirmRequestDTO, accessToken: String)

    var baseURL: URL {
        APIConfiguration.baseURL
    }

    var path: String {
        switch self {
        case .login:
            "/api/v1/auth/login"
        case .signup:
            "/api/v1/auth/signup"
        case .sendPhoneCode:
            "/api/v1/auth/phone/send-code"
        case .verifyPhoneCode:
            "/api/v1/auth/phone/verify-code"
        case .myProfile:
            "/api/v1/users/me"
        case .updateName:
            "/api/v1/users/me/name"
        case .profileImageUploadURL:
            "/api/v1/files/profile-image/upload-url"
        case .confirmProfileImage:
            "/api/v1/files/profile-image/confirm"
        }
    }

    var method: Moya.Method {
        switch self {
        case .myProfile:
            .get
        case .updateName:
            .patch
        default:
            .post
        }
    }

    var task: Moya.Task {
        switch self {
        case let .login(request):
            .requestJSONEncodable(request)
        case let .signup(request):
            .requestJSONEncodable(request)
        case let .sendPhoneCode(request):
            .requestJSONEncodable(request)
        case let .verifyPhoneCode(request):
            .requestJSONEncodable(request)
        case .myProfile:
            .requestPlain
        case let .updateName(request, _):
            .requestJSONEncodable(request)
        case let .profileImageUploadURL(request, _):
            .requestJSONEncodable(request)
        case let .confirmProfileImage(request, _):
            .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        var headers = ["Content-Type": "application/json", "Accept": "application/json"]
        switch self {
        case let .myProfile(token), let .updateName(_, token), let .profileImageUploadURL(_, token), let .confirmProfileImage(_, token):
            headers["Authorization"] = "Bearer \(token)"
        default:
            break
        }
        return headers
    }

    var sampleData: Data { Data() }
}
