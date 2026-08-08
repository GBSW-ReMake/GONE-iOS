import Foundation

struct MockSettingsRepository: SettingsRepository {
    func fetchOverview() async throws -> SettingsOverview {
        SettingsOverview(
            profile: SettingsProfile(
                name: "김은찬",
                department: "소프트웨어개발과",
                studentInfo: "2학년 2반 · 6번"
            ),
            activities: [
                RecentActivity(
                    id: "lab-001",
                    kind: .lab,
                    title: "iOS실 예약",
                    dateText: "7월 30일 목요일 · 19:10 ~ 20:30",
                    status: .completed
                ),
                RecentActivity(
                    id: "outing-001",
                    kind: .outing,
                    title: "외출 신청",
                    dateText: "8월 8일 · 병원 방문",
                    status: .pending
                ),
                RecentActivity(
                    id: "camping-001",
                    kind: .schoolCamping,
                    title: "스쿨캠핑 예약",
                    dateText: "8월 22일 금요일 · 4명",
                    status: .reserved
                )
            ]
        )
    }
}
