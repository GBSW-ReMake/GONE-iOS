import XCTest
@testable import GONE

@MainActor
final class SchoolCampingViewModelTests: XCTestCase {
    func testSubmitCreatesReservationFromSelectedDate() async {
        let viewModel = SchoolCampingViewModel(repository: MockSchoolCampingRepository())

        await viewModel.load()

        guard let selectedDay = viewModel.calendarDays.first(where: { $0.availability == .available }) else {
            return XCTFail("Expected an available camping date")
        }
        viewModel.select(selectedDay)

        guard var draft = viewModel.makeDraft() else {
            return XCTFail("Expected a reservation draft")
        }
        draft = SchoolCampingReservationDraft(
            date: draft.date,
            teacherName: "박00 선생님",
            participants: draft.participants
        )

        await viewModel.submit(draft)

        XCTAssertEqual(viewModel.reservation?.date, selectedDay.date)
        XCTAssertEqual(viewModel.reservation?.teacherName, "박00 선생님")
        XCTAssertEqual(viewModel.reservation?.participants.count, 1)
        XCTAssertNil(viewModel.selectedDate)
    }
}
