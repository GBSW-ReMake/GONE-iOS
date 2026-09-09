import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    private let role: AccountRole
    private let unreadNotificationCount: Int
    private let labReservation: LabReservation?
    private let outings: [OutingRequest]
    private let schoolCampingReservation: SchoolCampingReservation?
    private let onLabRequestTap: () -> Void
    private let onOutingRequestTap: () -> Void
    private let onSchoolCampingRequestTap: () -> Void
    private let onNotificationTap: () -> Void

    init(
        viewModel: HomeViewModel,
        role: AccountRole = .student,
        unreadNotificationCount: Int = 0,
        labReservation: LabReservation? = nil,
        outings: [OutingRequest] = [],
        schoolCampingReservation: SchoolCampingReservation? = nil,
        onLabRequestTap: @escaping () -> Void = {},
        onOutingRequestTap: @escaping () -> Void = {},
        onSchoolCampingRequestTap: @escaping () -> Void = {},
        onNotificationTap: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.role = role
        self.unreadNotificationCount = unreadNotificationCount
        self.labReservation = labReservation
        self.outings = outings
        self.schoolCampingReservation = schoolCampingReservation
        self.onLabRequestTap = onLabRequestTap
        self.onOutingRequestTap = onOutingRequestTap
        self.onSchoolCampingRequestTap = onSchoolCampingRequestTap
        self.onNotificationTap = onNotificationTap
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ZStack {
                    Color.goneHomeBackground.ignoresSafeArea()
                    ProgressView("홈 정보를 불러오는 중")
                        .tint(Color.goneTextSecondary)
                        .scaleEffect(1.25)
                }
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
        .overlay {
            if viewModel.isRefreshing {
                ZStack {
                    Color.white.opacity(0.28)
                    ProgressView()
                        .tint(Color.goneTextSecondary)
                        .scaleEffect(1.45)
                }
                .background(.ultraThinMaterial.opacity(0.32))
                .ignoresSafeArea()
            }
        }
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.load() }
    }

    private func dashboardContent(_ dashboard: HomeDashboard) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                header()
                PointSummaryCard(profile: dashboard.profile, showsPointSummary: role == .student)
                TodayScheduleCard(schedule: dashboard.schedule, meals: dashboard.meals)
                AcademicScheduleSection(
                    schedules: dashboard.academicSchedules,
                    displayedMonth: viewModel.displayedAcademicMonth,
                    onMoveMonth: viewModel.moveAcademicMonth
                )
                RequestStatusSection(
                    requests: visibleRequests(from: dashboard.requests),
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

    private func visibleRequests(from requests: [DashboardRequest]) -> [DashboardRequest] {
        role == .teacher ? requests.filter { $0.kind != .schoolCamping } : requests
    }

    private func header() -> some View {
        HStack {
            Image("GONELogo")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 24)
                .accessibilityLabel("GONE")
            Spacer()
            Button(action: onNotificationTap) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(Color.goneTextPrimary)
                        .frame(width: 48, height: 48)
                    if unreadNotificationCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .offset(x: -1, y: 3)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(unreadNotificationCount > 0 ? "알림, 읽지 않은 알림 \(unreadNotificationCount)개" : "알림")
            .accessibilityHint("새로운 알림을 확인합니다.")
        }
    }
}

private struct PointSummaryCard: View {
    let profile: StudentProfile
    let showsPointSummary: Bool

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

