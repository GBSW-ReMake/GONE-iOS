import Foundation

protocol SettingsRepository {
    func fetchOverview() async throws -> SettingsOverview
}
