import XCTest
@testable import GONE

@MainActor
final class TeacherLabOverviewViewModelTests: XCTestCase {
    func testLoadShowsReservedAndUnreservedRooms() async {
        let viewModel = TeacherLabOverviewViewModel(
            fetchOverview: FetchTeacherLabOverviewUseCase(repository: MockTeacherLabOverviewRepository()),
            selectedDate: Date()
        )

        await viewModel.load()

        guard case .loaded(let rooms) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertEqual(rooms.count, 5)
        XCTAssertEqual(rooms.filter(\.isReserved).count, 2)
        XCTAssertEqual(rooms.first?.booking?.period, .nightStudy)
        XCTAssertEqual(rooms[1].booking?.period, .afterSchool)
    }

    func testSelectFloorReloadsRooms() async {
        let viewModel = TeacherLabOverviewViewModel(
            fetchOverview: FetchTeacherLabOverviewUseCase(repository: MockTeacherLabOverviewRepository()),
            selectedDate: Date()
        )

        await viewModel.selectFloor(.third)

        guard case .loaded(let rooms) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertEqual(viewModel.selectedFloor, .third)
        XCTAssertEqual(rooms.count, 2)
    }
}
