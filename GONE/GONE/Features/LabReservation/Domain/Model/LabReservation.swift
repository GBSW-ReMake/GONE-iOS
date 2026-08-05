import Foundation

enum LabFloor: Int, CaseIterable, Identifiable {
    case fourth = 4
    case third = 3
    case second = 2

    var id: Int { rawValue }
    var title: String { "\(rawValue)층" }
}

struct LabRoom: Identifiable, Equatable {
    let id: String
    let floor: LabFloor
    let name: String
    let capacity: Int
    let amenities: [String]
    let isReservable: Bool

    var description: String {
        (["최대 \(capacity)명"] + amenities).joined(separator: " · ")
    }
}

struct LabReservationDraft: Equatable {
    var room: LabRoom
    var representative = ""
    var members = ""
    var purpose = ""
    var usageTime = "19:10 ~ 20:30"

    var isValid: Bool {
        !representative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !members.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct LabReservation: Identifiable, Equatable {
    enum Status: String, Equatable {
        case submitted = "신청완료"
        case pending = "승인대기"
        case approved = "이용가능"
    }

    let id: String
    let room: LabRoom
    let date: String
    let usageTime: String
    let representative: String
    let memberCount: Int
    let purpose: String
    let status: Status
}
