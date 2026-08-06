import Combine
import Foundation

@MainActor
final class SchoolCampingViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded
        case failed
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var calendarDays: [CampingCalendarDay] = []
    @Published private(set) var reservation: SchoolCampingReservation?
    @Published var displayedMonth: Date
    @Published var selectedDate: Date?
    @Published private(set) var errorMessage: String?

    private let repository: SchoolCampingRepository
    private let calendar = Calendar.current

    init(repository: SchoolCampingRepository, displayedMonth: Date = Date()) {
        self.repository = repository
        self.displayedMonth = calendar.startOfMonth(for: displayedMonth)
    }

    func load() async {
        state = .loading
        do {
            reservation = try await repository.fetchCurrentReservation()
            calendarDays = try await repository.fetchCalendarDays(for: displayedMonth)
            state = .loaded
        } catch {
            errorMessage = "스쿨캠핑 정보를 불러오지 못했어요."
            state = .failed
        }
    }

    func moveMonth(by value: Int) async {
        guard let month = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = calendar.startOfMonth(for: month)
        selectedDate = nil
        await loadCalendarDays()
    }

    func select(_ day: CampingCalendarDay) {
        guard day.availability == .available else { return }
        selectedDate = day.date
    }

    func makeDraft() -> SchoolCampingReservationDraft? {
        guard let selectedDate else { return nil }
        return makeDraft(for: selectedDate)
    }

    func makeDraft(for date: Date) -> SchoolCampingReservationDraft {
        return SchoolCampingReservationDraft(
            date: date,
            teacherName: "",
            participants: [CampingParticipant(studentNumber: "3206", name: "김은찬")]
        )
    }

    func searchStudents(query: String) async -> [CampingStudent] {
        do {
            return try await repository.searchStudents(query: query)
        } catch {
            errorMessage = "학생을 검색하지 못했어요."
            return []
        }
    }

    func searchTeachers(query: String) async -> [CampingTeacher] {
        do {
            return try await repository.searchTeachers(query: query)
        } catch {
            errorMessage = "선생님을 검색하지 못했어요."
            return []
        }
    }

    func submit(_ draft: SchoolCampingReservationDraft) async {
        do {
            reservation = try await repository.submit(draft)
            selectedDate = nil
            await loadCalendarDays()
        } catch {
            errorMessage = "스쿨캠핑 예약을 신청하지 못했어요."
        }
    }

    func updateReservation(_ draft: SchoolCampingReservationDraft) async -> Bool {
        do {
            let updatedReservation = try await repository.update(draft)
            if reservation !== updatedReservation {
                reservation = updatedReservation
            }
            await loadCalendarDays()
            return true
        } catch {
            errorMessage = "참여 명단을 수정하지 못했어요."
            return false
        }
    }

    func cancelReservation() async {
        guard let reservation else { return }
        do {
            try await repository.cancel(reservation)
            self.reservation = nil
            await loadCalendarDays()
        } catch {
            errorMessage = "스쿨캠핑 예약을 취소하지 못했어요."
        }
    }

    private func loadCalendarDays() async {
        do {
            calendarDays = try await repository.fetchCalendarDays(for: displayedMonth)
        } catch {
            errorMessage = "달력을 불러오지 못했어요."
        }
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}
