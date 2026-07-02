import SwiftUI

// 인라인 검색 입력바. 키보드 검색 액션 / 돋보기 버튼 탭 시 onSubmit 호출. (안드 SearchInputField)
struct SearchInputField: View {
    @Binding var text: String
    var hint: String = "그룹명, 도서명, 저자로 검색"
    let onSubmit: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 0) {
            TextField("", text: $text, prompt: Text(hint).foregroundColor(Color("grey500")))
                .pretendardText(size: 15)
                .foregroundColor(Color("grey900"))
                .tint(Color("main200"))
                .submitLabel(.search)
                .focused($focused)
                .onSubmit(submit)
                .padding(.leading, 16)

            Button(action: submit) {
                Image("ic_search")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color("white"))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(text.isEmpty ? Color("grey300") : Color("grey900"))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.trailing, 6)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 20, bottomLeadingRadius: 20,
                bottomTrailingRadius: 30, topTrailingRadius: 30
            )
            .fill(Color("white"))
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 20, bottomLeadingRadius: 20,
                bottomTrailingRadius: 30, topTrailingRadius: 30
            )
            .stroke(Color("grey200"), lineWidth: 1)
        )
    }

    private func submit() {
        focused = false
        onSubmit()
    }
}
