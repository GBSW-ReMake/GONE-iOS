import Foundation

struct FetchNotificationsUseCase {
    let repository: NotificationRepository

    func execute(for role: AccountRole) async throws -> [AppNotification] {
        try await repository.fetchNotifications(for: role)
    }
}
