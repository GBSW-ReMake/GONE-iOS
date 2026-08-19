import Foundation

enum LabUsagePeriod: String, CaseIterable, Identifiable {
    case nightStudy = "야자시간"
    case afterSchool = "방과후"

    var id: Self { self }
}

struct TeacherLabBooking: Equatable {
    let period: LabUsagePeriod
    let date: Date
    let usageTime: String
    let booker: String
    let memberCount: Int
    let purpose: String
    let location: String
}

struct TeacherLabRoomStatus: Identifiable, Equatable {
    let id: String
    let number: Int
    let room: LabRoom
    let booking: TeacherLabBooking?

    var isReserved: Bool { booking != nil }
}
