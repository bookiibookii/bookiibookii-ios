import SwiftUI

// 배송 정보 확인 다이얼로그 — "나"/상대방 탭 전환으로 각자의 배송지 정보를 확인.
// 카드 컨텐츠만 담당 — 스크림/오버레이는 호스트 담당.
struct TrackerDeliveryInfoDialog: View {
    let partnerNickname: String
    let myAddress: TrackerDeliveryAddressDisplay
    let partnerAddress: TrackerDeliveryAddressDisplay
    let canEditMyAddress: Bool
    let onDismiss: () -> Void
    let onEditClick: () -> Void
    let onConfirmClick: () -> Void

    @State private var selectedTabIndex: Int = 0

    private var current: TrackerDeliveryAddressDisplay {
        selectedTabIndex == 0 ? myAddress : partnerAddress
    }

    // "나" 탭이면서 canEditMyAddress=true 일 때만 수정 가능
    private var editEnabled: Bool {
        selectedTabIndex == 0 && canEditMyAddress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            tabRow
            InfoField(label: "수령인", value: current.receiverName)
            InfoField(label: "연락처", value: current.phoneNumber)
            InfoField(label: "주소", value: current.address)
            InfoField(label: "상세주소", value: current.addressDetail)
            buttonRow
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .center) {
            Text("배송 정보 확인")
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

    // MARK: - 나 / 상대방 탭

    private var tabRow: some View {
        HStack(spacing: 24) {
            TabItem(text: "나", selected: selectedTabIndex == 0, onClick: { selectedTabIndex = 0 })
            TabItem(text: partnerNickname, selected: selectedTabIndex == 1, onClick: { selectedTabIndex = 1 })
        }
    }

    // MARK: - 버튼

    private var buttonRow: some View {
        HStack(spacing: 8) {
            CardButton(
                text: "수정",
                style: editEnabled ? .white : .grey,
                action: { if editEnabled { onEditClick() } }
            )
            CardButton(
                text: "확인",
                style: .main,
                action: onConfirmClick
            )
        }
    }
}

private struct TabItem: View {
    let text: String
    let selected: Bool
    let onClick: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(text)
                .pretendardText(size: 18, weight: .medium)
                .foregroundColor(selected ? Color("main200") : Color("grey400"))
                .padding(.horizontal, 4)
            Rectangle()
                .fill(selected ? Color("main200") : Color.clear)
                .frame(height: 2)
        }
        .fixedSize(horizontal: true, vertical: false)
        .contentShape(Rectangle())
        .onTapGesture(perform: onClick)
    }
}

private struct InfoField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .pretendardText(size: 16)
                .foregroundColor(Color("grey900"))
            Text(value)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.trailing, 12)
                .padding(.vertical, 12)
                .frame(minHeight: 48)
                .background(Color("grey100"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey200"), lineWidth: 1))
        }
    }
}

#Preview {
    TrackerDeliveryInfoDialog(
        partnerNickname: "noshel",
        myAddress: TrackerDeliveryAddressDisplay(
            receiverName: "장우영",
            phoneNumber: "010-1111-1111",
            address: "서울 용산구 한강로2가 426",
            addressDetail: "101동 202호"
        ),
        partnerAddress: TrackerDeliveryAddressDisplay(
            receiverName: "noshel",
            phoneNumber: "010-2222-2222",
            address: "서울 강남구 테헤란로 123",
            addressDetail: "10층"
        ),
        canEditMyAddress: true,
        onDismiss: {},
        onEditClick: {},
        onConfirmClick: {}
    )
    .padding(24)
    .background(Color("uiBg"))
}
