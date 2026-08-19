import SwiftUI
import UniformTypeIdentifiers

struct RepresentativeBooksEditSheet: View {
    @ObservedObject var viewModel: MyBookShelfViewModel
    @State private var draggedBookId: Int?

    var body: some View {
        VStack(spacing: 20) {
            dragHandle

            VStack(alignment: .leading, spacing: 4) {
                Text("순서 변경")
                    .pretendardText(size: 20, weight: .semibold)
                    .foregroundColor(Color("grey900"))

                VStack(alignment: .leading, spacing: 0) {
                    Text("나를 잘 보여주는 책을 최대 7권까지 고를 수 있어요.")
                    Text("인생 책은 최소 1권 포함해주세요.")
                }
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(Color("grey500"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(viewModel.editingRepresentativeBooks) { book in
                        representativeRow(book)
                            .onDrop(
                                of: [UTType.text],
                                delegate: RepresentativeBookDropDelegate(
                                    book: book,
                                    draggedBookId: $draggedBookId,
                                    onMove: { draggedId, overId in
                                        viewModel.applyLocalRepresentativeReorder(
                                            draggedBookId: draggedId,
                                            overBookId: overId
                                        )
                                    },
                                    onDrop: { draggedId in
                                        Task {
                                            await viewModel.commitRepresentativeReorder(userBookId: draggedId)
                                        }
                                    }
                                )
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 32)
        .background(Color("white"))
    }

    private var dragHandle: some View {
        Capsule()
            .fill(Color("grey200"))
            .frame(width: 44, height: 4)
            .frame(maxWidth: .infinity)
    }

    private func representativeRow(_ book: BookshelfRepresentativeBook) -> some View {
        let metadata = viewModel.metadata(for: book)

        return HStack(spacing: 12) {
            Image("ic_hamburger")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
                .onDrag {
                    draggedBookId = book.userBookId
                    return NSItemProvider(object: String(book.userBookId) as NSString)
                }

            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title.stripBookSubtitle())
                        .pretendardText(size: 14, weight: .semibold)
                        .foregroundColor(Color("grey900"))
                        .lineLimit(1)

                    if metadata.author != nil || metadata.category != nil {
                        HStack(spacing: 2) {
                            if let author = metadata.author {
                                Text(author)
                                    .pretendardText(size: 14, weight: .regular)
                                    .foregroundColor(Color("grey900"))
                                    .lineLimit(1)
                            }

                            if let category = metadata.category, !category.isEmpty {
                                Text("(\(GroupTagMapper.koreanLabel(category)))")
                                    .pretendardText(size: 14, weight: .regular)
                                    .foregroundColor(Color("grey900"))
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)

                if let rating = book.rating {
                    RepresentativeSheetStarRating(rating: rating)
                }
            }

            Button {
                Task { await viewModel.deleteEditingRepresentativeBook(userBookId: book.userBookId) }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color("grey100"))
                        .frame(width: 28, height: 28)

                    Image("ic_x")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isRepresentativeMutating)
        }
        .padding(16)
        .background(Color("white"))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .opacity(draggedBookId == book.userBookId ? 0.45 : 1)
    }
}

private struct RepresentativeBookDropDelegate: DropDelegate {
    let book: BookshelfRepresentativeBook
    @Binding var draggedBookId: Int?
    let onMove: (Int, Int) -> Void
    let onDrop: (Int) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedBookId, draggedBookId != book.userBookId else { return }
        onMove(draggedBookId, book.userBookId)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedBookId else { return false }
        let droppedId = draggedBookId
        self.draggedBookId = nil
        onDrop(droppedId)
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

private struct RepresentativeSheetStarRating: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                starImage(for: index)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(starColor(for: index))
            }
        }
    }

    private func starImage(for index: Int) -> Image {
        let threshold = Double(index)
        if rating >= threshold + 0.5 {
            return Image("ic_star_fill")
        }
        return Image("ic_star")
    }

    private func starColor(for index: Int) -> Color {
        let threshold = Double(index)
        if rating >= threshold + 1 {
            return Color("sub200")
        }
        if rating >= threshold + 0.5 {
            return Color("sub200").opacity(0.5)
        }
        return Color("sub100")
    }
}
