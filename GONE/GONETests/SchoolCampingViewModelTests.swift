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

    func testUpdateReservationChangesTeacherAndParticipants() async {
        let viewModel = SchoolCampingViewModel(repository: MockSchoolCampingRepository())
        await viewModel.load()

        guard let selectedDay = viewModel.calendarDays.first(where: { $0.availability == .available }) else {
            return XCTFail("Expected an available camping date")
        }

        let initialDraft = SchoolCampingReservationDraft(
            date: selectedDay.date,
            teacherName: "박00 선생님",
            participants: [CampingParticipant(studentNumber: "3206", name: "김은찬")]
        )
        await viewModel.submit(initialDraft)

        let updatedDraft = SchoolCampingReservationDraft(
            date: selectedDay.date,
            teacherName: "김00 선생님",
            participants: [
                CampingParticipant(studentNumber: "3206", name: "김은찬"),
                CampingParticipant(studentNumber: "3201", name: "김민준")
            ]
        )

        let didUpdate = await viewModel.updateReservation(updatedDraft)

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(viewModel.reservation?.teacherName, "김00 선생님")
        XCTAssertEqual(viewModel.reservation?.participants.count, 2)
        XCTAssertEqual(viewModel.reservation?.participants.last?.studentNumber, "3201")
    }
}
