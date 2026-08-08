import Foundation

struct SettingsOverview: Equatable {
    let profile: SettingsProfile
    let activities: [RecentActivity]
}

struct SettingsProfile: Equatable {
    let name: String
    let department: String
    let studentInfo: String

    var initial: String { String(name.prefix(1)) }
}

struct RecentActivity: Identifiable, Equatable {
    enum Kind: String, CaseIterable, Equatable {
        case lab = "실습실 예약"
        case outing = "외출 신청"
        case schoolCamping = "스쿨캠핑 예약"

        var systemImage: String {
            switch self {
            case .lab: "desktopcomputer"
            case .outing: "figure.walk"
            case .schoolCamping: "tent"
            }
        }
    }

    enum Status: String, Equatable {
        case pending = "승인 대기"
        case completed = "신청 완료"
        case reserved = "예약 완료"
        case cancelled = "취소됨"
    }

    let id: String
    let kind: Kind
    let title: String
    let dateText: String
    let status: Status
}
