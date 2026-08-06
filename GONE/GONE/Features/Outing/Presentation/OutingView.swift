import SwiftUI
import UIKit

private enum OutingDisplayFormatter {
    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        return formatter.string(from: date)
    }
}

struct OutingView: View {
    @ObservedObject var viewModel: OutingViewModel
    @State private var isShowingForm = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("외출 정보를 불러오는 중")
                } else if let outing = viewModel.outing {
                    outingContent(outing)
                } else {
                    OutingLandingView { isShowingForm = true }
                }
            }
            .background(Color.goneScreenBackground.ignoresSafeArea())
            .navigationDestination(isPresented: $isShowingForm) {
                OutingRequestForm { draft in
                    await viewModel.submit(draft)
                    isShowingForm = false
                }
            }
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private func outingContent(_ outing: OutingRequest) -> some View {
        switch outing.status {
        case .pendingApproval:
            OutingPendingCard(
                outing: outing,
                onCancel: { Task { await viewModel.cancel() } },
                onPreviewWaiting: viewModel.simulateWaitingToStartForPreview,
                onPreviewApproval: viewModel.simulateApprovalForPreview
            )
        case .waitingToStart(let minutes):
            OutingStatusView(title: "대기 상태", value: "\(minutes)분 전", color: .goneStatusWaiting, buttonTitle: "대기", message: "잠시 후 외출을 시작할 수 있습니다.", isEnabled: false, action: {}, previewActionTitle: "외출 가능 상태 미리보기", onPreviewAction: viewModel.simulateApprovalForPreview)
        case .readyToLeave(let returnTime):
            OutingStatusView(title: "복귀 시간", value: OutingDisplayFormatter.time(returnTime), color: .goneBrandPrimary, buttonTitle: "외출", message: "1.5초간 길게 누르면 현재 위치와 이동 경로가 선도부 학생에게 공유됩니다.", isEnabled: true, action: { Task { await viewModel.startOuting() } })
        case .outing(let minutes):
            OutingStatusView(title: "남은 시간", value: "\(minutes)분", color: .goneStatusOuting, buttonTitle: "외출 중", message: "현재 위치와 이동 경로를 실시간으로 공유하고 있습니다.", isEnabled: false, showsPulse: true, action: {}, previewActionTitle: "복귀 가능 상태 미리보기", onPreviewAction: viewModel.simulateReturnAreaForPreview)
        case .readyToReturn(let minutes):
            OutingStatusView(title: "남은 시간", value: "\(minutes)분", color: .goneStatusReturn, buttonTitle: "복귀", message: "1.5초간 길게 누르면 외출을 종료합니다.", isEnabled: true, action: { Task { await viewModel.completeReturn() } })
        case .completed:
            OutingLandingView { isShowingForm = true }
        }
    }
}

