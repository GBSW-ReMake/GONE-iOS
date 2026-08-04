import Foundation

protocol HomeDashboardRepository {
    func fetchDashboard() async throws -> HomeDashboard
}
