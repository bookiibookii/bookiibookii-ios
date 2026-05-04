import SwiftUI

// 안드 fragment_guest_shipping_bottom_dialog.xml (GuestShippingBottomDialogFragment) 대응.
// GUEST_DONE — 게스트 완독 후 호스트로 회수 송장 등록.
struct GuestShippingSheet: View {
    let receiverName: String
    let receiverPhone: String
    let address: String
    let onCopy: () -> Void
    let onRegister: () -> Void

    var body: some View {
        SheetContainer {
            Text("배송지 정보")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            (
                Text("아래 주소로 책을 발송해주세요.\n")
                + Text("책이 파손되지 않도록 포장에 신경써주세요.")
            )
            .font(.pretendard(size: 14))
            .foregroundColor(Color("grey500"))
            .lineSpacing(4)
            .padding(.top, 8)

            addressCard.padding(.top, 24)
            privacyCard.padding(.top, 16)

            PrimarySheetButton(title: "운송장 등록하기", action: onRegister)
                .padding(.top, 20)
        }
    }

    private var addressCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("수령인").foregroundColor(Color("grey900"))
                Text(receiverName).foregroundColor(Color("grey900"))
            }
            .font(.pretendard(size: 14))

            HStack(spacing: 8) {
                Text("연락처").foregroundColor(Color("grey900"))
                Text(receiverPhone).foregroundColor(Color("grey900"))
            }
            .font(.pretendard(size: 14))
            .padding(.top, 4)

            VStack(alignment: .trailing, spacing: 0) {
                Text(address)
                    .font(.pretendard(size: 14))
                    .foregroundColor(Color("grey900"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onCopy) {
                    Text("복사")
                        .font(.pretendard(size: 12))
                        .foregroundColor(Color("grey700"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("grey200"))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 12)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(addressBg)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(addressStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: 8) {
            Image("ic_info")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(InfoBannerCard.green200)
                .frame(width: 20, height: 20)
            Text("개인정보 보호를 위해 배송 완료 후 자동으로 숨김\n처리됩니다.")
                .font(.pretendard(size: 13))
                .foregroundColor(InfoBannerCard.green200)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(InfoBannerCard.greenPale)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(InfoBannerCard.green150, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private let addressBg     = Color(red: 0xD4/255, green: 0xED/255, blue: 0xFF/255)
private let addressStroke = Color(red: 0x37/255, green: 0xAA/255, blue: 0xFF/255)

#Preview("GuestShipping") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        GuestShippingSheet(
            receiverName: "홍길동",
            receiverPhone: "010-7903-2321",
            address: "[06234] 서울특별시 강남구 테헤란로 123 북키빌딩 456호",
            onCopy: {},
            onRegister: {}
        )
    }
}
