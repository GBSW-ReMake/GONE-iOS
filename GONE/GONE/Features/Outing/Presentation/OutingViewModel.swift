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
        errorMessage = nil
        do {
            let submittedOuting = try await repository.submit(draft)
            outings.append(submittedOuting)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func submitPreview(_ draft: OutingDraft) -> Bool {
        let normalizedDraft = draft.normalizedToSelectedDate()
        let teacher = normalizedDraft.teacher ?? OutingTeacher(
            id: "teacher-preview",
            name: "이00 선생님",
            affiliation: "teacher"
        )
        outings.append(OutingRequest(
            id: "O-\(UUID().uuidString)",
            student: OutingStudent(name: "김은찬", studentNumber: "3206"),
            date: normalizedDraft.date,
            departureTime: normalizedDraft.departureTime,
            returnTime: normalizedDraft.returnTime,
            reason: normalizedDraft.reason.isEmpty ? "개인 사유" : normalizedDraft.reason,
            teacher: teacher,
            status: .pendingApproval
        ))
        return true
    }

    func cancelPreview(_ outing: OutingRequest) {
        outings.removeAll { $0.id == outing.id }
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
