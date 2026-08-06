import Combine
import SwiftUI
import UIKit

struct SchoolCampingView: View {
    @ObservedObject var viewModel: SchoolCampingViewModel
    @State private var activeReservationDate: Date?
    @State private var pendingSubmission: SchoolCampingReservationDraft?
    @State private var pendingParticipantUpdate: SchoolCampingReservationDraft?
    @State private var isShowingReservationForm = false
    @State private var isShowingCalendar = false
    @State private var isShowingParticipantList = false

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("스쿨캠핑 정보를 불러오는 중")
                case .loaded:
                    if let reservation = viewModel.reservation, !isShowingCalendar {
                        SchoolCampingReservationCompleteView(
                            reservation: reservation,
                            showCalendar: { isShowingCalendar = true },
                            showParticipants: { isShowingParticipantList = true },
                            cancel: {
                                Task { await viewModel.cancelReservation() }
                            }
                        )
                    } else {
                        SchoolCampingCalendarView(
                            viewModel: viewModel,
                            showReservation: viewModel.reservation == nil ? nil : { isShowingCalendar = false }
                        ) { day in
                            guard viewModel.reservation == nil else { return }
                            viewModel.select(day)
                            activeReservationDate = day.date
                            isShowingReservationForm = true
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
        }
        .fullScreenCover(isPresented: $isShowingParticipantList, onDismiss: submitPendingParticipantUpdate) {
            if let reservation = viewModel.reservation {
                NavigationStack {
                    SchoolCampingParticipantListView(
                        reservation: reservation,
                        searchStudents: viewModel.searchStudents,
                        searchTeachers: viewModel.searchTeachers,
                        save: queueParticipantUpdate,
                        close: { isShowingParticipantList = false }
                    )
                }
                .preferredColorScheme(.light)
            }
        }
        .fullScreenCover(isPresented: $isShowingReservationForm, onDismiss: submitPendingReservation) {
            if let date = activeReservationDate {
                NavigationStack {
                    SchoolCampingReservationForm(
                        draft: viewModel.makeDraft(for: date),
                        searchStudents: viewModel.searchStudents,
                        searchTeachers: viewModel.searchTeachers,
                        close: closeReservationForm,
                        submit: queueSubmission
                    )
                }
                .preferredColorScheme(.light)
            }
        }
        .task {
            guard viewModel.state == .loading else { return }
            await viewModel.load()
        }
    }

    private func closeReservationForm() {
        pendingSubmission = nil
        isShowingReservationForm = false
    }

    private func queueSubmission(_ draft: SchoolCampingReservationDraft) {
        pendingSubmission = draft
        isShowingReservationForm = false
    }

    private func submitPendingReservation() {
        activeReservationDate = nil
        guard let draft = pendingSubmission else { return }
        pendingSubmission = nil

        Task {
            await viewModel.submit(draft)
        }
    }

    private func queueParticipantUpdate(_ draft: SchoolCampingReservationDraft) {
        pendingParticipantUpdate = draft
        isShowingParticipantList = false
    }

    private func submitPendingParticipantUpdate() {
        guard let draft = pendingParticipantUpdate else { return }
        pendingParticipantUpdate = nil

        Task {
            if await viewModel.updateReservation(draft) {
                isShowingParticipantList = true
            }
        }
    }
}

