import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    private let labReservation: LabReservation?
    private let outings: [OutingRequest]
    private let schoolCampingReservation: SchoolCampingReservation?
    private let onLabRequestTap: () -> Void
    private let onOutingRequestTap: () -> Void
    private let onSchoolCampingRequestTap: () -> Void

    init(
        viewModel: HomeViewModel,
        labReservation: LabReservation? = nil,
        outings: [OutingRequest] = [],
        schoolCampingReservation: SchoolCampingReservation? = nil,
        onLabRequestTap: @escaping () -> Void = {},
        onOutingRequestTap: @escaping () -> Void = {},
        onSchoolCampingRequestTap: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.labReservation = labReservation
        self.outings = outings
        self.schoolCampingReservation = schoolCampingReservation
        self.onLabRequestTap = onLabRequestTap
        self.onOutingRequestTap = onOutingRequestTap
        self.onSchoolCampingRequestTap = onSchoolCampingRequestTap
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
            LazyVStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                header(for: dashboard.profile)
                ProfileSummaryCard(profile: dashboard.profile)
                TodayScheduleCard(schedule: dashboard.schedule, meals: dashboard.meals)
                AcademicScheduleSection(
                    schedules: dashboard.academicSchedules,
                    displayedMonth: viewModel.displayedAcademicMonth,
                    onMoveMonth: viewModel.moveAcademicMonth
                )
                RequestStatusSection(
                    requests: dashboard.requests,
                    labReservation: labReservation,
                    outings: outings,
                    schoolCampingReservation: schoolCampingReservation,
                    onLabRequestTap: onLabRequestTap,
                    onOutingRequestTap: onOutingRequestTap,
                    onSchoolCampingRequestTap: onSchoolCampingRequestTap
                )
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
                    ScoreView(title: "벌점", value: "-\(profile.penaltyPoints)", color: .gonePenalty)
                    ScoreView(title: "현재 점수", value: "+\(profile.totalPoints)점", color: .goneTextPrimary)
                }
                Divider()
                HStack(alignment: .center, spacing: GONESpacing.medium) {
                    Text("내 역할")
                        .font(.footnote)
                        .foregroundStyle(Color.goneTextSecondary)
                    ForEach(Array(profile.roles.enumerated()), id: \.offset) { index, role in
                        Text(role)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(roleForegroundColor(at: index))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(roleBackgroundColor(at: index), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private func roleForegroundColor(at index: Int) -> Color {
        switch index {
        case 0: Color(red: 42 / 255, green: 100 / 255, blue: 73 / 255)
        case 1: Color(red: 58 / 255, green: 93 / 255, blue: 147 / 255)
        default: Color(red: 89 / 255, green: 99 / 255, blue: 94 / 255)
        }
    }

    private func roleBackgroundColor(at index: Int) -> Color {
        switch index {
        case 0: Color(red: 229 / 255, green: 240 / 255, blue: 234 / 255)
        case 1: Color(red: 230 / 255, green: 237 / 255, blue: 249 / 255)
        default: Color(red: 241 / 255, green: 243 / 255, blue: 245 / 255)
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
    let meals: [Meal]

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.medium) {
            SchedulePager(schedule: schedule)
            MealPager(meals: meals)
        }
    }
}

private struct AcademicScheduleSection: View {
    let schedules: [AcademicSchedule]
    let displayedMonth: Date
    let onMoveMonth: (Int) -> Void

    private let calendar = Calendar.current

    private var monthlySchedules: [AcademicSchedule] {
        schedules
            .filter { calendar.isDate($0.date, equalTo: displayedMonth, toGranularity: .month) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.medium) {
            HStack(spacing: GONESpacing.small) {
                Text("학사일정")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.goneTextPrimary)
                Text(monthTitle)
                    .font(.caption)
                    .foregroundStyle(Color.goneTextSecondary)
                Spacer()
                monthButton(systemImage: "chevron.left", accessibilityLabel: "이전 달 학사일정") {
                    onMoveMonth(-1)
                }
                monthButton(systemImage: "chevron.right", accessibilityLabel: "다음 달 학사일정") {
                    onMoveMonth(1)
                }
            }

            if monthlySchedules.isEmpty {
                HomeCard {
                    ContentUnavailableView(
                        "등록된 학사일정이 없어요",
                        systemImage: "calendar",
                        description: Text("다른 달의 일정을 확인해 보세요.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, GONESpacing.small)
                }
            } else {
                VStack(spacing: GONESpacing.small) {
                    ForEach(monthlySchedules) { schedule in
                        HomeCard {
                            HStack(spacing: GONESpacing.medium) {
                                VStack(spacing: 2) {
                                    Text(dayFormatter.string(from: schedule.date))
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(Color.goneBrandPrimary)
                                    Text(weekdayFormatter.string(from: schedule.date))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.goneTextSecondary)
                                }
                                .frame(width: 42)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(schedule.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.goneTextPrimary)
                                    Text("학사일정")
                                        .font(.caption)
                                        .foregroundStyle(Color.goneTextSecondary)
                                }
                                Spacer()
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(monthTitle) 학사일정")
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: displayedMonth)
    }

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MM.dd"
        return formatter
    }

    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "EEE"
        return formatter
    }

    private func monthButton(
        systemImage: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.goneTextPrimary)
                .frame(width: 44, height: 44)
                .background(Color(.systemBackground), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct SchedulePager: View {
    let schedule: [ClassSchedule]
    @State private var selectedPeriod = 0
    @State private var movesForward = true

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            HStack {
                Text("오늘 시간표").font(.headline.weight(.bold)).foregroundStyle(Color.goneTextPrimary)
                Spacer()
                Text("\(selectedPeriod + 1) / \(schedule.count)").font(.caption).foregroundStyle(Color.goneTextSecondary)
            }
            if !schedule.isEmpty {
                let item = schedule[selectedPeriod]
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
                            Text(nextLabel(after: selectedPeriod)).font(.caption).foregroundStyle(Color.goneTextSecondary)
                            Text(nextTitle(after: selectedPeriod)).font(.caption.weight(.semibold)).foregroundStyle(Color.goneTextPrimary)
                            Spacer()
                            Text(nextLocation(after: selectedPeriod)).font(.caption).foregroundStyle(Color.goneTextSecondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .id(selectedPeriod)
                    .transition(cardTransition)
                    .highPriorityGesture(horizontalPagingGesture)
                }
            }
        }
        .animation(.snappy(duration: 0.28), value: selectedPeriod)
        .accessibilityLabel("오늘 시간표. 좌우로 넘겨 다음 교시를 확인하세요.")
    }

    private var horizontalPagingGesture: some Gesture {
        DragGesture(minimumDistance: 24).onEnded { value in
            if value.translation.width < -30, selectedPeriod < schedule.count - 1 {
                movesForward = true
                withAnimation(.snappy) { selectedPeriod += 1 }
            } else if value.translation.width > 30, selectedPeriod > 0 {
                movesForward = false
                withAnimation(.snappy) { selectedPeriod -= 1 }
            }
        }
    }

    private var cardTransition: AnyTransition {
        movesForward
            ? .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity))
            : .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity))
    }

    private func nextLabel(after index: Int) -> String { index == schedule.count - 1 ? "마지막" : "다음" }
    private func nextTitle(after index: Int) -> String { index == schedule.count - 1 ? "오늘 수업 종료" : "\(schedule[index + 1].period)교시 · \(schedule[index + 1].subject)" }
    private func nextLocation(after index: Int) -> String { index == schedule.count - 1 ? "수고했어요" : schedule[index + 1].location }
}

