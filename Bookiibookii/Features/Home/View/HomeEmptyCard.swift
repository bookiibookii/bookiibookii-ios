import SwiftUI

// 안드로이드 item_home_empty_card.xml 대응
// 흰 카드 + 제목 + 설명 + 버튼. 버튼 스타일은 dark(진행 교환) / pale(추천/메이트) 두 종류.
struct HomeEmptyCard: View {
    enum ButtonStyle {
        case dark   // grey900 배경 + white 텍스트
        case pale   // main100 배경 + main200 텍스트
    }

    let title: String
    let description: String
    let buttonTitle: String
    let buttonStyle: ButtonStyle
    var onTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.pretendard(size: 14, weight: .semibold))
                .foregroundColor(Color("grey900"))

            Text(description)
                .font(.pretendard(size: 12))
                .foregroundColor(Color("grey600"))
                .padding(.top, 6)

            Button(action: onTap) {
                Text(buttonTitle)
                    .font(.pretendard(size: 14, weight: .semibold))
                    .foregroundColor(buttonForeground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(buttonBackground)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("white"))
        )
    }

    private var buttonBackground: Color {
        switch buttonStyle {
        case .dark: return Color("grey900")
        case .pale: return Color("main100")
        }
    }

    private var buttonForeground: Color {
        switch buttonStyle {
        case .dark: return Color("white")
        case .pale: return Color("main200")
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HomeEmptyCard(
            title: "아직 진행 중인 교환이 없어요",
            description: "그룹에 참여하고 새로운 책을 만나보세요.",
            buttonTitle: "그룹 둘러보기",
            buttonStyle: .dark
        )
        HomeEmptyCard(
            title: "아직 추천할 그룹이 없어요",
            description: "읽고 싶은 책으로 그룹을 직접 만들어보세요.",
            buttonTitle: "그룹 만들기",
            buttonStyle: .pale
        )
    }
    .padding(20)
    .background(Color("grey100"))
}
