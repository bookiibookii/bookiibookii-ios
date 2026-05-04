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
                CircleButton(systemName: "bookmark") {
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
            HStack(spacing: 4) {
                Image(systemName: "square.grid.3x2.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color("grey700"))
                Text(viewModel.bookCountText)
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey900"))
            }
            Spacer()
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color("grey700"))
        }
    }

    private var booksGrid: some View {
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

#Preview {
    LibraryView(
        libraryService: LibraryService(
            interceptor: AuthInterceptor(authService: AuthService())
        )
    )
}
