import SwiftUI

// 진행률 기록 다이얼로그.
// 카드 컨텐츠만 담당 — 스크림/오버레이는 호스트 담당.
struct TrackerProgressRecordDialog: View {
    let totalPages: Int
    let onDismiss: () -> Void
    let onConfirm: (Int) -> Void

    @State private var pageInput: String = ""

    private var pageInt: Int { Int(pageInput) ?? 0 }
    private var isAllRead: Bool { totalPages > 0 && pageInt >= totalPages }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            pageInputSection
            buttonRow
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .center) {
            Text("진행률 기록")
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

    // MARK: - 현재 페이지 입력

    private var pageInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("몇 페이지까지 읽었나요?")
                    .pretendardText(size: 16)
                    .foregroundColor(Color("grey900"))
                Text("*")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("main200"))
            }

            HStack {
                ZStack(alignment: .leading) {
                    if pageInput.isEmpty {
                        Text("숫자만 입력해주세요")
                            .pretendardText(size: 16, weight: .medium)
                            .foregroundColor(Color("grey500"))
                    }
                    TextField("", text: $pageInput)
                        .keyboardType(.numberPad)
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey900"))
                        .tint(Color("main200"))
                        .onChange(of: pageInput) { _, newValue in
                            let digits = newValue.filter { $0.isNumber }
                            let asInt = Int(digits)
                            if digits.isEmpty {
                                pageInput = ""
                            } else if totalPages > 0, let asInt, asInt > totalPages {
                                pageInput = String(totalPages)
                            } else {
                                pageInput = digits
                            }
                        }
                }

                if isAllRead {
                    Text("다 읽었어요!")
                        .pretendardText(size: 16)
                        .foregroundColor(Color("main200"))
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .frame(height: 48)
            .background(Color("grey100"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: - 버튼

    private var buttonRow: some View {
        HStack(spacing: 8) {
            CardButton(
                text: "다 읽었어요",
                style: isAllRead ? .grey : .white,
                action: {
                    pageInput = isAllRead ? "" : String(totalPages)
                }
            )
            CardButton(
                text: "완료",
                style: .main,
                action: {
                    onConfirm(pageInt)
                    onDismiss()
                }
            )
        }
    }
}

#Preview {
    TrackerProgressRecordDialog(
        totalPages: 320,
        onDismiss: {},
        onConfirm: { _ in }
    )
    .padding(24)
    .background(Color("uiBg"))
}