private struct SchoolCampingCalendarView: View {
    @ObservedObject var viewModel: SchoolCampingViewModel
    let showReservation: (() -> Void)?
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
                    if let showReservation {
                        Button("내 예약", action: showReservation)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.goneTextSecondary)
                            .buttonStyle(.plain)
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
            ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                Color.clear.frame(height: 52).accessibilityHidden(true)
            }
            ForEach(viewModel.calendarDays) { day in
                Button { selectDate(day) } label: {
                    CampingDayCell(
                        day: day,
                        isSelected: calendar.isDate(day.date, inSameDayAs: viewModel.selectedDate ?? .distantPast)
                    )
                }
                .buttonStyle(.plain)
                .disabled(day.availability != .available || viewModel.reservation != nil)
                .accessibilityIdentifier(
                    "\(day.availability == .available ? "schoolCampingAvailableDate" : "schoolCampingDate")-\(day.id.timeIntervalSince1970)"
                )
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
    let close: () -> Void
    let submit: (SchoolCampingReservationDraft) -> Void
    let searchStudents: (String) async -> [CampingStudent]
    let searchTeachers: (String) async -> [CampingTeacher]
    @State private var teacherName: String
    @State private var participants: [CampingParticipant]
    @State private var isShowingStudentSearch = false
    @State private var isShowingTeacherSearch = false
    let date: Date

    init(
        draft: SchoolCampingReservationDraft,
        searchStudents: @escaping (String) async -> [CampingStudent],
        searchTeachers: @escaping (String) async -> [CampingTeacher],
        close: @escaping () -> Void,
        submit: @escaping (SchoolCampingReservationDraft) -> Void
    ) {
        self.date = draft.date
        self.searchStudents = searchStudents
        self.searchTeachers = searchTeachers
        self.close = close
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
                teacherSection
                participantSection
                GONEPrimaryButton(
                    title: "예약하기",
                    isEnabled: draft.isValid,
                    isLoading: false,
                    disabledBackground: Color.goneBrandPrimary.opacity(0.48),
                    disabledForeground: .white
                ) {
                    submit(draft)
                }
                .accessibilityIdentifier("schoolCampingSubmitButton")
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
            }
            .presentationDetents([.medium, .large])
            .presentationBackground(Color.goneSurfacePrimary)
            .preferredColorScheme(.light)
        }
        .sheet(isPresented: $isShowingTeacherSearch) {
            TeacherSearchSheet(searchTeachers: searchTeachers) { teacher in
                teacherName = teacher.name
            }
            .presentationDetents([.medium, .large])
            .presentationBackground(Color.goneSurfacePrimary)
            .preferredColorScheme(.light)
        }
        .navigationTitle("예약")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: close) {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.goneTextPrimary)
                }
                .accessibilityLabel("예약 화면 닫기")
            }
        }
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

    private var teacherSection: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text("담당 선생님").font(.headline.weight(.bold))
            Button { isShowingTeacherSearch = true } label: {
                HStack {
                    Text(teacherName.isEmpty ? "선생님 검색" : teacherName)
                        .foregroundStyle(teacherName.isEmpty ? Color.goneTextTertiary : Color.goneTextPrimary)
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.goneTextSecondary)
                }
                .font(.subheadline)
                .padding(GONESpacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.goneBorderDefault))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("schoolCampingTeacherSearchButton")
        }
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
    @ObservedObject var reservation: SchoolCampingReservation
    let showCalendar: () -> Void
    let showParticipants: () -> Void
    let cancel: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                HStack {
                    HStack(spacing: 4) {
                        Text("예약")
                        Text("신청").foregroundStyle(Color.goneBrandPrimary)
                        Text("완료")
                    }
                    .font(.title2.weight(.bold))
                    Spacer()
                    Button("달력 보기", action: showCalendar)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.goneTextSecondary)
                        .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: GONESpacing.large) {
                    Text("예약 완료")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.goneBrandPrimary)
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(Color.goneBrandPrimary.opacity(0.12), in: Capsule())
                        .accessibilityIdentifier("schoolCampingReservationComplete")
                    Text(CampingDisplayFormatter.dateTitle(reservation.date))
                        .font(.title3.weight(.bold))
                    CampingDetailRow(title: "담당 선생님", value: reservation.teacherName)
                    Divider()
                    CampingDetailRow(title: "예약 인원", value: "\(reservation.participants.count)명")
                    Divider()
                    CampingDetailRow(title: "대표 학생", value: reservation.representative?.displayName ?? "-")
                    Button(action: showParticipants) {
                        HStack { Text("참여 명단 확인 · 수정"); Spacer(); Image(systemName: "chevron.right") }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.goneTextPrimary)
                            .padding(GONESpacing.medium)
                            .background(Color.goneSurfaceDisabled, in: RoundedRectangle(cornerRadius: 12))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: cancel) {
                        Text("예약 취소")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.goneStatusReturn)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.goneStatusReturn))
                }
                .padding(GONESpacing.large)
                .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.goneBrandPrimary.opacity(0.12)))

                Text("예약한 날짜는 달력에서 내 예약 상태로 표시됩니다.")
                    .font(.footnote)
                    .foregroundStyle(Color.goneTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 64)
                    .padding(.horizontal, GONESpacing.medium)
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

@MainActor
private final class SchoolCampingParticipantEditor: ObservableObject {
    @Published var teacherName: String
    @Published var participants: [CampingParticipant]

    init(reservation: SchoolCampingReservation) {
        teacherName = reservation.teacherName
        participants = reservation.participants
    }

