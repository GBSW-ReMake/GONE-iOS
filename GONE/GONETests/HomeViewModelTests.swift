import XCTest
@testable import GONE

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testLoadPublishesDashboardOnSuccess() async {
        let dashboard = makeDashboard()
        let viewModel = HomeViewModel(
            fetchDashboard: FetchHomeDashboardUseCase(repository: StubHomeDashboardRepository(result: .success(dashboard)))
        )

        await viewModel.load()

        guard case .loaded(let loadedDashboard) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertEqual(loadedDashboard.profile.name, "김은찬")
        XCTAssertEqual(loadedDashboard.schedule.count, 1)
    }

    func testLoadPublishesFailureOnRepositoryError() async {
        let viewModel = HomeViewModel(
            fetchDashboard: FetchHomeDashboardUseCase(repository: StubHomeDashboardRepository(result: .failure(TestError.failed)))
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed)
    }

    private func makeDashboard() -> HomeDashboard {
        HomeDashboard(
            profile: StudentProfile(name: "김은찬", department: "소프트웨어개발과", studentInfo: "2학년 2반 · 6번", rewardPoints: 15, penaltyPoints: 3, roles: []),
            schedule: [ClassSchedule(period: 1, subject: "자료구조", location: "소프트웨어 1실", time: "08:40–09:30")],
            meals: [Meal(mealName: "점심", calories: "785 kcal", title: "오늘의 급식", servingTime: "12:20–13:20", leftMenu: [], rightMenu: [])],
            requests: []
        )
    }
}

private struct StubHomeDashboardRepository: HomeDashboardRepository {
    let result: Result<HomeDashboard, Error>

    func fetchDashboard() async throws -> HomeDashboard {
        try result.get()
    }
}

private enum TestError: Error {
    case failed
}
