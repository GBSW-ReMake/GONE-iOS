import SwiftUI
import UIKit

struct SchoolCampingView: View {
    @ObservedObject var viewModel: SchoolCampingViewModel
    @State private var isShowingForm = false

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("스쿨캠핑 정보를 불러오는 중")
                case .loaded:
                    if let reservation = viewModel.reservation {
                        SchoolCampingReservationCompleteView(reservation: reservation) {
                            Task { await viewModel.cancelReservation() }
                        }
                    } else {
                        SchoolCampingCalendarView(viewModel: viewModel) { day in
                            viewModel.select(day)
                            isShowingForm = viewModel.selectedDate != nil
                        }
                    }
                case .failed:
                    ContentUnavailableView {
                        Label("스쿨캠핑 정보를 불러올 수 없어요", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text("잠시 후 다시 시도해 주세요.")
                    } actions: {
                        Button("다시 시도") { Task { await viewModel.load() } }
                    }
                }
            }
            .background(Color.goneScreenBackground.ignoresSafeArea())
            .navigationDestination(isPresented: $isShowingForm) {
                if let draft = viewModel.makeDraft() {
                    SchoolCampingReservationForm(draft: draft, searchStudents: viewModel.searchStudents) { submittedDraft in
                        isShowingForm = false
                        await viewModel.submit(submittedDraft)
                    }
                }
            }
        }
        .task {
            guard viewModel.state == .loading else { return }
            await viewModel.load()
        }
    }
}

