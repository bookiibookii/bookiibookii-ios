import SwiftUI

// 안드로이드 HomeFragment 대응
struct HomeView: View {
    var body: some View {
        VStack(spacing: 0) {
            homeHeader
            ScrollView {
                VStack(spacing: 0) {
                    exchangeProgressSection  // 진행 중인 교환
                    homeGroupSection         // 이런 그룹은 어떠세요?
                    homeMateSection          // 부키메이트가 되어보세요!
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color("grey100"))
    }

    // MARK: - 헤더 (section_home_header.xml 대응)
    // 흰 배경 + 하단 grey_200 구분선
    private var homeHeader: some View {
        HStack {
            // ic_home_logo: bookiibookii 텍스트 로고 (주황색)
            Image("ic_splash_title")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 20)
                .foregroundColor(Color("main200"))

            Spacer()

            // ic_home_notification 대응 (clip-path → SF Symbol 대체)
            Button(action: {}) {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundColor(Color("grey900"))
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color("grey200"))
        }
    }

    // MARK: - 섹션 1: 진행 중인 교환 (section_home_exchange_progress.xml)
    private var exchangeProgressSection: some View {
        HomeSectionView(title: "진행 중인 교환") {
            emptyPlaceholder("진행 중인 교환이 없습니다")
        }
    }

    // MARK: - 섹션 2: 이런 그룹은 어떠세요? (section_home_group.xml)
    private var homeGroupSection: some View {
        HomeSectionView(title: "이런 그룹은 어떠세요?") {
            emptyPlaceholder("추천 그룹을 불러오는 중입니다")
        }
    }

    // MARK: - 섹션 3: 부키메이트가 되어보세요! (section_home_mate.xml)
    private var homeMateSection: some View {
        HomeSectionView(title: "부키메이트가 되어보세요!") {
            emptyPlaceholder("추천 부키메이트를 불러오는 중입니다")
        }
    }

    private func emptyPlaceholder(_ message: String) -> some View {
        HStack {
            Spacer()
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color("grey500"))
            Spacer()
        }
        .frame(height: 100)
    }
}

// MARK: - 홈 섹션 공통 컴포넌트
private struct HomeSectionView<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("grey900"))
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            content()
                .padding(.bottom, 8)
        }
    }
}

#Preview {
    HomeView()
}
