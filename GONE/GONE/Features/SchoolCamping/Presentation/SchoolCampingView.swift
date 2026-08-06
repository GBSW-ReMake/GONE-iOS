import SwiftUI

struct SchoolCampingView: View {
    @ObservedObject var viewModel: SchoolCampingViewModel

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("스쿨캠핑 정보를 불러오는 중")
                case .loaded:
                    SchoolCampingCalendarView(viewModel: viewModel)
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
        .task {
            guard viewModel.state == .loading else { return }
            await viewModel.load()
        }
    }
}

private struct SchoolCampingCalendarView: View {
    @ObservedObject var viewModel: SchoolCampingViewModel
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
                    legend
                }
                .padding(GONESpacing.large)
                .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .navigationTitle("스쿨캠핑")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var monthNavigation: some View {
        HStack {
            Button { Task { await viewModel.moveMonth(by: -1) } } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("이전 달")

            Spacer()
            Text(viewModel.displayedMonth.formatted(.dateTime.year().month()))
                .font(.headline.weight(.semibold))
            Spacer()

            Button { Task { await viewModel.moveMonth(by: 1) } } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("다음 달")
        }
        .foregroundStyle(Color.goneTextPrimary)
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
                Button { if let day = cell.day { viewModel.select(day) } } label: {
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
