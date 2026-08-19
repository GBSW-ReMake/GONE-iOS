import XCTest
@testable import GONE

@MainActor
final class NotificationViewModelTests: XCTestCase {
    func testStudentLoadsStudentNotifications() async {
        let notifications = [makeNotification(id: "student")]
        let viewModel = makeViewModel(fetchResult: .success(notifications))

        await viewModel.load()

        XCTAssertEqual(viewModel.unreadCount, 1)
        XCTAssertEqual(viewModel.state, .loaded(notifications))
    }

    func testMarkAllAsReadUpdatesLoadedNotifications() async {
        let notifications = [makeNotification(id: "one"), makeNotification(id: "two", isRead: true)]
        let viewModel = makeViewModel(fetchResult: .success(notifications))
        await viewModel.load()

        await viewModel.markAllAsRead()

        XCTAssertEqual(viewModel.unreadCount, 0)
        guard case .loaded(let loaded) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertTrue(loaded.allSatisfy(\.isRead))
    }

    func testLoadPublishesFailureOnRepositoryError() async {
        let viewModel = makeViewModel(fetchResult: .failure(NotificationTestError.failed))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed)
    }

    private func makeViewModel(fetchResult: Result<[AppNotification], Error>) -> NotificationViewModel {
        let repository = StubNotificationRepository(fetchResult: fetchResult)
        return NotificationViewModel(
            role: .student,
            fetchNotifications: FetchNotificationsUseCase(repository: repository),
            markAllNotificationsRead: MarkAllNotificationsReadUseCase(repository: repository)
        )
    }

    private func makeNotification(id: String, isRead: Bool = false) -> AppNotification {
        AppNotification(
            id: id,
            kind: .camping,
            title: "알림 제목",
            message: "알림 내용",
            date: .now,
            relativeTime: "방금 전",
            isRead: isRead
        )
    }
}

private struct StubNotificationRepository: NotificationRepository {
    let fetchResult: Result<[AppNotification], Error>

    func fetchNotifications(for role: AccountRole) async throws -> [AppNotification] {
        try fetchResult.get()
    }

    func markAllAsRead(for role: AccountRole) async throws { }
}

private enum NotificationTestError: Error {
    case failed
}
