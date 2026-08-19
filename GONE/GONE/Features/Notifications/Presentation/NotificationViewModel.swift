import Combine
import Foundation

@MainActor
final class NotificationViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded([AppNotification])
        case failed
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var isMarkingAllAsRead = false

    private let role: AccountRole
    private let fetchNotifications: FetchNotificationsUseCase
    private let markAllNotificationsRead: MarkAllNotificationsReadUseCase

    init(
        role: AccountRole,
        fetchNotifications: FetchNotificationsUseCase,
        markAllNotificationsRead: MarkAllNotificationsReadUseCase
    ) {
        self.role = role
        self.fetchNotifications = fetchNotifications
        self.markAllNotificationsRead = markAllNotificationsRead
    }

    var unreadCount: Int {
        guard case .loaded(let notifications) = state else { return 0 }
        return notifications.filter { !$0.isRead }.count
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await fetchNotifications.execute(for: role))
        } catch {
            state = .failed
        }
    }

    func markAllAsRead() async {
        guard unreadCount > 0, !isMarkingAllAsRead else { return }
        isMarkingAllAsRead = true
        defer { isMarkingAllAsRead = false }
        do {
            try await markAllNotificationsRead.execute(for: role)
            if case .loaded(let notifications) = state {
                state = .loaded(notifications.map { notification in
                    var updated = notification
                    updated.isRead = true
                    return updated
                })
            }
        } catch { }
    }
}
