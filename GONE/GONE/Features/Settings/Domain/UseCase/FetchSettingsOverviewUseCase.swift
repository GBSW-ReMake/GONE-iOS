import Foundation

struct FetchSettingsOverviewUseCase {
    private let repository: SettingsRepository

    init(repository: SettingsRepository) {
        self.repository = repository
    }

    func execute() async throws -> SettingsOverview {
        try await repository.fetchOverview()
    }
}
