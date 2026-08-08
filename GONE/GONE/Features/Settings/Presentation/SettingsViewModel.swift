import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded(SettingsOverview)
        case failed
    }

    @Published private(set) var state: State = .loading

    private let fetchOverview: FetchSettingsOverviewUseCase

    init(fetchOverview: FetchSettingsOverviewUseCase) {
        self.fetchOverview = fetchOverview
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await fetchOverview.execute())
        } catch {
            state = .failed
        }
    }
}
