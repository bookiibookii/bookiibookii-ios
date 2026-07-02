import SwiftUI
import Kingfisher

struct LifeBookSearchDialog: View {
    @Binding var searchQuery: String
    let searchResults: [BookItem]
    let isSearching: Bool
    let isSubmitting: Bool
    let onSearch: () -> Void
    let onSelect: (BookItem) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                header
                searchField
                resultsSection
            }
            .padding(20)
            .frame(maxWidth: 372)
            .frame(height: 480)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -3)
            .padding(.horizontal, 20)
        }
    }

    private var header: some View {
        HStack {
            Text("나의 인생 책")
                .pretendardText(size: 20, weight: .semibold)
                .foregroundColor(Color("grey900"))

            Spacer()

            Button(action: onDismiss) {
                ZStack {
                    Circle()
                        .fill(Color("grey100"))
                        .frame(width: 32, height: 32)

                    Image("ic_x")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(Color("grey700"))
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("도서 검색")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("grey900"))
                Text("*")
                    .pretendardText(size: 16, weight: .medium)
                    .foregroundColor(Color("main200"))
            }

            HStack(spacing: 8) {
                Image("ic_search")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color("grey500"))

                ZStack(alignment: .leading) {
                    if searchQuery.isEmpty {
                        Text("도서명, 저자명 검색")
                            .pretendardText(size: 15, weight: .medium)
                            .foregroundColor(Color("grey500"))
                    }

                    TextField("", text: $searchQuery)
                        .pretendardText(size: 15, weight: .medium)
                        .foregroundColor(Color("grey800"))
                        .tint(Color("main200"))
                        .submitLabel(.search)
                        .onSubmit(onSearch)
                        .onChange(of: searchQuery) { _, _ in onSearch() }
                }

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        onSearch()
                    } label: {
                        Image("ic_x")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color("grey500"))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(Color("white"))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color("grey300"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if isSearching || isSubmitting {
            ProgressView()
                .tint(Color("main200"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !searchResults.isEmpty {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color("grey100"))
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(searchResults) { book in
                            resultRow(book)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        } else if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color("grey100"))
                    .frame(height: 1)

                Text("검색 결과가 없습니다.")
                    .pretendardText(size: 16, weight: .regular)
                    .foregroundColor(Color("grey600"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        } else {
            Spacer(minLength: 0)
        }
    }

    private func resultRow(_ book: BookItem) -> some View {
        Button {
            onSelect(book)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                KFImage(URL(string: book.image))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 95)
                    .background(Color("grey200"))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title.stripBookSubtitle())
                        .pretendardText(size: 18, weight: .medium)
                        .foregroundColor(Color("grey800"))
                        .lineLimit(1)

                    Text("\(book.author) (\(book.categoryLabel))")
                        .pretendardText(size: 16, weight: .regular)
                        .foregroundColor(Color("grey600"))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
    }
}
