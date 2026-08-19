import SwiftUI

@MainActor
struct PointSystemView: View {
    private enum Section: String, CaseIterable, Identifiable, Hashable {
        case issue = "점수발급"
        case history = "발급 내역"
        case statistics = "통계"

        var id: String { rawValue }
    }

    @State private var selectedSection: Section = .issue
    @State private var isShowingStudentSearch = false
    @State private var editingStudent: PointStudent?
    @State private var isShowingIssueCompletion = false
    @State private var completedRecords: [PointIssueRecord] = []
    @StateObject private var viewModel: PointSystemViewModel

    init() {
        _viewModel = StateObject(wrappedValue: PointSystemViewModel(repository: MockPointRepository()))
    }

    init(viewModel: PointSystemViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                    header
                    sectionPicker
                    sectionContent
                }
                .padding(.horizontal, GONESpacing.screenHorizontal)
                .padding(.vertical, GONESpacing.xLarge)
            }
            .background(Color.goneScreenBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
            .sheet(isPresented: $isShowingStudentSearch) {
                StudentSearchView(viewModel: viewModel) { student in
                    isShowingStudentSearch = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        editingStudent = student
                    }
                }
            }
            .fullScreenCover(item: $editingStudent) { student in
                PointIssueFormView(viewModel: viewModel, student: student) {
                    editingStudent = nil
                }
            }
            .fullScreenCover(isPresented: $isShowingIssueCompletion) {
                PointIssueCompletionView(records: completedRecords) {
                    completedRecords = []
                    isShowingIssueCompletion = false
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if selectedSection == .issue {
                    IssueBottomBar(
                        isEnabled: !viewModel.selectedStudents.isEmpty,
                        onClear: viewModel.clearSelection,
                        onIssue: {
                            Task {
                                if await viewModel.issueAll() {
                                    completedRecords = viewModel.lastIssuedRecords
                                    isShowingIssueCompletion = true
                                }
                            }
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 18)
                    .background(Color.goneScreenBackground)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text("상벌점 시스템")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.goneTextSecondary)
            Text("상벌점 점수 발급")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.goneTextPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(Section.allCases) { section in
                Button { selectedSection = section } label: {
                    Text(section.rawValue)
                        .font(.system(size: 15, weight: selectedSection == section ? .bold : .medium))
                        .foregroundStyle(selectedSection == section ? Color.goneBrandPrimary : Color.goneTextSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(selectedSection == section ? Color.white : .clear, in: RoundedRectangle(cornerRadius: 12))
                        .shadow(color: selectedSection == section ? .black.opacity(0.08) : .clear, radius: 3, y: 1)
                }
            }
        }
        .padding(4)
        .background(Color(red: 235 / 255, green: 236 / 255, blue: 238 / 255), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("상벌점 메뉴")
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .issue:
            IssueContent(
                selectedStudents: viewModel.selectedStudents,
                onAddTap: { isShowingStudentSearch = true },
                onStudentTap: { editingStudent = $0 },
                onRemove: viewModel.removeStudent
            )
        case .history:
            HistoryContent(records: viewModel.records)
        case .statistics:
            StatisticsContent(statistics: viewModel.statistics)
        }
    }
}

private struct IssueContent: View {
    let selectedStudents: [PointStudent]
    let onAddTap: () -> Void
    let onStudentTap: (PointStudent) -> Void
    let onRemove: (PointStudent) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.large) {
            if selectedStudents.isEmpty {
                IssueEmptyState(onAddTap: onAddTap)
            } else {
                Text("발급 명단")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.goneTextPrimary)
                ForEach(selectedStudents) { student in
                    Button { onStudentTap(student) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(student.name).font(.headline)
                                Text(student.studentInfo).font(.caption).foregroundStyle(Color.goneTextSecondary)
                            }
                            Spacer()
                            Color.clear.frame(width: 40, height: 40)
                        }
                    }
                    .padding(.horizontal, GONESpacing.large)
                    .frame(height: 72)
                    .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: GONECornerRadius.button))
                    .overlay(alignment: .trailing) {
                        Button { onRemove(student) } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundStyle(Color.goneTextPrimary)
                                .frame(width: 40, height: 40)
                        }
                        .padding(.trailing, 12)
                        .accessibilityLabel("\(student.name) 발급 명단에서 삭제")
                    }
                    .buttonStyle(.plain)
                }
                Button("+ 발급 대상자 추가", action: onAddTap)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 304)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color.goneBrandPrimary)
                    .overlay { RoundedRectangle(cornerRadius: GONECornerRadius.button).stroke(Color.goneBrandPrimary, lineWidth: 1.5) }
            }
        }
        .padding(.bottom, 28)
    }
}

