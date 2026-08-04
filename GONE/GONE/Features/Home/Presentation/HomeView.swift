import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("홈 정보를 불러오는 중")
            case .loaded(let dashboard):
                dashboardContent(dashboard)
            case .failed:
                ContentUnavailableView {
                    Label("홈 정보를 불러올 수 없어요", systemImage: "wifi.exclamationmark")
                } description: {
                    Text("잠시 후 다시 시도해 주세요.")
                } actions: {
                    Button("다시 시도") { Task { await viewModel.load() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .task { await viewModel.load() }
    }

    private func dashboardContent(_ dashboard: HomeDashboard) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: GONESpacing.large) {
                header(for: dashboard.profile)
                ProfileSummaryCard(profile: dashboard.profile)
                TodayScheduleCard(schedule: dashboard.schedule, meal: dashboard.meal)
                RequestStatusSection(requests: dashboard.requests)
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .background(Color.goneHomeBackground.ignoresSafeArea())
        .accessibilityIdentifier("home.scrollView")
    }

    private func header(for profile: StudentProfile) -> some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text("7월 20일 월요일")
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(Color.goneTextSecondary)
            Text("안녕하세요, \(profile.name)님")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.goneTextPrimary)
                .accessibilityLabel("안녕하세요, \(profile.name)님")
        }
    }
}

private struct ProfileSummaryCard: View {
    let profile: StudentProfile

    var body: some View {
        HomeCard {
            VStack(alignment: .leading, spacing: GONESpacing.large) {
                HStack(spacing: 7) {
                    Text(profile.department)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color.goneTextPrimary)
                    Text(profile.studentInfo)
                        .font(.caption)
                        .foregroundStyle(Color.goneTextSecondary)
                }
                HStack(spacing: 0) {
                    ScoreView(title: "상점", value: "+\(profile.rewardPoints)", color: .goneBrandPrimary)
                    ScoreView(title: "벌점", value: "-\(profile.penaltyPoints)", color: .gonePenalty)
                    ScoreView(title: "현재 점수", value: "+\(profile.totalPoints)점", color: .goneTextPrimary)
                }
                Divider()
                VStack(alignment: .leading, spacing: GONESpacing.small) {
                    Text("내 역할")
                        .font(.caption)
                        .foregroundStyle(Color.goneTextSecondary)
                    Text(profile.roles.joined(separator: " · "))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.goneTextPrimary)
                }
            }
        }
    }
}

private struct ScoreView: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.xSmall) {
            Text(title).font(.caption2).foregroundStyle(Color.goneTextSecondary)
            Text(value).font(.headline).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct TodayScheduleCard: View {
    let schedule: [ClassSchedule]
    let meal: Meal

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.medium) {
            Text("학교생활")
                .font(.headline)
                .foregroundStyle(Color.goneTextPrimary)
            SchedulePager(schedule: schedule)
            MealCard(meal: meal)
        }
    }
}

private struct SchedulePager: View {
    let schedule: [ClassSchedule]
    @State private var selectedPeriod = 0

    var body: some View {
        TabView(selection: $selectedPeriod) {
            ForEach(Array(schedule.enumerated()), id: \.element.id) { index, item in
                HomeCard {
                    VStack(spacing: GONESpacing.large) {
                        HStack(spacing: GONESpacing.large) {
                            Text("\(item.period)")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.goneBrandPrimary)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: GONESpacing.xSmall) {
                                Text(item.subject).font(.headline).foregroundStyle(Color.goneTextPrimary)
                                Text(item.location).font(.subheadline).foregroundStyle(Color.goneTextSecondary)
                            }
                            Spacer()
                            Text(item.time).font(.caption).foregroundStyle(Color.goneTextSecondary)
                        }
                        Divider()
                        HStack {
                            Text(nextLabel(after: index)).font(.caption).foregroundStyle(Color.goneTextSecondary)
                            Text(nextTitle(after: index)).font(.caption.weight(.semibold)).foregroundStyle(Color.goneTextPrimary)
                            Spacer()
                            Text(nextLocation(after: index)).font(.caption).foregroundStyle(Color.goneTextSecondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                .tag(index)
            }
        }
        .frame(height: 142)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .accessibilityLabel("오늘 시간표. 좌우로 넘겨 다음 교시를 확인하세요.")
    }

    private func nextLabel(after index: Int) -> String { index == schedule.count - 1 ? "마지막" : "다음" }
    private func nextTitle(after index: Int) -> String { index == schedule.count - 1 ? "오늘 수업 종료" : "\(schedule[index + 1].period)교시 · \(schedule[index + 1].subject)" }
    private func nextLocation(after index: Int) -> String { index == schedule.count - 1 ? "수고했어요" : schedule[index + 1].location }
}

private struct MealCard: View {
    let meal: Meal

    var body: some View {
        HomeCard {
            VStack(alignment: .leading, spacing: GONESpacing.medium) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: GONESpacing.xSmall) {
                        Text(meal.title).font(.caption).foregroundStyle(Color.goneTextSecondary)
                        Text("점심").font(.title3.weight(.bold)).foregroundStyle(Color.goneTextPrimary)
                    }
                    Spacer()
                    Text(meal.servingTime).font(.caption).foregroundStyle(Color.goneTextSecondary)
                }
                HStack(alignment: .top, spacing: GONESpacing.xLarge) {
                    MealMenuColumn(items: meal.leftMenu)
                    MealMenuColumn(items: meal.rightMenu)
                }
                Text(meal.calories).font(.caption).foregroundStyle(Color.goneTextSecondary)
            }
        }
    }
}

private struct MealMenuColumn: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { Text($0).font(.footnote).foregroundStyle(Color.goneTextPrimary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RequestStatusSection: View {
    let requests: [DashboardRequest]

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.medium) {
            Text("신청현황").font(.headline).foregroundStyle(Color.goneTextPrimary)
            ForEach(requests) { request in
                HomeCard {
                    HStack(spacing: GONESpacing.medium) {
                        Image(request.kind.illustrationAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 34, height: 34)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(request.kind.rawValue).font(.subheadline.weight(.semibold)).foregroundStyle(Color.goneTextPrimary)
                            Text(request.detail).font(.caption).foregroundStyle(Color.goneTextSecondary)
                        }
                        Spacer(minLength: 8)
                        Text(request.status.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(statusColor(for: request.status))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.goneTextSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func statusColor(for status: DashboardRequest.Status) -> Color {
        switch status {
        case .completed, .reserved: .goneBrandPrimary
        case .pending: .orange
        }
    }
}

private struct HomeCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(GONESpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

private extension Color {
    static let goneHomeBackground = Color(red: 242 / 255, green: 244 / 255, blue: 247 / 255)
    static let gonePenalty = Color(red: 167 / 255, green: 71 / 255, blue: 61 / 255)
}

#Preview {
    AppTabView()
}
