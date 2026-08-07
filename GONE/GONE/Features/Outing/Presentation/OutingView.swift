import SwiftUI

struct OutingView: View {
    @ObservedObject var viewModel: OutingViewModel
    @State private var isShowingForm = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("외출 정보를 불러오는 중")
                } else if viewModel.role == .teacher {
                    TeacherOutingListView(viewModel: viewModel)
                } else {
                    StudentOutingListView(viewModel: viewModel, isShowingForm: $isShowingForm)
                }
            }
            .background(Color.goneScreenBackground.ignoresSafeArea())
            .navigationDestination(isPresented: $isShowingForm) {
                OutingRequestForm(searchTeachers: viewModel.searchTeachers) { draft in
                    if await viewModel.submit(draft) { isShowingForm = false }
                }
            }
            .alert("외출 신청", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task { await viewModel.load() }
    }
}

private struct StudentOutingListView: View {
    @ObservedObject var viewModel: OutingViewModel
    @Binding var isShowingForm: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.large) {
                Text("외출 신청").font(.largeTitle.bold())
                Text("이번 주 안에서만 신청할 수 있으며, 시간이 겹치지 않으면 여러 건을 신청할 수 있어요.")
                    .font(.subheadline).foregroundStyle(Color.goneTextSecondary)
                ForEach(viewModel.outings) { outing in
                    StudentOutingCard(outing: outing) { Task { await viewModel.cancel(outing) } }
                }
                if viewModel.outings.isEmpty {
                    ContentUnavailableView("신청한 외출이 없어요", systemImage: "figure.walk")
                }
                GONEPrimaryButton(title: "외출 신청", isEnabled: true, isLoading: false) {
                    isShowingForm = true
                }
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .navigationTitle("외출")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct OutingRequestForm: View {
    let searchTeachers: (String) async -> [OutingTeacher]
    let submit: (OutingDraft) async -> Void
    @State private var draft = OutingDraft()
    @State private var isSubmitting = false
    @State private var isShowingDatePicker = false
    @State private var isShowingTeacherSearch = false

    private let lunch = (11 * 60 + 50, 13 * 60 + 10)
    private let dinner = (17 * 60 + 30, 19 * 60)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                Text("외출 신청").font(.title2.bold())
                Text("신청 가능 기간: 이번 주 · 가능 시간: 오전 8:40 ~ 오후 8:30")
                    .font(.footnote).foregroundStyle(Color.goneTextSecondary)
                    .padding(GONESpacing.medium).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.goneBrandPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                formField(title: "외출 날짜") {
                    Button { isShowingDatePicker = true } label: {
                        fieldLabel(dateText(draft.date), icon: "calendar")
                    }.buttonStyle(.plain)
                }
                VStack(alignment: .leading, spacing: GONESpacing.small) {
                    Text("시간 프리셋").font(.headline)
                    HStack(spacing: GONESpacing.medium) {
                        presetButton("점심", minutes: lunch)
                        presetButton("저녁", minutes: dinner)
                    }
                }
                VStack(alignment: .leading, spacing: GONESpacing.small) {
                    Text("직접 시간 설정").font(.headline)
                    HStack(spacing: GONESpacing.medium) {
                        DatePicker("출발", selection: $draft.departureTime, displayedComponents: .hourAndMinute).datePickerStyle(.compact)
                        DatePicker("복귀", selection: $draft.returnTime, displayedComponents: .hourAndMinute).datePickerStyle(.compact)
                    }
                    .padding(GONESpacing.medium)
                    .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14))
                }
                formField(title: "담당 선생님") {
                    Button { isShowingTeacherSearch = true } label: {
                        fieldLabel(draft.teacher?.name ?? "선생님 검색", icon: "magnifyingglass")
                    }.buttonStyle(.plain)
                }
                formField(title: "외출 사유") {
                    TextEditor(text: $draft.reason)
                        .frame(minHeight: 120).padding(GONESpacing.small)
                        .scrollContentBackground(.hidden)
                        .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault))
                }
                if let message = draft.validationMessage {
                    Text(message).font(.footnote).foregroundStyle(Color.goneStatusError)
                }
                GONEPrimaryButton(title: "외출 신청하기", isEnabled: draft.isValid, isLoading: isSubmitting) {
                    isSubmitting = true
                    Task { await submit(draft); isSubmitting = false }
                }
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .background(Color.goneScreenBackground.ignoresSafeArea())
        .navigationTitle("외출 신청")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: draft.date) { _, newDate in alignTimes(to: newDate) }
        .sheet(isPresented: $isShowingDatePicker) { DatePickerSheet(date: $draft.date) }
        .sheet(isPresented: $isShowingTeacherSearch) {
            OutingTeacherSearchSheet(search: searchTeachers) { draft.teacher = $0 }
        }
    }

    private func formField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) { Text(title).font(.headline); content() }
    }

    private func presetButton(_ title: String, minutes: (Int, Int)) -> some View {
        Button(title) { setTime(start: minutes.0, end: minutes.1) }
            .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 46)
            .foregroundStyle(Color.goneBrandPrimary)
            .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.goneBrandPrimary.opacity(0.35)))
    }

    private func fieldLabel(_ title: String, icon: String) -> some View {
        HStack { Text(title).foregroundStyle(Color.goneTextPrimary); Spacer(); Image(systemName: icon).foregroundStyle(Color.goneTextSecondary) }
            .padding(.horizontal, GONESpacing.large).frame(height: 54)
            .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault))
    }

    private func setTime(start: Int, end: Int) {
        let day = Calendar.current.startOfDay(for: draft.date)
        draft.departureTime = Calendar.current.date(byAdding: .minute, value: start, to: day) ?? day
        draft.returnTime = Calendar.current.date(byAdding: .minute, value: end, to: day) ?? day
    }

    private func alignTimes(to date: Date) {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let departure = calendar.dateComponents([.hour, .minute], from: draft.departureTime)
        let returnTime = calendar.dateComponents([.hour, .minute], from: draft.returnTime)
        draft.departureTime = calendar.date(bySettingHour: departure.hour ?? 8, minute: departure.minute ?? 40, second: 0, of: day) ?? day
        draft.returnTime = calendar.date(bySettingHour: returnTime.hour ?? 9, minute: returnTime.minute ?? 10, second: 0, of: day) ?? day
    }
}

