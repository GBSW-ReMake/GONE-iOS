import Foundation

struct AppNotification: Identifiable, Equatable {
    enum Kind: String, Equatable {
        case camping
        case outing
        case reward
        case penalty
        case lab

        var illustrationAssetName: String {
            switch self {
            case .camping: "HomeCampingIllustration"
            case .outing: "HomeOutingIllustration"
            case .reward: "NotificationRewardIcon"
            case .penalty: "NotificationPenaltyIcon"
            case .lab: "HomeLabIllustration"
            }
        }
    }

    let id: String
    let kind: Kind
    let title: String
    let message: String
    let date: Date
    let relativeTime: String
    var isRead: Bool

    var daySection: DaySection {
        if Calendar.current.isDateInToday(date) { return .today }
        if Calendar.current.isDateInYesterday(date) { return .yesterday }
        return .recent
    }

    enum DaySection: String, CaseIterable, Identifiable {
        case today = "오늘"
        case yesterday = "어제"
        case recent = "최근 7일"

        var id: Self { self }
    }
}
