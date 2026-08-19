import Foundation

struct MockTeacherLabOverviewRepository: TeacherLabOverviewRepository {
    func fetchOverview(for floor: LabFloor, date: Date) async throws -> [TeacherLabRoomStatus] {
        let rooms = allRooms.filter { $0.floor == floor }
        return rooms.enumerated().map { index, room in
            TeacherLabRoomStatus(
                id: room.id,
                number: index + 1,
                room: room,
                booking: booking(for: room.id, date: date)
            )
        }
    }

    private func booking(for roomID: String, date: Date) -> TeacherLabBooking? {
        switch roomID {
        case "4-1":
            TeacherLabBooking(period: .nightStudy, date: date, usageTime: "19:10 ~ 20:30", booker: "김은찬", memberCount: 4, purpose: "대회 준비", location: "4층 1학년 1반 앞 실습실")
        case "4-2":
            TeacherLabBooking(period: .afterSchool, date: date, usageTime: "16:30 ~ 18:00", booker: "김은찬", memberCount: 4, purpose: "캡스톤 개발", location: "4층 1학년 1반 앞 실습실")
        default:
            nil
        }
    }

    private let allRooms: [LabRoom] = [
        LabRoom(id: "4-1", floor: .fourth, name: "NCS 응용 프로그래밍 실습실2", capacity: 20, amenities: ["빔프로젝터"], isReservable: true),
        LabRoom(id: "4-2", floor: .fourth, name: "NCS 게임콘텐츠 제작 실습실1", capacity: 20, amenities: ["빔프로젝터"], isReservable: true),
        LabRoom(id: "4-3", floor: .fourth, name: "SW 채움교실", capacity: 16, amenities: ["빔프로젝터"], isReservable: true),
        LabRoom(id: "4-4", floor: .fourth, name: "LAB 6실", capacity: 7, amenities: [], isReservable: true),
        LabRoom(id: "4-5", floor: .fourth, name: "LAB 7실", capacity: 7, amenities: [], isReservable: true),
        LabRoom(id: "3-1", floor: .third, name: "3층 멀티미디어실", capacity: 24, amenities: ["대형 모니터"], isReservable: true),
        LabRoom(id: "3-2", floor: .third, name: "3층 프로젝트실", capacity: 12, amenities: ["화이트보드"], isReservable: true),
        LabRoom(id: "2-1", floor: .second, name: "2층 협업실", capacity: 10, amenities: ["회의 테이블"], isReservable: true),
        LabRoom(id: "2-2", floor: .second, name: "2층 스터디실", capacity: 8, amenities: ["전자칠판"], isReservable: true)
    ]
}
