import Foundation

enum CampingDateAvailability: Equatable {
    case available
    case unavailable
    case reservedByMe
}

struct CampingCalendarDay: Identifiable, Equatable {
    let date: Date
    let availability: CampingDateAvailability

    var id: Date { date }
}

struct CampingParticipant: Identifiable, Equatable {
    let id: UUID
    var studentNumber: String
    var name: String

    init(id: UUID = UUID(), studentNumber: String, name: String) {
        self.id = id
        self.studentNumber = studentNumber
        self.name = name
    }

    var displayName: String {
        "\(studentNumber) \(name)"
    }

    var isValid: Bool {
        !studentNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct SchoolCampingReservationDraft: Equatable {
    let date: Date
    let teacherName: String
    var participants: [CampingParticipant]

    var representative: CampingParticipant? { participants.first }

    var isValid: Bool {
        (1...8).contains(participants.count) && participants.allSatisfy(\.isValid)
    }
}

struct SchoolCampingReservation: Identifiable, Equatable {
    enum Status: Equatable {
        case submitted
    }

    let id: String
    let date: Date
    let teacherName: String
    let participants: [CampingParticipant]
    let status: Status

    var representative: CampingParticipant? { participants.first }
}
