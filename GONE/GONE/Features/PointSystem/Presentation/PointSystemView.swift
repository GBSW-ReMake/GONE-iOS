import SwiftUI

struct PointSystemView: View {
    private enum Section: String, CaseIterable, Identifiable, Hashable {
        case issue = "점수발급"
        case history = "발급 내역"
        case statistics = "통계"

        var id: String { rawValue }
    }

    @State private var selectedSection: Section = .issue
    @State private var isShowingStudentSearch = false
    @State private var isShowingIssueForm = false
    @StateObject private var viewModel: PointSystemViewModel

    init(viewModel: PointSystemViewModel = PointSystemViewModel(repository: MockPointRepository())) {
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
                StudentSearchView(viewModel: viewModel)
            }
            .sheet(isPresented: $isShowingIssueForm) {
                PointIssueFormView(viewModel: viewModel)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text("상벌점 시스템")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.goneTextSecondary)
            Text("상벌점 점수 발급")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.goneTextPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    private var sectionPicker: some View {
        Picker("상벌점 메뉴", selection: $selectedSection) {
            ForEach(Section.allCases) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("상벌점 메뉴")
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .issue:
            IssueContent(
                selectedStudents: viewModel.selectedStudents,
                onAddTap: { isShowingStudentSearch = true },
                onRemove: viewModel.removeStudent,
                onIssueTap: { isShowingIssueForm = true },
                onClear: viewModel.clearSelection
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
    let onRemove: (PointStudent) -> Void
    let onIssueTap: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.large) {
            if selectedStudents.isEmpty {
                IssueEmptyState(onAddTap: onAddTap)
            } else {
                Text("발급 명단")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.goneTextPrimary)
                ForEach(selectedStudents) { student in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(student.name).font(.headline)
                            Text(student.studentInfo).font(.caption).foregroundStyle(Color.goneTextSecondary)
                        }
                        Spacer()
                        Button { onRemove(student) } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.goneTextPrimary)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("\(student.name) 발급 명단에서 삭제")
                    }
                    .padding(.horizontal, GONESpacing.large)
                    .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: GONECornerRadius.button))
                }
                Button("+ 발급 대상자 추가", action: onAddTap)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundStyle(Color.goneBrandPrimary)
                    .overlay { RoundedRectangle(cornerRadius: GONECornerRadius.button).stroke(Color.goneBrandPrimary) }
            }

            HStack(spacing: GONESpacing.medium) {
                Button("전체 삭제", role: .destructive, action: onClear)
                    .frame(maxWidth: 120)
                    .frame(height: 52)
                    .overlay { RoundedRectangle(cornerRadius: GONECornerRadius.button).stroke(Color.goneStatusError) }
                Button("점수 발급", action: onIssueTap)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.white)
                    .background(selectedStudents.isEmpty ? Color.goneStatusWaiting : Color.goneBrandPrimary, in: RoundedRectangle(cornerRadius: GONECornerRadius.button))
                    .disabled(selectedStudents.isEmpty)
            }
        }
    }
}

private struct StudentSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PointSystemViewModel
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
                    dismiss()
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

private struct PointIssueFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PointSystemViewModel
    @State private var draft = PointIssueDraft()
    @State private var isIssuing = false
    @State private var didSucceed = false
    @State private var issuedStudents: [PointStudent] = []

    var body: some View {
        NavigationStack {
            if didSucceed {
                PointIssueCompletionView(students: issuedStudents, draft: draft) { dismiss() }
            } else {
                Form {
                Section("발급 대상") {
                    ForEach(viewModel.selectedStudents) { student in
                        HStack {
                            Text(student.name)
                            Spacer()
                            Text(student.studentInfo).font(.caption).foregroundStyle(Color.goneTextSecondary)
                        }
                    }
                }
                Section("점수") {
                    Picker("구분", selection: $draft.kind) {
                        ForEach(PointKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Stepper("점수 \(draft.points)점", value: $draft.points, in: 1...10)
                }
                Section("발급 항목") {
                    TextField("발급 사유", text: $draft.item)
                    TextField("메모 (선택)", text: $draft.memo, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    Button(isIssuing ? "발급 중..." : "발급하기") {
                        isIssuing = true
                        issuedStudents = viewModel.selectedStudents
                        Task {
                            didSucceed = await viewModel.issue(draft: draft)
                            isIssuing = false
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(isIssuing || draft.item.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            }
            .navigationTitle("상벌점 폼")
            .toolbar {
                if !didSucceed {
                    ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                }
            }
        }
    }
}

private struct PointIssueCompletionView: View {
    let students: [PointStudent]
    let draft: PointIssueDraft
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: GONESpacing.xLarge) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text("점수 발급이 완료되었습니다.")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.goneTextPrimary)
            VStack(alignment: .leading, spacing: GONESpacing.medium) {
                Text("발급 명단").font(.headline.weight(.bold))
                ForEach(students) { student in
                    HStack {
                        Text("\(draft.kind.prefix)\(draft.points)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(draft.kind == .reward ? .green : Color.goneStatusError)
                        VStack(alignment: .leading) {
                            Text(student.name).font(.headline)
                            Text(student.studentInfo).font(.caption).foregroundStyle(Color.goneTextSecondary)
                        }
                    }
                    .padding(GONESpacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: GONECornerRadius.button))
                }
            }
            Spacer()
            Button("확인", action: onDone)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(.white)
                .background(Color.goneBrandPrimary, in: RoundedRectangle(cornerRadius: GONECornerRadius.button))
        }
        .padding(GONESpacing.screenHorizontal)
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
                    Picker("발급 내역 필터", selection: $filter) {
                        Text("전체").tag(Optional<PointKind>.none)
                        ForEach(PointKind.allCases) { kind in Text(kind.rawValue).tag(Optional(kind)) }
                    }
                    .pickerStyle(.segmented)
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
                                Text(record.issuedAt, style: .date).font(.caption).foregroundStyle(Color.goneTextTertiary)
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
        VStack(spacing: GONESpacing.large) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.goneBrandPrimary)
                .accessibilityHidden(true)
            VStack(spacing: GONESpacing.small) {
                Text("발급 대상자를 추가해 주세요")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.goneTextPrimary)
                Text("학생을 선택한 뒤 항목과 점수를 지정합니다.")
                    .font(.subheadline)
                    .foregroundStyle(Color.goneTextSecondary)
                    .multilineTextAlignment(.center)
            }
            Button("+ 발급 대상자 추가", action: onAddTap)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(Color.goneBrandPrimary)
                .overlay {
                    RoundedRectangle(cornerRadius: GONECornerRadius.button)
                        .stroke(Color.goneBrandPrimary, lineWidth: 2)
                }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 72)
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
