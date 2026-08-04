import SwiftUI

struct LabReservationView: View {
    @ObservedObject var viewModel: LabReservationViewModel
    @State private var isShowingForm = false

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("실습실 정보를 불러오는 중")
                case .loaded:
                    if let reservation = viewModel.reservation {
                        LabReservationDetailView(reservation: reservation) {
                            viewModel.startNewReservation()
                        }
                    } else {
                        LabRoomListView(viewModel: viewModel, isShowingForm: $isShowingForm)
                    }
                case .failed:
                    ContentUnavailableView {
                        Label("실습실 정보를 불러올 수 없어요", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text("잠시 후 다시 시도해 주세요.")
                    } actions: {
                        Button("다시 시도") { Task { await viewModel.load() } }
                    }
                }
            }
            .background(Color.goneHomeBackground.ignoresSafeArea())
            .navigationDestination(isPresented: $isShowingForm) {
                if let room = viewModel.selectedRoom {
                    LabReservationFormView(room: room) { draft in
                        await viewModel.submit(draft)
                        isShowingForm = false
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

private struct LabRoomListView: View {
    @ObservedObject var viewModel: LabReservationViewModel
    @Binding var isShowingForm: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                VStack(alignment: .leading, spacing: GONESpacing.small) {
                    Text("실습실 대여")
                        .font(.caption)
                        .foregroundStyle(Color.goneTextSecondary)
                    Text("7월 29일 실습실 예약")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.goneTextPrimary)
                }

                Picker("층 선택", selection: Binding(
                    get: { viewModel.selectedFloor },
                    set: { floor in
                        viewModel.selectFloor(floor)
                        Task { await viewModel.loadRooms() }
                    }
                )) {
                    ForEach(LabFloor.allCases) { floor in
                        Text(floor.title).tag(floor)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("\(viewModel.selectedFloor.title) 실습실")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Text("예약 가능 \(viewModel.rooms.filter(\.isReservable).count)개")
                        .font(.caption)
                        .foregroundStyle(Color.goneTextSecondary)
                }

                VStack(spacing: GONESpacing.medium) {
                    ForEach(Array(viewModel.rooms.enumerated()), id: \.element.id) { index, room in
                        LabRoomRow(room: room, number: index + 1, isSelected: viewModel.selectedRoom == room) {
                            viewModel.selectedRoom = room
                        }
                    }
                }

                GONEPrimaryButton(
                    title: viewModel.selectedRoom.map { "\($0.name) 예약하기" } ?? "실습실을 선택해 주세요",
                    isEnabled: viewModel.selectedRoom != nil,
                    isLoading: false
                ) {
                    isShowingForm = true
                }
                .padding(.top, GONESpacing.small)
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .navigationTitle("실습실")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LabRoomRow: View {
    let room: LabRoom
    let number: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: GONESpacing.medium) {
                Text("\(number)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isSelected ? Color.goneBrandPrimary : Color.goneTextTertiary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: GONESpacing.xSmall) {
                    Text(room.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.goneTextPrimary)
                    Text(room.description)
                        .font(.caption2)
                        .foregroundStyle(Color.goneTextSecondary)
                }
                Spacer(minLength: 8)
                Text(room.isReservable ? "예약 가능" : "예약 마감")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(room.isReservable ? Color.goneBrandPrimary : Color.goneTextTertiary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(
                        (room.isReservable ? Color.goneBrandPrimary : Color.goneSurfaceDisabled).opacity(0.12),
                        in: Capsule()
                    )
            }
            .padding(GONESpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.goneBrandPrimary : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!room.isReservable)
        .accessibilityLabel("\(room.name), \(room.description), \(room.isReservable ? "예약 가능" : "예약 마감")")
    }
}

private struct LabReservationFormView: View {
    let room: LabRoom
    let submit: (LabReservationDraft) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var representative = "김은찬"
    @State private var members = "3206김은찬, 3218정은경, 3211윤동은"
    @State private var purpose = "캡스톤 프로젝트 진행 및 대회 준비"
    @State private var isSubmitting = false

    private var draft: LabReservationDraft {
        LabReservationDraft(room: room, representative: representative, members: members, purpose: purpose)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                HStack(spacing: GONESpacing.medium) {
                    Text(room.floor.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.goneBrandPrimary)
                    VStack(alignment: .leading, spacing: GONESpacing.xSmall) {
                        Text(room.name).font(.subheadline.weight(.semibold))
                        Text(room.description).font(.caption).foregroundStyle(Color.goneTextSecondary)
                    }
                }
                .padding(GONESpacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 15))

                InputSection(title: "대표자") {
                    TextField("대표자 이름", text: $representative)
                        .textInputAutocapitalization(.never)
                }
                InputSection(title: "사용 인원 명단", helper: "본인 포함 · 쉼표(,)로 구분해 입력해 주세요.") {
                    TextEditor(text: $members)
                        .frame(minHeight: 86)
                }
                InputSection(title: "사용 목적") {
                    TextEditor(text: $purpose)
                        .frame(minHeight: 110)
                }

                GONEPrimaryButton(title: "대여 신청하기", isEnabled: draft.isValid, isLoading: isSubmitting) {
                    isSubmitting = true
                    Task {
                        await submit(draft)
                        isSubmitting = false
                    }
                }
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .background(Color.goneHomeBackground.ignoresSafeArea())
        .navigationTitle("실습실 대여")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct InputSection<Content: View>: View {
    let title: String
    var helper: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: GONESpacing.small) {
                Text(title).font(.subheadline.weight(.semibold))
                if let helper {
                    Text(helper).font(.caption2).foregroundStyle(Color.goneTextSecondary)
                }
            }
            content
                .padding(GONESpacing.medium)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.goneBorderDefault))
        }
    }
}

