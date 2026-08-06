import Foundation

struct OutingRequest: Identifiable, Equatable {
    enum Status: Equatable {
        case pendingApproval
        case waitingToStart(minutesRemaining: Int)
        case readyToLeave(returnTime: Date)
        case outing(minutesRemaining: Int)
        case readyToReturn(minutesRemaining: Int)
        case completed
    }

    let id: String
    let date: Date
    let departureTime: Date
    let returnTime: Date
    let reason: String
    var status: Status
}

struct OutingDraft: Equatable {
    var date = Date()
    var departureTime = Date()
    var returnTime = Date().addingTimeInterval(30 * 60)
    var reason = ""

    var isValid: Bool {
        returnTime > departureTime && !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