private struct OutingLandingView: View {
    let apply: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                Text("외출").font(.caption).foregroundStyle(Color.goneTextSecondary)
                Text("7월 29일 외출 신청").font(.title2.weight(.bold)).foregroundStyle(Color.goneTextPrimary)
                VStack(alignment: .leading, spacing: GONESpacing.small) {
                    Text("외출이 필요한가요?").font(.headline.weight(.bold))
                    Text("외출 날짜와 시간을 입력해 담당 선생님께 승인을 요청할 수 있습니다.").font(.subheadline).foregroundStyle(Color.goneTextSecondary)
                }
                Spacer(minLength: 40)
                Image("OutingHero")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 210)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 40)
                GONEPrimaryButton(title: "외출 신청", isEnabled: true, isLoading: false, action: apply)
        }
        .padding(.horizontal, GONESpacing.screenHorizontal)
        .padding(.vertical, GONESpacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct OutingRequestForm: View {
    let submit: (OutingDraft) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft = OutingDraft()
    @State private var isSubmitting = false
    @FocusState private var isReasonFocused: Bool
    @State private var isShowingDatePicker = false
    @State private var activeTimePicker: TimeField?

    private enum TimeField: Identifiable { case departure, `return`; var id: Self { self } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                dateField
                HStack(spacing: GONESpacing.medium) {
                    timeField(title: "출발 시간", selection: $draft.departureTime)
                    timeField(title: "복귀 시간", selection: $draft.returnTime)
                }
                VStack(alignment: .leading, spacing: GONESpacing.small) {
                    Text("외출 사유").font(.headline.weight(.bold))
                    TextEditor(text: $draft.reason).font(.body).focused($isReasonFocused).frame(minHeight: 146).padding(GONESpacing.medium).scrollContentBackground(.hidden).background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault))
                }
                OutingSubmitButton(isEnabled: draft.isValid, isLoading: isSubmitting) {
                    isSubmitting = true
                    Task { await submit(draft); isSubmitting = false }
                }
                .padding(.top, -8)
            }
            .padding(.horizontal, GONESpacing.screenHorizontal).padding(.vertical, GONESpacing.xLarge)
        }
        .background(Color.goneScreenBackground.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { isReasonFocused = false }
        .sheet(isPresented: $isShowingDatePicker) {
            NavigationStack {
                DatePicker("외출 날짜", selection: $draft.date, in: currentMonthRange, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                    .tint(Color.goneBrandPrimary)
                    .padding()
                    .navigationTitle("외출 날짜")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("완료") { isShowingDatePicker = false }
                        }
                    }
            }
            // 그래픽 달력의 마지막 주까지 보이되, 전체 화면을 차지하지 않도록 고정 높이를 사용합니다.
            .presentationDetents([.height(560)])
            .presentationBackground(Color.goneSurfacePrimary)
            .preferredColorScheme(.light)
        }
        .sheet(item: $activeTimePicker) { field in
            NavigationStack {
                DatePicker("", selection: timeBinding(for: field), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                    .tint(Color.goneBrandPrimary)
                    .padding()
                    .navigationTitle(field == .departure ? "출발 시간" : "복귀 시간")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("완료") { activeTimePicker = nil }
                        }
                    }
            }
            .presentationDetents([.height(310)])
            .presentationBackground(Color.goneSurfacePrimary)
            .preferredColorScheme(.light)
        }
        .navigationTitle("외출 신청").navigationBarTitleDisplayMode(.inline)
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text("외출 날짜").font(.headline.weight(.bold))
            Button { isShowingDatePicker = true } label: {
                HStack { Text(koreanDateLabel).foregroundStyle(Color.goneTextPrimary); Spacer(); Image(systemName: "chevron.down").foregroundStyle(Color.goneTextSecondary) }
                    .padding(.horizontal, GONESpacing.large).frame(height: 64).background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault))
            }
            .buttonStyle(.plain)
        }
    }

    private func timeField(title: String, selection: Binding<Date>) -> some View {
        let field: TimeField = title == "출발 시간" ? .departure : .return
        return VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text(title).font(.headline.weight(.bold))
            Button { activeTimePicker = field } label: {
                HStack { Text(OutingDisplayFormatter.time(selection.wrappedValue)).foregroundStyle(Color.goneTextPrimary); Spacer() }
                    .padding(.horizontal, GONESpacing.medium).frame(height: 64).background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault))
            }.buttonStyle(.plain)
        }
    }

    private var currentMonthRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
        return start...end
    }

    private var koreanDateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: draft.date)
    }

    private func timeBinding(for field: TimeField) -> Binding<Date> {
        field == .departure ? $draft.departureTime : $draft.returnTime
    }
}

