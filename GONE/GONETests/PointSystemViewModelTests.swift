import XCTest
@testable import GONE

@MainActor
final class PointSystemViewModelTests: XCTestCase {
    func testLoadFetchesStudentsAndRecords() async {
        let student = PointStudent(id: "3206", name: "김은찬", studentInfo: "3학년 2반 6번")
        let viewModel = PointSystemViewModel(
            repository: StubPointRepository(students: [student], records: [])
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.students, [student])
        XCTAssertTrue(viewModel.records.isEmpty)
    }

    func testIssueCreatesRecordForEachSelectedStudent() async {
        let students = [
            PointStudent(id: "3206", name: "김은찬", studentInfo: "3학년 2반 6번"),
            PointStudent(id: "3201", name: "김민준", studentInfo: "3학년 2반 1번")
        ]
        let viewModel = PointSystemViewModel(repository: StubPointRepository(students: students, records: []))
        await viewModel.load()
        students.forEach(viewModel.addStudent)

        let didIssue = await viewModel.issue(draft: PointIssueDraft(kind: .reward, points: 2, item: "참여", memo: ""))

        XCTAssertTrue(didIssue)
        XCTAssertEqual(viewModel.records.count, 2)
        XCTAssertTrue(viewModel.selectedStudents.isEmpty)
        XCTAssertEqual(viewModel.statistics.rewardPoints, 4)
    }

    func testSaveDraftDoesNotIssueUntilIssueAllIsCalled() async {
        let student = PointStudent(id: "3206", name: "김은찬", studentInfo: "3학년 2반 6번")
        let viewModel = PointSystemViewModel(repository: StubPointRepository(students: [student], records: []))
        await viewModel.load()
        viewModel.addStudent(student)

        viewModel.saveDraft(
            PointIssueDraft(kind: .reward, points: 2, item: "학교 홍보 활동", memo: ""),
            for: student
        )

        XCTAssertTrue(viewModel.records.isEmpty)
        XCTAssertEqual(viewModel.selectedStudents, [student])

        let didIssue = await viewModel.issueAll()

        XCTAssertTrue(didIssue)
        XCTAssertEqual(viewModel.records.count, 1)
        XCTAssertTrue(viewModel.selectedStudents.isEmpty)
    }

    func testIssueFailsWithoutStudentOrItem() async {
        let viewModel = PointSystemViewModel(repository: StubPointRepository(students: [], records: []))
        await viewModel.load()

        let didIssue = await viewModel.issue(draft: PointIssueDraft(item: ""))

        XCTAssertFalse(didIssue)
        XCTAssertTrue(viewModel.records.isEmpty)
    }
}

private struct StubPointRepository: PointRepository {
    let students: [PointStudent]
    var records: [PointIssueRecord]

    func fetchStudents() async throws -> [PointStudent] { students }
    func fetchRecords() async throws -> [PointIssueRecord] { records }
    func issue(records: [PointIssueRecord]) async throws { }
}
