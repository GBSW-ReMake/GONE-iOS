import Foundation

actor MockOutingRepository: OutingRepository {
    private var currentOuting: OutingRequest?

    func fetchCurrentOuting() async throws -> OutingRequest? { currentOuting }

    func submit(_ draft: OutingDraft) async throws -> OutingRequest {
        let outing = OutingRequest(
            id: "O-0729-06",
            date: draft.date,
            departureTime: draft.departureTime,
            returnTime: draft.returnTime,
            reason: draft.reason,
            status: .pendingApproval
        )
        currentOuting = outing
        return outing
    }

    func cancel(_ outing: OutingRequest) async throws { currentOuting = nil }

    func start(_ outing: OutingRequest) async throws -> OutingRequest {
        var updated = outing
        updated.status = .outing(minutesRemaining: max(1, Int(outing.returnTime.timeIntervalSinceNow / 60)))
        currentOuting = updated
        return updated
    }

    func completeReturn(_ outing: OutingRequest) async throws -> OutingRequest {
        var updated = outing
        updated.status = .completed
        currentOuting = updated
        return updated
    }
}
