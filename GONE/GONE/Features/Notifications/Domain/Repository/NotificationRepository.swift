import Foundation

protocol NotificationRepository {
    func fetchNotifications(for role: AccountRole) async throws -> [AppNotification]
    func markAllAsRead(for role: AccountRole) async throws
}
