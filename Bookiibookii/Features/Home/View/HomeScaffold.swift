import SwiftUI

// 안드 HomeWelcomeSection / HomeSearchCreateRow / HomeTabRow 대응.

// MARK: - 환영 섹션

struct HomeWelcomeSection: View {
    let nickname: String

    // 세션 동안 고정 (View 생성 시 1회 결정).
    private let topGreeting: String
    private let subtitle: String

    init(nickname: String) {
        self.nickname = nickname
        self.topGreeting = Self.topGreetings.randomElement() ?? "안녕하세요,"
        self.subtitle = Self.pickSubtitle()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            (
                Text(topGreeting + " ")
                    .foregroundColor(Color("grey900"))
                + Text(nickname)
                    .foregroundColor(Color("main200"))
                + Text("\n" + subtitle)
                    .foregroundColor(Color("grey900"))
            )
            .pretendardText(size: 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .background(Color("white"))
    }

    // 안드 topGreetings / 시간대별 멘트 대응.
    private static let topGreetings = ["안녕하세요,", "반가워요,", "어서오세요,", "환영해요,"]
    private static let nightMessages = ["잠들기 전 독서 어때요?", "늦은 밤에도 책과 함께 해요"]
    private static let morningMessages = ["오늘 하루도 책으로 활기차게 시작해요", "책 읽기 좋은 오전이네요"]
    private static let afternoonMessages = ["잠깐의 여유를 책과 함께 해요", "책과 함께 하는 편안한 오후 되세요"]
    private static let eveningMessages = ["책 읽기 좋은 저녁이네요", "하루의 마무리로 책 한 권 어떠세요?"]
    private static let fallbackMessage = "함께 독서할 파트너를 찾아보세요"

    private static func pickSubtitle() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 22...23, 0...4: return nightMessages.randomElement() ?? fallbackMessage
        case 5...10:         return morningMessages.randomElement() ?? fallbackMessage
        case 11...16:        return afternoonMessages.randomElement() ?? fallbackMessage
        case 17...21:        return eveningMessages.randomElement() ?? fallbackMessage
        default:             return fallbackMessage
        }
    }
}

// MARK: - 검색 + 그룹 생성 행

struct HomeSearchCreateRow: View {
    var onSearchTap: () -> Void
    var onCreateGroupTap: () -> Void

    // 안드: tl=20 tr=30 bl=20 br=30 — SwiftUI는 좌우 비대칭 라운드를 UnevenRoundedRectangle로.
    private var searchFieldShape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: 20, bottomLeadingRadius: 20,
            bottomTrailingRadius: 30, topTrailingRadius: 30
        )
    }

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onSearchTap) {
                HStack(spacing: 0) {
                    Text("그룹을 검색해보세요")
                        .pretendardText(size: 16)
                        .foregroundColor(Color("grey500"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ZStack {
                        Circle().fill(Color("grey300"))
                        Image("ic_search")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color("white"))
                    }
                    .frame(width: 44, height: 44)
                }
                .padding(.leading, 16)
                .padding(.trailing, 6)
                .padding(.vertical, 6)
                .frame(height: 56)
                .background(searchFieldShape.fill(Color("white")))
                .overlay(searchFieldShape.stroke(Color("grey200"), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button(action: onCreateGroupTap) {
                Text("그룹 생성")
                    .pretendardText(size: 16)
                    .foregroundColor(Color("white"))
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Capsule().fill(Color("main200")))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
    }
}

// MARK: - 탭바 (추천 / 내 그룹 / 신청한 그룹)

struct HomeTabRow: View {
    let selectedTab: HomeTab
    var onSelect: (HomeTab) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color("grey100"))
                .frame(height: 1)

            HStack(spacing: 12) {
                ForEach(HomeTab.allCases) { tab in
                    let isSelected = tab == selectedTab
                    Button {
                        onSelect(tab)
                    } label: {
                        Text(tab.title)
                            .pretendardText(size: 18, weight: .medium)
                            .foregroundColor(isSelected ? Color("main200") : Color("grey400"))
                            .padding(.trailing, 4)
                            .padding(.bottom, 16)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(isSelected ? Color("main200") : Color.clear)
                                    .frame(height: 2)
                            }
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
            .padding(.leading, 16)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
        .background(Color("white"))
    }
}
