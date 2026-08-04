import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded(HomeDashboard)
        case failed
    }

    @Published private(set) var state: State = .loading

    private let fetchDashboard: FetchHomeDashboardUseCase

    init(fetchDashboard: FetchHomeDashboardUseCase) {
        self.fetchDashboard = fetchDashboard
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await fetchDashboard.execute())
        } catch {
            state = .failed
        }
    }
}