                if showsPointSummary {
                    HStack(spacing: GONESpacing.medium) {
                        pointColumn(title: "상점", value: profile.rewardPoints, color: Color.goneBrandPrimary)
                        pointColumn(title: "벌점", value: profile.penaltyPoints, color: Color.gonePenalty)
                        pointColumn(title: "현재 점수", value: profile.totalPoints, color: Color.goneTextPrimary)
                    }
                }

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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("내 역할: \(profile.roles.joined(separator: ", "))")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(showsPointSummary ? "상벌점 현황" : "내 정보")
    }

    private func pointColumn(title: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(Color.goneTextSecondary)
            Text("\(value >= 0 ? "+" : "")\(value)")
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)점")
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
    @State private var movesForward = true

    private var monthlySchedules: [AcademicSchedule] {
        schedules
            .filter { calendar.isDate($0.date, equalTo: displayedMonth, toGranularity: .month) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.medium) {
            HStack(spacing: GONESpacing.small) {
                Image("HomeScheduleIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
                Text("학사일정")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.goneTextPrimary)
                Text(monthTitle)
                    .font(.caption)
                    .foregroundStyle(Color.goneTextSecondary)
                Spacer()
                monthButton(systemImage: "chevron.left", accessibilityLabel: "이전 달 학사일정") {
                    moveMonth(by: -1)
                }
                monthButton(systemImage: "chevron.right", accessibilityLabel: "다음 달 학사일정") {
                    moveMonth(by: 1)
                }
            }

            scheduleContent
                .id(displayedMonth)
                .transition(monthTransition)
        }
        .animation(.easeInOut(duration: 0.28), value: displayedMonth)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(monthTitle) 학사일정")
    }

    @ViewBuilder
    private var scheduleContent: some View {
        if monthlySchedules.isEmpty {
            HStack(spacing: GONESpacing.small) {
                Image(systemName: "calendar")
                    .font(.footnote)
                    .foregroundStyle(Color.goneTextSecondary)
                Text("등록된 학사일정이 없어요")
                    .font(.footnote)
                    .foregroundStyle(Color.goneTextSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, GONESpacing.large)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 15))
        } else {
            VStack(spacing: GONESpacing.small) {
                ForEach(monthlySchedules) { schedule in
                    HStack(spacing: GONESpacing.medium) {
                        Text(dateFormatter.string(from: schedule.date))
                            .font(.footnote.weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(Color.goneBrandPrimary)
                            .lineLimit(1)
                            .frame(width: 58, alignment: .leading)
                        Text(schedule.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.goneTextPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, GONESpacing.large)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 15))
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var monthTransition: AnyTransition {
        movesForward
            ? .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity))
            : .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity))
    }

    private func moveMonth(by value: Int) {
        movesForward = value > 0
        withAnimation(.easeInOut(duration: 0.28)) {
            onMoveMonth(value)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: displayedMonth)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MM.dd EEE"
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
                HStack(spacing: GONESpacing.small) {
                    Image("HomeTimetableIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .accessibilityHidden(true)
                    Text("오늘 시간표")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.goneTextPrimary)
                }
                Spacer()
                Text(schedule.isEmpty ? "0 / 0" : "\(selectedPeriod + 1) / \(schedule.count)")
                    .font(.caption)
                    .foregroundStyle(Color.goneTextSecondary)
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
                    .simultaneousGesture(horizontalPagingGesture)
                }
            }
        }
        .animation(.snappy(duration: 0.28), value: selectedPeriod)
        .onChange(of: schedule.count) { _, count in
            selectedPeriod = max(0, min(selectedPeriod, count - 1))
        }
        .accessibilityLabel("오늘 시간표. 좌우로 넘겨 다음 교시를 확인하세요.")
    }

    private var horizontalPagingGesture: some Gesture {
        DragGesture(minimumDistance: 16).onEnded { value in
            guard abs(value.translation.width) > abs(value.translation.height) else { return }
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
                HStack(spacing: GONESpacing.small) {
                    Image("HomeMealIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .accessibilityHidden(true)
                    Text("오늘 급식")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.goneTextPrimary)
                }
                Spacer()
                Text(meals.isEmpty ? "0 / 0" : "\(selectedMeal + 1) / \(meals.count)")
                    .font(.caption)
                    .foregroundStyle(Color.goneTextSecondary)
            }
            if !meals.isEmpty {
                mealCard(meals[selectedMeal])
                    .id(selectedMeal)
                    .transition(cardTransition)
            }
        }
        .animation(.snappy(duration: 0.28), value: selectedMeal)
        .onChange(of: meals.count) { _, count in
            selectedMeal = max(0, min(selectedMeal, count - 1))
        }
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
        .simultaneousGesture(DragGesture(minimumDistance: 16).onEnded { value in
            guard abs(value.translation.width) > abs(value.translation.height) else { return }
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
    @State private var transitioningRequestID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.medium) {
            HStack(spacing: GONESpacing.small) {
                Image("HomeRequestIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
                Text("신청현황")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.goneTextPrimary)
            }
            ForEach(requests) { request in
                let displayRequest = requestForDisplay(request)
                Button {
                    transitionToRequest(for: request)
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
                    .scaleEffect(transitioningRequestID == request.id ? 0.97 : 1)
                    .opacity(transitioningRequestID == request.id ? 0.72 : 1)
                }
                .buttonStyle(.plain)
                .disabled(transitioningRequestID != nil)
                .animation(.easeOut(duration: 0.14), value: transitioningRequestID)
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
            case .outing: .reserved
            case .completed: .completed
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

    private func transitionToRequest(for request: DashboardRequest) {
        withAnimation(.easeOut(duration: 0.14)) {
            transitioningRequestID = request.id
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            requestTapAction(for: request.kind)
            transitioningRequestID = nil
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
