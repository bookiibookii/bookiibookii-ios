import SwiftUI

// 안드로이드 TrkHostMainFragment 대응
struct TrackerView: View {
    @State private var selectedTab = 0  // 0: 내 그룹, 1: 참여한 그룹

    var body: some View {
        VStack(spacing: 0) {
            trackerHeader
            toggleButtons
                .padding(.horizontal, 24)
                .padding(.top, 16)

            // RecyclerView 영역 (빈 상태)
            ScrollView {
                emptyPlaceholder
                    .padding(.top, 60)
            }
            .padding(.horizontal, 24)
        }
        .background(Color("grey100"))
    }

    // MARK: - 헤더 (top_background + tracker_title_tv)
    private var trackerHeader: some View {
        HStack {
            Text("북 트래커")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(Color("grey900"))
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(height: 68)
        .background(Color("white"))
    }

    // MARK: - 토글 버튼 (layout_toggle_container: myGroup_bt + joinedGroup_bt)
    // cornerRadius: 16dp, height: 48dp
    private var toggleButtons: some View {
        HStack(spacing: 16) {
            toggleButton(title: "내 그룹", index: 0)
            toggleButton(title: "참여한 그룹", index: 1)
        }
        .frame(height: 48)
    }

    private func toggleButton(title: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        return Button {
            selectedTab = index
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Color("white") : Color("grey900"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSelected ? Color("grey900") : Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? Color("grey900") : Color("grey200"),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var emptyPlaceholder: some View {
        Text("그룹 목록을 불러오는 중입니다")
            .font(.system(size: 14))
            .foregroundColor(Color("grey500"))
    }
}

#Preview {
    TrackerView()
}
