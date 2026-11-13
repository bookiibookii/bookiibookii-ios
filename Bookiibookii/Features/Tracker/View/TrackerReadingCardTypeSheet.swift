import SwiftUI

/// 트래커 "독서카드 작성"에서 열 작성 화면을 정하는 요청. 시트 표시 상태로도 쓴다.
struct TrackerReadingCardRequest: Identifiable, Equatable {
    let groupId: Int
    let bookTitle: String

    var id: Int { groupId }
}

/// 만들 독서카드 종류를 고르는 시트. 서재 상세의 추가 메뉴와 같은 아이콘·문구를 쓴다.
struct TrackerReadingCardTypeSheet: View {
    let onSelect: (LibraryCardType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Capsule()
                .fill(Color("grey200"))
                .frame(width: 44, height: 4)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                typeButton(title: "이미지 카드 추가", icon: "ic_image", type: .image)
                typeButton(title: "인용구 카드 추가", icon: "ic_text", type: .text)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
    }

    private func typeButton(title: String, icon: String, type: LibraryCardType) -> some View {
        Button {
            onSelect(type)
        } label: {
            HStack(spacing: 8) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color("grey800"))
                    .frame(width: 24, height: 24)
                Text(title)
                    .pretendardText(size: 18)
                    .foregroundColor(Color("grey800"))
            }
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension View {
    /// `request`가 생기면 카드 종류 시트를 띄우고, 고른 종류의 독서카드 작성 화면으로 이동한다.
    func trackerReadingCardTypeSheet(
        request: Binding<TrackerReadingCardRequest?>,
        libraryService: LibraryService,
        router: NavigationRouter
    ) -> some View {
        sheet(item: request) { current in
            TrackerReadingCardTypeSheet { type in
                request.wrappedValue = nil
                Task {
                    await openTrackerReadingCardAdd(
                        type: type, request: current, libraryService: libraryService, router: router
                    )
                }
            }
            .presentationDetents([.height(176)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(20)
        }
    }
}

/// 트래커에는 userBookId가 없어 서재 목록에서 책을 찾아 작성 화면으로 이동한다.
/// userBookId가 없으면 작성할 수 없으므로 기존처럼 서재 상세로 보낸다.
@MainActor
private func openTrackerReadingCardAdd(
    type: LibraryCardType,
    request: TrackerReadingCardRequest,
    libraryService: LibraryService,
    router: NavigationRouter
) async {
    guard let book = await resolveTrackerLibraryBook(
        libraryService: libraryService, groupId: request.groupId, bookTitle: request.bookTitle
    ) else { return }

    if let userBookId = book.userBookId {
        router.push(to: .libraryCardAdd(
            userBookId: userBookId, cardType: type, bookTitle: book.title, totalPages: book.totalPages
        ))
    } else {
        router.push(to: .libraryCards(book: book))
    }
}
