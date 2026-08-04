import SwiftUI

enum AppTab: Hashable {
    case home, lab, outing, schoolCamping, settings
}

struct AppTabView: View {
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView(viewModel: HomeViewModel(fetchDashboard: FetchHomeDashboardUseCase(repository: MockHomeDashboardRepository())))
                .tabItem { Label("홈", systemImage: "house.fill") }
                .tag(AppTab.home)

            TabPlaceholderView(title: "실습실", systemImage: "desktopcomputer")
                .tabItem { Label("실습실", systemImage: "desktopcomputer") }
                .tag(AppTab.lab)

            TabPlaceholderView(title: "외출", systemImage: "figure.walk")
                .tabItem { Label("외출", systemImage: "figure.walk") }
                .tag(AppTab.outing)

            TabPlaceholderView(title: "스쿨캠핑", systemImage: "tent")
                .tabItem { Label("스쿨캠핑", systemImage: "tent") }
                .tag(AppTab.schoolCamping)

            TabPlaceholderView(title: "설정", systemImage: "gearshape.fill")
                .tabItem { Label("설정", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(.goneBrandPrimary)
    }
}

private struct TabPlaceholderView: View {
    let title: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text("준비 중인 기능입니다."))
    }
}
