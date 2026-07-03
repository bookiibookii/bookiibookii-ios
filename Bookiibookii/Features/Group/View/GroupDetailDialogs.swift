import SwiftUI

// 그룹 상세: 주소 안내 / 삭제 확인 다이얼로그.
// 안드 GroupAddressRequiredDialog.kt, editor/GroupDeleteDialog.kt 대응.

// 주소 미등록 상태에서 그룹 참여 시도 시 안내 다이얼로그
struct GroupAddressRequiredDialog: View {
    let onDismiss: () -> Void
    let onManageAddress: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("그룹에 참여하려면 먼저 배송지 또는 희망 교환 장소를 등록해주세요.")
                .pretendardText(size: 16)
                .foregroundColor(Color("grey900"))

            HStack(spacing: 8) {
                CardButton(text: "닫기", style: .grey, height: 48, fontSize: 15, action: onDismiss)
                CardButton(text: "주소지 관리", style: .main, height: 48, fontSize: 15, action: onManageAddress)
            }
            .padding(.top, 24)
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// 그룹 삭제 확인 다이얼로그. ic_x/취소 → onDismiss, 삭제 → onConfirm.
// 안드 소스에도 groupName 파라미터는 존재하나 본문 문구에는 보간되지 않는다(안드 원본 그대로 이식).
struct GroupDeleteDialog: View {
    let groupName: String
    let onDismiss: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("그룹 삭제")
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

            Text("그룹을 삭제하시겠습니까? 삭제하면 그룹 정보가 즉시 사라지며, 이후 되돌릴 수 없습니다.")
                .pretendardText(size: 16)
                .foregroundColor(Color("grey900"))
                .padding(.top, 24)

            HStack(spacing: 8) {
                BottomSheetTwoBtnShort(text: "취소", style: .white, action: onDismiss)
                BottomSheetTwoBtnShort(text: "삭제", style: .red, action: onConfirm)
            }
            .padding(.top, 24)
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
