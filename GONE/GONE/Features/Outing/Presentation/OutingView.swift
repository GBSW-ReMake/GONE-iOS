import SwiftUI
import MapKit

struct OutingView: View {
    @ObservedObject var viewModel: OutingViewModel
    @State private var navigationPath: [OutingNavigationRoute] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading {
                    ProgressView("외출 정보를 불러오는 중")
                } else if viewModel.canMonitorOutings {
                    LeaderOutingListView(viewModel: viewModel)
                } else if viewModel.role == .teacher {
                    TeacherOutingListView(viewModel: viewModel)
                } else {
                    StudentOutingListView(viewModel: viewModel) {
                        viewModel.errorMessage = nil
                        navigationPath.append(.requestForm)
                    }
                }
            }
            .background(Color.goneScreenBackground.ignoresSafeArea())
            .navigationDestination(for: OutingNavigationRoute.self) { route in
                switch route {
                case .requestForm:
                    OutingRequestForm(searchTeachers: viewModel.searchTeachers) { draft in
                        viewModel.submitPreview(draft)
                    }
                }
            }
        }
        .task {
            guard viewModel.isLoading else { return }
            await viewModel.load()
        }
    }
}

private enum OutingNavigationRoute: Hashable {
    case requestForm
}

private struct LeaderOutingListView: View {
    @ObservedObject var viewModel: OutingViewModel
    @State private var selectedOuting: OutingRequest?

    private var activeOutings: [OutingRequest] {
        viewModel.outings.filter { outing in
            if case .outing = outing.status { return true }
            if case .completed = outing.status { return true }
            return false
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.large) {
                Text(dateText(Date()))
                    .font(.footnote)
                    .foregroundStyle(Color.goneTextSecondary)
                Text("외출 학생 관리")
                    .font(.title.bold())
                    .foregroundStyle(Color.goneTextPrimary)

                if activeOutings.isEmpty {
                    ContentUnavailableView("외출 중인 학생이 없어요", systemImage: "location.slash", description: Text("학생이 외출을 시작하면 이곳에 표시됩니다."))
                } else {
                    ForEach(activeOutings) { outing in
                        Button { selectedOuting = outing } label: {
                            VStack(alignment: .leading, spacing: GONESpacing.small) {
                                statusBadge(outing.status)
                                Text(dateText(Date()))
                                    .font(.caption)
                                    .foregroundStyle(Color.goneTextSecondary)
                                Text("\(outing.student.studentNumber) \(outing.student.name)")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color.goneTextPrimary)
                                Text("오후 12:30 ~ 오후 1:30")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.goneTextPrimary)
                                Text(outing.reason)
                                    .font(.caption)
                                    .foregroundStyle(Color.goneTextSecondary)
                                Text("담당: \(outing.teacher.name)")
                                    .font(.caption)
                                    .foregroundStyle(Color.goneTextSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(GONESpacing.large)
                            .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 120)
                GONEPrimaryButton(title: "외출 신청", isEnabled: true, isLoading: false, action: {})
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .navigationTitle("외출")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.goneScreenBackground.ignoresSafeArea())
        .navigationDestination(item: $selectedOuting) { outing in
            OutingRouteDetailView(outing: outing, viewModel: viewModel)
        }
    }

    private func statusBadge(_ status: OutingRequest.Status) -> some View {
        let isCompleted = status == .completed
        return Text(isCompleted ? "복귀 완료" : "외출 중")
            .font(.caption.weight(.bold))
            .foregroundStyle(isCompleted ? Color.goneBrandPrimary : Color.goneStatusOuting)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background((isCompleted ? Color.goneBrandPrimary : Color.goneStatusOuting).opacity(0.12), in: Capsule())
    }
}

private struct OutingRouteDetailView: View {
    let outing: OutingRequest
    @ObservedObject var viewModel: OutingViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.large) {
                detailStatusBadge
                Text(dateText(Date()))
                    .font(.subheadline)
                    .foregroundStyle(Color.goneTextSecondary)
                Text("\(outing.student.studentNumber) \(outing.student.name)")
                    .font(.title3.bold())
                Text("오후 12:30 ~ 오후 1:30")
                    .font(.headline)

                if let route = viewModel.route {
                    Text("이동 경로")
                        .font(.headline.weight(.bold))
                    routeMap(route)
                    VStack(alignment: .leading, spacing: GONESpacing.small) {
                        Text("복귀 알림 예정")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.goneTextSecondary)
                        Text(route.status == .arrived
                             ? "학생이 복귀 버튼을 눌러 경로 추적이 종료되었고 선도부에게 복귀 완료 알림이 전송되었습니다."
                             : "학생이 복귀 버튼을 누르면 경로 추적이 종료되고 선도부에게 복귀 완료 알림이 전송됩니다.")
                            .font(.caption)
                            .foregroundStyle(Color.goneTextSecondary)
                            .lineSpacing(5)
                    }
                    .padding(.top, GONESpacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ProgressView("경로를 불러오는 중")
                        .frame(maxWidth: .infinity, minHeight: 300)
                }
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.large)
        }
        .navigationTitle("외출")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.white.ignoresSafeArea())
        .task { await viewModel.loadRoute(for: outing) }
        .onDisappear { viewModel.stopLocationSharing() }
    }

    private var detailStatusBadge: some View {
        let isArrived = viewModel.route?.status == .arrived
        return Text(isArrived ? "복귀 완료" : "외출 중")
            .font(.caption.weight(.bold))
            .foregroundStyle(isArrived ? Color.goneBrandPrimary : Color.goneStatusOuting)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background((isArrived ? Color.goneBrandPrimary : Color.goneStatusOuting).opacity(0.12), in: Capsule())
    }

    private func routeMap(_ route: OutingRoute) -> some View {
        let coordinates = route.points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        return Map(position: $cameraPosition) {
            if coordinates.count > 1 {
                MapPolyline(coordinates: coordinates)
                    .stroke(Color.goneBrandPrimary, lineWidth: 5)
            }
            if let start = coordinates.first {
                Annotation("출발", coordinate: start) {
                    Image(systemName: "figure.walk.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.goneBrandPrimary)
                        .background(.white, in: Circle())
                }
            }
            if let current = coordinates.last {
                Annotation(route.status == .arrived ? "도착" : "현재 위치", coordinate: current) {
                    ProfileMarker(student: outing.student, size: 38)
                }
            }
        }
        .mapStyle(.standard)
        .mapControls { MapCompass(); MapScaleView() }
        .frame(height: 330)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityLabel("외출 이동 경로 지도")
        .accessibilityHint("지도를 확대하거나 축소해서 이동 경로를 확인할 수 있습니다.")
    }
}

