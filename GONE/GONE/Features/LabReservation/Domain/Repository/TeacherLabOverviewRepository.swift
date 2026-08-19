import Foundation

protocol TeacherLabOverviewRepository {
    func fetchOverview(for floor: LabFloor, date: Date) async throws -> [TeacherLabRoomStatus]
}
