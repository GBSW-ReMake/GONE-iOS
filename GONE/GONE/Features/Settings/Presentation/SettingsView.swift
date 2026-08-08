import SwiftUI

struct SettingsView: View {
    private enum ActivityFilter: String, CaseIterable, Identifiable {
        case all = "전체"
        case lab = "실습실"
        case outing = "외출"
        case schoolCamping = "스쿨캠핑"

        var id: String { rawValue }

        func includes(_ activity: RecentActivity) -> Bool {
            switch self {
            case .all: true
            case .lab: activity.kind == .lab
            case .outing: activity.kind == .outing
            case .schoolCamping: activity.kind == .schoolCamping
            }
        }
    }

    @StateObject private var viewModel: SettingsViewModel
    private let onActivityTap: (RecentActivity.Kind) -> Void
    @State private var selectedMenuTitle: String?
    @State private var isShowingLogoutConfirmation = false
    @State private var activityFilter: ActivityFilter = .all

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
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
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
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var settingsMenu: some View {
        VStack(spacing: GONESpacing.medium) {
            SettingsCard(verticalPadding: GONESpacing.small) {
                settingsMenuRow(title: "알림 설정", systemImage: "bell")
            }
            SettingsCard(verticalPadding: GONESpacing.small) {
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
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("\(title) 안내를 표시합니다")
    }

    private func recentActivitySection(_ activities: [RecentActivity]) -> some View {
        let filteredActivities = activities.filter(activityFilter.includes)

        return VStack(alignment: .leading, spacing: GONESpacing.medium) {
            Text("최근 활동")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.goneTextPrimary)

            activityFilters

            if filteredActivities.isEmpty {
                SettingsCard(verticalPadding: GONESpacing.small) {
                    HStack(spacing: GONESpacing.small) {
                        Image(systemName: "clock")
                            .font(.footnote)
                        Text("최근 \(activityFilter.rawValue) 활동이 없어요")
                            .font(.footnote)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(Color.goneTextSecondary)
                    .frame(minHeight: 44)
                }
            } else {
                VStack(spacing: GONESpacing.small) {
                    ForEach(filteredActivities) { activity in
                        SettingsCard(verticalPadding: GONESpacing.small) {
                            activityRow(activity)
                        }
                    }
                }
            }
        }
    }

    private var activityFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GONESpacing.small) {
                ForEach(ActivityFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activityFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(activityFilter == filter ? .white : Color.goneTextSecondary)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 44)
                            .background(
                                activityFilter == filter ? Color.goneBrandPrimary : Color.goneSurfacePrimary,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(activityFilter == filter ? .clear : Color.goneBorderDefault)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(activityFilter == filter ? .isSelected : [])
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
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.goneTextTertiary)
            }
            .padding(.vertical, GONESpacing.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(activity.kind.rawValue), \(activity.title), \(activity.dateText)")
        .accessibilityHint("해당 기능 탭으로 이동합니다")
    }

}

private struct SettingsCard<Content: View>: View {
    private let verticalPadding: CGFloat
    private let content: Content

    init(
        verticalPadding: CGFloat = GONESpacing.large,
        @ViewBuilder content: () -> Content
    ) {
        self.verticalPadding = verticalPadding
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, GONESpacing.large)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel(fetchOverview: FetchSettingsOverviewUseCase(repository: MockSettingsRepository())))
}