private struct OutingSubmitButton: View {
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading { ProgressView().tint(.white) }
                else { Text("외출 신청하기").font(.headline.weight(.semibold)) }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(.white)
            .background(isEnabled ? Color.goneBrandPrimary : Color.goneBrandPrimary.opacity(0.48), in: RoundedRectangle(cornerRadius: GONECornerRadius.button))
        }
        .disabled(!isEnabled || isLoading)
        .accessibilityHint(isEnabled ? "외출 신청을 제출합니다." : "날짜, 시간, 사유를 입력하면 사용할 수 있습니다.")
    }
}

private struct OutingPendingCard: View {
    let outing: OutingRequest
    let onCancel: () -> Void
    let onPreviewWaiting: () -> Void
    let onPreviewApproval: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
                HStack { (Text("외출 ").foregroundStyle(Color.goneTextPrimary) + Text("신청").foregroundStyle(Color.goneBrandPrimary) + Text(" 완료").foregroundStyle(Color.goneTextPrimary)).font(.title2.weight(.bold)); Spacer(); Button("재신청", action: onCancel).foregroundStyle(Color.goneBrandPrimary) }
                VStack(alignment: .leading, spacing: GONESpacing.large) {
                    HStack { Text("승인 대기").font(.caption.weight(.bold)).foregroundStyle(Color.goneStatusOuting).padding(.horizontal, 10).padding(.vertical, 8).background(Color.goneStatusOuting.opacity(0.15), in: Capsule()); Spacer(); Text("신청번호  \(outing.id)").font(.caption).foregroundStyle(Color.goneTextSecondary) }
                    OutingDateTitle(date: outing.date)
                    Text("점심시간 외출").font(.footnote).foregroundStyle(Color.goneTextSecondary)
                    CardDetailRow(title: "외출 시간", value: OutingDisplayFormatter.time(outing.departureTime) + " ~ " + OutingDisplayFormatter.time(outing.returnTime), emphasizesValue: true)
                    CardDetailRow(title: "외출 사유", value: outing.reason)
                    Divider()
                    OutingProgress()
                    Button("신청 취소", action: onCancel)
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundStyle(Color.goneStatusReturn)
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.goneStatusReturn))
                }.padding(GONESpacing.large).background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.goneBrandPrimary.opacity(0.12)))
                Text("담당 선생님이 승인하면 외출 가능 상태로 변경되고, 홈의 신청 현황에서도 바로 확인할 수 있습니다.").font(.footnote).foregroundStyle(Color.goneTextSecondary).padding(GONESpacing.large).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneTextSecondary.opacity(0.5)))
                HStack(spacing: GONESpacing.large) {
                    Button("대기 상태 미리보기", action: onPreviewWaiting)
                    Button("외출 가능 상태 미리보기", action: onPreviewApproval)
                }
                .font(.caption)
                .foregroundStyle(Color.goneBrandPrimary)
            }.padding(.horizontal, GONESpacing.screenHorizontal).padding(.vertical, GONESpacing.xLarge)
        }
    }
}

private struct OutingDateTitle: View {
    let date: Date
    private var components: DateComponents { Calendar.current.dateComponents([.year, .month, .day], from: date) }

    var body: some View {
        HStack(spacing: 0) {
            Text("\(components.year ?? 0)년 ").foregroundStyle(Color.goneBrandPrimary)
            Text("\(components.month ?? 0)월 ").foregroundStyle(Color.goneTextPrimary)
            Text("\(components.day ?? 0)일 ").foregroundStyle(Color.goneBrandPrimary)
            Text("외출").foregroundStyle(Color.goneTextPrimary)
        }
        .font(.title3.weight(.bold))
    }
}

