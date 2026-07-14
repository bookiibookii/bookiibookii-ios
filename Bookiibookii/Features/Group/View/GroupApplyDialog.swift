import SwiftUI

// 그룹 참여 신청 다이얼로그. 안드 ui/joinrequest/GroupApplyDialog.kt 대응.
// 활성화: 책 선택(bookSelected) && applyMsg 비어있지 않음 → canSubmit
struct GroupApplyDialog: View {
    @Binding var query: String
    let results: [BookItem]
    let bookSelected: Bool
    @Binding var applyMsg: String
    let loading: Bool
    let canSubmit: Bool
    let onSearch: () -> Void
    let onClear: () -> Void
    let onSelect: (BookItem) -> Void
    let onSubmit: () -> Void
    let onDismiss: () -> Void

    private let applyMsgMax = 50

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            bookSearchField
            applyMessageField
            footerButton
        }
        .padding(20)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(alignment: .center) {
            Text("그룹 참여 신청")
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

    // MARK: - 책 검색 입력 + 결과 드롭다운

    private var bookSearchField: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Button(action: onSearch) {
                    Image("ic_search")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color("grey500"))
                }
                .buttonStyle(.plain)

                TextField("", text: $query, prompt: Text("어떤 책을 읽어볼까요?").foregroundColor(Color("grey500")))
                    .pretendardText(size: 16)
                    .foregroundColor(Color("grey900"))
                    .tint(Color("main200"))
                    .disabled(bookSelected)
                    .submitLabel(.search)
                    .onSubmit(onSearch)

                Button(action: onClear) {
                    Image("ic_x")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("black"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color("white")))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey200"), lineWidth: 1))

            if !results.isEmpty {
                BookSearchResultDropdown(books: results, onSelect: onSelect)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - 신청 한 마디

    private var applyMessageField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("신청 한 마디")
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("grey900"))

            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    if applyMsg.isEmpty {
                        Text("한 마디를 입력해주세요")
                            .pretendardText(size: 16, weight: .medium)
                            .foregroundColor(Color("grey300"))
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $applyMsg)
                        .pretendardText(size: 16, weight: .medium)
                        .foregroundColor(Color("grey900"))
                        .scrollContentBackground(.hidden)
                        .onChange(of: applyMsg) { value in
                            if value.count > applyMsgMax {
                                applyMsg = String(value.prefix(applyMsgMax))
                            }
                        }
                }
                .frame(maxHeight: .infinity)

                Text("\(applyMsg.count)/\(applyMsgMax)")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey300"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .frame(height: 100)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey200"), lineWidth: 1))
        }
    }

    // MARK: - 풋터 버튼

    private var footerButton: some View {
        Button(action: onSubmit) {
            ZStack {
                if loading {
                    ProgressView().tint(Color("white"))
                } else {
                    Text("완료")
                        .pretendardText(size: 15)
                        .foregroundColor(canSubmit ? Color("white") : Color("grey500"))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(canSubmit ? Color("main200") : Color("grey200"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit || loading)
    }
}

// 도서 검색 결과 드롭다운 (안드 BookSearchDropdown 대응)
private struct BookSearchResultDropdown: View {
    let books: [BookItem]
    let onSelect: (BookItem) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(books) { book in
                    BookSearchResultRow(book: book, onTap: { onSelect(book) })
                }
            }
            .padding(8)
        }
        .frame(maxHeight: 240)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("grey200"), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// 안드 BookSearchDropdown.BookCard 대응
private struct BookSearchResultRow: View {
    let book: BookItem
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            BookCover(imageUrl: book.image)
                .frame(width: 48, height: 60)

            VStack(alignment: .leading, spacing: 2) {
                Text(book.title.stripBookSubtitle())
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey800"))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(book.author) (\(book.categoryLabel))")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey600"))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
