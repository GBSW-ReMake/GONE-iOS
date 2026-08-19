import Foundation

struct FetchTeacherLabOverviewUseCase {
    let repository: TeacherLabOverviewRepository

    func execute(for floor: LabFloor, date: Date) async throws -> [TeacherLabRoomStatus] {
        try await repository.fetchOverview(for: floor, date: date)
    }
}
