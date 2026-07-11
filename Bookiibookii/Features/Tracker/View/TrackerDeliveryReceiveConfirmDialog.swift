import SwiftUI

// 책 수령 확인 다이얼로그.
// 카드 컨텐츠만 담당 — 스크림/오버레이는 호스트 담당.
struct TrackerDeliveryReceiveConfirmDialog: View {
    let onDismiss: () -> Void
    let onConfirmClick: () -> Void

    @State private var isChecked: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            checkRow
            CardButton(
                text: "받았어요",
                style: isChecked ? .main : .grey,
                fontSize: 15,
                action: { if isChecked { onConfirmClick() } }
            )
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .center) {
            Text("책을 받았나요?")
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

    // MARK: - 확인 체크박스

    private var checkRow: some View {
        HStack(alignment: .top, spacing: 8) {
            CheckBox(checked: isChecked, onToggle: { isChecked.toggle() })
            VStack(alignment: .leading, spacing: 4) {
                Text("책의 상태를 확인했습니다")
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey900"))
                    .contentShape(Rectangle())
                    .onTapGesture { isChecked.toggle() }
                Text("파손, 훼손, 낙서 등이 있다면 즉시 상대방에게\n댓글로 알려주세요.")
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey600"))
            }
        }
    }
}

private struct CheckBox: View {
    let checked: Bool
    let onToggle: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(checked ? Color("main100") : Color("grey200"))
                .frame(width: 20, height: 20)
            Image("ic_check")
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(checked ? Color("main200") : Color("white"))
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

#Preview {
    TrackerDeliveryReceiveConfirmDialog(
        onDismiss: {},
        onConfirmClick: {}
    )
    .padding(24)
    .background(Color("uiBg"))
}
