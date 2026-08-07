import Foundation

actor MockOutingRepository: OutingRepository {
    private let teachers = [
        OutingTeacher(id: "teacher-park", name: "박00 선생님", affiliation: "teacher"),
        OutingTeacher(id: "teacher-kim", name: "김00 선생님", affiliation: "teacher"),
        OutingTeacher(id: "teacher-lee", name: "이00 선생님", affiliation: "teacher")
    ]
    private var outings: [OutingRequest]

    init() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let departure = calendar.date(byAdding: .minute, value: 12 * 60, to: today) ?? today
        let returnTime = calendar.date(byAdding: .minute, value: 12 * 60 + 40, to: today) ?? today
        outings = [OutingRequest(
            id: "O-001",
            student: OutingStudent(name: "김은찬", studentNumber: "3206"),
            date: today,
            departureTime: departure,
            returnTime: returnTime,
            reason: "병원 진료",
            teacher: teachers[0],
            status: .pendingApproval
        )]
    }

    func fetchOutings(for role: AccountRole) async throws -> [OutingRequest] {
        role == .teacher ? outings : outings.filter { $0.student.studentNumber == "3206" }
    }

    func searchTeachers(keyword: String) async throws -> [OutingTeacher] {
        guard !keyword.isEmpty else { return teachers }
        return teachers.filter { $0.name.localizedCaseInsensitiveContains(keyword) }
    }

    func submit(_ draft: OutingDraft) async throws -> OutingRequest {
        guard draft.isValid, let teacher = draft.teacher else { throw OutingRepositoryError.invalidDraft }
        let overlaps = outings.contains { request in
            let isRejected: Bool
            if case .rejected = request.status { isRejected = true } else { isRejected = false }
            return !isRejected
                && Calendar.current.isDate(request.date, inSameDayAs: draft.date)
                && draft.departureTime < request.returnTime
                && draft.returnTime > request.departureTime
        }
        guard !overlaps else { throw OutingRepositoryError.timeOverlap }
        let request = OutingRequest(
            id: "O-\(String(format: "%03d", outings.count + 1))",
            student: OutingStudent(name: "김은찬", studentNumber: "3206"),
            date: draft.date,
            departureTime: draft.departureTime,
            returnTime: draft.returnTime,
            reason: draft.reason.trimmingCharacters(in: .whitespacesAndNewlines),
            teacher: teacher,
            status: .pendingApproval
        )
        outings.append(request)
        return request
    }

    func decide(_ outing: OutingRequest, approve: Bool, rejectionReason: String?) async throws -> OutingRequest {
        let trimmedReason = rejectionReason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard approve || !trimmedReason.isEmpty else { throw OutingRepositoryError.missingRejectionReason }
        guard let index = outings.firstIndex(where: { $0.id == outing.id }) else { throw OutingRepositoryError.notFound }
        outings[index].status = approve ? .approved : .rejected(reason: trimmedReason)
        return outings[index]
    }

    func cancel(_ outing: OutingRequest) async throws {
        outings.removeAll { $0.id == outing.id }
    }
}

enum OutingRepositoryError: LocalizedError {
    case invalidDraft
    case timeOverlap
    case missingRejectionReason
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidDraft: "신청 내용을 확인해 주세요."
        case .timeOverlap: "같은 날짜에 시간이 겹치는 외출 신청이 있어요."
        case .missingRejectionReason: "거절 사유를 입력해 주세요."
        case .notFound: "외출 신청을 찾을 수 없어요."
        }
    }
}
