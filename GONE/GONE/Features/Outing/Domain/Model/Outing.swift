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
    static let earliestMinute = 8 * 60 + 40
    static let latestMinute = 20 * 60 + 30

    var date = Date()
    var departureTime = Date()
    var returnTime = Date().addingTimeInterval(30 * 60)
    var reason = ""
    var teacher: OutingTeacher?

    nonisolated var validationMessage: String? {
        guard minute(of: departureTime) >= Self.earliestMinute,
              minute(of: returnTime) <= Self.latestMinute else {
            return "외출 가능 시간은 오전 8:40부터 오후 8:30까지예요."
        }
        guard returnTime > departureTime else { return "복귀 시간은 출발 시간 이후로 설정해 주세요." }
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "외출 사유를 입력해 주세요." }
        guard teacher != nil else { return "담당 선생님을 선택해 주세요." }
        return nil
    }

    nonisolated var isValid: Bool { validationMessage == nil }

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

    nonisolated private func minute(of date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
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