private struct SchoolCampingCalendarView: View {
    @ObservedObject var viewModel: SchoolCampingViewModel
    let selectDate: (CampingCalendarDay) -> Void
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.section) {
                HStack {
                    Text("스쿨캠핑")
                        .font(.caption)
                        .foregroundStyle(Color.goneTextSecondary)
                    Spacer()
                    if viewModel.reservation != nil {
                        Text("내 예약")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.goneTextSecondary)
                    }
                }

                Text("원하는 날짜를 선택하세요")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.goneTextPrimary)

                VStack(spacing: GONESpacing.large) {
                    monthNavigation
                    weekdayHeader
                    calendarGrid
                }
                .padding(GONESpacing.large)
                .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 16))

                legend
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .navigationTitle("스쿨캠핑")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var monthNavigation: some View {
        HStack(spacing: 36) {
            Button { Task { await viewModel.moveMonth(by: -1) } } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("이전 달")

            Text(CampingDisplayFormatter.month(viewModel.displayedMonth))
                .font(.headline.weight(.semibold))

            Button { Task { await viewModel.moveMonth(by: 1) } } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("다음 달")
        }
        .foregroundStyle(Color.goneTextPrimary)
        .frame(maxWidth: .infinity)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { weekday in
                Text(weekday)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.goneTextSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach((0..<leadingEmptyDays).map { _ in CalendarCell(day: nil) }, id: \.id) { cell in
                Color.clear.frame(height: 52).accessibilityHidden(true)
            }
            ForEach(viewModel.calendarDays.map(CalendarCell.day)) { cell in
                Button { if let day = cell.day { selectDate(day) } } label: {
                    CampingDayCell(
                        day: cell.day,
                        isSelected: cell.day.map { calendar.isDate($0.date, inSameDayAs: viewModel.selectedDate ?? .distantPast) } ?? false
                    )
                }
                .buttonStyle(.plain)
                .disabled(cell.day?.availability != .available)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: GONESpacing.medium) {
            CampingLegendItem(color: .goneSurfacePrimary, title: "예약 가능", hasBorder: true)
            CampingLegendItem(color: .goneTextPrimary, title: "내 예약")
            CampingLegendItem(color: .goneSurfaceDisabled, title: "예약 불가")
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var leadingEmptyDays: Int {
        calendar.component(.weekday, from: viewModel.displayedMonth) - 1
    }
}

private struct SchoolCampingReservationForm: View {
    let submit: (SchoolCampingReservationDraft) async -> Void
    let searchStudents: (String) async -> [CampingStudent]
    @Environment(\.dismiss) private var dismiss
    @State private var teacherName: String
    @State private var participants: [CampingParticipant]
    @State private var isSubmitting = false
    @State private var isShowingStudentSearch = false
    let date: Date

    init(
        draft: SchoolCampingReservationDraft,
        searchStudents: @escaping (String) async -> [CampingStudent],
        submit: @escaping (SchoolCampingReservationDraft) async -> Void
    ) {
        self.date = draft.date
        self.searchStudents = searchStudents
        self.submit = submit
        _teacherName = State(initialValue: draft.teacherName)
        _participants = State(initialValue: draft.participants)
    }

    private var draft: SchoolCampingReservationDraft {
        SchoolCampingReservationDraft(date: date, teacherName: teacherName, participants: participants)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                selectedDateRow
                formSection(title: "담당 선생님") {
                    TextField("담당 선생님", text: $teacherName)
                        .textInputAutocapitalization(.never)
                }
                participantSection
                GONEPrimaryButton(
                    title: "예약하기",
                    isEnabled: draft.isValid,
                    isLoading: isSubmitting,
                    disabledBackground: Color.goneBrandPrimary.opacity(0.48),
                    disabledForeground: .white
                ) {
                    isSubmitting = true
                    let submission = draft
                    Task {
                        await submit(submission)
                    }
                }
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .background(Color.goneScreenBackground.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { dismissKeyboard() }
        .sheet(isPresented: $isShowingStudentSearch) {
            StudentSearchSheet(searchStudents: searchStudents) { student in
                addParticipant(student)
                isShowingStudentSearch = false
            }
            .presentationDetents([.medium, .large])
            .presentationBackground(Color.goneSurfacePrimary)
            .preferredColorScheme(.light)
        }
        .navigationTitle("예약")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var selectedDateRow: some View {
        HStack {
            Text("선택한 날짜").font(.subheadline).foregroundStyle(Color.goneTextSecondary)
            Spacer()
            Text(CampingDisplayFormatter.dateWithWeekday(date))
                .font(.subheadline.weight(.semibold))
        }
        .padding(GONESpacing.large)
        .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault))
    }

    private var participantSection: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text("사용 인원").font(.headline.weight(.bold))
                Text("본인포함").font(.caption).foregroundStyle(Color.goneTextSecondary)
                Spacer()
                Text("\(participants.count) / 8명").font(.caption).foregroundStyle(Color.goneTextSecondary)
            }

            ForEach(participants) { participant in
                HStack(spacing: GONESpacing.small) {
                    Text(participant.studentNumber)
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 58, alignment: .leading)
                    Text(participant.name)
                    if participants.count > 1 {
                        Button { removeParticipant(id: participant.id) } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.goneTextTertiary)
                        }
                        .accessibilityLabel("참여 인원 삭제")
                    }
                }
                .font(.subheadline)
                .padding(GONESpacing.medium)
                .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.goneBorderDefault))
            }

            Button { isShowingStudentSearch = true } label: {
                Label("인원 추가", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundStyle(Color.goneTextSecondary)
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.goneTextSecondary, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
            }
            .disabled(participants.count >= 8)

            Text("학생을 검색해 추가할 수 있습니다. 최대 8명까지 예약할 수 있습니다.")
                .font(.caption2)
                .foregroundStyle(Color.goneTextSecondary)
        }
    }

    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text(title).font(.headline.weight(.bold))
            content()
                .font(.subheadline)
                .padding(GONESpacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.goneBorderDefault))
        }
    }

    private func addParticipant(_ student: CampingStudent) {
        guard participants.count < 8 else { return }
        guard !participants.contains(where: { $0.studentNumber == student.studentNumber }) else { return }
        participants.append(CampingParticipant(studentNumber: student.studentNumber, name: student.name))
    }

    private func removeParticipant(id: UUID) {
        participants.removeAll { $0.id == id }
    }
}

private struct SchoolCampingReservationCompleteView: View {
    let reservation: SchoolCampingReservation
    let cancel: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                HStack {
                    (Text("예약 ") + Text("신청").foregroundStyle(Color.goneBrandPrimary) + Text(" 완료"))
                        .font(.title2.weight(.bold))
                    Spacer()
                    Text("달력 보기").font(.subheadline.weight(.semibold)).foregroundStyle(Color.goneTextSecondary)
                }

