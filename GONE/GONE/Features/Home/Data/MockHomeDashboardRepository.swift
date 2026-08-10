import Foundation

struct MockHomeDashboardRepository: HomeDashboardRepository {
    func fetchDashboard() async throws -> HomeDashboard {
        let currentYear = Calendar.current.component(.year, from: Date())

        return HomeDashboard(
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
            academicSchedules: [
                AcademicSchedule(id: "summer-vacation", date: date(year: currentYear, month: 8, day: 1), title: "토요휴업일"),
                AcademicSchedule(id: "summer-vacation-2", date: date(year: currentYear, month: 8, day: 8), title: "토요휴업일"),
                AcademicSchedule(id: "school-opening", date: date(year: currentYear, month: 8, day: 10), title: "개학식"),
                AcademicSchedule(id: "liberation-day", date: date(year: currentYear, month: 8, day: 15), title: "광복절"),
                AcademicSchedule(id: "fall-semester", date: date(year: currentYear, month: 9, day: 1), title: "2학기 시작")
            ],
            meals: [Meal(
                mealName: "점심",
                calories: "785 kcal",
                title: "오늘의 급식",
                servingTime: "12:20–13:20",
                leftMenu: ["현미밥", "쇠고기미역국 (5.6.16)", "돼지갈비찜 (5.6.10.13)", "깻잎양념무침 (5.6.13)"],
                rightMenu: ["쌈배추무생채(해고) (5.6.13)", "잡채 (5.6.13.16.18)", "배추김치 (9)", "미숫가루수박화채 (2.5.13)"]
            ), Meal(mealName: "저녁", calories: "720 kcal", title: "오늘의 급식", servingTime: "17:30–18:30", leftMenu: ["잡곡밥", "된장국", "닭갈비"], rightMenu: ["콩나물무침", "배추김치", "요구르트"]), Meal(mealName: "간식", calories: "310 kcal", title: "오늘의 급식", servingTime: "20:00–20:30", leftMenu: ["미니 핫도그"], rightMenu: ["과일 주스"])],
            requests: [
                DashboardRequest(kind: .lab, detail: "신청 내역이 없어요", status: .notApplied),
                DashboardRequest(kind: .outing, detail: "신청 내역이 없어요", status: .notApplied),
                DashboardRequest(kind: .schoolCamping, detail: "신청 내역이 없어요", status: .notApplied)
            ]
        )
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }
}
