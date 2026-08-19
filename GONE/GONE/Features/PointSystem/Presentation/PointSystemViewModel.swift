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
    }

    func removeStudent(_ student: PointStudent) {
        selectedStudents.removeAll { $0.id == student.id }
    }

    func clearSelection() {
        selectedStudents.removeAll()
    }

    func issue(draft: PointIssueDraft) async -> Bool {
        guard !selectedStudents.isEmpty, draft.points > 0, !draft.item.isEmpty else { return false }
        let newRecords = selectedStudents.map { student in
            PointIssueRecord(
                id: UUID().uuidString,
                student: student,
                kind: draft.kind,
                points: draft.points,
                item: draft.item,
                memo: draft.memo,
                issuedAt: .now
            )
        }
        do {
            try await repository.issue(records: newRecords)
            records.insert(contentsOf: newRecords.reversed(), at: 0)
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
