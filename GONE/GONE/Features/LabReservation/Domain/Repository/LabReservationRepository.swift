import Foundation

protocol LabReservationRepository {
    func fetchRooms(for floor: LabFloor) async throws -> [LabRoom]
    func fetchCurrentReservation() async throws -> LabReservation?
    func submit(_ draft: LabReservationDraft) async throws -> LabReservation
}
