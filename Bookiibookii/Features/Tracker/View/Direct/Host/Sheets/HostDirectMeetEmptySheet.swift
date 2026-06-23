import SwiftUI

// 안드 fragment_direct_host_meet_empty_bottom_sheet.xml (DirectHostMeetEmptyBottomSheetFragment) 대응.
// GUEST_DONE — 게스트가 다 읽고 호스트가 회수 약속 미설정 상태. 호스트가 본인이 등록 유도.
struct HostDirectMeetEmptySheet: View {
    let onGoComment: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        SheetContainer {
            Text("게스트와 만날 약속을 정해요")
                .pretendardText(size: 18, weight: .medium)
                .foregroundColor(Color("grey900"))
                .padding(.top, 20)

            Text("책을 주고 받을 구체적인 일시 및 장소를 댓글로 정해 주세요.")
                .pretendardText(size: 14)
                .foregroundColor(Color("grey500"))
                .padding(.top, 14)

            EmptyAppointmentCard().padding(.top, 16)

            OutlineSheetButton(title: "댓글 바로가기", action: onGoComment)
                .padding(.top, 16)
            DisabledSheetButton(title: "확인", action: onConfirm)
                .padding(.top, 16)
        }
    }
}

#Preview("HostDirectMeetEmpty") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        HostDirectMeetEmptySheet(onGoComment: {}, onConfirm: {})
    }
}

// MARK: - meetEmpty 전용 작은 부품

/// 안드 card_empty_state — "아직 약속이 정해지지 않았어요" 회색 박스.
struct EmptyAppointmentCard: View {
    var body: some View {
        Text("아직 약속이 정해지지 않았어요")
            .pretendardText(size: 14)
            .foregroundColor(Color("grey500"))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color("grey100"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("grey200"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 안드 btn_confirm — grey200 배경 + grey500 텍스트, disabled 외형이지만 탭 동작 있음.
struct DisabledSheetButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .pretendardText(size: 15, weight: .medium)
                .foregroundColor(Color("grey500"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("grey200"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
