import Combine
import Foundation

@MainActor
final class OutingViewModel: ObservableObject {
    @Published private(set) var outings: [OutingRequest] = []
    @Published private(set) var route: OutingRoute?
    @Published private(set) var canMonitorOutings = false
    @Published private(set) var isLocationSharing = false
    @Published private(set) var lastLocationUpdate: Date?
    @Published private(set) var locationSharingState: OutingLocationManager.SharingState = .idle
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    let role: AccountRole
    private let repository: OutingRepository
    private let hasLeaderRole: Bool
    private let locationManager = OutingLocationManager()
    private var locationTask: Task<Void, Never>?
    private var deviceLocationTask: Task<Void, Never>?

    init(role: AccountRole, repository: OutingRepository, hasLeaderRole: Bool = false) {
        self.role = role
        self.repository = repository
        self.hasLeaderRole = hasLeaderRole
        canMonitorOutings = role == .student && hasLeaderRole
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            outings = try await repository.fetchOutings(for: role)
        }
        catch { errorMessage = "외출 정보를 불러오지 못했어요." }
    }

    func loadRoute(for outing: OutingRequest) async {
        do {
            route = try await repository.fetchRoute(for: outing)
            lastLocationUpdate = route?.updatedAt
            if case .outing = outing.status {
                startLocationSharing(for: outing)
            }
        } catch {
            errorMessage = "외출 경로를 불러오지 못했어요."
        }
    }

    func startLocationSharing(for outing: OutingRequest) {
        locationTask?.cancel()
        isLocationSharing = true
        locationTask = Task { [weak self] in
            guard let self else { return }
            let stream = await repository.locationStream(for: outing)
            for await nextRoute in stream {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.route = nextRoute
                    self.lastLocationUpdate = nextRoute.updatedAt
                }
            }
        }
    }

    func stopLocationSharing() {
        locationTask?.cancel()
        locationTask = nil
        deviceLocationTask?.cancel()
        deviceLocationTask = nil
        isLocationSharing = false
        locationManager.stopSharing()
        locationSharingState = locationManager.state
    }

    func startOuting(_ outing: OutingRequest) async {
        do {
            let started = try await repository.startOuting(outing)
            outings = outings.map { $0.id == started.id ? started : $0 }
            locationManager.requestPermissionAndStartSharing()
            locationSharingState = locationManager.state
            let locationUpdates = locationManager.updates()
            deviceLocationTask = Task { [weak self] in
                for await coordinate in locationUpdates {
                    guard !Task.isCancelled else { return }
                    await MainActor.run { self?.appendLocation(coordinate) }
                }
            }
            await loadRoute(for: started)
        } catch {
            errorMessage = "외출 시작 처리에 실패했어요."
        }
    }

    func completeReturn(for outing: OutingRequest) async {
        do {
            let completed = try await repository.completeReturn(outing)
            if let currentRoute = route {
                route = OutingRoute(
                    outingID: currentRoute.outingID,
                    points: currentRoute.points,
                    startedAt: currentRoute.startedAt,
                    updatedAt: Date(),
                    status: .arrived
                )
            }
            outings = outings.map { $0.id == completed.id ? completed : $0 }
            stopLocationSharing()
        } catch {
            errorMessage = "복귀 완료 처리에 실패했어요."
        }
    }

    deinit {
        locationTask?.cancel()
        deviceLocationTask?.cancel()
    }

    private func appendLocation(_ coordinate: OutingCoordinate) {
        guard let route else { return }
        let updatedPoints = route.points + [coordinate]
        self.route = OutingRoute(
            outingID: route.outingID,
            points: updatedPoints,
            startedAt: route.startedAt,
            updatedAt: Date(),
            status: .outing
        )
        lastLocationUpdate = self.route?.updatedAt
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

    func updatePreview(_ outing: OutingRequest, with draft: OutingDraft) -> OutingRequest? {
        guard let index = outings.firstIndex(where: { $0.id == outing.id }) else { return nil }
        let normalizedDraft = draft.normalizedToSelectedDate()
        let updated = OutingRequest(
            id: outing.id,
            student: outing.student,
            date: normalizedDraft.date,
            departureTime: normalizedDraft.departureTime,
            returnTime: normalizedDraft.returnTime,
            reason: normalizedDraft.reason.isEmpty ? outing.reason : normalizedDraft.reason,
            teacher: normalizedDraft.teacher ?? outing.teacher,
            status: outing.status
        )
        outings[index] = updated
        return updated
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
