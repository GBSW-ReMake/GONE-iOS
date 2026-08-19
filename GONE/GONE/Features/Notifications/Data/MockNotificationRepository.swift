import Foundation

struct MockNotificationRepository: NotificationRepository {
    func fetchNotifications(for role: AccountRole) async throws -> [AppNotification] {
        let now = Date()
        switch role {
        case .student:
            return [
                AppNotification(id: "student-camping-open", kind: .camping, title: "8월 스쿨캠핑이 오픈되었습니다", message: "8월 스쿨캠핑 예약이 시작됐어요. 원하는 날짜를 확인해 주세요", date: now, relativeTime: "방금 전", isRead: false),
                AppNotification(id: "student-outing-approved", kind: .outing, title: "외출 신청이 승인되었습니다", message: "오늘 14:00~17:50 외출이 승인되어 외출증이 발급됐어요", date: now.addingTimeInterval(-30 * 60), relativeTime: "30분 전", isRead: false),
                AppNotification(id: "student-reward", kind: .reward, title: "상점 5점이 발급 되었습니다", message: "학교 홍보 활동에 성실히 참여한 학생 항목으로 발급됐어요", date: now.addingTimeInterval(-60 * 60), relativeTime: "1시간 전", isRead: false),
                AppNotification(id: "student-penalty", kind: .penalty, title: "벌점 3점이 발급되었습니다", message: "교복을 착용하지 않은 학생", date: now.addingTimeInterval(-24 * 60 * 60), relativeTime: "어제", isRead: true),
                AppNotification(id: "student-lab-approved", kind: .lab, title: "실습실 대여가 승인되었습니다", message: "오늘 19:00~21:00 iOS실을 이용할 수 있어요", date: now.addingTimeInterval(-24 * 60 * 60), relativeTime: "어제", isRead: true),
                AppNotification(id: "student-camping-recent", kind: .camping, title: "8월 스쿨캠핑이 오픈되었습니다", message: "8월 스쿨캠핑 예약이 시작됐어요. 원하는 날짜를 확인해 주세요", date: now.addingTimeInterval(-3 * 24 * 60 * 60), relativeTime: "8월 12일", isRead: true),
                AppNotification(id: "student-outing-recent", kind: .outing, title: "외출 신청이 승인되었습니다", message: "오늘 14:00~17:50 외출이 승인되어 외출증이 발급됐어요", date: now.addingTimeInterval(-4 * 24 * 60 * 60), relativeTime: "8월 11일", isRead: true),
                AppNotification(id: "student-reward-recent", kind: .reward, title: "상점 5점이 발급 되었습니다", message: "학교 홍보 활동에 성실히 참여한 학생 항목으로 발급됐어요", date: now.addingTimeInterval(-5 * 24 * 60 * 60), relativeTime: "8월 9일", isRead: true)
            ]
        case .teacher:
            return [
                AppNotification(id: "teacher-camping-request", kind: .camping, title: "박지민 학생이 스쿨캠핑을 신청 했습니다.", message: "8월 12일 · 학생 6명", date: now, relativeTime: "방금 전", isRead: false),
                AppNotification(id: "teacher-camping-open", kind: .camping, title: "8월 스쿨캠핑이 오픈되었습니다", message: "8월 스쿨캠핑 예약이 시작됐어요. 원하는 날짜를 확인해 주세요", date: now, relativeTime: "방금 전", isRead: false),
                AppNotification(id: "teacher-outing-request", kind: .outing, title: "김은찬 학생이 외출을 신청 했습니다.", message: "2학년 2반 6번 · 오늘 14:00~17:00 · 병원방문", date: now.addingTimeInterval(-30 * 60), relativeTime: "30분 전", isRead: false),
                AppNotification(id: "teacher-outing-request-yesterday", kind: .outing, title: "정문경 학생이 외출을 신청 했습니다.", message: "3학년 2반 18번 · 오늘 14:00~17:00 · 병원방문", date: now.addingTimeInterval(-24 * 60 * 60), relativeTime: "30분 전", isRead: true),
                AppNotification(id: "teacher-lab-request", kind: .lab, title: "김은찬 학생이 실습실을 대여 신청 했습니다", message: "8월 11일 · 8명 · 19:00~21:00 · iOS실", date: now.addingTimeInterval(-24 * 60 * 60), relativeTime: "어제", isRead: true),
                AppNotification(id: "teacher-outing-recent", kind: .outing, title: "정문경 학생이 외출을 신청 했습니다.", message: "3학년 2반 18번 · 오늘 14:00~17:00 · 병원방문", date: now.addingTimeInterval(-3 * 24 * 60 * 60), relativeTime: "30분 전", isRead: true),
                AppNotification(id: "teacher-lab-recent", kind: .lab, title: "김은찬 학생이 실습실을 대여 신청 했습니다", message: "8월 11일 · 8명 · 19:00~21:00 · iOS실", date: now.addingTimeInterval(-4 * 24 * 60 * 60), relativeTime: "어제", isRead: true)
            ]
        }
    }

    func markAllAsRead(for role: AccountRole) async throws { }
}