    func makeDraft(for date: Date) -> SchoolCampingReservationDraft {
        SchoolCampingReservationDraft(date: date, teacherName: teacherName, participants: participants)
    }

    func add(_ student: CampingStudent) {
        guard participants.count < 8 else { return }
        guard !participants.contains(where: { $0.studentNumber == student.studentNumber }) else { return }
        participants.append(CampingParticipant(studentNumber: student.studentNumber, name: student.name))
    }

    func remove(id: UUID) {
        participants.removeAll { $0.id == id }
    }

    func reset(using reservation: SchoolCampingReservation) {
        teacherName = reservation.teacherName
        participants = reservation.participants
    }

    func participantNumber(for participant: CampingParticipant) -> Int {
        (participants.firstIndex(where: { $0.id == participant.id }) ?? 0) + 1
    }
}

private struct SchoolCampingParticipantListView: View {
    @ObservedObject var reservation: SchoolCampingReservation
    let searchStudents: (String) async -> [CampingStudent]
    let searchTeachers: (String) async -> [CampingTeacher]
    let save: (SchoolCampingReservationDraft) -> Void
    let close: () -> Void

    @State private var isShowingEditor = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: GONESpacing.large) {
                teacherSection

                Text("참여 학생")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.goneTextPrimary)

                ForEach(reservation.participants) { participant in
                    participantRow(participant)
                }
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .background(Color.goneScreenBackground.ignoresSafeArea())
        .navigationTitle("참여 명단")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: close) {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.goneTextPrimary)
                }
                .accessibilityLabel("참여 명단 닫기")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingEditor = true
                } label: {
                    Text("수정")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.goneBrandPrimary)
                        .padding(.horizontal, GONESpacing.medium)
                        .frame(minHeight: 40)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("참여 명단 수정")
            }
        }
        .fullScreenCover(isPresented: $isShowingEditor) {
            NavigationStack {
                SchoolCampingParticipantEditView(
                    reservation: reservation,
                    searchStudents: searchStudents,
                    searchTeachers: searchTeachers,
                    save: finishEditing,
                    close: { isShowingEditor = false }
                )
            }
            .preferredColorScheme(.light)
        }
    }

    private var teacherSection: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text("담당 선생님")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.goneTextPrimary)

            HStack(spacing: GONESpacing.medium) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.goneBrandPrimary)

                Text(reservation.teacherName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.goneTextPrimary)

                Spacer()
            }
            .padding(.horizontal, GONESpacing.large)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 62)
            .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault))
        }
    }

    private func participantRow(_ participant: CampingParticipant) -> some View {
        HStack(spacing: GONESpacing.medium) {
            Text("\(participantNumber(for: participant))")
                .font(.subheadline)
                .foregroundStyle(Color.goneTextTertiary)
                .frame(width: 24, alignment: .leading)

            Text(participant.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.goneTextPrimary)

            Spacer()
        }
        .padding(.horizontal, GONESpacing.large)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 64)
        .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault))
    }

    private func participantNumber(for participant: CampingParticipant) -> Int {
        (reservation.participants.firstIndex(where: { $0.id == participant.id }) ?? 0) + 1
    }

    private func finishEditing(_ draft: SchoolCampingReservationDraft) {
        isShowingEditor = false

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            save(draft)
        }
    }
}

private struct SchoolCampingParticipantEditView: View {
    let reservation: SchoolCampingReservation
    let searchStudents: (String) async -> [CampingStudent]
    let searchTeachers: (String) async -> [CampingTeacher]
    let save: (SchoolCampingReservationDraft) -> Void
    let close: () -> Void

    @StateObject private var editor: SchoolCampingParticipantEditor
    @State private var isShowingStudentSearch = false
    @State private var isShowingTeacherSearch = false

    init(
        reservation: SchoolCampingReservation,
        searchStudents: @escaping (String) async -> [CampingStudent],
        searchTeachers: @escaping (String) async -> [CampingTeacher],
        save: @escaping (SchoolCampingReservationDraft) -> Void,
        close: @escaping () -> Void
    ) {
        self.reservation = reservation
        self.searchStudents = searchStudents
        self.searchTeachers = searchTeachers
        self.save = save
        self.close = close
        _editor = StateObject(wrappedValue: SchoolCampingParticipantEditor(reservation: reservation))
    }

    private var draft: SchoolCampingReservationDraft {
        editor.makeDraft(for: reservation.date)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: GONESpacing.large) {
                teacherSection

                Text("참여 학생")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.goneTextPrimary)

