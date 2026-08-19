import SwiftUI

struct PointSystemView: View {
    private enum Section: String, CaseIterable, Identifiable {
        case issue = "점수발급"
        case history = "발급 내역"
        case statistics = "통계"

        var id: String { rawValue }
    }

    @State private var selectedSection: Section = .issue

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
            .background(Color.goneHomeBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
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
            IssueEmptyState()
        case .history:
            HistoryEmptyState()
        case .statistics:
            StatisticsPreview()
        }
    }
}

private struct IssueEmptyState: View {
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
            Button("+ 발급 대상자 추가") { }
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
