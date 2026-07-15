import SwiftUI

// 택배 배송 정보 수정 다이얼로그 (택배 교환 전용)
// - 나의 배송지 선택 → 기존 배송지 선택 API
// - 직접 입력(주소 검색) → 직접 입력 API
// 카드 컨텐츠만 담당 — 스크림/오버레이는 호스트 담당.
struct TrackerDeliveryAddressEditDialog: View {
    let savedAddresses: [DeliveryAddressOption]
    let initialSelectedUserDeliveryId: Int?
    let onDismiss: () -> Void
    let onConfirmSaved: (_ userDeliveryId: Int) -> Void
    let onConfirmDirect: (_ zipCode: String, _ address: String, _ addressDetail: String) -> Void

    @State private var selectedUserDeliveryId: Int?
    @State private var isDirectMode = false
    @State private var directAddress = ""
    @State private var directZipCode = ""
    @State private var directDetail = ""
    @State private var showAddressSearch = false

    init(
        savedAddresses: [DeliveryAddressOption],
        initialSelectedUserDeliveryId: Int?,
        onDismiss: @escaping () -> Void,
        onConfirmSaved: @escaping (_ userDeliveryId: Int) -> Void,
        onConfirmDirect: @escaping (_ zipCode: String, _ address: String, _ addressDetail: String) -> Void
    ) {
        self.savedAddresses = savedAddresses
        self.initialSelectedUserDeliveryId = initialSelectedUserDeliveryId
        self.onDismiss = onDismiss
        self.onConfirmSaved = onConfirmSaved
        self.onConfirmDirect = onConfirmDirect
        _selectedUserDeliveryId = State(initialValue: initialSelectedUserDeliveryId)
    }

    private var canConfirm: Bool {
        isDirectMode ? !directAddress.isEmpty : selectedUserDeliveryId != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            if !savedAddresses.isEmpty {
                savedAddressSection
            }
            directInputSection
            buttonRow
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .fullScreenCover(isPresented: $showAddressSearch) {
            AddressSearchOverlay(
                title: "주소 검색",
                onClose: { showAddressSearch = false },
                onSelect: { result in
                    directAddress = result.roadAddress
                    directZipCode = result.zonecode
                    isDirectMode = true
                    selectedUserDeliveryId = nil
                }
            )
            .presentationBackground(.clear)
        }
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

            VStack(spacing: 8) {
                ForEach(savedAddresses) { option in
                    AddressButton(
                        title: option.title,
                        address: option.displayAddress,
                        selected: !isDirectMode && selectedUserDeliveryId == option.userDeliveryId,
                        onClick: {
                            selectedUserDeliveryId = option.userDeliveryId
                            isDirectMode = false
                            // 선택한 배송지 주소를 직접 입력 칸에도 반영
                            directAddress = option.address
                            directZipCode = option.zipCode
                            directDetail = option.addressDetail
                        }
                    )
                }
            }
        }
    }

    // MARK: - 직접 입력

    private var directInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text("직접 입력")
                    .pretendardText(size: 16)
                    .foregroundColor(Color("grey900"))
                // 주소: 탭하면 우편번호 검색으로 이동 (직접 타이핑 불가)
                AddressSearchBox(
                    value: directAddress,
                    placeholder: "건물명, 도로명, 지번으로 검색",
                    onClick: { showAddressSearch = true }
                )
            }
            // 상세 주소: 직접 입력
            AddressDetailInputBox(
                value: $directDetail,
                placeholder: "상세 주소",
                onChange: {
                    isDirectMode = true
                    selectedUserDeliveryId = nil
                }
            )
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
                    guard canConfirm else { return }
                    if isDirectMode {
                        onConfirmDirect(directZipCode, directAddress, directDetail)
                    } else if let selectedUserDeliveryId {
                        onConfirmSaved(selectedUserDeliveryId)
                    }
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

// 주소 검색 진입 박스 (클릭 전용)
private struct AddressSearchBox: View {
    let value: String
    let placeholder: String
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            Text(value.isEmpty ? placeholder : value)
                .pretendardText(size: 16)
                .foregroundColor(value.isEmpty ? Color("grey500") : Color("grey900"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color("white")))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("grey300"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// 상세 주소 입력 박스 (직접 타이핑)
private struct AddressDetailInputBox: View {
    @Binding var value: String
    let placeholder: String
    let onChange: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            if value.isEmpty {
                Text(placeholder)
                    .pretendardText(size: 16)
                    .foregroundColor(Color("grey500"))
            }
            TextField("", text: $value)
                .font(.pretendard(size: 16))
                .foregroundColor(Color("grey900"))
                .tint(Color("main200"))
                .onChange(of: value) { _, _ in onChange() }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color("white")))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("grey300"), lineWidth: 1))
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
        onConfirmSaved: { _ in },
        onConfirmDirect: { _, _, _ in }
    )
    .padding(24)
    .background(Color("uiBg"))
}