                ForEach(editor.participants) { participant in
                    participantRow(participant)
                }

                addParticipantButton
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .background(Color.goneScreenBackground.ignoresSafeArea())
        .navigationTitle("명단 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: close) {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.goneTextPrimary)
                }
                .accessibilityLabel("명단 수정 닫기")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            editActions
        }
        .sheet(isPresented: $isShowingStudentSearch) {
            StudentSearchSheet(searchStudents: searchStudents) { student in
                addParticipant(student)
            }
            .presentationDetents([.medium, .large])
            .presentationBackground(Color.goneSurfacePrimary)
            .preferredColorScheme(.light)
        }
        .sheet(isPresented: $isShowingTeacherSearch) {
            TeacherSearchSheet(searchTeachers: searchTeachers) { teacher in
                editor.teacherName = teacher.name
            }
            .presentationDetents([.medium, .large])
            .presentationBackground(Color.goneSurfacePrimary)
            .preferredColorScheme(.light)
        }
    }

    private var teacherSection: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text("담당 선생님")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.goneTextPrimary)

            Button {
                isShowingTeacherSearch = true
            } label: {
                HStack {
                    Text(editor.teacherName)
                        .foregroundStyle(Color.goneTextPrimary)
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.goneBrandPrimary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("schoolCampingParticipantTeacherSearchButton")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, GONESpacing.large)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 62)
            .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault))
        }
    }

    private func participantRow(_ participant: CampingParticipant) -> some View {
        HStack(spacing: GONESpacing.medium) {
            Text("\(participantNumber(for: participant))")
                .font(.subheadline)
                .foregroundStyle(Color.goneTextTertiary)
                .frame(width: 24, alignment: .leading)

            Text(participant.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.goneTextPrimary)

            Spacer()

            if editor.participants.count > 1 {
                Button {
                    removeParticipant(id: participant.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.goneTextTertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(participant.displayName) 삭제")
            }
        }
        .padding(.leading, GONESpacing.large)
        .padding(.trailing, GONESpacing.small)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 64)
        .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault))
    }

    private var addParticipantButton: some View {
        Button {
            isShowingStudentSearch = true
        } label: {
            Label("인원 추가", systemImage: "plus")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.goneTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(editor.participants.count >= 8)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.goneTextSecondary, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        )
    }

    private var editActions: some View {
        HStack(spacing: GONESpacing.medium) {
            Button {
                cancelEditing()
            } label: {
                Text("취소")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.goneTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault))

            Button {
                saveChanges()
            } label: {
                Text("수정")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(draft.isValid ? Color.goneBrandPrimary : Color.goneBrandPrimary.opacity(0.48))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(!draft.isValid)
            .accessibilityIdentifier("schoolCampingParticipantSaveButton")
        }
        .padding(.horizontal, GONESpacing.screenHorizontal)
        .padding(.vertical, GONESpacing.medium)
        .background(Color.goneScreenBackground)
    }

    private func participantNumber(for participant: CampingParticipant) -> Int {
        editor.participantNumber(for: participant)
    }

    private func addParticipant(_ student: CampingStudent) {
        editor.add(student)
    }

    private func removeParticipant(id: UUID) {
        editor.remove(id: id)
    }

    private func cancelEditing() {
        editor.reset(using: reservation)
        close()
    }

    private func saveChanges() {
        guard draft.isValid else { return }

        if draft == SchoolCampingReservationDraft(
            date: reservation.date,
            teacherName: reservation.teacherName,
            participants: reservation.participants
        ) {
            close()
        } else {
            save(draft)
        }
    }
}

private struct StudentSearchSheet: View {
    let searchStudents: (String) async -> [CampingStudent]
    let select: (CampingStudent) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [CampingStudent] = []
    @State private var isClosing = false
    @FocusState private var isQueryFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField(prompt: "학번 또는 이름 검색")
                    .padding(.horizontal, GONESpacing.screenHorizontal)
                    .padding(.vertical, GONESpacing.medium)

