import SwiftUI

struct NotificationView: View {
    @StateObject private var viewModel: NotificationViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: NotificationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("알림을 불러오는 중")
            case .loaded(let notifications):
                notificationList(notifications)
            case .failed:
                ContentUnavailableView {
                    Label("알림을 불러올 수 없어요", systemImage: "bell.slash")
                } description: {
                    Text("잠시 후 다시 시도해 주세요.")
                } actions: {
                    Button("다시 시도") { Task { await viewModel.load() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(Color.goneTextPrimary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("뒤로 가기")
            }
            ToolbarItem(placement: .principal) {
                Text("알림")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.goneTextPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("모두 읽음") { Task { await viewModel.markAllAsRead() } }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(viewModel.unreadCount > 0 ? Color.goneBrandPrimary : Color.goneTextSecondary)
                    .disabled(viewModel.unreadCount == 0 || viewModel.isMarkingAllAsRead)
                    .accessibilityLabel("모든 알림 읽음 처리")
            }
        }
        .task { await viewModel.load() }
    }

    private func notificationList(_ notifications: [AppNotification]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                ForEach(AppNotification.DaySection.allCases) { section in
                    let items = notifications.filter { $0.daySection == section }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(section.rawValue)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color.goneTextPrimary)
                            ForEach(items) { notification in
                                NotificationRow(notification: notification)
                            }
                        }
                    }
                }
                if notifications.isEmpty {
                    ContentUnavailableView("새로운 알림이 없어요", systemImage: "bell")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.large)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .accessibilityIdentifier("notifications.scrollView")
    }
}

private struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: GONESpacing.medium) {
            Image(notification.kind.illustrationAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(notification.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.goneTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(notification.message)
                    .font(.footnote)
                    .foregroundStyle(Color.goneTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Text(notification.relativeTime)
                .font(.caption)
                .foregroundStyle(notification.isRead ? Color.goneTextSecondary : Color.goneBrandPrimary)
                .fixedSize()
        }
        .opacity(notification.isRead ? 0.82 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(notification.title). \(notification.message). \(notification.relativeTime)")
    }
}
