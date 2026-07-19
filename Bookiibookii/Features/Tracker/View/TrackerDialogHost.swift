import SwiftUI
import UIKit

struct TrackerDialogHost: ViewModifier {
    @ObservedObject var coordinator: TrackerDialogCoordinator
    @Environment(\.openURL) private var openURL
    let cardFor: (Int) -> TrackerCardModel?
    @State private var toastMessage: String?

    func body(content: Content) -> some View {
        content
            .overlay { dialogOverlay }
            .toast($toastMessage)
            // 다이얼로그가 떠 있는 동안 하단 탭바 숨김
            .preference(key: TabBarHiddenKey.self, value: coordinator.route != nil)
    }

    @ViewBuilder private var dialogOverlay: some View {
        if let route = coordinator.route {
            ZStack {
                Color.black.opacity(0.45).ignoresSafeArea()
                    .onTapGesture { coordinator.dismiss() }
                dialogCard(route)
                    .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder private func dialogCard(_ route: TrackerDialogRoute) -> some View {
        switch route {
        case let .progress(groupId):
            TrackerProgressRecordDialog(
                totalPages: cardFor(groupId)?.left.totalPages ?? 0,
                onDismiss: { coordinator.dismiss() },
                onConfirm: { page in coordinator.recordProgress(groupId: groupId, currentPage: page) }
            )
        case let .deliveryInfo(groupId):
            TrackerDeliveryInfoDialog(
                partnerNickname: cardFor(groupId)?.right.nickname ?? "",
                myAddress: coordinator.deliveryAddress?.myAddress.toDisplay() ?? TrackerDeliveryAddressDisplay(),
                partnerAddress: coordinator.deliveryAddress?.partnerAddress.toDisplay() ?? TrackerDeliveryAddressDisplay(),
                canEditMyAddress: coordinator.deliveryAddress?.canEditMyAddress ?? false,
                onDismiss: { coordinator.dismiss() },
                onEditClick: { coordinator.openDeliveryEdit(groupId: groupId) },
                onConfirmClick: { coordinator.dismiss() }
            )
        case let .deliveryEdit(groupId):
            TrackerDeliveryAddressEditDialog(
                savedAddresses: coordinator.savedDeliveries.map { $0.toDeliveryAddressOption() },
                initialSelectedUserDeliveryId: coordinator.savedDeliveries.matchUserDeliveryId(coordinator.deliveryAddress?.myAddress),
                onDismiss: { coordinator.dismiss() },
                onConfirmSaved: { userDeliveryId in coordinator.changeDeliveryAddressSaved(groupId: groupId, userDeliveryId: userDeliveryId) },
                onConfirmDirect: { zipCode, address, addressDetail in coordinator.changeDeliveryAddressDirect(groupId: groupId, zipCode: zipCode, address: address, addressDetail: addressDetail) }
            )
        case let .tracking(groupId):
            TrackerDeliveryTrackingNumberDialog(
                onDismiss: { coordinator.dismiss() },
                onConfirm: { company, number in coordinator.registerDelivery(groupId: groupId, deliveryCompany: company, trackingNumber: number) }
            )
        case .shippingConfirm:
            TrackerDeliveryShippingConfirmDialog(
                companyName: coordinator.partnerDelivery?.deliveryCompanyName ?? "",
                trackingNumber: coordinator.partnerDelivery?.trackingNumber ?? "",
                onDismiss: { coordinator.dismiss() },
                onTrackingSearchClick: {
                    if let url = deliveryTrackingUrl(companyCode: coordinator.partnerDelivery?.deliveryCompany, trackingNumber: coordinator.partnerDelivery?.trackingNumber) {
                        UIApplication.shared.open(url)
                    } else {
                        toastMessage = "배송 조회를 지원하지 않는 택배사예요."
                    }
                },
                onConfirmClick: { coordinator.dismiss() }
            )
        case let .receiveConfirm(groupId):
            TrackerDeliveryReceiveConfirmDialog(
                onDismiss: { coordinator.dismiss() },
                onConfirmClick: { coordinator.confirmReceive(groupId: groupId) }
            )
        case let .meeting(groupId, step, editMode):
            switch step {
            case 1:
                TrackerDirectMeetingTimeDialog(
                    onDismiss: { coordinator.dismiss() },
                    onNextClick: { iso in
                        coordinator.setMeetingScheduledAt(iso)
                        coordinator.goMeetingStep(2)
                    },
                    initialScheduledAt: editMode ? coordinator.meetingDraft.scheduledAt : nil
                )
            case 2:
                TrackerDirectMeetingPlaceDialog(
                    address: coordinator.meetingDraft.place?.address ?? "",
                    addressDetail: coordinator.meetingDraft.addressDetail,
                    onAddressDetailChange: { coordinator.updateMeetingAddressDetail($0) },
                    onSelectPlace: { coordinator.setMeetingPlace($0.toMeetingPlace()) },
                    onLoadMyPlaceClick: { coordinator.loadMyExchangePlace() },
                    onDismiss: { coordinator.dismiss() },
                    onPreviousClick: { coordinator.goMeetingStep(1) },
                    onNextClick: { coordinator.goMeetingStep(3) }
                )
            default:
                TrackerDirectMeetingConfirmDialog(
                    scheduledAt: coordinator.meetingDraft.scheduledAt ?? "",
                    address: coordinator.meetingDraft.place?.address ?? "",
                    addressDetail: coordinator.meetingDraft.addressDetail,
                    onDismiss: { coordinator.dismiss() },
                    onConfirmClick: { coordinator.submitMeeting(groupId: groupId, editMode: editMode) }
                )
            }
        case let .meetingInfo(groupId):
            TrackerDirectMeetingInfoDialog(
                scheduledAt: coordinator.meetingInfo?.meetingAt ?? "",
                address: coordinator.meetingInfo?.location?.address ?? "",
                addressDetail: coordinator.meetingInfo?.addressDetail ?? "",
                isHost: cardFor(groupId)?.isHost ?? false,
                onDismiss: { coordinator.dismiss() },
                onConfirmClick: { coordinator.dismiss() },
                onEditClick: { coordinator.openMeetingEdit(groupId: groupId) }
            )
        case let .exchangeConfirm(groupId):
            TrackerDirectExchangeConfirmDialog(
                onDismiss: { coordinator.dismiss() },
                onNotYetClick: { coordinator.openExchangeFail(groupId: groupId) },
                onConfirmClick: { coordinator.completeMeeting(groupId: groupId) }
            )
        case .exchangeFail:
            TrackerDirectExchangeFailDialog(
                onDismiss: { coordinator.dismiss() },
                onReportClick: { openURL(TrackerExternalLink.reportChannel) },
                onGoToCommentsClick: { coordinator.dismiss() }
            )
        case let .readingPeriod(groupId, originalEndDate):
            TrackerReadingPeriodEditDialog(
                originalEndDate: originalEndDate,
                onConfirm: { newDate in
                    coordinator.updateReadingPeriod(groupId: groupId, newEndDate: Self.isoDate(newDate))
                },
                onDismiss: { coordinator.dismiss() }
            )
        }
    }
}

extension TrackerDialogHost {
    static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }
}

extension View {
    func trackerDialogHost(_ coordinator: TrackerDialogCoordinator, cardFor: @escaping (Int) -> TrackerCardModel?) -> some View {
        modifier(TrackerDialogHost(coordinator: coordinator, cardFor: cardFor))
    }
}
