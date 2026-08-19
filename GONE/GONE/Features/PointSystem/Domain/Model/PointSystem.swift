import Foundation

struct PointStudent: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let studentInfo: String
}

enum PointKind: String, CaseIterable, Identifiable, Hashable {
    case reward = "상점"
    case penalty = "벌점"

    var id: String { rawValue }
    var prefix: String { self == .reward ? "+" : "-" }
}

struct PointIssueDraft: Equatable {
    var kind: PointKind = .reward
    var points: Int = 2
    var item = "학교 홍보 활동에 성실히 참여한 학생"
    var memo = ""
}

struct PointIssueRecord: Identifiable, Equatable {
    let id: String
    let student: PointStudent
    let kind: PointKind
    let points: Int
    let item: String
    let memo: String
    let issuedAt: Date
}

struct PointStatistics: Equatable {
    let issueCount: Int
    let rewardPoints: Int
    let penaltyPoints: Int
    let monthlyIssueCounts: [Int]
}
