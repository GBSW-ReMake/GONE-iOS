import SwiftUI

enum AppTab: Hashable {
    case home, lab, outing, schoolCamping, settings
}

struct AppTabView: View {
    let role: AccountRole
    @State private var selection: AppTab = .home
    @StateObject private var labReservationViewModel: LabReservationViewModel
    @StateObject private var outingViewModel: OutingViewModel
    @StateObject private var schoolCampingViewModel: SchoolCampingViewModel

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
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView(
                viewModel: HomeViewModel(fetchDashboard: FetchHomeDashboardUseCase(repository: MockHomeDashboardRepository())),
                labReservation: labReservationViewModel.reservation,
                outings: outingViewModel.outings,
                schoolCampingReservation: schoolCampingViewModel.reservation,
                onLabRequestTap: { selection = .lab },
                onOutingRequestTap: { selection = .outing },
                onSchoolCampingRequestTap: { selection = .schoolCamping }
            )
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

            TabPlaceholderView(title: "설정", systemImage: "gearshape.fill")
                .tabItem { Label("설정", image: "SettingsTabIcon") }
                .tag(AppTab.settings)
        }
        .tint(.goneBrandPrimary)
        .task {
            async let labLoad: Void = labReservationViewModel.load()
            async let outingLoad: Void = outingViewModel.load()
            async let schoolCampingLoad: Void = schoolCampingViewModel.load()
            _ = await (labLoad, outingLoad, schoolCampingLoad)
        }
    }
}

private struct TabPlaceholderView: View {
    let title: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text("준비 중인 기능입니다."))
    }
}