private struct ProfileMarker: View {
    let student: OutingStudent
    let size: CGFloat

    var body: some View {
        Group {
            if let imageName = student.profileImageName, UIImage(named: imageName) != nil {
                Image(imageName).resizable().scaledToFill()
            } else {
                Text(String(student.name.prefix(1)))
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.goneBrandPrimary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.16), radius: 4, y: 2)
        .accessibilityLabel("\(student.name) 프로필 사진")
    }
}

private struct StudentOutingListView: View {
    @ObservedObject var viewModel: OutingViewModel
    let apply: () -> Void
    @State private var selectedOuting: OutingRequest?

    var body: some View {
        Group {
            if viewModel.outings.isEmpty {
                StudentOutingLandingView(apply: apply)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: GONESpacing.large) {
                        Text("외출 신청").font(.title2.bold())
                        Text("이번 주 안에서만 신청할 수 있으며, 시간이 겹치지 않으면 여러 건을 신청할 수 있어요.")
                            .font(.subheadline).foregroundStyle(Color.goneTextSecondary)
                        ForEach(viewModel.outings) { outing in
                            StudentOutingCard(outing: outing) { viewModel.cancelPreview(outing) }
                                .contentShape(Rectangle())
                                .onTapGesture { selectedOuting = outing }
                        }
                        GONEPrimaryButton(title: "외출 신청", isEnabled: true, isLoading: false, action: apply)
                    }
                    .padding(.horizontal, GONESpacing.screenHorizontal)
                    .padding(.vertical, GONESpacing.xLarge)
                }
            }
        }
        .navigationTitle(viewModel.outings.isEmpty ? "" : "외출")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedOuting) { outing in
            StudentOutingDetailView(
                outing: outing,
                searchTeachers: viewModel.searchTeachers,
                update: viewModel.updatePreview,
                startOuting: { await viewModel.startOuting($0) },
                completeReturn: { await viewModel.completeReturn(for: $0) },
                locationSharingState: viewModel.locationSharingState
            )
        }
    }
}

