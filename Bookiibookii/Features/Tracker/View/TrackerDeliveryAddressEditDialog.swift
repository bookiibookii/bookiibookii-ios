import SwiftUI

// 택배 배송 정보 수정 다이얼로그 (택배 교환 전용) — 저장된 "나의 배송지" 중 선택.
// 카드 컨텐츠만 담당 — 스크림/오버레이는 호스트 담당.
struct TrackerDeliveryAddressEditDialog: View {
    let savedAddresses: [DeliveryAddressOption]
    let initialSelectedUserDeliveryId: Int?
    let onDismiss: () -> Void
    let onConfirmSaved: (_ userDeliveryId: Int) -> Void

    @State private var selectedUserDeliveryId: Int?

    init(
        savedAddresses: [DeliveryAddressOption],
        initialSelectedUserDeliveryId: Int?,
        onDismiss: @escaping () -> Void,
        onConfirmSaved: @escaping (_ userDeliveryId: Int) -> Void
    ) {
        self.savedAddresses = savedAddresses
        self.initialSelectedUserDeliveryId = initialSelectedUserDeliveryId
        self.onDismiss = onDismiss
        self.onConfirmSaved = onConfirmSaved
        _selectedUserDeliveryId = State(initialValue: initialSelectedUserDeliveryId)
    }

    private var canConfirm: Bool { selectedUserDeliveryId != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            savedAddressSection
            buttonRow
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .center) {
            Text("배송 정보 수정")
                .pretendardText(size: 24, weight: .bold)
                .foregroundColor(Color("grey900"))
            Spacer()
            Button(action: onDismiss) {
                Image("ic_x")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color("grey900"))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color("grey100")))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 나의 배송지

    private var savedAddressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("나의 배송지")
                .pretendardText(size: 16)
                .foregroundColor(Color("grey900"))

            if savedAddresses.isEmpty {
                Text("배송지를 등록해주세요")
                    .pretendardText(size: 16)
                    .foregroundColor(Color("grey400"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color("grey200")))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("grey300"), lineWidth: 1))
            } else {
                VStack(spacing: 8) {
                    ForEach(savedAddresses) { option in
                        AddressButton(
                            title: option.title,
                            address: option.displayAddress,
                            selected: selectedUserDeliveryId == option.userDeliveryId,
                            onClick: { selectedUserDeliveryId = option.userDeliveryId }
                        )
                    }
                }
            }
        }
    }

    // MARK: - 버튼

    private var buttonRow: some View {
        HStack(spacing: 8) {
            CardButton(text: "이전", style: .white, action: onDismiss)
            CardButton(
                text: "확인",
                style: .main,
                action: {
                    guard let selectedUserDeliveryId else { return }
                    onConfirmSaved(selectedUserDeliveryId)
                }
            )
            .disabled(!canConfirm)
        }
    }
}

private struct AddressButton: View {
    let title: String
    let address: String
    let selected: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 8) {
                Image("ic_map")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(selected ? Color("main200") : Color("grey500"))
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(selected ? Color("main200") : Color("grey700"))
                    Text(address)
                        .pretendardText(size: 14)
                        .foregroundColor(selected ? Color("grey600") : Color("grey500"))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 20).fill(selected ? Color("main100") : Color("white")))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(selected ? Color("main105") : Color("grey200"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TrackerDeliveryAddressEditDialog(
        savedAddresses: [
            DeliveryAddressOption(userDeliveryId: 1, title: "자취방", address: "서울 용산구 한강로2가 426", addressDetail: "101동 202호", zipCode: "04379"),
            DeliveryAddressOption(userDeliveryId: 2, title: "회사", address: "서울 강남구 테헤란로 123", addressDetail: "5층", zipCode: "06234"),
        ],
        initialSelectedUserDeliveryId: 1,
        onDismiss: {},
        onConfirmSaved: { _ in }
    )
    .padding(24)
    .background(Color("uiBg"))
}
