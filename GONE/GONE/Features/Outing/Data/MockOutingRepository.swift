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
            student: OutingStudent(name: "박지민", studentNumber: "20314"),
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
        let normalizedDraft = draft.normalizedToSelectedDate()
        let teacher = normalizedDraft.teacher ?? teachers[0]
        let student = OutingStudent(name: "김은찬", studentNumber: "3206")
        let overlaps = outings.contains { request in
            let isRejected: Bool
            if case .rejected = request.status { isRejected = true } else { isRejected = false }
            return request.student.studentNumber == student.studentNumber
                && !isRejected
                && Calendar.current.isDate(request.date, inSameDayAs: normalizedDraft.date)
                && normalizedDraft.departureTime < request.returnTime
                && normalizedDraft.returnTime > request.departureTime
        }
        guard !overlaps else { throw OutingRepositoryError.timeOverlap }
        let request = OutingRequest(
            id: "O-\(String(format: "%03d", outings.count + 1))",
            student: student,
            date: normalizedDraft.date,
            departureTime: normalizedDraft.departureTime,
            returnTime: normalizedDraft.returnTime,
            reason: normalizedDraft.reason.trimmingCharacters(in: .whitespacesAndNewlines),
            teacher: teacher,
            status: .pendingApproval
        )
        outings.append(request)
        return request
    }

    func update(_ outing: OutingRequest, with draft: OutingDraft) async throws -> OutingRequest {
        let normalizedDraft = draft.normalizedToSelectedDate()
        let teacher = normalizedDraft.teacher ?? outing.teacher
        guard let index = outings.firstIndex(where: { $0.id == outing.id }) else { throw OutingRepositoryError.notFound }
        let overlaps = outings.contains { request in
            guard request.id != outing.id else { return false }
            if case .rejected = request.status { return false }
            return request.student.studentNumber == outing.student.studentNumber
                && Calendar.current.isDate(request.date, inSameDayAs: normalizedDraft.date)
                && normalizedDraft.departureTime < request.returnTime
                && normalizedDraft.returnTime > request.departureTime
        }
        guard !overlaps else { throw OutingRepositoryError.timeOverlap }
        let updated = OutingRequest(
            id: outing.id,
            student: outing.student,
            date: normalizedDraft.date,
            departureTime: normalizedDraft.departureTime,
            returnTime: normalizedDraft.returnTime,
            reason: normalizedDraft.reason.trimmingCharacters(in: .whitespacesAndNewlines),
            teacher: teacher,
            status: outing.status
        )
        outings[index] = updated
        return updated
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
    case invalidDraft(String)
    case timeOverlap
    case missingRejectionReason
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidDraft(let message): message
        case .timeOverlap: "같은 날짜에 시간이 겹치는 외출 신청이 있어요."
        case .missingRejectionReason: "거절 사유를 입력해 주세요."
        case .notFound: "외출 신청을 찾을 수 없어요."
        }
    }
}
