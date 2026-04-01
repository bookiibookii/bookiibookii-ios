import SwiftUI

// 안드로이드 GroupFragment 대응
struct GroupView: View {
    @State private var selectedSort = 0          // 0: 추천순, 1: 최신순, 2: 인기순
    @State private var selectedChips: Set<String> = []
    @State private var showFabMenu = false

    private let sortOptions = ["추천순", "최신순", "인기순"]
    private let chips = ["그룹 유형", "지역별", "분야별"]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                dashboardHeader
                sortBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                Divider().foregroundColor(.grey200)

                // RecyclerView 영역 (빈 상태)
                ScrollView {
                    emptyPlaceholder
                        .padding(.top, 60)
                }
            }
            .background(Color.uiBg)

            // FAB 영역
            fabArea
                .padding(.trailing, 20)
                .padding(.bottom, 16)
        }
    }

    // MARK: - 대시보드 헤더 (흰 배경 카드 + 하단 border)
    // grp_main_dashBoard_Iv + 타이틀 + 검색 + 칩 그룹
    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                // grp_main_title_Tv
                Text("그룹")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.grey700)

                Spacer()

                // grp_search_Iv (ic_search: clip-path → SF Symbol 대체)
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.grey500)
                            .font(.system(size: 16, weight: .regular))
                    )
                    .overlay(Circle().stroke(Color.grey200, lineWidth: 1))
            }
            .padding(.top, 20)

            // grp_chip_scroll_view: HorizontalScrollView + ChipGroup
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chips, id: \.self) { chip in
                        chipButton(chip)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle().frame(height: 1).foregroundColor(.grey200)
        }
    }

    // MARK: - 칩 버튼 (Widget.App.Chip.Filter 스타일 대응)
    private func chipButton(_ title: String) -> some View {
        let isSelected = selectedChips.contains(title)
        return Button {
            if isSelected { selectedChips.remove(title) } else { selectedChips.insert(title) }
        } label: {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : .grey900)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.preMain : Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.preMain : Color.grey200, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 정렬 바 (추천순 | 최신순 | 인기순, 우측 정렬)
    private var sortBar: some View {
        HStack(spacing: 4) {
            Spacer()
            ForEach(Array(sortOptions.enumerated()), id: \.offset) { index, option in
                if index > 0 {
                    Text("|")
                        .font(.system(size: 14))
                        .foregroundColor(.grey200)
                }
                Button {
                    selectedSort = index
                } label: {
                    Text(option)
                        .font(.system(size: 14))
                        .foregroundColor(selectedSort == index ? .grey700 : .grey500)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyPlaceholder: some View {
        Text("그룹 목록을 불러오는 중입니다")
            .font(.system(size: 14))
            .foregroundColor(.grey500)
    }

    // MARK: - FAB 영역 (grp_group_fab_main_btn + grp_group_fab_menu_layout)
    private var fabArea: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if showFabMenu {
                // grp_group_fab_option_together (ic_share_read 대응)
                fabOptionButton(title: "함께읽기", icon: "person.2")
                // grp_group_fab_option_relay (ic_relay 대응)
                fabOptionButton(title: "이어읽기", icon: "arrow.clockwise")
            }

            // grp_group_fab_main_btn (ic_grouplist 대응): 70dp 원형 다크 버튼
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showFabMenu.toggle()
                }
            } label: {
                Circle()
                    .fill(Color.grey900)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: showFabMenu ? "xmark" : "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    )
            }
        }
    }

    private func fabOptionButton(title: String, icon: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(Color.grey900)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    GroupView()
}
