import Foundation

enum AccountRole: String, CaseIterable, Identifiable {
    case student
    case teacher

    var id: Self { self }
    var title: String { self == .student ? "학생" : "선생님" }
}

struct OutingTeacher: Identifiable, Equatable {
    let id: String
    let name: String
    let affiliation: String
}

struct OutingStudent: Equatable {
    let name: String
    let studentNumber: String
}

struct OutingRequest: Identifiable, Equatable {
    enum Status: Equatable {
        case pendingApproval
        case approved
        case rejected(reason: String)
    }

    let id: String
    let student: OutingStudent
    let date: Date
    let departureTime: Date
    let returnTime: Date
    let reason: String
    let teacher: OutingTeacher
    var status: Status
}

struct OutingDraft: Equatable {
    static let earliestMinute = 8 * 60 + 40
    static let latestMinute = 20 * 60 + 30

    var date = Date()
    var departureTime = Date()
    var returnTime = Date().addingTimeInterval(30 * 60)
    var reason = ""
    var teacher: OutingTeacher?

    var validationMessage: String? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilSunday = 7 - weekday
        let endOfWeek = calendar.date(byAdding: .day, value: daysUntilSunday, to: today) ?? today
        guard date >= today && date <= endOfWeek else { return "외출은 이번 주 안에서만 신청할 수 있어요." }
        guard minute(of: departureTime) >= Self.earliestMinute,
              minute(of: returnTime) <= Self.latestMinute else {
            return "외출 가능 시간은 오전 8:40부터 오후 8:30까지예요."
        }
        guard returnTime > departureTime else { return "복귀 시간은 출발 시간 이후로 설정해 주세요." }
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "외출 사유를 입력해 주세요." }
        guard teacher != nil else { return "담당 선생님을 선택해 주세요." }
        return nil
    }

    var isValid: Bool { validationMessage == nil }

    private func minute(of date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
