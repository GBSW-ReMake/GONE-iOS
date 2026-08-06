import Combine
import Foundation

@MainActor
final class OutingViewModel: ObservableObject {
    @Published private(set) var outing: OutingRequest?
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    private let repository: OutingRepository

    init(repository: OutingRepository) { self.repository = repository }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do { outing = try await repository.fetchCurrentOuting() }
        catch { errorMessage = "외출 정보를 불러오지 못했어요." }
    }

    func submit(_ draft: OutingDraft) async {
        do { outing = try await repository.submit(draft) }
        catch { errorMessage = "외출 신청에 실패했어요." }
    }

    func cancel() async {
        guard let outing else { return }
        do {
            try await repository.cancel(outing)
            self.outing = nil
        } catch { errorMessage = "외출 신청을 취소하지 못했어요." }
    }

    func startOuting() async {
        guard let outing else { return }
        do { self.outing = try await repository.start(outing) }
        catch { errorMessage = "외출을 시작하지 못했어요." }
    }

    func completeReturn() async {
        guard let outing else { return }
        do { self.outing = try await repository.completeReturn(outing) }
        catch { errorMessage = "복귀 처리를 완료하지 못했어요." }
    }

    func simulateApprovalForPreview() {
        guard var outing else { return }
        outing.status = .readyToLeave(returnTime: outing.returnTime)
        self.outing = outing
    }

    func simulateWaitingToStartForPreview() {
        guard var outing else { return }
        outing.status = .waitingToStart(minutesRemaining: 10)
        self.outing = outing
    }

    func simulateReturnAreaForPreview() {
        guard var outing else { return }
        outing.status = .readyToReturn(minutesRemaining: 5)
        self.outing = outing
    }
}
