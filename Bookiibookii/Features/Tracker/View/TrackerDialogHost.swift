import SwiftUI
import UIKit

struct TrackerDialogHost: ViewModifier {
    @ObservedObject var coordinator: TrackerDialogCoordinator
    let cardFor: (Int) -> TrackerCardModel?
    @State private var toastMessage: String?

    func body(content: Content) -> some View {
        content
            .overlay { dialogOverlay }
            .toast($toastMessage)
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
                onConfirmSaved: { userDeliveryId in coordinator.changeDeliveryAddressSaved(groupId: groupId, userDeliveryId: userDeliveryId) }
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
        // 직접교환 (PR-C)
        case .meeting, .meetingInfo, .exchangeConfirm, .exchangeFail:
            EmptyView()
        }
    }
}

extension View {
    func trackerDialogHost(_ coordinator: TrackerDialogCoordinator, cardFor: @escaping (Int) -> TrackerCardModel?) -> some View {
        modifier(TrackerDialogHost(coordinator: coordinator, cardFor: cardFor))
    }
}
