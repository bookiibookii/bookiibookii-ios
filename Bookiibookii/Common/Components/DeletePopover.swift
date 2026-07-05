import SwiftUI

// 본인 댓글 롱프레스 시 뜨는 삭제 팝오버 — 안드 DeletePopover 대응.
// 흰 카드 + grey200 보더 + 그림자, "삭제" 탭 시 onDelete.
struct DeletePopover: View {
    var width: CGFloat = 96
    let onDelete: () -> Void

    var body: some View {
        Button(action: onDelete) {
            Text("삭제")
                .pretendardText(size: 14, weight: .medium)
                .foregroundColor(Color("grey700"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .frame(width: width)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
    }
}
