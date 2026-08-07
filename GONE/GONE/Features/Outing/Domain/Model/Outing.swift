import Foundation

enum AccountRole: String, CaseIterable, Identifiable, Hashable {
    case student
    case teacher

    var id: Self { self }
    var title: String { self == .student ? "학생" : "선생님" }
}

struct OutingTeacher: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let affiliation: String
}

struct OutingStudent: Equatable, Hashable {
    let name: String
    let studentNumber: String
}

struct OutingRequest: Identifiable, Equatable, Hashable {
    enum Status: Equatable, Hashable {
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

struct OutingDraft: Equatable, Hashable {
    var date = Date()
    var departureTime = Date()
    var returnTime = Date().addingTimeInterval(30 * 60)
    var reason = ""
    var teacher: OutingTeacher?

    nonisolated func normalizedToSelectedDate() -> OutingDraft {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        var normalized = self
        normalized.date = day
        let departure = calendar.dateComponents([.hour, .minute], from: departureTime)
        let returnTime = calendar.dateComponents([.hour, .minute], from: returnTime)
        normalized.departureTime = calendar.date(
            bySettingHour: departure.hour ?? 8,
            minute: departure.minute ?? 40,
            second: 0,
            of: day
        ) ?? day
        normalized.returnTime = calendar.date(
            bySettingHour: returnTime.hour ?? 9,
            minute: returnTime.minute ?? 10,
            second: 0,
            of: day
        ) ?? day
        return normalized
    }

}

enum OutingApplicationPeriod {
    static func weekRange(referenceDate: Date = Date(), calendar: Calendar = .current) -> ClosedRange<Date> {
        let start = calendar.startOfDay(for: referenceDate)
        let weekday = calendar.component(.weekday, from: start)
        let daysUntilSaturday = 7 - weekday
        let end = calendar.date(byAdding: .day, value: daysUntilSaturday, to: start) ?? start
        return start...end
    }

    static func contains(_ date: Date, referenceDate: Date = Date(), calendar: Calendar = .current) -> Bool {
        if calendar.isDate(date, inSameDayAs: referenceDate) {
            return true
        }
        return weekRange(referenceDate: referenceDate, calendar: calendar).contains(calendar.startOfDay(for: date))
    }
}
