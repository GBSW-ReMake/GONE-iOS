import Foundation

nonisolated struct HomeProfileDTO: Decodable {
    let name: String
    let realName: String?
    let grade: Int?
    let classNo: Int?
}

nonisolated struct HomeConductSummaryDTO: Decodable {
    let totalMeritPoints: Int
    let totalDemeritPoints: Int
    let netScore: Int
}

nonisolated struct HomeMealsDTO: Decodable {
    let date: String
    let meals: [HomeMealDTO]
}

nonisolated struct HomeMealDTO: Decodable {
    let mealType: String
    let dishes: [String]
    let calorie: String
}

nonisolated struct HomeTimetableDTO: Decodable {
    let periods: [HomePeriodDTO]
}

nonisolated struct HomePeriodDTO: Decodable {
    let period: Int
    let subject: String
}

nonisolated struct HomePageDTO<Item: Decodable>: Decodable {
    let content: [Item]
}

nonisolated struct HomeOutingDTO: Decodable {
    let code: String
    let reason: String
    let outingDate: String
    let startTime: String
    let endTime: String
    let status: String
}

nonisolated struct HomeSchoolCampDTO: Decodable {
    let id: Int
    let campDate: String
    let cancelledAt: String?
}
