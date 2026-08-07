import Foundation

protocol OutingRepository {
    func fetchOutings(for role: AccountRole) async throws -> [OutingRequest]
    func searchTeachers(keyword: String) async throws -> [OutingTeacher]
    func submit(_ draft: OutingDraft) async throws -> OutingRequest
    func decide(_ outing: OutingRequest, approve: Bool, rejectionReason: String?) async throws -> OutingRequest
    func cancel(_ outing: OutingRequest) async throws
}
