import Alamofire
import Foundation
import Moya

enum HomeTarget: TargetType {
    case profile(accessToken: String)
    case conductSummary(accessToken: String)
    case meals(date: String)
    case timetable(date: String, accessToken: String)
    case outingRequests(accessToken: String)
    case schoolCampParticipations(accessToken: String)

    var baseURL: URL { APIConfiguration.baseURL }

    var path: String {
        switch self {
        case .profile: "/api/v1/users/me"
        case .conductSummary: "/api/v1/conduct-records/me/summary"
        case .meals: "/api/v1/meals"
        case .timetable: "/api/v1/timetables"
        case .outingRequests: "/api/v1/outings/me/requests"
        case .schoolCampParticipations: "/api/v1/school-camps/me"
        }
    }

    var method: Moya.Method { .get }

    var task: Moya.Task {
        switch self {
        case let .meals(date), let .timetable(date, _):
            return .requestParameters(parameters: ["date": date], encoding: URLEncoding.queryString)
        default:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        var headers = ["Accept": "application/json"]
        switch self {
        case let .profile(token), let .conductSummary(token), let .timetable(_, token), let .outingRequests(token), let .schoolCampParticipations(token):
            headers["Authorization"] = "Bearer \(token)"
        case .meals:
            break
        }
        return headers
    }

    var sampleData: Data { Data() }
}
