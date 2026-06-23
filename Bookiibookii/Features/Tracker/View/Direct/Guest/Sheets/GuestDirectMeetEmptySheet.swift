import SwiftUI

// 안드 fragment_direct_guest_meet_empty_bottom_sheet.xml (DirectGuestMeetEmptyBottomSheetFragment) 대응.
// HOST_DONE — 호스트 다 읽고 약속 미설정. 게스트가 댓글로 협의 유도.
struct GuestDirectMeetEmptySheet: View {
    let onGoComment: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        SheetContainer {
            Text("호스트와 만날 약속을 정해요")
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

#Preview("GuestDirectMeetEmpty") {
    ZStack(alignment: .bottom) {
        Color("grey100").ignoresSafeArea()
        GuestDirectMeetEmptySheet(onGoComment: {}, onConfirm: {})
    }
}
