import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded(HomeDashboard)
        case failed
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var displayedAcademicMonth: Date
    @Published private(set) var isRefreshing = false

    private let fetchDashboard: FetchHomeDashboardUseCase
    private let calendar: Calendar

    init(
        fetchDashboard: FetchHomeDashboardUseCase,
        displayedAcademicMonth: Date = Date(),
        calendar: Calendar = .current
    ) {
        self.fetchDashboard = fetchDashboard
        self.calendar = calendar
        self.displayedAcademicMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: displayedAcademicMonth)
        ) ?? displayedAcademicMonth
    }

    func load() async {
        guard case .loaded = state else {
            await fetchDashboard(showLoading: true)
            return
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await fetchDashboard(showLoading: false)
    }

    private func fetchDashboard(showLoading: Bool) async {
        if showLoading {
            state = .loading
        }
        do {
            state = .loaded(try await fetchDashboard.execute())
        } catch {
            state = .failed
        }
    }

    func moveAcademicMonth(by value: Int) {
        guard let month = calendar.date(byAdding: .month, value: value, to: displayedAcademicMonth) else { return }
        displayedAcademicMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: month)
        ) ?? month
    }
}
