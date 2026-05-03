import SwiftUI
import PhotosUI
import UIKit

// 안드 GuestActivity 대응. ViewModel이 phase / 시트 / 액션을 관리.
struct GuestDeliveryView: View {
    @StateObject private var vm: GuestDeliveryViewModel
    private let onBack: () -> Void

    init(groupId: Int, service: TrackerService, onBack: @escaping () -> Void = {}) {
        _vm = StateObject(wrappedValue: GuestDeliveryViewModel(groupId: groupId, service: service))
        self.onBack = onBack
    }

    // 폼 / 사진 상태 (Host와 동일 패턴)
    @State private var extendDaysInput: String = ""
    @State private var courier: String = ""
    @State private var trackingNumber: String = ""
    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var showCourierPicker: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var receivePickedItem: PhotosPickerItem?
    @State private var receivePickedImage: UIImage?
    @State private var receiveChecked: Bool = false
    @State private var showReceivePhotoPicker: Bool = false
    @State private var shippingPhotoUrl: String?
    @State private var shippingPhotoSource: ShippingPhotoSource = .delivery

    private enum ShippingPhotoSource {
        case delivery
        case received
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
        .sheet(item: $vm.activeSheet, onDismiss: handleSheetDismiss) { sheet in
            sheetView(for: sheet)
                .presentationBackground(Color("white"))
                .presentationCornerRadius(24)
                .presentationDetents([.height(sheet.fixedHeight)])
        }
        .overlay {
            if vm.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                    .overlay(ProgressView().tint(.white))
            }
        }
        .toast($vm.toastMessage)
    }

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
                    Image("ic_more")
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

    private var statusTitle: some View {
        HStack(spacing: 0) {
            Text(vm.detail?.partnerNickname ?? "")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(Color("sub200"))   // 게스트는 파랑
            Text(" 님과의 현황")
                .font(.pretendard(size: 18))
                .foregroundColor(Color("black"))
        }
    }

    private var statusCard: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                let row = rows[index]
                Button {
                    if let sheet = row.sheet { vm.tapStep(sheet) }
                } label: {
                    TradeStatusRow(item: row.step)
                }
                .buttonStyle(.plain)
                if index != rows.count - 1 {
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

    private var rows: [GuestDeliveryRow] {
        let p = vm.phase
        return [
            GuestDeliveryRow(step: .init(title: "호스트 독서", description: "호스트가 책을 읽는 중",
                                         badge: badge(for: p, threshold: .hostReading)),
                             sheet: .readingStatus),
            GuestDeliveryRow(step: .init(title: "게스트에게 발송", description: "호스트가 책을 발송",
                                         badge: badge(for: p, threshold: .hostShipped)),
                             sheet: .shippingStatus),
            GuestDeliveryRow(step: .init(title: "게스트 수령", description: "수령 사진 등록",
                                         badge: badge(for: p, threshold: .guestReading)),
                             sheet: .receiveConfirm),
            GuestDeliveryRow(step: .init(title: "게스트 독서", description: "내가 책을 읽는 중",
                                         badge: badge(for: p, threshold: .guestReading)),
                             sheet: .reading),
            GuestDeliveryRow(step: .init(title: "호스트에게 회수", description: "운송장 등록 후 발송",
                                         badge: badge(for: p, threshold: .guestShipped)),
                             sheet: .shippingInput),
            GuestDeliveryRow(step: .init(title: "호스트 수령", description: "호스트가 수령",
                                         badge: badge(for: p, threshold: .finished)),
                             sheet: .shipped),
            GuestDeliveryRow(step: .init(title: "거래 종료", description: "리뷰 작성",
                                         badge: badge(for: p, threshold: .finished)),
                             sheet: .tradeFinish),
        ]
    }

    private func badge(for phase: DeliveryPhase, threshold: DeliveryPhase) -> String {
        let order: [DeliveryPhase] = [
            .initState, .hostReading, .hostShippingReady, .hostShipped,
            .guestReading, .guestShippingReady, .guestShipped, .finished
        ]
        let current = order.firstIndex(of: phase) ?? 0
        let target = order.firstIndex(of: threshold) ?? 0
        if current > target { return "완료" }
        if current == target { return "진행중" }
        return "대기"
    }

    @ViewBuilder
    private func sheetView(for sheet: DeliverySheet) -> some View {
        switch sheet {
        case .start:
            GuestStartSheet(
                startDate: TrackerDateFormatter.prettyDate(vm.detail?.startDate),
                endDate: TrackerDateFormatter.prettyDate(vm.detail?.endDate),
                onStart: { vm.dismissSheet() }
            )
        case .reading:
            GuestReadingSheet(
                title: "책을 읽고 있어요",
                startDate: TrackerDateFormatter.prettyDate(vm.detail?.startDate),
                endDate: TrackerDateFormatter.prettyDate(vm.detail?.endDate),
                onWriteCard: vm.dismissSheet,
                onExtendPeriod: { vm.tapStep(.extendPeriod) },
                onFinish: { Task { await vm.markDone(); vm.dismissSheet() } }
            )
        case .readingStatus:
            GuestReadingStatusSheet(
                startDate: TrackerDateFormatter.prettyDate(vm.detail?.startDate),
                endDate: TrackerDateFormatter.prettyDate(vm.detail?.endDate),
                onGoCard: vm.dismissSheet
            )
        case .readingDone:
            GuestReadingDoneSheet(onGoCard: vm.dismissSheet)
        case .extendPeriod:
            GuestExtendPeriodSheet(
                days: $extendDaysInput,
                originalEndDate: TrackerDateFormatter.prettyDate(vm.detail?.endDate),
                extendedEndDate: TrackerDateFormatter.extendedEndDateText(
                    endRaw: vm.detail?.endDate,
                    days: Int(extendDaysInput) ?? 0
                ),
                onClose: { extendDaysInput = ""; vm.dismissSheet() },
                onCancel: { extendDaysInput = ""; vm.dismissSheet() },
                onApply: {
                    let days = Int(extendDaysInput) ?? 3
                    Task {
                        await vm.requestExtension(days: days)
                        extendDaysInput = ""
                        vm.dismissSheet()
                    }
                }
            )
        case .extendRequest:
            GuestExtendRequestSheet(
                originalEndDate: TrackerDateFormatter.prettyDate(vm.detail?.endDate),
                newEndDate: TrackerDateFormatter.prettyDate(vm.detail?.endDate),
                onConfirm: vm.dismissSheet
            )
        case .shipping:
            GuestShippingSheet(
                receiverName: vm.detail?.deliveryInfo?.receiverName ?? "",
                receiverPhone: vm.detail?.deliveryInfo?.receiverPhone ?? "",
                address: vm.detail?.deliveryInfo?.receiverAddress ?? "",
                onCopy: {
                    let address = vm.detail?.deliveryInfo?.receiverAddress ?? ""
                    UIPasteboard.general.string = address
                    vm.toastMessage = "주소가 복사되었어요"
                },
                onRegister: { vm.tapStep(.shippingInput) }
            )
        case .shippingInput:
            GuestShippingInputSheet(
                courier: $courier,
                trackingNumber: $trackingNumber,
                courierOptions: courierOptions,
                pickedImage: pickedImage,
                onClose: { resetShippingForm(); vm.dismissSheet() },
                onSelectCourier: { showCourierPicker = true },
                onPickImage: { showPhotoPicker = true },
                onRegister: {
                    guard !courier.isEmpty, !trackingNumber.isEmpty, let image = pickedImage else { return }
                    Task {
                        await vm.startShipping(company: courier, trackingNumber: trackingNumber, image: image)
                        resetShippingForm()
                        vm.dismissSheet()
                    }
                }
            )
            .confirmationDialog("택배사 선택", isPresented: $showCourierPicker, titleVisibility: .visible) {
                ForEach(courierOptions, id: \.self) { option in
                    Button(option) { courier = option }
                }
                Button("취소", role: .cancel) {}
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $pickedItem, matching: .images)
            .onChange(of: pickedItem) { _, newItem in
                Task {
                    guard let newItem,
                          let data = try? await newItem.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    pickedImage = image
                }
            }
        case .shippingPhoto:
            GuestShippingPhotoSheet(
                imageUrl: shippingPhotoUrl,
                onConfirm: { shippingPhotoUrl = nil; vm.dismissSheet() }
            )
            .task {
                shippingPhotoUrl = nil
                do {
                    let url = try await vm.service.fetchShippingImageURL(groupId: vm.groupId)
                    shippingPhotoUrl = url.absoluteString
                } catch {
                    vm.toastMessage = "사진을 불러올 수 없어요"
                }
            }
        case .shipped:
            GuestShippedSheet(
                courier: vm.detail?.deliveryInfo?.deliveryCompany ?? "",
                trackingNumber: vm.detail?.deliveryInfo?.trackingNumber ?? "",
                onViewShippingPhoto: { vm.tapStep(.shippingPhoto) },
                onDoReceiveConfirm: { vm.tapStep(.receiveConfirm) }
            )
        case .shippingStatus:
            GuestShippingStatusSheet(
                courier: vm.detail?.deliveryInfo?.deliveryCompany ?? "",
                trackingNumber: vm.detail?.deliveryInfo?.trackingNumber ?? "",
                isReceived: vm.detail?.deliveryInfo?.isVerified ?? false,
                onConfirm: { vm.tapStep(.shippingPhoto) }
            )
        case .receiveConfirm:
            GuestReceiveConfirmSheet(
                pickedImage: receivePickedImage,
                isChecked: $receiveChecked,
                onClose: { resetReceiveForm(); vm.dismissSheet() },
                onPickImage: { showReceivePhotoPicker = true },
                onFinish: {
                    guard let image = receivePickedImage, receiveChecked else { return }
                    Task {
                        await vm.registerReceipt(image: image)
                        resetReceiveForm()
                        vm.dismissSheet()
                    }
                }
            )
            .photosPicker(isPresented: $showReceivePhotoPicker, selection: $receivePickedItem, matching: .images)
            .onChange(of: receivePickedItem) { _, newItem in
                Task {
                    guard let newItem,
                          let data = try? await newItem.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    receivePickedImage = image
                }
            }
        case .tradeFinish:
            GuestTradeFinishSheet(onWriteReview: vm.dismissSheet)
        case .groupManage:
            GuestGroupManageSheet(
                onTapDetail: vm.dismissSheet,
                onTapReport: vm.dismissSheet
            )
        case .photoSelection:
            Color.clear.onAppear { vm.dismissSheet() }
        case .sendConfirm:
            GuestSendConfirmView(imageUrl: nil, isChecked: false, onConfirm: vm.dismissSheet)
        }
    }

    private var courierOptions: [String] {
        ["CJ대한통운", "롯데택배", "한진택배", "우체국택배", "로젠택배", "쿠팡로지스틱스"]
    }

    private func resetShippingForm() {
        courier = ""
        trackingNumber = ""
        pickedItem = nil
        pickedImage = nil
    }

    private func resetReceiveForm() {
        receivePickedItem = nil
        receivePickedImage = nil
        receiveChecked = false
    }

    /// 시트가 어떤 경로(콜백/swipe-down)로 닫히든 폼 상태 초기화.
    /// SwiftUI .sheet(item:onDismiss:)는 swipe-dismiss에도 호출되므로
    /// 콜백 안의 reset과 중복되더라도 여기서 일괄 정리한다.
    private func handleSheetDismiss() {
        extendDaysInput = ""
        resetShippingForm()
        resetReceiveForm()
        shippingPhotoUrl = nil
    }
}

private struct GuestDeliveryRow {
    let step: TradeStepRow
    let sheet: DeliverySheet?
}

#Preview("GuestDelivery") {
    GuestDeliveryView(
        groupId: 1,
        service: TrackerService(interceptor: AuthInterceptor(authService: AuthService()))
    )
}