private struct StudentOutingLandingView: View {
    let apply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
            Text("외출")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.goneTextSecondary)
            landingTitle
            VStack(alignment: .leading, spacing: GONESpacing.small) {
                Text("외출이 필요한가요?").font(.headline.weight(.bold))
                Text("외출 날짜와 시간을 입력해 담당 선생님께\n승인을 요청할 수 있습니다.")
                    .font(.subheadline).foregroundStyle(Color.goneTextSecondary).lineSpacing(3)
            }
            Image("OutingHero")
                .resizable().scaledToFit().frame(width: 210, height: 230)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 100)
            Spacer(minLength: 0)
            GONEPrimaryButton(title: "외출 신청", isEnabled: true, isLoading: false, action: apply)
        }
        .padding(.horizontal, GONESpacing.screenHorizontal)
        .padding(.top, GONESpacing.xLarge + GONESpacing.medium)
        .padding(.bottom, GONESpacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var landingTitle: some View {
        let components = Calendar.current.dateComponents([.month, .day], from: Date())
        return HStack(spacing: 2) {
            Text("\(components.month ?? 0)월 \(components.day ?? 0)일")
                .foregroundStyle(Color.goneBrandPrimary)
            Text("외출 신청")
                .foregroundStyle(Color.goneTextPrimary)
        }
        .font(.title.bold())
    }
}

private struct OutingRequestForm: View {
    let searchTeachers: (String) async -> [OutingTeacher]
    let submit: (OutingDraft) -> Bool
    let submitTitle: String
    @Environment(\.dismiss) private var dismiss
    @State private var draft: OutingDraft
    @State private var reason: String
    @State private var isSubmitting = false
    @State private var isShowingDatePicker = false
    @State private var isShowingTeacherSearch = false
    @State private var selectedTimeMode: TimeSelectionMode?
    @FocusState private var isReasonFocused: Bool

    private let lunch = (12 * 60 + 30, 13 * 60 + 30)
    private let dinner = (18 * 60 + 10, 19 * 60 + 10)

