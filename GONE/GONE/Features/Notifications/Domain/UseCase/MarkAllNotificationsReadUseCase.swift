import Foundation

struct MarkAllNotificationsReadUseCase {
    let repository: NotificationRepository

    func execute(for role: AccountRole) async throws {
        try await repository.markAllAsRead(for: role)
    }
}
