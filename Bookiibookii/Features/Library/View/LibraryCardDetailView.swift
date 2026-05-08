import SwiftUI

struct LibraryCardDetailView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: LibraryCardDetailViewModel
    @State private var isShareSheetPresented = false

    /// 독서카드 수정 화면 진입·presigned 업로드용. 목록에서 넘겨 주며 없으면 수정 버튼을 비활성화합니다.
    private let userBookId: Int?

    init(cardId: Int, userBookId: Int?, libraryService: LibraryService) {
        self.userBookId = userBookId
        _viewModel = StateObject(
            wrappedValue: LibraryCardDetailViewModel(cardId: cardId, libraryService: libraryService)
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("white").ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 80)
                            .frame(maxWidth: .infinity)
                    } else if let detail = viewModel.detail {
                        detailContent(detail)
                            .padding(.top, 16)
                            .padding(.bottom, 140)
                    }
                }
            }

            bottomCommentBar
                .ignoresSafeArea(edges: .bottom)
        }
        .task { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .libraryCardMutationFinished)) { _ in
            Task { await viewModel.load() }
        }
        .sheet(isPresented: $viewModel.isCommentSheetPresented) {
            commentSheet
                .presentationDetents([.height(336)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let detail = viewModel.detail {
                LibraryCardShareSheet(
                    detail: detail,
                    onClose: { isShareSheetPresented = false }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        HStack {
            Button {
                container.navigationRouter.pop()
            } label: {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("grey900"))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()
            Text("독서카드")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
            Spacer()

            Button {
                guard viewModel.detail != nil else { return }
                isShareSheetPresented = true
            } label: {
                Image("share")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.detail == nil)
            .opacity(viewModel.detail == nil ? 0.4 : 1)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color("grey200")).frame(height: 1)
        }
    }

    private func detailContent(_ detail: LibraryCardDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            userSection(detail)
                .padding(.horizontal, 24)

            infoRow(detail)
                .padding(.horizontal, 24)

            cardImage(detail)
                .padding(.horizontal, 24)

            memoSection(detail)
                .padding(.horizontal, 24)
                .padding(.top, 0)

            commentSummaryRow
                .padding(.horizontal, 24)
        }
    }

    private var commentSummaryRow: some View {
        Button {
            viewModel.openComments()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color("main200"))
                Text("댓글 \(viewModel.commentCount)개 보기")
                    .font(.pretendard(size: 14, weight: .medium))
                    .foregroundColor(Color("grey900"))
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func userSection(_ detail: LibraryCardDetail) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color("grey200"))
                .frame(width: 28, height: 28)

            Text(detail.creatorName)
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))

            Spacer()

            Button {
                // TODO: bookmark toggle
            } label: {
                Image("ic_bookmark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(detail.isBookmarked ? Color("main200") : Color("grey900"))
                    .frame(width: 14, height: 14)
                    .frame(width: 32, height: 32)
                    .background(Color("grey100"))
                    .overlay(
                        Circle().stroke(Color("grey200"), lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func infoRow(_ detail: LibraryCardDetail) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                HStack(spacing: 4) {
                    if let title = detail.bookTitle, !title.isEmpty {
                        Text(title)
                            .font(.pretendard(size: 14, weight: .regular))
                            .foregroundColor(Color("grey500"))
                            .lineLimit(1)
                    }
                    Text("p.\(detail.page)")
                        .font(.pretendard(size: 14, weight: .regular))
                        .foregroundColor(Color("grey500"))
                }

                Spacer()

                Text(formatDate(detail.createdAt))
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey500"))
            }
            .padding(.bottom, 16)

            Rectangle()
                .fill(Color("grey100"))
                .frame(height: 1)
        }
    }

    private func cardImage(_ detail: LibraryCardDetail) -> some View {
        Color("grey200")
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                AsyncImage(url: URL(string: detail.imageURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty, .failure:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
            )
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 8) {
                    Button {
                        // TODO: delete
                    } label: {
                        pdfAssetImage("trash", side: 32)
                    }
                    .buttonStyle(.plain)

                    Button {
                        guard let uid = userBookId else { return }
                        container.navigationRouter.push(to: .libraryCardEdit(cardId: detail.cardId, userBookId: uid))
                    } label: {
                        pdfAssetImage("pencil", side: 32)
                    }
                    .buttonStyle(.plain)
                    .disabled(userBookId == nil)
                    .opacity(userBookId == nil ? 0.35 : 1)
                }
                .padding(16)
            }
    }

    private func memoSection(_ detail: LibraryCardDetail) -> some View {
        Text(detail.memo.isEmpty ? "메모가 없어요." : detail.memo)
            .font(.pretendard(size: 16, weight: .regular))
            .foregroundColor(Color("grey900"))
            .lineSpacing(16 * 0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomCommentBar: some View {
        Button {
            viewModel.openComments()
        } label: {
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color("grey200"))
                    .frame(width: 44, height: 4)

                HStack(spacing: 8) {
                    Text("댓글")
                        .font(.pretendard(size: 20, weight: .medium))
                        .foregroundColor(Color("grey900"))
                    Text("\(viewModel.commentCount)")
                        .font(.pretendard(size: 14, weight: .regular))
                        .foregroundColor(Color("main200"))
                    Spacer()
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
            .background(Color("white"))
            .clipShape(RoundedCorner(radius: 24, corners: [.topLeft, .topRight]))
            .shadow(color: Color.black.opacity(0.1), radius: 17.5, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }

    private var commentSheet: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("댓글")
                    .font(.pretendard(size: 20, weight: .medium))
                    .foregroundColor(Color("grey900"))
                Text("\(viewModel.commentCount)")
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("main200"))
                Spacer()
                Button {
                    Task { await viewModel.reloadComments() }
                } label: {
                    pdfAssetImage("reload", side: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Rectangle()
                .fill(Color("grey100"))
                .frame(height: 1)
                .padding(.top, 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if viewModel.comments.isEmpty {
                        Text("아직 댓글이 없어요.")
                            .font(.pretendard(size: 14, weight: .regular))
                            .foregroundColor(Color("grey500"))
                            .padding(.top, 40)
                    } else {
                        ForEach(viewModel.comments) { comment in
                            commentRow(comment)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .frame(minHeight: 0, maxHeight: .infinity)

            Rectangle()
                .fill(Color("grey100"))
                .frame(height: 1)

            commentSheetInputBar
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color("white"))
    }

    private var commentSheetInputBar: some View {
        let trimmed = viewModel.commentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let canSubmit = !trimmed.isEmpty && !viewModel.isSubmittingComment

        return HStack(spacing: 12) {
            pdfAssetImage("lock", side: 40)

            TextField("텍스트 입력 전", text: $viewModel.commentInput)
                .font(.pretendard(size: 15, weight: .regular))
                .foregroundColor(Color("grey900"))
                .textInputAutocapitalization(.never)
                .frame(maxWidth: .infinity)

            Button {
                Task { await viewModel.submitComment() }
            } label: {
                pdfAssetImage("upload", side: 40)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.45)
        }
        .padding(4)
        .background(Color.white)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 30,
                topTrailingRadius: 30,
                style: .continuous
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 30,
                topTrailingRadius: 30,
                style: .continuous
            )
            .strokeBorder(Color("grey300"), lineWidth: 0.5)
        )
    }

    /// 피그마에서 추출한 PDF 에셋(외곽 원·테두리·색 포함)을 그대로 표시할 때 사용합니다.
    @ViewBuilder
    private func pdfAssetImage(_ name: String, side: CGFloat) -> some View {
        Image(name)
            .renderingMode(.original)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: side, height: side)
    }

    private func commentRow(_ comment: LibraryCardComment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color("grey200"))
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.writerName)
                        .font(.pretendard(size: 13, weight: .medium))
                        .foregroundColor(Color("grey900"))
                    Text(formatDate(comment.createdAt))
                        .font(.pretendard(size: 11, weight: .regular))
                        .foregroundColor(Color("grey500"))
                }

                Text(comment.content)
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey900"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
        }
    }

    private func formatDate(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "-" }

        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = parser.date(from: value) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy. MM. dd."
            return formatter.string(from: date)
        }

        parser.formatOptions = [.withInternetDateTime]
        if let date = parser.date(from: value) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy. MM. dd."
            return formatter.string(from: date)
        }

        return value.replacingOccurrences(of: "T", with: " ").prefix(10).description
    }
}

extension Notification.Name {
    /// 독서카드 생성·수정 후 상세 등에서 목록을 새로고침할 때 사용합니다.
    static let libraryCardMutationFinished = Notification.Name("libraryCardMutationFinished")
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