    init(
        initialDraft: OutingDraft = OutingDraft(),
        submitTitle: String = "외출 신청하기",
        searchTeachers: @escaping (String) async -> [OutingTeacher],
        submit: @escaping (OutingDraft) -> Bool
    ) {
        self.searchTeachers = searchTeachers
        self.submit = submit
        self.submitTitle = submitTitle
        _draft = State(initialValue: initialDraft)
        _reason = State(initialValue: initialDraft.reason)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GONESpacing.xLarge) {
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
                    Text("시간 선택").font(.headline)
                    HStack(spacing: GONESpacing.small) {
                        timeModeButton(.lunch, title: "점심", minutes: lunch)
                        timeModeButton(.dinner, title: "저녁", minutes: dinner)
                        timeModeButton(.custom, title: "직접 설정", minutes: nil)
                    }
                }
                if selectedTimeMode == .custom {
                    VStack(alignment: .leading, spacing: GONESpacing.small) {
                        Text("직접 시간 설정").font(.headline)
                        HStack(spacing: GONESpacing.medium) {
                            timeField(title: "출발", selection: $draft.departureTime)
                            timeField(title: "복귀", selection: $draft.returnTime)
                        }
                        .padding(GONESpacing.medium)
                        .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                formField(title: "담당 선생님") {
                    Button { isShowingTeacherSearch = true } label: {
                        fieldLabel(draft.teacher?.name ?? "선생님 검색", icon: "magnifyingglass")
                    }
                    .buttonStyle(.plain)
                }
                formField(title: "외출 사유") {
                    TextField("외출 사유를 입력해 주세요", text: $reason, axis: .vertical)
                        .focused($isReasonFocused)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(3, reservesSpace: true)
                        .padding(.horizontal, GONESpacing.medium)
                        .padding(.top, GONESpacing.medium)
                        .padding(.bottom, GONESpacing.small)
                        .frame(minHeight: 88, alignment: .topLeading)
                        .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault))
                }
                GONEPrimaryButton(
                    title: submitTitle,
                    isEnabled: selectedTimeMode != nil,
                    isLoading: isSubmitting,
                    disabledBackground: Color.goneBrandPrimary.opacity(0.35),
                    disabledForeground: .white
                ) {
                    guard !isSubmitting else { return }
                    isSubmitting = true
                    isReasonFocused = false
                    DispatchQueue.main.async {
                        let succeeded = submit(normalizedDraft)
                        if succeeded {
                            dismiss()
                        } else {
                            isSubmitting = false
                        }
                    }
                }
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
        }
        .background(Color.goneScreenBackground.ignoresSafeArea())
        .navigationTitle("외출 신청")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.24), value: selectedTimeMode)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: draft.date) { _, newDate in alignTimes(to: newDate) }
        .sheet(isPresented: $isShowingDatePicker) { DatePickerSheet(date: $draft.date) }
        .sheet(isPresented: $isShowingTeacherSearch) {
            OutingTeacherSearchSheet(search: searchTeachers) { draft.teacher = $0 }
        }
    }

    private func formField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) { Text(title).font(.headline); content() }
    }

    private var normalizedDraft: OutingDraft {
        var previewDraft = draft
        previewDraft.reason = reason
        if previewDraft.teacher == nil {
            previewDraft.teacher = OutingTeacher(
                id: "teacher-preview",
                name: "이00 선생님",
                affiliation: "teacher"
            )
        }
        return previewDraft.normalizedToSelectedDate()
    }

    private func timeModeButton(_ mode: TimeSelectionMode, title: String, minutes: (Int, Int)?) -> some View {
        Button {
            selectedTimeMode = mode
            if let minutes { setTime(start: minutes.0, end: minutes.1) }
        } label: {
            Text(title).font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 46)
        }
        .foregroundStyle(selectedTimeMode == mode ? .white : Color.goneBrandPrimary)
        .background(selectedTimeMode == mode ? Color.goneBrandPrimary : Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.goneBrandPrimary.opacity(0.35)))
    }

    private func fieldLabel(_ title: String, icon: String) -> some View {
        HStack { Text(title).foregroundStyle(Color.goneTextPrimary); Spacer(); Image(systemName: icon).foregroundStyle(Color.goneTextSecondary) }
            .padding(.horizontal, GONESpacing.large).frame(height: 54)
            .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneBorderDefault))
    }

    private func timeField(title: String, selection: Binding<Date>) -> some View {
        HStack(spacing: GONESpacing.small) {
            Text(title).font(.subheadline.weight(.semibold))
            DatePicker("", selection: selection, in: timeRange, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .environment(\.locale, Locale(identifier: "ko_KR"))
                .tint(Color.goneBrandPrimary)
                .padding(.horizontal, GONESpacing.small)
                .frame(height: 42)
                .background(Color.goneSurfacePrimary, in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var timeRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: draft.date)
        let start = calendar.date(bySettingHour: 8, minute: 40, second: 0, of: day) ?? day
        let end = calendar.date(bySettingHour: 20, minute: 30, second: 0, of: day) ?? day
        return start...end
    }
}

private enum TimeSelectionMode: Equatable { case lunch, dinner, custom }

private struct StudentOutingDetailView: View {
    @State private var outing: OutingRequest
    let searchTeachers: (String) async -> [OutingTeacher]
    let update: (OutingRequest, OutingDraft) -> OutingRequest?
    let startOuting: (OutingRequest) async -> Void
    let completeReturn: (OutingRequest) async -> Void
    let locationSharingState: OutingLocationManager.SharingState
    @State private var isEditing = false

    init(outing: OutingRequest, searchTeachers: @escaping (String) async -> [OutingTeacher], update: @escaping (OutingRequest, OutingDraft) -> OutingRequest?, startOuting: @escaping (OutingRequest) async -> Void, completeReturn: @escaping (OutingRequest) async -> Void, locationSharingState: OutingLocationManager.SharingState) {
        _outing = State(initialValue: outing)
        self.searchTeachers = searchTeachers
        self.update = update
        self.startOuting = startOuting
        self.completeReturn = completeReturn
        self.locationSharingState = locationSharingState
    }

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
                if case .approved = outing.status {
                    locationPermissionNotice
                    actionButton(title: "외출 시작") {
                        Task {
                            await startOuting(outing)
                            outing.status = .outing
                        }
                    }
                } else if case .outing = outing.status {
                    locationPermissionNotice
                    actionButton(title: "복귀 완료") {
                        Task {
                            await completeReturn(outing)
                            outing.status = .completed
                        }
                    }
                }
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
            .padding(.vertical, GONESpacing.xLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("외출 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if case .pendingApproval = outing.status {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("수정") { isEditing = true }
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .navigationDestination(isPresented: $isEditing) {
            OutingRequestForm(
                initialDraft: OutingDraft(outing: outing),
                submitTitle: "외출 수정",
                searchTeachers: searchTeachers
            ) { draft in
                guard let updated = update(outing, draft) else { return false }
                outing = updated
                return true
            }
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.footnote).foregroundStyle(Color.goneTextSecondary)
            Text(value).font(.body)
        }
    }

    private var locationPermissionNotice: some View {
        Text(locationSharingState == .denied
             ? "위치 권한이 꺼져 있어 외출 중 위치를 공유할 수 없습니다. 설정에서 위치 권한을 허용해 주세요."
             : "외출 시작 시 현재 위치가 선도부에게 공유됩니다. 복귀 완료를 누르면 위치 공유가 종료됩니다.")
            .font(.caption)
            .foregroundStyle(locationSharingState == .denied ? Color.goneStatusError : Color.goneTextSecondary)
            .lineSpacing(4)
    }

    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.goneBrandPrimary, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct TeacherOutingListView: View {
    @ObservedObject var viewModel: OutingViewModel
    @State private var filter: OutingFilter = .all
    @State private var selectedOuting: OutingRequest?

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            Text("외출 신청 목록")
                .font(.title2.weight(.bold))
                .padding(.horizontal, GONESpacing.screenHorizontal)
                .padding(.top, GONESpacing.medium)
            OutingFilterBar(selection: $filter)
            List(filteredOutings) { outing in
                Button { selectedOuting = outing } label: {
                    HStack(spacing: GONESpacing.medium) {
                        VStack(alignment: .leading, spacing: 5) {
                            statusBadge(outing.status).padding(.bottom, 4)
                            Text(dateText(outing.date)).font(.caption).foregroundStyle(Color.goneTextSecondary)
                            HStack(spacing: 4) {
                                Text(outing.student.studentNumber).font(.headline.weight(.semibold))
                                Text(outing.student.name).font(.headline.weight(.semibold)).foregroundStyle(Color.goneBrandPrimary)
                                Text("외출").font(.headline.weight(.semibold))
                            }
                            Text("\(timeText(outing.departureTime)) ~ \(timeText(outing.returnTime))")
                                .font(.footnote.weight(.semibold)).foregroundStyle(Color.goneTextPrimary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.goneTextTertiary)
                    }
                    .padding(.horizontal, GONESpacing.large)
                    .padding(.vertical, GONESpacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: GONESpacing.screenHorizontal, bottom: 6, trailing: GONESpacing.screenHorizontal))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.goneScreenBackground)
            .overlay {
                if filteredOutings.isEmpty {
                    ContentUnavailableView("해당 외출 신청이 없어요", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedOuting) { outing in
            TeacherOutingDetailView(outing: outing, decide: viewModel.decide)
        }
    }

    private var filteredOutings: [OutingRequest] { viewModel.outings.filter { filter.includes($0.status) } }
}

private enum OutingFilter: String, CaseIterable, Identifiable {
    case all = "전체"
    case pending = "승인 요청"
    case approved = "승인 완료"
    case rejected = "거절됨"

    var id: Self { self }

    func includes(_ status: OutingRequest.Status) -> Bool {
        switch self {
        case .all: return true
        case .pending: if case .pendingApproval = status { return true } else { return false }
        case .approved: if case .approved = status { return true } else { return false }
        case .rejected: if case .rejected = status { return true } else { return false }
        }
    }
}

private struct OutingFilterBar: View {
    @Binding var selection: OutingFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GONESpacing.small) {
                ForEach(OutingFilter.allCases) { filter in
                    Button(filter.rawValue) { selection = filter }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selection == filter ? .white : Color.goneTextSecondary)
                        .padding(.horizontal, 13).frame(height: 34)
                        .background(selection == filter ? Color.goneBrandPrimary : Color.goneSurfacePrimary, in: Capsule())
                        .overlay(Capsule().stroke(selection == filter ? Color.clear : Color.goneBorderDefault))
                }
            }
            .padding(.horizontal, GONESpacing.screenHorizontal)
        }
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
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.goneStatusError)
                .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.goneStatusError))
            Button("수락") { Task { if await decide(outing, true, nil) { dismiss() } } }
                .frame(maxWidth: .infinity, minHeight: 52)
                .font(.subheadline.weight(.bold))
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
                .datePickerStyle(.graphical)
                .padding()
                .environment(\.locale, Locale(identifier: "ko_KR"))
                .navigationTitle("외출 날짜")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } } }
        }
    }

    private var weekRange: ClosedRange<Date> {
        OutingApplicationPeriod.weekRange()
    }
}

