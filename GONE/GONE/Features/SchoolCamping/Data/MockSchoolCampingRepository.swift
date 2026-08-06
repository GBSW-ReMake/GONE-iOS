import Foundation

actor MockSchoolCampingRepository: SchoolCampingRepository {
    private var currentReservation: SchoolCampingReservation?
    private let calendar = Calendar.current

    func fetchCalendarDays(for month: Date) async throws -> [CampingCalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }

        return calendar.dates(in: monthInterval).map { date in
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

    func submit(_ draft: SchoolCampingReservationDraft) async throws -> SchoolCampingReservation {
        let reservation = SchoolCampingReservation(
            id: "C-\(Self.identifierDateFormatter.string(from: draft.date))",
            date: draft.date,
            teacherName: draft.teacherName,
            participants: draft.participants,
            status: .submitted
        )
        currentReservation = reservation
        return reservation
    }

    func cancel(_ reservation: SchoolCampingReservation) async throws {
        guard currentReservation?.id == reservation.id else { return }
        currentReservation = nil
    }

    private static let identifierDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMdd"
        return formatter
    }()
}

private extension Calendar {
    func dates(in interval: DateInterval) -> [Date] {
        var dates: [Date] = []
        var date = startOfDay(for: interval.start)

        while date < interval.end {
            dates.append(date)
            guard let nextDate = self.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }
        return dates
    }
}
