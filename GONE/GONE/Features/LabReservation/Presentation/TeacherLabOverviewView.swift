import SwiftUI

struct TeacherLabOverviewView: View {
    @ObservedObject var viewModel: TeacherLabOverviewViewModel

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("실습실 현황을 불러오는 중")
                case .loaded(let rooms):
                    overviewContent(rooms)
                case .failed:
                    ContentUnavailableView {
                        Label("실습실 현황을 불러올 수 없어요", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text("잠시 후 다시 시도해 주세요.")
                    } actions: {
                        Button("다시 시도") { Task { await viewModel.load() } }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .background(Color.goneScreenBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            guard viewModel.state == .loading else { return }
            await viewModel.load()
        }
    }

    private func overviewContent(_ rooms: [TeacherLabRoomStatus]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                VStack(alignment: .leading, spacing: GONESpacing.small) {
                    Text("실습실 대여")
                        .font(.caption)
                        .foregroundStyle(Color.goneTextSecondary)
                    HStack(alignment: .firstTextBaseline) {
                        Text(dateTitle)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.goneTextPrimary)
                        Spacer()
                        DatePicker("조회 날짜", selection: $viewModel.selectedDate, displayedComponents: .date)
                            .labelsHidden()
                            .tint(Color.goneBrandPrimary)
                    }
                }

                Picker("층 선택", selection: Binding(
                    get: { viewModel.selectedFloor },
                    set: { floor in Task { await viewModel.selectFloor(floor) } }
                )) {
                    ForEach(LabFloor.allCases) { floor in
                        Text(floor.title).tag(floor)
                    }
                }
                .pickerStyle(.segmented)
                .frame(height: 48)

                HStack {
                    Text("\(viewModel.selectedFloor.title) 실습실")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.goneTextPrimary)
                    Spacer()
                    Text("예약 \(rooms.filter(\.isReserved).count)개")
                        .font(.caption)
                        .foregroundStyle(Color.goneTextSecondary)
                }

                VStack(spacing: GONESpacing.medium) {
                    ForEach(rooms) { status in
                        if let booking = status.booking {
                            NavigationLink {
                                TeacherLabBookingDetailView(status: status, booking: booking)
                            } label: {
                                TeacherLabRoomCard(status: status)
                            }
                            .buttonStyle(.plain)
                        } else {
                            TeacherLabRoomCard(status: status)
                        }
                    }
                }
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .accessibilityIdentifier("teacherLabOverview.scrollView")
        .onChange(of: viewModel.selectedDate) { _, _ in
            Task { await viewModel.load() }
        }
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 실습실 현황"
        return formatter.string(from: viewModel.selectedDate)
    }
}

private struct TeacherLabRoomCard: View {
    let status: TeacherLabRoomStatus

    var body: some View {
        HStack(spacing: GONESpacing.medium) {
            Text("\(status.number)")
                .font(.title3.weight(.bold))
                .foregroundStyle(status.isReserved ? Color.goneBrandPrimary : Color.goneTextTertiary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: GONESpacing.xSmall) {
                Text(status.room.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.goneTextPrimary)
                    .lineLimit(2)
                if let booking = status.booking {
                    Text("\(booking.booker) 외 \(booking.memberCount)명")
                        .font(.caption)
                        .foregroundStyle(Color.goneTextSecondary)
                    Text(booking.purpose)
                        .font(.caption)
                        .foregroundStyle(Color.goneTextSecondary)
                } else {
                    Text("예약없음")
                        .font(.caption)
                        .foregroundStyle(Color.goneTextSecondary)
                }
            }
            Spacer(minLength: 8)
            Text(status.booking?.period.rawValue ?? "미예약")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(status.isReserved ? Color.goneBrandPrimary : Color.goneTextTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background((status.isReserved ? Color.goneBrandPrimary : Color.goneSurfaceDisabled).opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, GONESpacing.large)
        .padding(.vertical, 14)
        .frame(minHeight: 80)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 15))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(cardAccessibilityLabel)
    }

    private var cardAccessibilityLabel: String {
        guard let booking = status.booking else { return "\(status.room.name), 미예약" }
        return "\(status.room.name), \(booking.booker) 외 \(booking.memberCount)명, \(booking.period.rawValue), \(booking.usageTime)"
    }
}

private struct TeacherLabBookingDetailView: View {
    let status: TeacherLabRoomStatus
    let booking: TeacherLabBooking

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                Text(booking.period.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.goneBrandPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.goneBrandPrimary.opacity(0.1), in: Capsule())

                Text(dateTitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.goneTextSecondary)
                Text(status.room.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.goneTextPrimary)

                detailSection(title: "이용시간", value: booking.usageTime)
                detailSection(title: "대여자", value: "\(booking.booker), 외 \(booking.memberCount)명")
                detailSection(title: "사용 목적", value: booking.purpose)
                detailSection(title: "사용 위치", value: booking.location)
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(status.room.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailSection(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.goneTextPrimary)
            Text(value)
                .font(.body)
                .foregroundStyle(Color.goneTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: booking.date)
    }
}