private struct StudentOutingCard: View {
    let outing: OutingRequest
    let cancel: () -> Void
    @State private var isShowingCancelAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: GONESpacing.small) {
            statusBadge(outing.status)
            Text(dateText(outing.date)).font(.subheadline).foregroundStyle(Color.goneTextSecondary)
            Text("\(timeText(outing.departureTime)) ~ \(timeText(outing.returnTime))")
                .font(.headline.weight(.semibold))
            Text(outing.reason).font(.subheadline).foregroundStyle(Color.goneTextSecondary)
            Text("담당: \(outing.teacher.name)").font(.footnote).foregroundStyle(Color.goneTextSecondary)
            if case .pendingApproval = outing.status {
                Button("신청 취소", role: .destructive) {
                    isShowingCancelAlert = true
                }
                .font(.footnote.weight(.semibold))
            }
        }
        .padding(GONESpacing.large).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.goneSurfacePrimary, in: RoundedRectangle(cornerRadius: 16))
        .alert("외출 신청을 취소하시겠습니까?", isPresented: $isShowingCancelAlert) {
            Button("취소하기", role: .destructive, action: cancel)
            Button("닫기", role: .cancel) { }
        } message: {
            Text("취소한 신청은 다시 복구할 수 없습니다.")
        }
    }
}