private struct IssueBottomBar: View {
    let isEnabled: Bool
    let onClear: () -> Void
    let onIssue: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button("전체 삭제", role: .destructive, action: onClear)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 112, height: 56)
                .foregroundStyle(Color.goneStatusError)
                .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.goneStatusError, lineWidth: 1.5) }
            Button("점수 발급", action: onIssue)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(.white)
                .background(isEnabled ? Color.goneBrandPrimary : Color(red: 204 / 255, green: 207 / 255, blue: 212 / 255), in: RoundedRectangle(cornerRadius: 16))
                .disabled(!isEnabled)
        }
    }
}

@MainActor
private struct StudentSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PointSystemViewModel
    let onStudentAdded: (PointStudent) -> Void
    @State private var query = ""

    private var filteredStudents: [PointStudent] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return viewModel.students }
        return viewModel.students.filter { $0.name.contains(trimmed) || $0.id.contains(trimmed) }
    }

    var body: some View {
        NavigationStack {
            List(filteredStudents) { student in
                Button {
                    viewModel.addStudent(student)
                    onStudentAdded(student)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(student.id) \(student.name)").font(.headline).foregroundStyle(Color.goneTextPrimary)
                            Text("학생 추가").font(.caption).foregroundStyle(Color.goneTextSecondary)
                        }
                        Spacer()
                        Image(systemName: viewModel.selectedStudents.contains(student) ? "checkmark.circle.fill" : "plus.circle.fill")
                            .foregroundStyle(Color.goneBrandPrimary)
                    }
                }
                .disabled(viewModel.selectedStudents.contains(student))
            }
            .searchable(text: $query, prompt: "학번 또는 이름 검색")
            .navigationTitle("학생 검색")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
        }
    }
}