private struct TeacherOutingListView: View {
    @ObservedObject var viewModel: OutingViewModel

    var body: some View {
        List(viewModel.outings) { outing in
            NavigationLink { TeacherOutingDetailView(outing: outing, decide: viewModel.decide) } label: {
                VStack(alignment: .leading, spacing: GONESpacing.small) {
                    statusBadge(outing.status)
                        .padding(.bottom, 4)
                    HStack(spacing: 5) {
                        Text(outing.student.studentNumber).font(.headline)
                        Text(outing.student.name).font(.headline).foregroundStyle(Color.goneBrandPrimary)
                        Text("외출").font(.headline)
                    }
                    Text(dateText(outing.date)).font(.caption).foregroundStyle(Color.goneTextSecondary)
                    Text("\(timeText(outing.departureTime)) ~ \(timeText(outing.returnTime))")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.goneTextPrimary)
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("외출 신청 목록")
        .overlay { if viewModel.outings.isEmpty { ContentUnavailableView("대기 중인 신청이 없어요", systemImage: "checkmark.circle") } }
    }
}

private struct TeacherOutingDetailView: View {
    let outing: OutingRequest
    let decide: (OutingRequest, Bool, String?) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var isRejecting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.large) {
                statusBadge(outing.status)
                    .padding(.bottom, 4)
                HStack(spacing: 5) {
                    Text(outing.student.studentNumber).font(.title2.bold())
                    Text(outing.student.name).font(.title2.bold()).foregroundStyle(Color.goneBrandPrimary)
                    Text("외출").font(.title2.bold())
                }
                detailRow("학적 정보", outing.student.studentNumber)
                detailRow("날짜", dateText(outing.date))
                detailRow("시간", "\(timeText(outing.departureTime)) ~ \(timeText(outing.returnTime))")
                detailRow("사유", outing.reason)
                detailRow("지정 선생님", outing.teacher.name)
                if case .pendingApproval = outing.status { actionButtons }
            }.padding(.horizontal, GONESpacing.screenHorizontal).padding(.vertical, GONESpacing.xLarge)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("외출 상세")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var actionButtons: some View {
        HStack(spacing: GONESpacing.medium) {
            Button("거절") { isRejecting = true }
                .frame(maxWidth: .infinity, minHeight: 52)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.goneStatusError)
                .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneStatusError))
            Button("수락") { Task { if await decide(outing, true, nil) { dismiss() } } }
                .frame(maxWidth: .infinity, minHeight: 52)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .background(Color.goneBrandPrimary, in: RoundedRectangle(cornerRadius: 14))
        }
        .sheet(isPresented: $isRejecting) {
            RejectionReasonSheet { reason in
                Task { if await decide(outing, false, reason) { dismiss() } }
            }
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) { Text(title).font(.footnote).foregroundStyle(Color.goneTextSecondary); Text(value).font(.body) }
    }
}