private extension OutingDraft {
    init(outing: OutingRequest) {
        date = outing.date
        departureTime = outing.departureTime
        returnTime = outing.returnTime
        reason = outing.reason
        teacher = outing.teacher
    }
}

private extension OutingRequest {
    func updated(with draft: OutingDraft) -> OutingRequest {
        OutingRequest(
            id: id,
            student: student,
            date: draft.date,
            departureTime: draft.departureTime,
            returnTime: draft.returnTime,
            reason: draft.reason,
            teacher: draft.teacher ?? teacher,
            status: status
        )
    }
}

@ViewBuilder private func statusLabel(_ status: OutingRequest.Status) -> some View {
    switch status {
    case .pendingApproval: Text("승인 대기").foregroundStyle(Color.goneStatusOuting)
    case .approved: Text("승인됨").foregroundStyle(Color.goneBrandPrimary)
    case .outing: Text("외출 중").foregroundStyle(Color.goneBrandPrimary)
    case .completed: Text("도착").foregroundStyle(Color.goneTextSecondary)
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
    case .outing:
        Text("외출 중")
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.goneBrandPrimary)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Color.goneBrandPrimary.opacity(0.12), in: Capsule())
    case .completed:
        Text("도착")
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.goneTextSecondary)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Color.goneSurfaceDisabled, in: Capsule())
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
                    .font(.subheadline.weight(.bold))
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
