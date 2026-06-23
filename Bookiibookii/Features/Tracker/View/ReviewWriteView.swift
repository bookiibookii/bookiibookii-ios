import SwiftUI
import Kingfisher

// 안드 fragment_lib_book_detail_relay_write.xml + LibraryBookDetailRelayWriteFragment 대응.
// 직접교환/택배교환 마지막 단계 "후기 남기기" 화면.
struct ReviewWriteView: View {
    @StateObject private var vm: ReviewWriteViewModel
    @EnvironmentObject private var container: DIContainer

    init(groupId: Int, groupService: GroupService, libraryService: LibraryService) {
        _vm = StateObject(
            wrappedValue: ReviewWriteViewModel(
                groupId: groupId,
                groupService: groupService,
                libraryService: libraryService
            )
        )
    }

    #if DEBUG
    fileprivate init(previewModel: ReviewWriteViewModel) {
        _vm = StateObject(wrappedValue: previewModel)
    }
    #endif

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(spacing: 16) {
                    bookInfoCard
                    bookRatingSection
                    partnerRatingSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 30)
            }

            submitButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("grey100"))
        .toast($vm.toastMessage)
        .task { await vm.load() }
    }

    // MARK: - 상단바
    private var topBar: some View {
        ZStack {
            Text("교환독서 후기")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

            HStack {
                Button(action: handleBack) {
                    Image("ic_back")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                .padding(.leading, 16)
                Spacer()
            }
        }
        .frame(height: 73)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
    }

    private func handleBack() {
        if vm.isSubmitted {
            container.navigationRouter.popToRoot()
        } else {
            container.navigationRouter.pop()
        }
    }

    // MARK: - 책 정보 카드
    private var bookInfoCard: some View {
        HStack(alignment: .top, spacing: 14) {
            KFImage(URL(string: vm.bookImageUrl ?? ""))
                .placeholder {
                    RoundedRectangle(cornerRadius: 10).fill(Color("grey200"))
                }
                .resizable()
                .scaledToFill()
                .frame(width: 92, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    KFImage(URL(string: vm.hostProfileImageUrl ?? ""))
                        .placeholder {
                            Circle().fill(Color("grey300"))
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())

                    Text(vm.hostNickname)
                        .pretendardText(size: 12, weight: .medium)
                        .foregroundColor(Color("grey700"))
                }

                Text(vm.bookTitle)
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey900"))
                    .lineLimit(1)
                    .padding(.top, 11)

                Text(vm.bookAuthor)
                    .pretendardText(size: 12)
                    .foregroundColor(Color("grey500"))
                    .lineLimit(1)
                    .padding(.top, 4)

                Spacer(minLength: 0)

                Text(startDateText)
                    .pretendardText(size: 11)
                    .foregroundColor(Color("grey400"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var startDateText: String {
        let pretty = TrackerDateFormatter.prettyDate(vm.startDate)
        return "\(pretty) ~"
    }

    // MARK: - 책 평가 섹션
    private var bookRatingSection: some View {
        VStack(spacing: 20) {
            highlightTitle(
                full: "\(vm.bookTitle.isEmpty ? "이 책" : vm.bookTitle)에 대한 평가를 남겨주세요!",
                accent: vm.bookTitle.isEmpty ? "이 책" : vm.bookTitle
            )

            starRow(rating: vm.bookRating, onTap: vm.tapBookStar(index:))

            commentField(
                text: $vm.bookComment,
                hint: "책에 대한 솔직한 후기를 남겨주세요."
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 파트너 평가 섹션
    private var partnerRatingSection: some View {
        VStack(spacing: 20) {
            highlightTitle(
                full: "\(vm.partnerName) 님에 대한 평가를 남겨주세요!",
                accent: vm.partnerName
            )

            starRow(rating: vm.partnerRating, onTap: vm.tapPartnerStar(index:))

            badgeFlow

            commentField(
                text: $vm.partnerComment,
                hint: "파트너에 대한 따뜻한 후기를 남겨주세요."
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 부분
    private func highlightTitle(full: String, accent: String) -> some View {
        let attr: AttributedString = {
            var s = AttributedString(full)
            if let range = s.range(of: accent) {
                s[range].foregroundColor = Color("main200")
            }
            return s
        }()
        return Text(attr)
            .pretendardText(size: 16, weight: .medium)
            .foregroundColor(Color("grey900"))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func starRow(rating: Double, onTap: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { i in
                Button {
                    onTap(i)
                } label: {
                    starShape(rating: rating, index: i)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color("grey100"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    /// 별 상태:
    /// - 빈 상태: 회색 외곽선
    /// - 한번 눌림(half): 가장자리 sub200 + 안쪽 sub100
    /// - 완전 채움(full): 전부 sub200
    @ViewBuilder
    private func starShape(rating: Double, index i: Int) -> some View {
        if rating >= Double(i) + 1.0 {
            Image(systemName: "star.fill")
                .resizable()
                .foregroundColor(Color("sub200"))
        } else if rating >= Double(i) + 0.5 {
            ZStack {
                Image(systemName: "star.fill")
                    .resizable()
                    .foregroundColor(Color("sub100"))
                Image(systemName: "star")
                    .resizable()
                    .foregroundColor(Color("sub200"))
            }
        } else {
            Image(systemName: "star")
                .resizable()
                .foregroundColor(Color("grey400"))
        }
    }

    private var badgeFlow: some View {
        FlexibleHStack(spacing: 8, lineSpacing: 8) {
            ForEach(ReviewBadge.all) { badge in
                let selected = vm.selectedBadgeIds.contains(badge.id)
                Button {
                    vm.toggleBadge(badge)
                } label: {
                    Text(badge.label)
                        .pretendardText(size: 12)
                        .foregroundColor(selected ? Color("main200") : Color("grey900"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(selected ? Color("main200") : Color("grey200"), lineWidth: 1)
                        )
                        .background(Color("white"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func commentField(text: Binding<String>, hint: String) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(hint)
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey500"))
                    .padding(20)
            }
            TextEditor(text: text)
                .pretendardText(size: 14)
                .foregroundColor(Color("grey900"))
                .scrollContentBackground(.hidden)
                .padding(16)
                .disabled(vm.isSubmitted)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("grey200"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 하단 CTA
    private var submitButton: some View {
        Button {
            Task {
                let ok = await vm.submit()
                if ok {
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    container.navigationRouter.popToRoot()
                }
            }
        } label: {
            Text(vm.isSubmitting ? "전송 중..." : "후기 남기기")
                .pretendardText(size: 18, weight: .medium)
                .foregroundColor(vm.canSubmit ? Color("white") : Color("grey500"))
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(vm.canSubmit ? Color("grey900") : Color("grey200"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .disabled(!vm.canSubmit)
    }
}

#if DEBUG
#Preview("ReviewWrite — 빈 상태") {
    ReviewWriteView(previewModel: ReviewWriteViewModel.preview())
        .environmentObject(DIContainer())
}

#Preview("ReviewWrite — 입력 완료") {
    let vm = ReviewWriteViewModel.preview()
    vm.bookRating = 4.5
    vm.partnerRating = 5.0
    vm.bookComment = "정말 인상 깊게 읽었어요. 다시 곱씹어보고 싶은 책."
    vm.partnerComment = "꼼꼼하게 읽고 코멘트도 정성껏 남겨주셨어요."
    vm.selectedBadgeIds = ["KINDNESS", "INSIGHTFUL", "PUNCTUAL"]
    return ReviewWriteView(previewModel: vm)
        .environmentObject(DIContainer())
}
#endif

// MARK: - 간단 Flex Wrap

/// 한 줄에 못 들어가면 다음 줄로 넘기는 wrap container.
private struct FlexibleHStack<Content: View>: View {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    @ViewBuilder var content: () -> Content

    init(spacing: CGFloat = 8, lineSpacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content
    }

    var body: some View {
        _FlexibleLayout(spacing: spacing, lineSpacing: lineSpacing) {
            content()
        }
    }
}

private struct _FlexibleLayout: Layout {
    let spacing: CGFloat
    let lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(0) { acc, row in
            acc + (row.first.map { $0.height } ?? 0)
        } + CGFloat(max(0, rows.count - 1)) * lineSpacing
        let width = rows.map { row in
            row.reduce(0) { $0 + $1.width } + CGFloat(max(0, row.count - 1)) * spacing
        }.max() ?? 0
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)

        var y = bounds.minY
        var subviewIndex = 0
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.first?.height ?? 0
            for size in row {
                subviews[subviewIndex].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
                subviewIndex += 1
            }
            y += rowHeight + lineSpacing
        }
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [[CGSize]] {
        var rows: [[CGSize]] = [[]]
        var currentWidth: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            let widthWithSpacing = (rows.last?.isEmpty ?? true) ? size.width : size.width + spacing
            if currentWidth + widthWithSpacing > maxWidth, !(rows.last?.isEmpty ?? true) {
                rows.append([size])
                currentWidth = size.width
            } else {
                rows[rows.count - 1].append(size)
                currentWidth += widthWithSpacing
            }
        }
        return rows
    }
}
