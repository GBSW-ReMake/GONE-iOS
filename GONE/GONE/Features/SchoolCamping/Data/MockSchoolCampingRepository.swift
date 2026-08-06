import Foundation

@MainActor
final class MockSchoolCampingRepository: SchoolCampingRepository {
    private var currentReservation: SchoolCampingReservation?
    private let calendar = Calendar.current

    func fetchCalendarDays(for month: Date) async throws -> [CampingCalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }

        return dates(in: monthInterval).map { date in
            let availability: CampingDateAvailability
            if calendar.isDate(date, inSameDayAs: currentReservation?.date ?? .distantPast) {
                availability = .reservedByMe
            } else if calendar.isDateInWeekend(date) {
                availability = .unavailable
            } else {
                availability = .available
            }
            return CampingCalendarDay(date: date, availability: availability)
        }
    }

    func fetchCurrentReservation() async throws -> SchoolCampingReservation? {
        currentReservation
    }

    func searchStudents(query: String) async throws -> [CampingStudent] {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return students }
        return students.filter {
            $0.studentNumber.localizedCaseInsensitiveContains(keyword)
                || $0.name.localizedCaseInsensitiveContains(keyword)
        }
    }

    func searchTeachers(query: String) async throws -> [CampingTeacher] {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return teachers }
        return teachers.filter { $0.name.localizedCaseInsensitiveContains(keyword) }
    }

    func submit(_ draft: SchoolCampingReservationDraft) async throws -> SchoolCampingReservation {
        let reservation = SchoolCampingReservation(
            id: "C-\(reservationIdentifier(for: draft.date))",
            date: draft.date,
            teacherName: draft.teacherName,
            participants: draft.participants,
            status: .submitted
        )
        currentReservation = reservation
        return reservation
    }

    func update(_ draft: SchoolCampingReservationDraft) async throws -> SchoolCampingReservation {
        guard let currentReservation else {
            return try await submit(draft)
        }

        currentReservation.apply(draft)
        return currentReservation
    }

    func cancel(_ reservation: SchoolCampingReservation) async throws {
        guard currentReservation?.id == reservation.id else { return }
        currentReservation = nil
    }

    private func reservationIdentifier(for date: Date) -> String {
        let components = calendar.dateComponents([.month, .day], from: date)
        return String(format: "%02d%02d", components.month ?? 0, components.day ?? 0)
    }

    private func dates(in interval: DateInterval) -> [Date] {
        var dates: [Date] = []
        var date = calendar.startOfDay(for: interval.start)

        while date < interval.end {
            dates.append(date)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }
        return dates
    }

    private let students: [CampingStudent] = [
        CampingStudent(studentNumber: "3206", name: "김은찬"),
        CampingStudent(studentNumber: "3201", name: "김민준"),
        CampingStudent(studentNumber: "3202", name: "박서연"),
        CampingStudent(studentNumber: "3203", name: "이도윤"),
        CampingStudent(studentNumber: "3204", name: "최유진"),
        CampingStudent(studentNumber: "3205", name: "한지민")
    ]

    private let teachers: [CampingTeacher] = [
        CampingTeacher(id: "teacher-1", name: "박00 선생님"),
        CampingTeacher(id: "teacher-2", name: "김00 선생님"),
        CampingTeacher(id: "teacher-3", name: "이00 선생님")
    ]
}
