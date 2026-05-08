import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: LibraryViewModel

    init(libraryService: LibraryService) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(libraryService: libraryService))
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header
                tabSection

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        listHeader
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.top, 60)
                                .frame(maxWidth: .infinity)
                        } else {
                            booksGrid
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .padding(.bottom, 120)
                }
            }
        }
        .task {
            await viewModel.loadBooks()
        }
    }

    private var header: some View {
        HStack {
            Text("내 서재")
                .font(.pretendard(size: 24, weight: .medium))
                .foregroundColor(Color("grey800"))

            Spacer()

            HStack(spacing: 8) {
                CircleButton(systemName: "magnifyingglass") {
                    container.navigationRouter.push(to: .librarySearch)
                }
                CircleAssetButton(assetName: "ic_bookmark") {
                    container.navigationRouter.push(to: .libraryBookmarkedCards)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Divider().overlay(Color("grey200"))
        }
    }

    private var tabSection: some View {
        HStack(spacing: 12) {
            tabButton(title: "진행 중", isSelected: viewModel.selectedTab == .inProgress) {
                viewModel.selectedTab = .inProgress
            }
            tabButton(title: "종료", isSelected: viewModel.selectedTab == .completed) {
                viewModel.selectedTab = .completed
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color("grey100"))
    }

    private var listHeader: some View {
        HStack {
            HStack(spacing: 10) {
                Button {
                    viewModel.layoutStyle = (viewModel.layoutStyle == .grid) ? .list : .grid
                } label: {
                    Image(viewModel.layoutStyle == .grid ? "6square" : "line")
                        .renderingMode(.template)
                        .foregroundColor(Color("grey900"))
                }
                .buttonStyle(.plain)

                Text(viewModel.bookCountText)
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey900"))
            }
            Spacer()

            Button {
                // TODO: 정렬 기능 연결 시 액션 추가
            } label: {
                Image("array")
            }
            .buttonStyle(.plain)
        }
    }

    private var booksGrid: some View {
        Group {
            if viewModel.layoutStyle == .grid {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 24
                ) {
                    ForEach(viewModel.filteredBooks) { book in
                        LibraryBookCard(book: book) {
                            container.navigationRouter.push(to: .libraryCards(book: book))
                        }
                    }
                }
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 32, maximum: 44), spacing: 6, alignment: .bottom)],
                    alignment: .leading,
                    spacing: 18
                ) {
                    ForEach(viewModel.filteredBooks) { book in
                        LibraryBookSpine(book: book) {
                            container.navigationRouter.push(to: .libraryCards(book: book))
                        }
                    }
                }
            }
        }
    }

    private func tabButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(size: 15, weight: .regular))
                .foregroundColor(isSelected ? Color("grey100") : Color("grey900"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSelected ? Color("grey900") : Color("white"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color("grey900") : Color("grey200"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

private struct LibraryBookSpine: View {
    let book: LibraryBook
    var onTap: (() -> Void)? = nil

    @State private var titleNaturalSize: CGSize = .zero

    private var textColor: Color {
        book.isCreatedByMe ? Color("main200") : Color("sub200")
    }

    private var backgroundColor: Color {
        book.isCreatedByMe ? Color("main105") : Color("sub100")
    }

    private var spineWidth: CGFloat {
        max(titleNaturalSize.height + 12, 28)
    }

    private var spineHeight: CGFloat {
        max(titleNaturalSize.width + 32, 96)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ZStack {
                Text(book.title)
                    .font(.pretendard(size: 15, weight: .medium))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .fixedSize()
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: SpineTextSizeKey.self, value: geo.size)
                        }
                    )
                    .rotationEffect(.degrees(90))
            }
            .frame(width: spineWidth, height: spineHeight)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            BookSpineTopCap(color: backgroundColor, width: spineWidth)
                .offset(y: -BookSpineTopCap.capHeight / 2)
        }
        .padding(.top, BookSpineTopCap.capHeight / 2)
        .onPreferenceChange(SpineTextSizeKey.self) { titleNaturalSize = $0 }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

private struct BookSpineTopCap: View {
    static let capHeight: CGFloat = 13

    let color: Color
    let width: CGFloat

    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: width, height: Self.capHeight)
    }
}

private struct SpineTextSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct CircleButton: View {
    let systemName: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color("grey700"))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle().stroke(Color("grey200"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct CircleAssetButton: View {
    let assetName: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            Image(assetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color("grey700"))
                .frame(width: 16, height: 16)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle().stroke(Color("grey200"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LibraryView(
        libraryService: LibraryService(
            interceptor: AuthInterceptor(authService: AuthService())
        )
    )
}