private struct MealPager: View {
    let meals: [Meal]
    @State private var selectedMeal = 0
    @State private var movesForward = true

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            HStack {
                Text("오늘 급식").font(.headline.weight(.bold)).foregroundStyle(Color.goneTextPrimary)
                Spacer()
                Text("\(selectedMeal + 1) / \(meals.count)").font(.caption).foregroundStyle(Color.goneTextSecondary)
            }
            if !meals.isEmpty {
                mealCard(meals[selectedMeal])
                    .id(selectedMeal)
                    .transition(cardTransition)
            }
        }
        .animation(.snappy(duration: 0.28), value: selectedMeal)
    }

    private func mealCard(_ meal: Meal) -> some View {
        HomeCard {
            VStack(alignment: .leading, spacing: GONESpacing.large) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: GONESpacing.xSmall) {
                        Text(meal.title).font(.caption).foregroundStyle(Color.goneTextSecondary)
                        Text(meal.mealName).font(.title3.weight(.bold)).foregroundStyle(Color.goneTextPrimary)
                    }
                    Spacer()
                    Text(meal.servingTime).font(.caption).foregroundStyle(Color.goneTextSecondary)
                }
                HStack(alignment: .top, spacing: GONESpacing.large) {
                    MealMenuColumn(items: meal.leftMenu)
                    MealMenuColumn(items: meal.rightMenu)
                }
                Text(meal.calories).font(.caption).foregroundStyle(Color.goneTextSecondary)
            }
        }
        .highPriorityGesture(DragGesture(minimumDistance: 24).onEnded { value in
            if value.translation.width < -30, selectedMeal < meals.count - 1 {
                movesForward = true
                withAnimation(.snappy) { selectedMeal += 1 }
            } else if value.translation.width > 30, selectedMeal > 0 {
                movesForward = false
                withAnimation(.snappy) { selectedMeal -= 1 }
            }
        })
    }

    private var cardTransition: AnyTransition {
        movesForward
            ? .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity))
            : .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity))
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
    let labReservation: LabReservation?
    let outings: [OutingRequest]
    let schoolCampingReservation: SchoolCampingReservation?
    let onLabRequestTap: () -> Void
    let onOutingRequestTap: () -> Void
    let onSchoolCampingRequestTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.medium) {
            Text("신청현황").font(.headline.weight(.bold)).foregroundStyle(Color.goneTextPrimary)
            ForEach(requests) { request in
                let displayRequest = requestForDisplay(request)
                Button {
                    requestTapAction(for: request.kind)
                } label: {
                    HomeCard {
                        HStack(spacing: GONESpacing.medium) {
                            Image(request.kind.illustrationAssetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 34, height: 34)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(request.kind.rawValue).font(.subheadline.weight(.semibold)).foregroundStyle(Color.goneTextPrimary)
                                Text(displayRequest.detail).font(.caption).foregroundStyle(Color.goneTextSecondary)
                            }
                            Spacer(minLength: 8)
                            Text(displayRequest.status.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(statusColor(for: displayRequest.status))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(statusBackgroundColor(for: displayRequest.status), in: Capsule())
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.goneTextSecondary)
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func requestForDisplay(_ request: DashboardRequest) -> (detail: String, status: DashboardRequest.Status) {
        switch request.kind {
        case .lab:
            guard let labReservation else { return (request.detail, request.status) }
            let status: DashboardRequest.Status = switch labReservation.status {
            case .submitted: .completed
            case .pending: .pending
            case .approved: .reserved
            }
            return ("\(labReservation.date) · \(labReservation.usageTime)", status)
        case .outing:
            guard let outing = outings.first else { return (request.detail, request.status) }
            let status: DashboardRequest.Status = switch outing.status {
            case .pendingApproval: .pending
            case .approved: .completed
            case .rejected: .rejected
            }
            return ("\(outingDateFormatter.string(from: outing.date)) · \(outing.reason)", status)
        case .schoolCamping:
            guard let schoolCampingReservation else { return (request.detail, request.status) }
            return ("\(campingDateFormatter.string(from: schoolCampingReservation.date)) · \(schoolCampingReservation.participants.count)명", .reserved)
        }
    }

    private func requestTapAction(for kind: DashboardRequest.Kind) {
        switch kind {
        case .lab: onLabRequestTap()
        case .outing: onOutingRequestTap()
        case .schoolCamping: onSchoolCampingRequestTap()
        }
    }

    private func statusColor(for status: DashboardRequest.Status) -> Color {
        switch status {
        case .notApplied: .goneTextSecondary
        case .rejected: .gonePenalty
        case .completed, .reserved: .goneBrandPrimary
        case .pending: .orange
        }
    }

    private func statusBackgroundColor(for status: DashboardRequest.Status) -> Color {
        switch status {
        case .notApplied: Color.goneSurfaceDisabled
        case .rejected: Color.gonePenalty.opacity(0.12)
        case .completed, .reserved: Color.goneBrandPrimary.opacity(0.12)
        case .pending: Color.orange.opacity(0.14)
        }
    }

    private var outingDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter
    }

    private var campingDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEE"
        return formatter
    }
}

private struct HomeCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(GONESpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 15))
    }
}

private extension Color {
    static let goneHomeBackground = Color(red: 242 / 255, green: 244 / 255, blue: 247 / 255)
    static let gonePenalty = Color(red: 167 / 255, green: 71 / 255, blue: 61 / 255)
}

#Preview {
    AppTabView()
}
