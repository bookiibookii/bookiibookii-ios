import SwiftUI

// 안드 DirectHostActivity 대응. ViewModel이 phase / 시트 / 액션을 관리.
// 본 사이클: toolbar + statusCard + sheet 라우팅 스캐폴드. 개별 시트 본문은 다음 세션부터.
struct HostDirectView: View {
    @StateObject private var vm: HostDirectViewModel
    @EnvironmentObject private var container: DIContainer
    private let onBack: () -> Void

    // 폼 / 입력 상태 (HostDeliveryView와 동일 패턴)
    @State private var extendDaysInput: String = ""
    @State private var appointmentDateTime: String = ""
    @State private var appointmentPlace: String = ""
    @State private var appointmentDate: Date = Date()
    @State private var showDateTimePicker: Bool = false

    init(
        groupId: Int,
        service: TrackerService,
        libraryService: LibraryService,
        onBack: @escaping () -> Void = {}
    ) {
        _vm = StateObject(wrappedValue: HostDirectViewModel(
            groupId: groupId,
            service: service,
            libraryService: libraryService
        ))
        self.onBack = onBack
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Rectangle()
                .fill(Color(red: 0xEE/255, green: 0xEE/255, blue: 0xEE/255))
                .frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    statusTitle.padding(.leading, 20).padding(.top, 24)
                    statusCard.padding(.horizontal, 20).padding(.top, 16)
                }
                .padding(.bottom, 50)
            }
        }
        .background(Color("grey100"))
        .task { await vm.onAppear() }
        .sheet(item: bottomSheetBinding) { sheet in
            sheetView(for: sheet)
                .presentationBackground(Color("white"))
                .presentationCornerRadius(24)
                .presentationDetents([.height(sheet.fixedHeight)])
        }
        .overlay {
            if let sheet = vm.activeSheet, !sheet.isBottomSheet {
                centerDialogOverlay(for: sheet)
            }
        }
        .overlay {
            if vm.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(ProgressView().tint(.white))
            }
        }
        .toast($vm.toastMessage)
        .onChange(of: vm.libraryBookToOpen) { _, book in
            guard let book else { return }
            vm.dismissSheet()
            container.navigationRouter.push(to: .libraryCards(book: book))
            vm.libraryBookToOpen = nil
        }
    }

    // MARK: - 툴바

    private var toolbar: some View {
        ZStack {
            Text(vm.detail?.bookTitle ?? "")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(Color("black"))
                .lineLimit(1)
                .padding(.horizontal, 60)

            HStack {
                Button(action: onBack) {
                    Image("ic_back")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color("black"))
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)

                Spacer()

                Button { vm.tapStep(.groupManage) } label: {
                    Image("ic_meetball")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
    }

    // MARK: - 상태 카드

    private var statusTitle: some View {
        HStack(spacing: 0) {
            Text(vm.detail?.partnerNickname ?? "")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(Color("main200"))
            Text(" 님과의 현황")
                .font(.pretendard(size: 18))
                .foregroundColor(Color("black"))
        }
    }

    private var statusCard: some View {
        let steps = DirectStepBuilder.buildHostSteps(status: vm.detail?.trackerStatus ?? .unknown)
        return VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                Button { tapCurrentPhaseSheet() } label: {
                    TradeStatusRow(item: TradeStepRow(
                        title: step.title,
                        description: step.description,
                        badge: step.badge
                    ))
                }
                .buttonStyle(.plain)
                if index != steps.count - 1 {
                    Rectangle()
                        .fill(Color("grey100"))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func tapCurrentPhaseSheet() {
        Task { await vm.refreshAndShowSheet() }
    }

    // MARK: - 시트 라우팅

    @ViewBuilder
    private func sheetView(for sheet: DirectSheet) -> some View {
        switch sheet {
        case .start:
            HostDirectStartSheet(
                startDate: TrackerDateFormatter.prettyDate(vm.detail?.startDate),
                endDate: TrackerDateFormatter.prettyDate(vm.detail?.endDate),
                onStart: {
                    vm.dismissSheet()
                    Task { await vm.startReading() }
                }
            )
        case .reading:
            HostDirectReadingSheet(
                title: "책을 읽고 있어요",
                startDate: TrackerDateFormatter.prettyDate(vm.detail?.startDate),
                endDate: TrackerDateFormatter.prettyDate(vm.detail?.endDate),
                canExtendPeriod: (vm.detail?.extensionCount ?? 0) < 1
                    && (vm.detail?.trackerStatus == .hostReading
                        || vm.detail?.trackerStatus == .hostExtension),
                onWriteCard: { Task { await vm.openLibraryCards() } },
                onExtendPeriod: { vm.tapStep(.extendPeriod) },
                onFinish: {
                    vm.dismissSheet()
                    Task { await vm.markDone() }
                },
                isLoadingCard: vm.isOpeningLibraryCards
            )
        case .readingStatus:
            HostDirectReadingStatusSheet(
                startDate: TrackerDateFormatter.prettyDate(vm.detail?.startDate),
                endDate: TrackerDateFormatter.prettyDate(vm.detail?.endDate),
                onGoCard: { Task { await vm.openLibraryCards() } },
                isLoadingCard: vm.isOpeningLibraryCards
            )
        case .extendPeriod:
            HostDirectExtendPeriodSheet(
                days: $extendDaysInput,
                originalEndDate: TrackerDateFormatter.prettyDate(vm.detail?.endDate),
                extendedEndDate: TrackerDateFormatter.extendedEndDateText(
                    endRaw: vm.detail?.endDate,
                    days: Int(extendDaysInput) ?? 0
                ),
                onClose: { extendDaysInput = ""; vm.dismissSheet() },
                onCancel: { extendDaysInput = ""; vm.dismissSheet() },
                onApply: {
                    let days = Int(extendDaysInput) ?? 0
                    extendDaysInput = ""
                    vm.dismissSheet()
                    guard days > 0 else { return }
                    Task { await vm.requestExtension(days: days) }
                }
            )
        case .extendRequest:
            HostDirectExtendRequestSheet(
                originalEndDate: TrackerDateFormatter.prettyDate(vm.detail?.endDate),
                newEndDate: TrackerDateFormatter.prettyDate(vm.detail?.endDate),
                onConfirm: vm.dismissSheet
            )
        case .appointment:
            HostDirectAppointmentSheet(
                onGoComment: vm.dismissSheet,
                onRegisterMeet: { vm.tapStep(.setAppointment) }
            )
        case .setAppointment:
            HostDirectSetAppointmentDialog(
                dateTime: $appointmentDateTime,
                place: $appointmentPlace,
                onClose: { resetAppointmentForm(); vm.dismissSheet() },
                onPickDateTime: { showDateTimePicker = true },
                onSubmit: {
                    let formInput = appointmentDateTime
                    let place = appointmentPlace
                    resetAppointmentForm()
                    vm.dismissSheet()
                    Task { await vm.makeMeeting(formInput: formInput, place: place) }
                }
            )
            .sheet(isPresented: $showDateTimePicker) {
                DateTimePickerSheet(date: $appointmentDate) {
                    appointmentDateTime = DirectMeetingFormatter.formDateTime(date: appointmentDate)
                    showDateTimePicker = false
                }
            }
        case .appointmentEdit:
            HostDirectAppointmentEditSheet(
                titleDateTime: DirectMeetingFormatter.titleDateTime(vm.detail?.meetingInfo?.meetingTime),
                appointmentDateTime: DirectMeetingFormatter.cardDateTime(vm.detail?.meetingInfo?.meetingTime),
                appointmentPlace: vm.detail?.meetingInfo?.meetingPlace ?? "",
                onGoComment: vm.dismissSheet,
                onEditMeet: {
                    appointmentDateTime = DirectMeetingFormatter.formDateTime(vm.detail?.meetingInfo?.meetingTime)
                    appointmentPlace = vm.detail?.meetingInfo?.meetingPlace ?? ""
                    vm.tapStep(.appointmentEditDialog)
                }
            )
        case .appointmentEditDialog:
            HostDirectAppointmentEditDialog(
                dateTime: $appointmentDateTime,
                place: $appointmentPlace,
                onClose: { resetAppointmentForm(); vm.dismissSheet() },
                onPickDateTime: { showDateTimePicker = true },
                onSubmit: {
                    let formInput = appointmentDateTime
                    let place = appointmentPlace
                    resetAppointmentForm()
                    vm.dismissSheet()
                    Task { await vm.makeMeeting(formInput: formInput, place: place) }
                }
            )
            .sheet(isPresented: $showDateTimePicker) {
                DateTimePickerSheet(date: $appointmentDate) {
                    appointmentDateTime = DirectMeetingFormatter.formDateTime(date: appointmentDate)
                    showDateTimePicker = false
                }
            }
        case .appointmentStatus:
            HostDirectAppointmentStatusSheet(
                titleDateTime: DirectMeetingFormatter.titleDateTime(vm.detail?.meetingInfo?.meetingTime),
                appointmentDateTime: DirectMeetingFormatter.cardDateTime(vm.detail?.meetingInfo?.meetingTime),
                appointmentPlace: vm.detail?.meetingInfo?.meetingPlace ?? "",
                onGoChat: vm.dismissSheet
            )
        case .meetEmpty:
            HostDirectMeetEmptySheet(
                onGoComment: vm.dismissSheet,
                onConfirm: vm.dismissSheet
            )
        case .meetIssue:
            HostDirectMeetIssueDialog(
                onClose: vm.dismissSheet,
                onReport: vm.dismissSheet,
                onReschedule: { vm.tapStep(.appointmentEditDialog) }
            )
        case .exchange:
            HostDirectExchangeSheet(
                appointmentDateTime: DirectMeetingFormatter.cardDateTime(vm.detail?.meetingInfo?.meetingTime),
                appointmentPlace: vm.detail?.meetingInfo?.meetingPlace ?? "",
                onNoSend: { vm.tapStep(.meetIssue) },
                onSend: {
                    vm.dismissSheet()
                    Task { await vm.completeMeeting() }
                }
            )
        case .receive:
            HostDirectReceiveSheet(
                appointmentDateTime: DirectMeetingFormatter.cardDateTime(vm.detail?.meetingInfo?.meetingTime),
                appointmentPlace: vm.detail?.meetingInfo?.meetingPlace ?? "",
                onNoReceive: { vm.tapStep(.receiveIssue) },
                onReceive: {
                    vm.dismissSheet()
                    Task { await vm.completeMeeting() }
                }
            )
        case .receiveIssue:
            HostDirectReceiveIssueDialog(
                onClose: vm.dismissSheet,
                onReport: vm.dismissSheet,
                onReschedule: { vm.tapStep(.appointmentEditDialog) }
            )
        case .tradeFinish:
            HostDirectTradeFinishSheet(onWriteReview: {
                vm.dismissSheet()
                container.navigationRouter.push(to: .reviewWrite(groupId: vm.groupId))
            })
        case .groupManage:
            HostGroupManageSheet(
                isInProgress: vm.phase != .initState && vm.phase != .finished,
                onTapDetail: vm.dismissSheet,
                onTapEdit: vm.dismissSheet,
                onTapDelete: vm.dismissSheet
            )
        }
    }

    private func resetAppointmentForm() {
        appointmentDateTime = ""
        appointmentPlace = ""
    }

    private var bottomSheetBinding: Binding<DirectSheet?> {
        Binding(
            get: {
                guard let s = vm.activeSheet, s.isBottomSheet else { return nil }
                return s
            },
            set: { newValue in
                if newValue == nil, let s = vm.activeSheet, s.isBottomSheet {
                    vm.dismissSheet()
                }
            }
        )
    }

    @ViewBuilder
    private func centerDialogOverlay(for sheet: DirectSheet) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { /* 외부 탭 ignore */ }
            sheetView(for: sheet)
                .padding(.horizontal, 20)
        }
        .transition(.opacity)
    }
}

#Preview("HostDirect") {
    HostDirectView(
        groupId: 1,
        service: TrackerService(interceptor: AuthInterceptor(authService: AuthService())),
        libraryService: LibraryService(interceptor: AuthInterceptor(authService: AuthService()))
    )
}
