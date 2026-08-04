import Foundation

struct MockHomeDashboardRepository: HomeDashboardRepository {
    func fetchDashboard() async throws -> HomeDashboard {
        HomeDashboard(
            profile: StudentProfile(
                name: "김은찬",
                department: "소프트웨어개발과",
                studentInfo: "2학년 2반 · 6번",
                rewardPoints: 15,
                penaltyPoints: 3,
                roles: ["선도부", "방송부", "iOS 전공동아리"]
            ),
            schedule: [
                ClassSchedule(period: 1, subject: "자료구조", location: "소프트웨어 1실", time: "08:40–09:30"),
                ClassSchedule(period: 2, subject: "영어", location: "2학년 2반", time: "09:40–10:30"),
                ClassSchedule(period: 3, subject: "iOS 프로그래밍", location: "소프트웨어 2실", time: "10:40–11:30"),
                ClassSchedule(period: 4, subject: "데이터베이스", location: "소프트웨어 1실", time: "11:40–12:30"),
                ClassSchedule(period: 5, subject: "네트워크", location: "6", time: "13:30–14:20"),
                ClassSchedule(period: 6, subject: "웹 프로그래밍", location: "웹 개발실", time: "14:30–15:20"),
                ClassSchedule(period: 7, subject: "동아리 활동", location: "iOS실", time: "15:30–16:20")
            ],
            meal: Meal(
                calories: "785 kcal",
                title: "오늘의 급식",
                servingTime: "12:20–13:20",
                leftMenu: ["현미밥", "쇠고기미역국 (5.6.16)", "돼지갈비찜 (5.6.10.13)", "깻잎양념무침 (5.6.13)"],
                rightMenu: ["쌈배추무생채(해고) (5.6.13)", "잡채 (5.6.13.16.18)", "배추김치 (9)", "미숫가루수박화채 (2.5.13)"]
            ),
            requests: [
                DashboardRequest(kind: .lab, detail: "오늘 19:00–21:00 iOS실", status: .completed),
                DashboardRequest(kind: .outing, detail: "7월 22일 · 병원 방문", status: .pending),
                DashboardRequest(kind: .schoolCamping, detail: "7월 24일 금요일 · 4명", status: .reserved)
            ]
        )
    }
}
