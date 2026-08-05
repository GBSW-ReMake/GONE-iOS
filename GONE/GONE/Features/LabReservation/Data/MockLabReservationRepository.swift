import Foundation

actor MockLabReservationRepository: LabReservationRepository {
    private var currentReservation: LabReservation?

    func fetchRooms(for floor: LabFloor) async throws -> [LabRoom] {
        rooms.filter { $0.floor == floor }
    }

    func fetchCurrentReservation() async throws -> LabReservation? {
        currentReservation
    }

    func submit(_ draft: LabReservationDraft) async throws -> LabReservation {
        let reservation = LabReservation(
            id: "R-0720-06",
            room: draft.room,
            date: "7월 30일 목요일",
            usageTime: draft.usageTime,
            representative: draft.representative,
            memberCount: draft.members.split(separator: ",").count,
            purpose: draft.purpose,
            status: .submitted
        )
        currentReservation = reservation
        return reservation
    }

    private let rooms: [LabRoom] = [
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
