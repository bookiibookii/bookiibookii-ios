import SwiftUI

// 직접교환 약속 잡기 2/3 - 장소 선택 다이얼로그.
// 카드 컨텐츠만 담당 — 스크림/오버레이는 호스트 담당.
// 검색바 탭 시 내부적으로 ExchangePlaceSearchOverlay를 ZStack 상단에 표시(자체 스크림 보유).
struct TrackerDirectMeetingPlaceDialog: View {
    let address: String
    let addressDetail: String
    let onAddressDetailChange: (String) -> Void
    let onSelectPlace: (KakaoPlaceResult) -> Void
    let onLoadMyPlaceClick: () -> Void
    let onDismiss: () -> Void
    let onPreviousClick: () -> Void
    let onNextClick: () -> Void

    @State private var showSearch = false

    private var addressDetailBinding: Binding<String> {
        Binding(get: { addressDetail }, set: onAddressDetailChange)
    }

    var body: some View {
        ZStack {
            content

            if showSearch {
                ExchangePlaceSearchOverlay(
                    onClose: { showSearch = false },
                    onSelect: {
                        onSelectPlace($0)
                        showSearch = false
                    }
                )
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            VStack(alignment: .leading, spacing: 16) {
                searchInput
                VStack(spacing: 12) {
                    placeField
                    detailAddressField
                }
                loadMyPlacesButton
            }
            buttonRow
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                StepChip(text: "2/3")
                Text("어디서 만날까요?")
                    .pretendardText(size: 24, weight: .bold)
                    .foregroundColor(Color("grey900"))
            }
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

    // MARK: - 검색바

    private var searchInput: some View {
        Button(action: { showSearch = true }) {
            HStack(spacing: 8) {
                Image("ic_search")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color("grey500"))
                Text("지번, 도로명, 건물명으로 검색")
                    .pretendardText(size: 16)
                    .foregroundColor(Color("grey300"))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(Color("white"))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey200"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 선택된 장소 표시

    private var placeField: some View {
        HStack {
            Text(address.isEmpty ? "교환 장소를 선택해주세요" : address)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(address.isEmpty ? Color("grey500") : Color("grey900"))
                .lineLimit(1)
            Spacer(minLength: 0)
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .frame(height: 48)
        .background(Color("grey100"))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey200"), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 상세주소 입력

    private var detailAddressField: some View {
        TextField(
            "",
            text: addressDetailBinding,
            prompt: Text("상세주소를 입력해주세요")
                .font(.pretendard(size: 16, weight: .medium))
                .foregroundColor(Color("grey500"))
        )
        .font(.pretendard(size: 16, weight: .medium))
        .foregroundColor(Color("grey900"))
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .frame(height: 48)
        .background(Color("grey100"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 나의 희망교환장소 불러오기

    private var loadMyPlacesButton: some View {
        Button(action: onLoadMyPlaceClick) {
            Text("나의 희망교환장소 불러오기")
                .pretendardText(size: 15)
                .foregroundColor(Color("main200"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color("main100"))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("main105"), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 버튼

    private var buttonRow: some View {
        HStack(spacing: 8) {
            CardButton(text: "이전", style: .grey, action: onPreviousClick)
            CardButton(text: "다음", style: .main, action: onNextClick)
        }
    }
}

// MARK: - StepChip

private struct StepChip: View {
    let text: String

    var body: some View {
        Text(text)
            .pretendardText(size: 14, weight: .medium)
            .foregroundColor(Color("grey900"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("white"))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color("grey200"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    TrackerDirectMeetingPlaceDialog(
        address: "서울특별시 강남구 강남대로 396",
        addressDetail: "",
        onAddressDetailChange: { _ in },
        onSelectPlace: { _ in },
        onLoadMyPlaceClick: {},
        onDismiss: {},
        onPreviousClick: {},
        onNextClick: {}
    )
    .padding(24)
    .background(Color("uiBg"))
}
