import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    private let onActivityTap: (RecentActivity.Kind) -> Void
    @State private var selectedMenuTitle: String?
    @State private var isShowingLogoutConfirmation = false

    init(
        viewModel: SettingsViewModel,
        onActivityTap: @escaping (RecentActivity.Kind) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onActivityTap = onActivityTap
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("설정 정보를 불러오는 중")
            case .loaded(let overview):
                content(overview)
            case .failed:
                ContentUnavailableView {
                    Label("설정 정보를 불러올 수 없어요", systemImage: "wifi.exclamationmark")
                } description: {
                    Text("잠시 후 다시 시도해 주세요.")
                } actions: {
                    Button("다시 시도") { Task { await viewModel.load() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .background(Color.goneScreenBackground.ignoresSafeArea())
        .task { await viewModel.load() }
        .alert("준비 중인 기능", isPresented: Binding(
            get: { selectedMenuTitle != nil },
            set: { if !$0 { selectedMenuTitle = nil } }
        )) {
            Button("확인", role: .cancel) { selectedMenuTitle = nil }
        } message: {
            Text("\(selectedMenuTitle ?? "이 기능")은(는) 실제 연동 후 제공됩니다.")
        }
        .confirmationDialog(
            "로그아웃하시겠어요?",
            isPresented: $isShowingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("로그아웃", role: .destructive) { }
            Button("취소", role: .cancel) { }
        } message: {
            Text("현재는 UI 확인 단계라 실제로 로그아웃되지 않습니다.")
        }
    }

    private func content(_ overview: SettingsOverview) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.section) {
                header
                profileCard(overview.profile)
                settingsMenu
                recentActivitySection(overview.activities)
                Button(role: .destructive) {
                    isShowingLogoutConfirmation = true
                } label: {
                    Text("로그아웃")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.goneStatusError)
                .accessibilityHint("로그아웃 확인 대화상자를 엽니다")
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .accessibilityIdentifier("settings.scrollView")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text("설정")
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(Color.goneTextSecondary)
            Text("계정 및 활동")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.goneTextPrimary)
        }
    }

    private func profileCard(_ profile: SettingsProfile) -> some View {
        SettingsCard {
            HStack(spacing: GONESpacing.medium) {
                Text(profile.initial)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 62, height: 62)
                    .background(Color.goneTextPrimary, in: Circle())
                    .accessibilityLabel("\(profile.name) 프로필")
                VStack(alignment: .leading, spacing: GONESpacing.xSmall) {
                    Text(profile.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.goneTextPrimary)
                    Text("\(profile.department) · \(profile.studentInfo)")
                        .font(.caption)
                        .foregroundStyle(Color.goneTextSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                Text("인증됨")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.goneBrandPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.goneBrandPrimary.opacity(0.12), in: Capsule())
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var settingsMenu: some View {
        SettingsCard {
            VStack(spacing: 0) {
                settingsMenuRow(title: "알림 설정", systemImage: "bell")
                Divider()
                settingsMenuRow(title: "문의하기", systemImage: "questionmark.bubble")
            }
        }
    }

    private func settingsMenuRow(title: String, systemImage: String) -> some View {
        Button {
            selectedMenuTitle = title
        } label: {
            HStack(spacing: GONESpacing.medium) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.goneTextSecondary)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.goneTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.goneTextSecondary)
            }
            .frame(minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("\(title) 안내를 표시합니다")
    }

    private func recentActivitySection(_ activities: [RecentActivity]) -> some View {
        VStack(alignment: .leading, spacing: GONESpacing.medium) {
            Text("최근 활동")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.goneTextPrimary)

            if activities.isEmpty {
                SettingsCard {
                    HStack(spacing: GONESpacing.small) {
                        Image(systemName: "clock")
                            .font(.footnote)
                        Text("최근 예약·신청 활동이 없어요")
                            .font(.footnote)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(Color.goneTextSecondary)
                    .frame(minHeight: 44)
                }
            } else {
                SettingsCard {
                    VStack(spacing: 0) {
                        ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                            activityRow(activity)
                            if index < activities.count - 1 { Divider() }
                        }
                    }
                }
            }
        }
    }

    private func activityRow(_ activity: RecentActivity) -> some View {
        Button {
            onActivityTap(activity.kind)
        } label: {
            HStack(spacing: GONESpacing.medium) {
                Image(systemName: activity.kind.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.goneBrandPrimary)
                    .frame(width: 26, height: 26)
                    .background(Color.goneBrandPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.kind.rawValue)
                        .font(.caption)
                        .foregroundStyle(Color.goneTextSecondary)
                    Text(activity.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.goneTextPrimary)
                    Text(activity.dateText)
                        .font(.caption2)
                        .foregroundStyle(Color.goneTextSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: GONESpacing.small) {
                    Text(activity.status.rawValue)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(statusColor(activity.status))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(statusColor(activity.status).opacity(0.12), in: Capsule())
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.goneTextTertiary)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(activity.kind.rawValue), \(activity.title), \(activity.dateText), \(activity.status.rawValue)")
        .accessibilityHint("해당 기능 탭으로 이동합니다")
    }

    private func statusColor(_ status: RecentActivity.Status) -> Color {
        switch status {
        case .pending: .goneStatusOuting
        case .completed, .reserved: .goneBrandPrimary
        case .cancelled: .goneTextSecondary
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(GONESpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel(fetchOverview: FetchSettingsOverviewUseCase(repository: MockSettingsRepository())))
}