private struct LabReservationDetailView: View {
    let reservation: LabReservation
    let newReservation: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                HStack {
                    Text("내 실습실 대여")
                        .font(.title3.weight(.bold))
                    Spacer()
                    Button("새 예약", action: newReservation)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.goneTextSecondary)
                }

                VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                    HStack {
                        Text("예약 가능")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.orange.opacity(0.14), in: Capsule())
                        Spacer()
                        Text("신청번호  \(reservation.id)")
                            .font(.caption2)
                            .foregroundStyle(Color.goneTextSecondary)
                    }
                    Text(reservation.room.name)
                        .font(.title3.weight(.bold))
                    Text("\(reservation.room.floor.title) · \(reservation.date)")
                        .font(.caption)
                        .foregroundStyle(Color.goneTextSecondary)

                    HStack {
                        Text("이용시간").foregroundStyle(Color.goneTextSecondary)
                        Spacer()
                        Text(reservation.usageTime).font(.title3.weight(.bold))
                    }
                    ReservationInfoRow(title: "대표자", value: reservation.representative)
                    ReservationInfoRow(title: "사용인원", value: "\(reservation.memberCount)명")
                    ReservationInfoRow(title: "사용목적", value: reservation.purpose)
                    ReservationProgress(status: reservation.status)

                    Button("대여 취소") {}
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.goneStatusError)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.goneStatusError))
                }
                .padding(GONESpacing.large)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.goneBrandPrimary.opacity(0.12)))

                Text("담당 선생님이 승인하면 이용 가능 상태로 변경되고, 홈의 신청 현황에서도 바로 확인할 수 있습니다.")
                    .font(.caption)
                    .foregroundStyle(Color.goneTextSecondary)
                    .padding(GONESpacing.large)
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.goneTextSecondary.opacity(0.55)))
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .navigationTitle("실습실")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ReservationInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).foregroundStyle(Color.goneTextSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, GONESpacing.small)
        .overlay(alignment: .bottom) { Divider() }
    }
}

private struct ReservationProgress: View {
    let status: LabReservation.Status

    var body: some View {
        HStack {
            progressItem("신청완료", isActive: true)
            Rectangle().fill(Color.goneBorderDefault).frame(height: 1)
            progressItem("승인대기", isActive: status == .pending || status == .approved)
            Rectangle().fill(Color.goneBorderDefault).frame(height: 1)
            progressItem("이용가능", isActive: status == .approved)
        }
        .padding(.vertical, GONESpacing.medium)
    }

    private func progressItem(_ title: String, isActive: Bool) -> some View {
        VStack(spacing: GONESpacing.xSmall) {
            Circle().fill(isActive ? Color.goneBrandPrimary : Color.goneTextTertiary).frame(width: 12, height: 12)
            Text(title).font(.caption2).foregroundStyle(isActive ? Color.goneBrandPrimary : Color.goneTextTertiary)
        }
    }
}

private extension Color {
    static let goneHomeBackground = Color(red: 242 / 255, green: 244 / 255, blue: 247 / 255)
}

#Preview {
    AppTabView()
}
