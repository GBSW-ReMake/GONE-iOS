import Foundation

protocol SchoolCampingRepository {
    func fetchCalendarDays(for month: Date) async throws -> [CampingCalendarDay]
    func fetchCurrentReservation() async throws -> SchoolCampingReservation?
    func submit(_ draft: SchoolCampingReservationDraft) async throws -> SchoolCampingReservation
    func cancel(_ reservation: SchoolCampingReservation) async throws
}