                ZStack {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(results) { student in
                                Button { choose(student) } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(student.displayName).font(.body.weight(.semibold))
                                            Text("학생 추가").font(.caption).foregroundStyle(Color.goneTextSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill").foregroundStyle(Color.goneBrandPrimary)
                                    }
                                    .contentShape(Rectangle())
                                    .padding(.horizontal, GONESpacing.screenHorizontal)
                                    .padding(.vertical, GONESpacing.medium)
                                }
                                .buttonStyle(.plain)
                                .disabled(isClosing)

                                Divider()
                                    .padding(.leading, GONESpacing.screenHorizontal)
                            }
                        }
                    }

                    if results.isEmpty {
                        ContentUnavailableView(
                            "검색 결과가 없어요",
                            systemImage: "person.crop.circle.badge.questionmark",
                            description: Text("학번 또는 이름으로 다시 검색해 주세요.")
                        )
                    }
                }
            }
            .background(Color.goneSurfacePrimary)
            .navigationTitle("학생 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { close() }
                        .disabled(isClosing)
                }
            }
        }
        .task(id: query) { await loadResults() }
    }

    private func searchField(prompt: String) -> some View {
        HStack(spacing: GONESpacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.goneTextSecondary)
            TextField(prompt, text: $query)
                .focused($isQueryFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.goneTextTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(.horizontal, GONESpacing.medium)
        .frame(height: 44)
        .background(Color.goneSurfaceDisabled, in: RoundedRectangle(cornerRadius: 12))
    }

    private func loadResults() async {
        if !query.isEmpty {
            try? await Task.sleep(for: .milliseconds(120))
        }
        guard !Task.isCancelled else { return }
        let matches = await searchStudents(query)
        guard !Task.isCancelled else { return }
        results = matches
    }

    private func choose(_ student: CampingStudent) {
        finishKeyboardInteraction {
            select(student)
        }
    }

    private func close() {
        finishKeyboardInteraction()
    }

    private func finishKeyboardInteraction(action: @escaping () -> Void = {}) {
        guard !isClosing else { return }
        isClosing = true
        isQueryFocused = false

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            action()
            dismiss()
        }
    }
}

private struct TeacherSearchSheet: View {
    let searchTeachers: (String) async -> [CampingTeacher]
    let select: (CampingTeacher) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [CampingTeacher] = []
    @State private var isClosing = false
    @FocusState private var isQueryFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                    .padding(.horizontal, GONESpacing.screenHorizontal)
                    .padding(.vertical, GONESpacing.medium)

                ZStack {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(results) { teacher in
                                Button { choose(teacher) } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(teacher.name).font(.body.weight(.semibold))
                                            Text("담당 선생님으로 선택")
                                                .font(.caption)
                                                .foregroundStyle(Color.goneTextSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(Color.goneBrandPrimary)
                                    }
                                    .contentShape(Rectangle())
                                    .padding(.horizontal, GONESpacing.screenHorizontal)
                                    .padding(.vertical, GONESpacing.medium)
                                }
                                .buttonStyle(.plain)
                                .disabled(isClosing)
                                .accessibilityIdentifier("schoolCampingTeacher-\(teacher.id)")

                                Divider()
                                    .padding(.leading, GONESpacing.screenHorizontal)
                            }
                        }
                    }

                    if results.isEmpty {
                        ContentUnavailableView(
                            "검색 결과가 없어요",
                            systemImage: "person.crop.circle.badge.questionmark",
                            description: Text("선생님 이름으로 다시 검색해 주세요.")
                        )
                    }
                }
            }
            .background(Color.goneSurfacePrimary)
            .navigationTitle("선생님 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { close() }
                        .disabled(isClosing)
                }
            }
        }
        .task(id: query) { await loadResults() }
    }

    private var searchField: some View {
        HStack(spacing: GONESpacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.goneTextSecondary)
            TextField("선생님 이름 검색", text: $query)
                .focused($isQueryFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.goneTextTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(.horizontal, GONESpacing.medium)
        .frame(height: 44)
        .background(Color.goneSurfaceDisabled, in: RoundedRectangle(cornerRadius: 12))
    }

    private func loadResults() async {
        if !query.isEmpty {
            try? await Task.sleep(for: .milliseconds(120))
        }
        guard !Task.isCancelled else { return }
        let matches = await searchTeachers(query)
        guard !Task.isCancelled else { return }
        results = matches
    }

    private func choose(_ teacher: CampingTeacher) {
        finishKeyboardInteraction {
            select(teacher)
        }
    }

    private func close() {
        finishKeyboardInteraction()
    }

    private func finishKeyboardInteraction(action: @escaping () -> Void = {}) {
        guard !isClosing else { return }
        isClosing = true
        isQueryFocused = false

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            action()
            dismiss()
        }
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
