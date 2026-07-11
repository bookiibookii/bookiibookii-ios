import SwiftUI

// 운송장 정보 확인 다이얼로그.
// 카드 컨텐츠만 담당 — 스크림/오버레이는 호스트 담당.
struct TrackerDeliveryShippingConfirmDialog: View {
    let companyName: String
    let trackingNumber: String
    let onDismiss: () -> Void
    let onTrackingSearchClick: () -> Void
    let onConfirmClick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            ReadOnlyField(label: "택배사", value: companyName)
            ReadOnlyField(label: "운송장 번호", value: trackingNumber)
            buttonRow
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .center) {
            Text("운송장 정보 확인")
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

    // MARK: - 버튼

    private var buttonRow: some View {
        HStack(spacing: 8) {
            CardButton(text: "배송 조회", style: .white, action: onTrackingSearchClick)
            CardButton(text: "확인", style: .main, action: onConfirmClick)
        }
    }
}

private struct ReadOnlyField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(label)
                    .pretendardText(size: 16)
                    .foregroundColor(Color("grey900"))
                Text("*")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("main200"))
            }
            Text(value)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.trailing, 12)
                .padding(.vertical, 12)
                .frame(height: 48)
                .background(Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey200"), lineWidth: 1))
        }
    }
}

#Preview {
    TrackerDeliveryShippingConfirmDialog(
        companyName: "CJ대한통운",
        trackingNumber: "790335274231",
        onDismiss: {},
        onTrackingSearchClick: {},
        onConfirmClick: {}
    )
    .padding(24)
    .background(Color("uiBg"))
}
