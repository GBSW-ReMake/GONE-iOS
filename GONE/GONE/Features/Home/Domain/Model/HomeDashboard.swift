import Foundation

struct HomeDashboard: Equatable {
    let profile: StudentProfile
    let schedule: [ClassSchedule]
    let meal: Meal
    let requests: [DashboardRequest]
}

struct StudentProfile: Equatable {
    let name: String
    let department: String
    let studentInfo: String
    let rewardPoints: Int
    let penaltyPoints: Int
    let roles: [String]

    var totalPoints: Int { rewardPoints - penaltyPoints }
}

struct ClassSchedule: Identifiable, Equatable {
    let id = UUID()
    let period: Int
    let subject: String
    let location: String
    let time: String
}

struct Meal: Equatable {
    let calories: String
    let title: String
    let servingTime: String
    let leftMenu: [String]
    let rightMenu: [String]
}

struct DashboardRequest: Identifiable, Equatable {
    enum Kind: String, CaseIterable, Identifiable {
        case lab = "실습실 신청"
        case outing = "외출 신청"
        case schoolCamping = "스쿨캠핑 예약"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .lab: "desktopcomputer"
            case .outing: "figure.walk"
            case .schoolCamping: "tent"
            }
        }

        var illustrationAssetName: String {
            switch self {
            case .lab: "HomeLabIllustration"
            case .outing: "HomeOutingIllustration"
            case .schoolCamping: "HomeCampingIllustration"
            }
        }
    }

    enum Status: String, Equatable {
        case completed = "신청 완료"
        case pending = "승인 대기"
        case reserved = "예약 완료"
    }

    let id = UUID()
    let kind: Kind
    let detail: String
    let status: Status
}