private struct OutingTeacherSearchSheet: View {
    let search: (String) async -> [OutingTeacher]
    let select: (OutingTeacher) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var keyword = ""
    @State private var teachers: [OutingTeacher] = []

    var body: some View {
        NavigationStack {
            List(teachers) { teacher in
                Button { select(teacher); dismiss() } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(teacher.name).font(.body.weight(.semibold))
                            Text("담당 선생님으로 선택").font(.caption).foregroundStyle(Color.goneTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(Color.goneBrandPrimary)
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
            .searchable(text: $keyword, prompt: "선생님 이름 검색")
            .navigationTitle("선생님 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
        }
        .task(id: keyword) { teachers = await search(keyword) }
    }
}

private struct DatePickerSheet: View {
    @Binding var date: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker("외출 날짜", selection: $date, in: weekRange, displayedComponents: .date)
                .datePickerStyle(.graphical).padding().navigationTitle("외출 날짜")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } } }
        }
    }

    private var weekRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 7 - calendar.component(.weekday, from: today), to: today) ?? today
        return today...end
    }
}

private struct StudentOutingCard: View {
    let outing: OutingRequest
    let cancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            statusBadge(outing.status)
            Text(dateText(outing.date)).font(.headline)
            Text("\(timeText(outing.departureTime)) ~ \(timeText(outing.returnTime))").font(.title3.bold())
            Text(outing.reason).foregroundStyle(Color.goneTextSecondary)
            Text("담당: \(outing.teacher.name)").font(.footnote).foregroundStyle(Color.goneTextSecondary)
            if case .pendingApproval = outing.status { Button("신청 취소", role: .destructive, action: cancel).font(.footnote.weight(.semibold)) }
        }
        .padding(GONESpacing.large).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 16))
    }
}

@ViewBuilder private func statusLabel(_ status: OutingRequest.Status) -> some View {
    switch status {
    case .pendingApproval: Text("승인 대기").foregroundStyle(Color.goneStatusOuting)
    case .approved: Text("승인됨").foregroundStyle(Color.goneBrandPrimary)
    case .rejected(let reason): Text("거절 · \(reason)").foregroundStyle(Color.goneStatusError)
    }
}

@ViewBuilder private func statusBadge(_ status: OutingRequest.Status) -> some View {
    switch status {
    case .pendingApproval:
        Text("승인 요청")
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.goneStatusOuting)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Color.goneStatusOuting.opacity(0.14), in: Capsule())
    case .approved:
        Text("승인 완료")
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.goneBrandPrimary)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Color.goneBrandPrimary.opacity(0.12), in: Capsule())
    case .rejected:
        Text("거절됨")
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.goneStatusError)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Color.goneStatusError.opacity(0.12), in: Capsule())
    }
}

private struct RejectionReasonSheet: View {
    let submit: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: GONESpacing.large) {
                Text("거절 사유를 입력해 주세요")
                    .font(.title3.bold())
                TextEditor(text: $reason)
                    .frame(minHeight: 150)
                    .padding(GONESpacing.small)
                    .scrollContentBackground(.hidden)
                    .background(Color.goneSurfaceDisabled, in: RoundedRectangle(cornerRadius: 14))
                Button("거절하기") { submit(reason); dismiss() }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .background(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.goneBrandPrimary.opacity(0.45) : Color.goneStatusError, in: RoundedRectangle(cornerRadius: 14))
                    .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Spacer()
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.top, GONESpacing.xLarge)
            .navigationTitle("외출 거절")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

private func dateText(_ date: Date) -> String {
    let formatter = DateFormatter(); formatter.locale = Locale(identifier: "ko_KR"); formatter.dateFormat = "M월 d일 (E)"; return formatter.string(from: date)
}

private func timeText(_ date: Date) -> String {
    let formatter = DateFormatter(); formatter.locale = Locale(identifier: "ko_KR"); formatter.dateFormat = "a h:mm"; return formatter.string(from: date)
}
