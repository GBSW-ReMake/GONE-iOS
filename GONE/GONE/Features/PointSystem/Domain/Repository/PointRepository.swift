import Foundation

protocol PointRepository {
    func fetchStudents() async throws -> [PointStudent]
    func fetchRecords() async throws -> [PointIssueRecord]
    func issue(records: [PointIssueRecord]) async throws
}

final class MockPointRepository: PointRepository {
    private var records: [PointIssueRecord] = []

    private let students = [
        PointStudent(id: "3206", name: "김은찬", studentInfo: "3학년 2반 6번"),
        PointStudent(id: "3201", name: "김민준", studentInfo: "3학년 2반 1번"),
        PointStudent(id: "3202", name: "박서연", studentInfo: "3학년 2반 2번"),
        PointStudent(id: "3203", name: "이도윤", studentInfo: "3학년 2반 3번"),
        PointStudent(id: "3204", name: "최유진", studentInfo: "3학년 2반 4번"),
        PointStudent(id: "3205", name: "한지민", studentInfo: "3학년 2반 5번")
    ]

    func fetchStudents() async throws -> [PointStudent] { students }
    func fetchRecords() async throws -> [PointIssueRecord] { records }

    func issue(records: [PointIssueRecord]) async throws {
        self.records.insert(contentsOf: records.reversed(), at: 0)
    }
}
