import Foundation

protocol OutingRepository {
    func fetchOutings(for role: AccountRole) async throws -> [OutingRequest]
    func fetchRoute(for outing: OutingRequest) async throws -> OutingRoute
    func startOuting(_ outing: OutingRequest) async throws -> OutingRequest
    func completeReturn(_ outing: OutingRequest) async throws -> OutingRequest
    func locationStream(for outing: OutingRequest) async -> AsyncStream<OutingRoute>
    func searchTeachers(keyword: String) async throws -> [OutingTeacher]
    func submit(_ draft: OutingDraft) async throws -> OutingRequest
    func update(_ outing: OutingRequest, with draft: OutingDraft) async throws -> OutingRequest
    func decide(_ outing: OutingRequest, approve: Bool, rejectionReason: String?) async throws -> OutingRequest
    func cancel(_ outing: OutingRequest) async throws
}
