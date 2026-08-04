import Foundation

@MainActor
final class LabReservationViewModel: ObservableObject {
    enum State: Equatable { case loading, loaded, failed }

    @Published private(set) var state: State = .loading
    @Published var selectedFloor: LabFloor = .fourth
    @Published private(set) var rooms: [LabRoom] = []
    @Published var selectedRoom: LabRoom?
    @Published private(set) var reservation: LabReservation?

    private let repository: LabReservationRepository

    init(repository: LabReservationRepository) { self.repository = repository }

    func load() async {
        state = .loading
        do {
            rooms = try await repository.fetchRooms(for: selectedFloor)
            reservation = try await repository.fetchCurrentReservation()
            selectedRoom = nil
            state = .loaded
        } catch { state = .failed }
    }

    func selectFloor(_ floor: LabFloor) { selectedFloor = floor }

    func submit(_ draft: LabReservationDraft) async {
        do { reservation = try await repository.submit(draft) } catch { state = .failed }
    }
}