                VStack(alignment: .leading, spacing: GONESpacing.large) {
                    Text("예약 완료")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.goneBrandPrimary)
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(Color.goneBrandPrimary.opacity(0.12), in: Capsule())
                    Text(CampingDisplayFormatter.dateTitle(reservation.date))
                        .font(.title3.weight(.bold))
                    CampingDetailRow(title: "담당 선생님", value: reservation.teacherName)
                    Divider()
                    CampingDetailRow(title: "예약 인원", value: "\(reservation.participants.count)명 / 최대 8명")
                    Divider()
                    CampingDetailRow(title: "대표 학생", value: reservation.representative?.displayName ?? "-")
                    Button { } label: {
                        HStack { Text("참여 명단 확인 · 수정"); Spacer(); Image(systemName: "chevron.right") }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.goneTextPrimary)
                            .padding(GONESpacing.medium)
                            .background(Color.goneSurfaceDisabled, in: RoundedRectangle(cornerRadius: 12))
                    }
                    Button("예약 취소", action: cancel)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.goneStatusReturn)
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.goneStatusReturn))
                }
                .padding(GONESpacing.large)
                .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.goneBrandPrimary.opacity(0.12)))

                Text("예약한 날짜는 달력에서 내 예약 상태로 표시됩니다.")
                    .font(.footnote).foregroundStyle(Color.goneTextSecondary)
                    .padding(GONESpacing.large)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneTextSecondary.opacity(0.5)))
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
    }
}

private struct CampingDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.goneTextSecondary)
            Spacer(minLength: GONESpacing.large)
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(Color.goneTextPrimary).multilineTextAlignment(.trailing)
        }
    }
}

private struct StudentSearchSheet: View {
    let searchStudents: (String) async -> [CampingStudent]
    let select: (CampingStudent) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [CampingStudent] = []

    var body: some View {
        NavigationStack {
            List(results) { student in
                Button { select(student) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(student.displayName).font(.body.weight(.semibold))
                            Text("학생 추가").font(.caption).foregroundStyle(Color.goneTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill").foregroundStyle(Color.goneBrandPrimary)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView("검색 결과가 없어요", systemImage: "person.crop.circle.badge.questionmark", description: Text("학번 또는 이름으로 다시 검색해 주세요."))
                }
            }
            .searchable(text: $query, prompt: "학번 또는 이름 검색")
            .navigationTitle("학생 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .task { await loadResults() }
        .task(id: query) { await loadResults() }
    }

    private func loadResults() async {
        results = await searchStudents(query)
    }
}

private enum CampingDisplayFormatter {
    static func month(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: date)
    }

    static func dateWithWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.string(from: date)
    }

    static func dateTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: date)
    }
}

private func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

private struct CalendarCell: Identifiable {
    let id = UUID()
    let day: CampingCalendarDay?

    static func day(_ day: CampingCalendarDay) -> CalendarCell { CalendarCell(day: day) }
}

private struct CampingDayCell: View {
    let day: CampingCalendarDay?
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(day.map { String(Calendar.current.component(.day, from: $0.date)) } ?? "")
                .font(.caption.weight(.semibold))
            if let day, day.availability != .available {
                Text(day.availability == .reservedByMe ? "예약됨" : "불가")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(day.availability == .reservedByMe ? Color.goneSurfacePrimary : Color.goneTextTertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(day.availability == .reservedByMe ? Color.goneTextPrimary : Color.goneSurfaceDisabled, in: Capsule())
            }
        }
        .foregroundStyle(textColor)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(isSelected ? Color.goneBrandPrimary.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.goneBrandPrimary : .clear, lineWidth: 1.5))
        .accessibilityLabel(accessibilityLabel)
    }

    private var textColor: Color {
        guard let day else { return .clear }
        return day.availability == .unavailable ? .goneTextTertiary : .goneTextPrimary
    }

    private var accessibilityLabel: String {
        guard let day else { return "" }
        let date = day.date.formatted(.dateTime.year().month().day())
        let status: String = switch day.availability {
        case .available: "예약 가능"
        case .unavailable: "예약 불가"
        case .reservedByMe: "내 예약"
        }
        return "\(date), \(status)"
    }
}

private struct CampingLegendItem: View {
    let color: Color
    let title: String
    var hasBorder = false

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 9, height: 9)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(hasBorder ? Color.goneBorderDefault : .clear))
            Text(title).font(.caption2).foregroundStyle(Color.goneTextSecondary)
        }
    }
}
