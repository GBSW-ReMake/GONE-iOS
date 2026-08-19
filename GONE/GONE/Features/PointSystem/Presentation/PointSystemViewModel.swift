import Foundation
import Combine

@MainActor
final class PointSystemViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var students: [PointStudent] = []
    @Published private(set) var selectedStudents: [PointStudent] = []
    @Published private(set) var draftsByStudentID: [String: PointIssueDraft] = [:]
    @Published private(set) var records: [PointIssueRecord] = []

    private let repository: PointRepository

    init(repository: PointRepository) {
        self.repository = repository
    }

    func load() async {
        state = .loading
        do {
            async let fetchedStudents = repository.fetchStudents()
            async let fetchedRecords = repository.fetchRecords()
            students = try await fetchedStudents
            records = try await fetchedRecords
            state = .loaded
        } catch {
            state = .failed
        }
    }

    func addStudent(_ student: PointStudent) {
        guard !selectedStudents.contains(student) else { return }
        selectedStudents.append(student)
        draftsByStudentID[student.id] = PointIssueDraft()
    }

    func removeStudent(_ student: PointStudent) {
        selectedStudents.removeAll { $0.id == student.id }
        draftsByStudentID[student.id] = nil
    }

    func clearSelection() {
        selectedStudents.removeAll()
        draftsByStudentID.removeAll()
    }

    func draft(for student: PointStudent) -> PointIssueDraft {
        draftsByStudentID[student.id] ?? PointIssueDraft()
    }

    func saveDraft(_ draft: PointIssueDraft, for student: PointStudent) {
        if !selectedStudents.contains(student) { addStudent(student) }
        draftsByStudentID[student.id] = draft
    }

    func issue(draft: PointIssueDraft) async -> Bool {
        guard !selectedStudents.isEmpty, draft.points > 0, !draft.item.isEmpty else { return false }
        selectedStudents.forEach { draftsByStudentID[$0.id] = draft }
        return await issueAll()
    }

    func issueAll() async -> Bool {
        guard !selectedStudents.isEmpty else { return false }
        let newRecords = selectedStudents.compactMap { student -> PointIssueRecord? in
            guard let draft = draftsByStudentID[student.id], draft.points > 0, !draft.item.isEmpty else { return nil }
            return PointIssueRecord(
                id: UUID().uuidString,
                student: student,
                kind: draft.kind,
                points: draft.points,
                item: draft.item,
                memo: draft.memo,
                issuedAt: .now
            )
        }
        guard newRecords.count == selectedStudents.count else { return false }
        do {
            try await repository.issue(records: newRecords)
            records.insert(contentsOf: newRecords.reversed(), at: 0)
            clearSelection()
            return true
        } catch {
            return false
        }
    }

    var statistics: PointStatistics {
        PointStatistics(
            issueCount: records.count,
            rewardPoints: records.filter { $0.kind == .reward }.reduce(0) { $0 + $1.points },
            penaltyPoints: records.filter { $0.kind == .penalty }.reduce(0) { $0 + $1.points },
            monthlyIssueCounts: Array(repeating: 0, count: 5)
        )
    }
}
