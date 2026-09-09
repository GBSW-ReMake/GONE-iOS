import Foundation

final class RemoteHomeDashboardRepository: HomeDashboardRepository {
    private let client: APIClient
    private let sessionStore: SessionStore
    private let calendar: Calendar

    init(client: APIClient, sessionStore: SessionStore, calendar: Calendar = .current) {
        self.client = client
        self.sessionStore = sessionStore
        self.calendar = calendar
    }

    func fetchDashboard() async throws -> HomeDashboard {
        let date = dateString(Date())
        let accessToken = try sessionStore.load()?.accessToken

        async let profile = fetchProfile(accessToken)
        async let conduct = fetchConduct(accessToken)
        async let meals = try? request(HomeTarget.meals(date: date), as: HomeMealsDTO.self)
        async let timetable = fetchTimetable(date: date, accessToken: accessToken)
        async let outings = fetchOutings(accessToken)
        async let camps = fetchCamps(accessToken)

        let profileData = await profile
        let conductData = await conduct
        let mealsData = await meals
        let timetableData = await timetable
        let outingsData = await outings
        let campsData = await camps

        let profileValue = profileData ?? HomeProfileDTO(name: "", realName: nil, grade: nil, classNo: nil)
        let conductValue = conductData ?? HomeConductSummaryDTO(totalMeritPoints: 0, totalDemeritPoints: 0, netScore: 0)

        return HomeDashboard(
            profile: StudentProfile(
                name: profileValue.name,
                department: "",
                studentInfo: studentInfo(from: profileValue),
                rewardPoints: conductValue.totalMeritPoints,
                penaltyPoints: conductValue.totalDemeritPoints,
                roles: []
            ),
            schedule: timetableData?.periods.map {
                ClassSchedule(period: $0.period, subject: $0.subject, location: "", time: "")
            } ?? [],
            academicSchedules: [],
            meals: mealsData?.meals.map { meal in
                Meal(
                    mealName: meal.mealType,
                    calories: meal.calorie,
                    title: "오늘의 급식",
                    servingTime: "",
                    leftMenu: Array(meal.dishes.prefix((meal.dishes.count + 1) / 2)),
                    rightMenu: Array(meal.dishes.dropFirst((meal.dishes.count + 1) / 2))
                )
            } ?? [],
            requests: requestSummaries(outings: outingsData?.content ?? [], camps: campsData?.content ?? [])
        )
    }

    private func request<Response: Decodable>(_ target: HomeTarget, as type: Response.Type) async throws -> Response {
        let envelope: APIResponseDTO<Response> = try await client.request(target, responseType: APIResponseDTO<Response>.self)
        guard let data = envelope.data else { throw APIError.decoding }
        return data
    }

    private func fetchProfile(_ accessToken: String?) async -> HomeProfileDTO? {
        guard let accessToken else { return nil }
        return try? await request(HomeTarget.profile(accessToken: accessToken), as: HomeProfileDTO.self)
    }

    private func fetchConduct(_ accessToken: String?) async -> HomeConductSummaryDTO? {
        guard let accessToken else { return nil }
        return try? await request(HomeTarget.conductSummary(accessToken: accessToken), as: HomeConductSummaryDTO.self)
    }

    private func fetchTimetable(date: String, accessToken: String?) async -> HomeTimetableDTO? {
        guard let accessToken else { return nil }
        return try? await request(HomeTarget.timetable(date: date, accessToken: accessToken), as: HomeTimetableDTO.self)
    }

    private func fetchOutings(_ accessToken: String?) async -> HomePageDTO<HomeOutingDTO>? {
        guard let accessToken else { return nil }
        return try? await request(HomeTarget.outingRequests(accessToken: accessToken), as: HomePageDTO<HomeOutingDTO>.self)
    }

    private func fetchCamps(_ accessToken: String?) async -> HomePageDTO<HomeSchoolCampDTO>? {
        guard let accessToken else { return nil }
        return try? await request(HomeTarget.schoolCampParticipations(accessToken: accessToken), as: HomePageDTO<HomeSchoolCampDTO>.self)
    }

    private func studentInfo(from profile: HomeProfileDTO) -> String {
        guard let grade = profile.grade, let classNo = profile.classNo else { return "" }
        return "\(grade)학년 \(classNo)반"
    }

    private func requestSummaries(outings: [HomeOutingDTO], camps: [HomeSchoolCampDTO]) -> [DashboardRequest] {
        let outing = outings.first.map {
            DashboardRequest(kind: .outing, detail: "\($0.outingDate) · \($0.reason)", status: status(for: $0.status))
        } ?? DashboardRequest(kind: .outing, detail: "신청 내역이 없어요", status: .notApplied)
        let camp = camps.first.map {
            DashboardRequest(kind: .schoolCamping, detail: "\($0.campDate)", status: $0.cancelledAt == nil ? .reserved : .rejected)
        } ?? DashboardRequest(kind: .schoolCamping, detail: "신청 내역이 없어요", status: .notApplied)
        return [DashboardRequest(kind: .lab, detail: "실습실 신청 API 명세 대기", status: .notApplied), outing, camp]
    }

    private func status(for value: String) -> DashboardRequest.Status {
        switch value {
        case "PENDING": .pending
        case "APPROVED": .completed
        case "DEPARTED": .reserved
        case "REJECTED": .rejected
        default: .notApplied
        }
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: date)
    }
}
