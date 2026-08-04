import Foundation

struct FetchHomeDashboardUseCase {
    private let repository: HomeDashboardRepository

    init(repository: HomeDashboardRepository) {
        self.repository = repository
    }

    func execute() async throws -> HomeDashboard {
        try await repository.fetchDashboard()
    }
}
