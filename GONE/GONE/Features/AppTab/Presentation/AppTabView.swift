import SwiftUI

enum AppTab: Hashable {
    case home, lab, outing, schoolCamping, settings
}

struct AppTabView: View {
    let role: AccountRole
    @State private var selection: AppTab = .home
    @State private var isNotificationPresented = false
    @StateObject private var notificationViewModel: NotificationViewModel
    @StateObject private var labReservationViewModel: LabReservationViewModel
    @StateObject private var outingViewModel: OutingViewModel
    @StateObject private var schoolCampingViewModel: SchoolCampingViewModel
    @StateObject private var settingsViewModel: SettingsViewModel

    init(role: AccountRole = .student) {
        self.role = role
        _labReservationViewModel = StateObject(
            wrappedValue: LabReservationViewModel(repository: MockLabReservationRepository())
        )
        _outingViewModel = StateObject(
            wrappedValue: OutingViewModel(role: role, repository: MockOutingRepository())
        )
        _schoolCampingViewModel = StateObject(
            wrappedValue: SchoolCampingViewModel(repository: MockSchoolCampingRepository())
        )
        _settingsViewModel = StateObject(
            wrappedValue: SettingsViewModel(
                fetchOverview: FetchSettingsOverviewUseCase(repository: MockSettingsRepository())
            )
        )
        _notificationViewModel = StateObject(
            wrappedValue: NotificationViewModel(
                role: role,
                fetchNotifications: FetchNotificationsUseCase(repository: MockNotificationRepository()),
                markAllNotificationsRead: MarkAllNotificationsReadUseCase(repository: MockNotificationRepository())
            )
        )
    }

    var body: some View {
        TabView(selection: animatedSelection) {
            NavigationStack {
                HomeView(
                    viewModel: HomeViewModel(fetchDashboard: FetchHomeDashboardUseCase(repository: MockHomeDashboardRepository())),
                    role: role,
                    unreadNotificationCount: notificationViewModel.unreadCount,
                    labReservation: labReservationViewModel.reservation,
                    outings: outingViewModel.outings,
                    schoolCampingReservation: schoolCampingViewModel.reservation,
                    onLabRequestTap: { select(.lab) },
                    onOutingRequestTap: { select(.outing) },
                    onSchoolCampingRequestTap: { select(.schoolCamping) },
                    onNotificationTap: { isNotificationPresented = true }
                )
                .navigationDestination(isPresented: $isNotificationPresented) {
                    NotificationView(
                        viewModel: notificationViewModel
                    )
                }
            }
                .tabItem { Label("홈", image: "HomeTabIcon") }
                .tag(AppTab.home)

            LabReservationView(viewModel: labReservationViewModel)
                .tabItem { Label("실습실", image: "LabTabIcon") }
                .tag(AppTab.lab)

            OutingView(viewModel: outingViewModel)
                .tabItem { Label("외출", image: "OutingTabIcon") }
                .tag(AppTab.outing)

            SchoolCampingView(viewModel: schoolCampingViewModel)
                .tabItem { Label("스쿨캠핑", image: "CampingTabIcon") }
                .tag(AppTab.schoolCamping)

            SettingsView(viewModel: settingsViewModel) { activityKind in
                switch activityKind {
                case .lab: selection = .lab
                case .outing: selection = .outing
                case .schoolCamping: selection = .schoolCamping
                }
            }
                .tabItem { Label("설정", image: "SettingsTabIcon") }
                .tag(AppTab.settings)
        }
        .tint(.goneBrandPrimary)
        .task {
            async let labLoad: Void = labReservationViewModel.load()
            async let outingLoad: Void = outingViewModel.load()
            async let schoolCampingLoad: Void = schoolCampingViewModel.load()
            async let notificationLoad: Void = notificationViewModel.load()
            _ = await (labLoad, outingLoad, schoolCampingLoad, notificationLoad)
        }
    }

    private var animatedSelection: Binding<AppTab> {
        Binding(
            get: { selection },
            set: { newSelection in select(newSelection) }
        )
    }

    private func select(_ tab: AppTab) {
        withAnimation(.easeInOut(duration: 0.28)) {
            selection = tab
        }
    }
}
