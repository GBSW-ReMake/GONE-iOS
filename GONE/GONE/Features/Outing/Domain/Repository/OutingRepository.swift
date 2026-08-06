import Foundation

protocol OutingRepository {
    func fetchCurrentOuting() async throws -> OutingRequest?
    func submit(_ draft: OutingDraft) async throws -> OutingRequest
    func cancel(_ outing: OutingRequest) async throws
    func start(_ outing: OutingRequest) async throws -> OutingRequest
    func completeReturn(_ outing: OutingRequest) async throws -> OutingRequest
}
