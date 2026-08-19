import Combine
import Foundation

@MainActor
final class TeacherLabOverviewViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded([TeacherLabRoomStatus])
        case failed
    }

    @Published private(set) var state: State = .loading
    @Published var selectedFloor: LabFloor = .fourth
    @Published var selectedDate: Date

    private let fetchOverview: FetchTeacherLabOverviewUseCase

    init(fetchOverview: FetchTeacherLabOverviewUseCase, selectedDate: Date = Date()) {
        self.fetchOverview = fetchOverview
        self.selectedDate = selectedDate
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await fetchOverview.execute(for: selectedFloor, date: selectedDate))
        } catch {
            state = .failed
        }
    }

    func selectFloor(_ floor: LabFloor) async {
        selectedFloor = floor
        await load()
    }
}
