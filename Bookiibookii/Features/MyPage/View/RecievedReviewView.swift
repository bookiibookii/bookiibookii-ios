//
//  RecievedReviewView.swift
//  Bookiibookii
//
//  Created by 한태빈 on 4/24/26.
//

import SwiftUI

struct RecievedReviewView: View {
    @EnvironmentObject private var container: DIContainer

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: "받은 후기",
                    onBack: { container.navigationRouter.pop() },
                    rightButton: .none
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        summaryRow
                        CollapsedReviewCard()
                        ExpandedReviewCard()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var summaryRow: some View {
        HStack {
            HStack(spacing: 4) {
                Text("5")
                Text("개")
            }
            .pretendardText(size: 14, weight: .regular)
            .foregroundColor(Color("grey700"))

            Spacer()

            HStack(spacing: 4) {
                Text("최신순")
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("grey700"))
                Text("|")
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey500"))
                Text("과거순")
                    .pretendardText(size: 14, weight: .regular)
                    .foregroundColor(Color("grey500"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    RecievedReviewView()
        .environmentObject(DIContainer())
}

private struct ReviewHeaderRow: View {
    let isExpanded: Bool

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text("noshel")
                    .pretendardText(size: 14, weight: .semibold)
                    .foregroundColor(Color("main200"))
                Text("님과의 교환독서")
                    .pretendardText(size: 14, weight: .medium)
                    .foregroundColor(Color("grey900"))
            }

            Spacer()

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("grey700"))
        }
    }
}

private struct BookInfoRow: View {
    private let coverURL = URL(string: "https://www.figma.com/api/mcp/asset/192a04ec-35d8-437e-9b69-046fab0e7041")

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let coverURL {
                    AsyncImage(url: coverURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Color("grey300")
                        }
                    }
                } else {
                    Color("grey300")
                }
            }
            .frame(width: 50, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("괴테는 모든 것을 말했다")
                        .pretendardText(size: 14, weight: .medium)
                        .foregroundColor(Color("grey900"))
                    HStack(spacing: 4) {
                        Text("스즈키 유이")
                        Text("(소설)")
                            .pretendardText(size: 11, weight: .regular)
                    }
                    .pretendardText(size: 12, weight: .regular)
                    .foregroundColor(Color("grey500"))
                }

                Text("2025. 12. 18. ~ 2026. 01. 12.")
                    .pretendardText(size: 11, weight: .regular)
                    .foregroundColor(Color("grey400"))
            }
            Spacer()
        }
    }
}

private struct TagChip: View {
    let text: String

    var body: some View {
        HStack(spacing: 0) {
            Text("#")
            Text(text)
        }
        .pretendardText(size: 12, weight: .regular)
        .foregroundColor(Color("sub200"))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color("sub105"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PlusChip: View {
    let value: String

    var body: some View {
        HStack(spacing: 0) {
            Text("+")
            Text(value)
        }
        .pretendardText(size: 12, weight: .regular)
        .foregroundColor(Color("sub200"))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color("sub105"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct CollapsedReviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReviewHeaderRow(isExpanded: true)
            BookInfoRow()
            HStack(spacing: 8) {
                TagChip(text: "글씨가 예뻐요")
                TagChip(text: "코멘트가 다정해요")
                PlusChip(value: "1")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct ExpandedReviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReviewHeaderRow(isExpanded: false)
            BookInfoRow()

            Text("도서 후기")
                .pretendardText(size: 12, weight: .medium)
                .foregroundColor(Color("grey900"))
            StarRating(value: 3)
            ReviewTextBox(text: "이동진 평론가도 추천한 책이라서 기대했는데 역시 존잼이었어요...")

            Text("파트너의 한줄평")
                .pretendardText(size: 12, weight: .medium)
                .foregroundColor(Color("grey900"))
            StarRating(value: 3)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    TagChip(text: "글씨가 예뻐요")
                    TagChip(text: "코멘트가 다정해요")
                }
                TagChip(text: "코멘트가 재미있어요")
            }

            ReviewTextBox(text: "책을 빠르게 보내주셔서 감사합니다!! 좋은 책을 함께 읽게 되어 너무 기뻐요~~")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct StarRating: View {
    let value: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { idx in
                Image(systemName: idx < value ? "star.fill" : "star")
                    .font(.system(size: 14))
                    .foregroundColor(idx < value ? Color("sub200") : Color("grey300"))
            }
        }
    }
}

private struct ReviewTextBox: View {
    let text: String

    var body: some View {
        Text(text)
            .pretendardText(size: 12, weight: .regular)
            .foregroundColor(Color("grey900"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color("grey100"))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("grey200"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
