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
            student: OutingStudent(name: "김은찬", studentNumber: "3206", profileImageName: "student-profile"),
            date: today,
            departureTime: departure,
            returnTime: returnTime,
            reason: "병원 진료",
            teacher: teachers[0],
            status: .outing
        )]
    }

    func fetchOutings(for role: AccountRole) async throws -> [OutingRequest] {
        role == .teacher ? outings : outings.filter { $0.student.studentNumber == "3206" }
    }

    func fetchRoute(for outing: OutingRequest) async throws -> OutingRoute {
        let calendar = Calendar.current
        let startedAt = calendar.date(byAdding: .minute, value: -18, to: Date()) ?? Date()
        let points = samplePoints
        return OutingRoute(
            outingID: outing.id,
            points: points,
            startedAt: startedAt,
            updatedAt: Date(),
            status: outing.status == .completed ? .arrived : .outing
        )
    }

    func startOuting(_ outing: OutingRequest) async throws -> OutingRequest {
        guard let index = outings.firstIndex(where: { $0.id == outing.id }) else { throw OutingRepositoryError.notFound }
        outings[index].status = .outing
        return outings[index]
    }

    func completeReturn(_ outing: OutingRequest) async throws -> OutingRequest {
        guard let index = outings.firstIndex(where: { $0.id == outing.id }) else { throw OutingRepositoryError.notFound }
        outings[index].status = .completed
        return outings[index]
    }

    func locationStream(for outing: OutingRequest) async -> AsyncStream<OutingRoute> {
        let points = samplePoints
        let startedAt = Calendar.current.date(byAdding: .minute, value: -18, to: Date()) ?? Date()
        return AsyncStream { continuation in
            continuation.yield(OutingRoute(outingID: outing.id, points: Array(points.prefix(2)), startedAt: startedAt, updatedAt: Date(), status: .outing))
            Task {
                for count in 3...points.count {
                    try? await Task.sleep(for: .seconds(3))
                    guard !Task.isCancelled else { return }
                    continuation.yield(OutingRoute(outingID: outing.id, points: Array(points.prefix(count)), startedAt: startedAt, updatedAt: Date(), status: .outing))
                }
                continuation.finish()
            }
        }
    }

    private var samplePoints: [OutingCoordinate] {
        [
            OutingCoordinate(latitude: 35.1579, longitude: 128.9825),
            OutingCoordinate(latitude: 35.1584, longitude: 128.9831),
            OutingCoordinate(latitude: 35.1591, longitude: 128.9840),
            OutingCoordinate(latitude: 35.1595, longitude: 128.9850),
            OutingCoordinate(latitude: 35.1602, longitude: 128.9857)
        ]
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