@MainActor
private struct PointIssueFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PointSystemViewModel
    let student: PointStudent
    let onSaved: () -> Void
    @State private var draft: PointIssueDraft
    @FocusState private var isMemoFocused: Bool

    init(viewModel: PointSystemViewModel, student: PointStudent, onSaved: @escaping () -> Void) {
        self.viewModel = viewModel
        self.student = student
        self.onSaved = onSaved
        _draft = State(initialValue: viewModel.draft(for: student))
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                formNavigationHeader
                    .padding(.top, 12)
                successBanner
                    .padding(.top, 14)
                studentCard
                    .padding(.top, 12)
                kindPicker
                    .padding(.top, 12)
                issueItemField
                    .padding(.top, 18)
                memoField
                    .padding(.top, 16)
            }
            .padding(.horizontal, 24)
            Spacer(minLength: 0)
            actionBar
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 12)
        }
        .background(Color.goneScreenBackground.ignoresSafeArea())
        .preferredColorScheme(.light)
        .contentShape(Rectangle())
        .onTapGesture { isMemoFocused = false }
    }

    private var formNavigationHeader: some View {
        ZStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.goneTextPrimary)
                        .frame(width: 36, height: 36)
                }
                Spacer()
            }
            Text("상벌점 발급")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(Color.goneTextPrimary)
        }
        .frame(height: 36)
    }

    private var successBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
            Text("\(student.name) 학생을 추가했습니다.")
                .font(.system(size: 15, weight: .medium))
        }
        .foregroundStyle(Color(red: 52 / 255, green: 199 / 255, blue: 123 / 255))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(red: 225 / 255, green: 243 / 255, blue: 236 / 255), in: RoundedRectangle(cornerRadius: 8))
    }

    private var studentCard: some View {
        HStack {
            Text(student.name).font(.system(size: 20, weight: .bold))
            Text(student.studentInfo).font(.system(size: 13)).foregroundStyle(Color.goneTextSecondary)
            Spacer()
            Button { viewModel.removeStudent(student); dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 18, weight: .heavy)).foregroundStyle(.black)
            }
            .frame(width: 44, height: 44)
            .accessibilityLabel("\(student.name) 삭제")
        }
        .padding(.horizontal, 22)
        .frame(height: 56)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
    }

    private var kindPicker: some View {
        HStack(spacing: 20) {
            kindButton(.reward)
            kindButton(.penalty)
        }
    }

    private func kindButton(_ kind: PointKind) -> some View {
        Button { draft.kind = kind } label: {
            Text(kind.rawValue)
                .font(.system(size: 17, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(draft.kind == kind ? .white : (kind == .reward ? Color(red: 52 / 255, green: 199 / 255, blue: 123 / 255) : Color.goneStatusError))
                .background(draft.kind == kind ? (kind == .reward ? Color(red: 52 / 255, green: 199 / 255, blue: 123 / 255) : Color.goneStatusError) : .white, in: RoundedRectangle(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).stroke(kind == .reward ? Color(red: 52 / 255, green: 199 / 255, blue: 123 / 255) : Color.goneStatusError, lineWidth: draft.kind == kind ? 0 : 1) }
        }
    }

    private var issueItemField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("발급 항목").font(.system(size: 18, weight: .bold)).foregroundStyle(Color.goneTextPrimary)
            Menu {
                Button("[2점] 학교 홍보 활동에 성실히 참여한 학생") { draft.points = 2; draft.item = "학교 홍보 활동에 성실히 참여한 학생" }
                Button("[1점] 교내 행사에 참여한 학생") { draft.points = 1; draft.item = "교내 행사에 참여한 학생" }
                Button("[3점] 수업시간 교사지시 불이행") { draft.points = 3; draft.item = "수업시간 교사지시 불이행" }
            } label: {
                HStack {
                    Text("[\(draft.points)점] \(draft.item)").font(.system(size: 16, weight: .medium)).foregroundStyle(Color.goneTextPrimary).lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down").font(.system(size: 18, weight: .medium)).foregroundStyle(.black)
                }
                .padding(.horizontal, 20)
                .frame(height: 56)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color.goneBorderDefault) }
            }
        }
    }

    private var memoField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("메모").font(.system(size: 18, weight: .bold)).foregroundStyle(Color.goneTextPrimary)
            TextField("선택 사항", text: $draft.memo, axis: .vertical)
                .font(.system(size: 16))
                .focused($isMemoFocused)
                .lineLimit(3, reservesSpace: true)
                .padding(20)
                .frame(height: 100, alignment: .topLeading)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault) }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button("전체 삭제", role: .destructive) {
                viewModel.clearSelection()
                dismiss()
            }
            .font(.system(size: 15, weight: .bold))
            .frame(width: 112, height: 52)
            .foregroundStyle(Color.goneStatusError)
            .overlay { RoundedRectangle(cornerRadius: 14).stroke(Color.goneStatusError, lineWidth: 1.5) }
            Button("명단 추가하기") {
                viewModel.saveDraft(draft, for: student)
                onSaved()
            }
            .font(.system(size: 17, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(.white)
            .background(Color.goneBrandPrimary, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct PointIssueCompletionView: View {
    let records: [PointIssueRecord]
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image("PointIssueCompleteIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 112, height: 112)
                .accessibilityHidden(true)
                .padding(.top, 58)
            Text("점수 발급이 완료되었습니다.")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(Color.goneTextPrimary)
                .padding(.top, 28)
            VStack(alignment: .leading, spacing: 12) {
                Text("발급 명단").font(.system(size: 18, weight: .bold))
                ForEach(records) { record in
                    HStack {
                        Text("\(record.kind.prefix)\(record.points)")
                            .font(.system(size: 27, weight: .bold))
                            .foregroundStyle(record.kind == .reward ? .green : Color.goneStatusError)
                            .frame(width: 72, alignment: .leading)
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 7) {
                                Text(record.student.name).font(.system(size: 17, weight: .bold))
                                Text(record.student.studentInfo).font(.caption).foregroundStyle(Color.goneTextSecondary)
                            }
                            Text(record.item).font(.system(size: 14)).foregroundStyle(Color.goneTextPrimary).lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 78)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: GONECornerRadius.button))
                }
            }
            .padding(.top, 58)
            .frame(maxWidth: 320)
            Spacer()
            HStack(spacing: 12) {
                Button("취소", action: onDone)
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 132, height: 54)
                    .foregroundStyle(Color.goneStatusError)
                    .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.goneStatusError, lineWidth: 1.5) }
                Button("확인", action: onDone)
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .foregroundStyle(.white)
                    .background(Color.goneBrandPrimary, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.bottom, 26)
        }
        .padding(GONESpacing.screenHorizontal)
        .background(Color.goneScreenBackground.ignoresSafeArea())
        .preferredColorScheme(.light)
    }
}

private struct HistoryContent: View {
    let records: [PointIssueRecord]
    @State private var filter: PointKind?

