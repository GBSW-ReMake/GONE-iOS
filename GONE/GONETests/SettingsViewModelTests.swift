import XCTest
@testable import GONE

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testLoadPublishesOverviewOnSuccess() async {
        let overview = SettingsOverview(
            profile: SettingsProfile(name: "김은찬", department: "소프트웨어개발과", studentInfo: "2학년 2반 · 6번"),
            activities: [RecentActivity(id: "activity", kind: .outing, title: "외출 신청", dateText: "8월 8일", status: .pending)]
        )
        let viewModel = SettingsViewModel(
            fetchOverview: FetchSettingsOverviewUseCase(repository: StubSettingsRepository(result: .success(overview)))
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded(overview))
    }

    func testLoadPublishesFailureOnRepositoryError() async {
        let viewModel = SettingsViewModel(
            fetchOverview: FetchSettingsOverviewUseCase(repository: StubSettingsRepository(result: .failure(TestError.failed)))
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed)
    }
}

private struct StubSettingsRepository: SettingsRepository {
    let result: Result<SettingsOverview, Error>

    func fetchOverview() async throws -> SettingsOverview {
        try result.get()
    }
}

private enum TestError: Error {
    case failed
}