private struct CardDetailRow: View {
    let title: String
    let value: String
    var emphasizesValue = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.goneTextSecondary)
            Spacer(minLength: 24)
            Text(value)
                .font(emphasizesValue ? .headline.weight(.bold) : .subheadline.weight(.semibold))
                .foregroundStyle(Color.goneTextPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct OutingStatusView: View {
    let title: String; let value: String; let color: Color; let buttonTitle: String; let message: String; let isEnabled: Bool; var showsPulse = false; let action: () -> Void; var previewActionTitle: String? = nil; var onPreviewAction: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 0) {
            Text(title).font(.title2.weight(.bold)).foregroundStyle(Color.goneTextPrimary).padding(.top, 84)
            Text(value).font(.system(size: 52, weight: .bold)).foregroundStyle(color).padding(.top, GONESpacing.small)
            Spacer()
            ZStack {
                if showsPulse { LocationPulse(color: color) }
                HoldToConfirmButton(title: buttonTitle, color: color, isEnabled: isEnabled, action: action).accessibilityAction(named: buttonTitle + " 실행", action)
            }.frame(height: 200)
            Spacer()
            Text(message).font(.body).foregroundStyle(Color.goneTextSecondary).multilineTextAlignment(.center).lineSpacing(5).padding(.horizontal, 42)
            if let previewActionTitle, let onPreviewAction { Button(previewActionTitle, action: onPreviewAction).font(.caption).foregroundStyle(Color.goneBrandPrimary).padding(.top, 16) }
            Spacer()
        }.frame(maxWidth: .infinity).background(Color.goneScreenBackground.ignoresSafeArea())
    }
}

private struct OutingProgress: View {
    var body: some View {
        VStack(spacing: GONESpacing.small) {
            HStack(spacing: 0) {
                Circle().fill(Color.goneBrandPrimary).frame(width: 20, height: 20)
                Rectangle().fill(Color.goneTextTertiary).frame(height: 2)
                Circle().fill(Color.goneSurfacePrimary).frame(width: 20, height: 20).overlay(Circle().stroke(Color.goneTextTertiary, lineWidth: 4))
                Rectangle().fill(Color.goneTextTertiary).frame(height: 2)
                Circle().fill(Color.goneSurfacePrimary).frame(width: 20, height: 20).overlay(Circle().stroke(Color.goneTextTertiary, lineWidth: 4))
            }
            HStack {
                Text("신청완료").foregroundStyle(Color.goneBrandPrimary)
                Spacer()
                Text("승인대기")
                Spacer()
                Text("외출가능")
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.goneTextTertiary)
        }
    }
}

private struct HoldToConfirmButton: View {
    let title: String; let color: Color; let isEnabled: Bool; let action: () -> Void
    @State private var isPressing = false
    @State private var chargingTimer: Timer?
    var body: some View {
        Text(title).font(.system(size: 27, weight: .bold)).foregroundStyle(.white).frame(width: 170, height: 170).background(color.opacity(isEnabled ? 1 : 0.55), in: Circle()).overlay(Circle().trim(from: 0, to: isPressing ? 1 : 0).stroke(.white.opacity(0.9), lineWidth: 6).rotationEffect(.degrees(-90)).padding(6).animation(.linear(duration: 1.5), value: isPressing)).contentShape(Circle()).onLongPressGesture(minimumDuration: 1.5, pressing: { pressing in
            guard isEnabled else { return }
            isPressing = pressing
            pressing ? startChargingHaptics() : stopChargingHaptics()
        }, perform: {
            stopChargingHaptics()
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            action()
            isPressing = false
        })
    }

    private func startChargingHaptics() {
        guard chargingTimer == nil else { return }
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred(intensity: 0.9)
        chargingTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            generator.impactOccurred(intensity: 1.0)
            generator.prepare()
        }
    }

    private func stopChargingHaptics() {
        chargingTimer?.invalidate()
        chargingTimer = nil
    }
}

private struct LocationPulse: View {
    let color: Color; @State private var pulse = false
    var body: some View { ZStack { ForEach(0..<3) { index in Circle().stroke(color.opacity(0.55), lineWidth: 2).frame(width: 150, height: 150).scaleEffect(pulse ? 1.8 : 0.65).opacity(pulse ? 0 : 0.8).animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false).delay(Double(index) * 0.55), value: pulse) } }.onAppear { pulse = true } }
}