    private var filteredRecords: [PointIssueRecord] {
        guard let filter else { return records }
        return records.filter { $0.kind == filter }
    }

    var body: some View {
        Group {
            if records.isEmpty {
                HistoryEmptyState()
            } else {
                VStack(alignment: .leading, spacing: GONESpacing.medium) {
                    HStack(spacing: 12) {
                        filterButton(title: "전체", value: nil)
                        filterButton(title: PointKind.reward.rawValue, value: .reward)
                        filterButton(title: PointKind.penalty.rawValue, value: .penalty)
                    }
                    LazyVStack(spacing: GONESpacing.medium) {
                        ForEach(filteredRecords) { record in
                            HStack(spacing: GONESpacing.medium) {
                            Text("\(record.kind.prefix)\(record.points)")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(record.kind == .reward ? .green : Color.goneStatusError)
                                .frame(width: 54)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.student.name).font(.headline)
                                Text(record.item).font(.subheadline).foregroundStyle(Color.goneTextSecondary)
                                Text(formattedDate(record.issuedAt)).font(.caption).foregroundStyle(Color.goneTextTertiary)
                            }
                            Spacer()
                            }
                            .padding(GONESpacing.large)
                            .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: GONECornerRadius.button))
                        }
                    }
                }
            }
        }
    }

    private func filterButton(title: String, value: PointKind?) -> some View {
        Button { filter = value } label: {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(filter == value ? .white : Color.goneTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(filter == value ? Color.goneBrandPrimary : Color.white, in: Capsule())
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: date)
    }
}

private struct StatisticsContent: View {
    let statistics: PointStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.large) {
            Text("내 발급 통계").font(.headline.weight(.bold)).foregroundStyle(Color.goneTextPrimary)
            HStack(spacing: GONESpacing.small) {
                statisticCard(title: "이번 달 발급", value: statistics.issueCount, unit: "건", color: .goneBrandPrimary)
                statisticCard(title: "발급한 상점", value: statistics.rewardPoints, unit: "점", color: .green)
                statisticCard(title: "발급한 벌점", value: statistics.penaltyPoints, unit: "점", color: .goneStatusError)
            }
            Text("현재 로그인한 선생님의 발급 기록 기준").font(.subheadline).foregroundStyle(Color.goneTextSecondary)
        }
    }

    private func statisticCard(title: String, value: Int, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text(title).font(.caption).foregroundStyle(Color.goneTextSecondary).lineLimit(1)
            Text("\(value)\(unit)").font(.title3.weight(.bold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GONESpacing.medium)
        .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: GONECornerRadius.button))
    }
}

private struct IssueEmptyState: View {
    var onAddTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            Image("PointPlusIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)
                .accessibilityHidden(true)
                .padding(.top, 44)
            Text("발급 대상자를 추가해 주세요")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.goneTextPrimary)
                .padding(.top, 26)
            Text("학생을 선택한 뒤 항목과 점수를 지정합니다.")
                .font(.subheadline)
                .foregroundStyle(Color.goneTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            Button("+ 발급 대상자 추가", action: onAddTap)
                .font(.headline)
                .frame(width: 304)
                .frame(height: 54)
                .foregroundStyle(Color.goneBrandPrimary)
                .overlay {
                    RoundedRectangle(cornerRadius: GONECornerRadius.button)
                        .stroke(Color.goneBrandPrimary, lineWidth: 2)
                }
                .padding(.top, 28)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct HistoryEmptyState: View {
    var body: some View {
        ContentUnavailableView {
            Label("발급 내역이 없어요", systemImage: "list.clipboard")
        } description: {
            Text("상벌점을 발급하면 이곳에서 확인할 수 있습니다.")
        }
    }
}

private struct StatisticsPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.large) {
            Text("내 발급 통계")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.goneTextPrimary)
            HStack(spacing: GONESpacing.small) {
                statisticCard(title: "이번 달 발급", value: "0", unit: "건", color: .goneBrandPrimary)
                statisticCard(title: "발급한 상점", value: "0", unit: "점", color: .green)
                statisticCard(title: "발급한 벌점", value: "0", unit: "점", color: .goneStatusError)
            }
            Text("발급 기록이 쌓이면 최근 5개월 현황을 확인할 수 있습니다.")
                .font(.subheadline)
                .foregroundStyle(Color.goneTextSecondary)
        }
    }

    private func statisticCard(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.goneTextSecondary)
                .lineLimit(1)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GONESpacing.medium)
        .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: GONECornerRadius.button))
    }
}
