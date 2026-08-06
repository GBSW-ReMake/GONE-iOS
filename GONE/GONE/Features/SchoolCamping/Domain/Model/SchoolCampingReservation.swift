import Combine
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

struct CampingStudent: Identifiable, Equatable {
    let studentNumber: String
    let name: String

    var id: String { studentNumber }
    var displayName: String { "\(studentNumber) \(name)" }
}

struct CampingTeacher: Identifiable, Equatable {
    let id: String
    let name: String
}

struct SchoolCampingReservationDraft: Equatable {
    let date: Date
    let teacherName: String
    var participants: [CampingParticipant]

    var representative: CampingParticipant? { participants.first }

    var isValid: Bool {
        !teacherName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (1...8).contains(participants.count)
            && participants.allSatisfy(\.isValid)
    }
}

final class SchoolCampingReservation: ObservableObject, Identifiable, Equatable {
    enum Status {
        case submitted
    }

    let id: String
    let date: Date
    let status: Status
    private(set) var teacherName: String
    private(set) var participants: [CampingParticipant]

    var representative: CampingParticipant? { participants.first }

    init(
        id: String,
        date: Date,
        teacherName: String,
        participants: [CampingParticipant],
        status: Status
    ) {
        self.id = id
        self.date = date
        self.teacherName = teacherName
        self.participants = participants
        self.status = status
    }

    static func == (lhs: SchoolCampingReservation, rhs: SchoolCampingReservation) -> Bool {
        lhs === rhs
    }

    func apply(_ draft: SchoolCampingReservationDraft) {
        objectWillChange.send()
        teacherName = draft.teacherName
        participants = draft.participants
    }
}
