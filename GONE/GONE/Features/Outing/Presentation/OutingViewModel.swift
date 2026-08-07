import Combine
import Foundation

@MainActor
final class OutingViewModel: ObservableObject {
    @Published private(set) var outings: [OutingRequest] = []
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    let role: AccountRole
    private let repository: OutingRepository

    init(role: AccountRole, repository: OutingRepository) {
        self.role = role
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do { outings = try await repository.fetchOutings(for: role) }
        catch { errorMessage = "외출 정보를 불러오지 못했어요." }
    }

    func searchTeachers(_ keyword: String) async -> [OutingTeacher] {
        (try? await repository.searchTeachers(keyword: keyword)) ?? []
    }

    func submit(_ draft: OutingDraft) async -> Bool {
        do {
            let submittedOuting = try await repository.submit(draft)
            outings.append(submittedOuting)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func update(_ outing: OutingRequest, with draft: OutingDraft) async -> Bool {
        do {
            _ = try await repository.update(outing, with: draft)
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func decide(_ outing: OutingRequest, approve: Bool, rejectionReason: String? = nil) async -> Bool {
        do {
            _ = try await repository.decide(outing, approve: approve, rejectionReason: rejectionReason)
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func cancel(_ outing: OutingRequest) async {
        do { try await repository.cancel(outing); await load() }
        catch { errorMessage = error.localizedDescription }
    }
}
