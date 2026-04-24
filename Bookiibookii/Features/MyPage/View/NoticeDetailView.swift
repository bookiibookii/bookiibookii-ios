import SwiftUI

struct NoticeDetailView: View {
    @EnvironmentObject private var container: DIContainer

    let title: String
    let dateText: String
    let content: String

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: title,
                    onBack: { container.navigationRouter.pop() },
                    rightButton: .none
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(dateText)
                            .font(.pretendard(size: 12, weight: .regular))
                            .foregroundColor(Color("grey400"))

                        Text(content)
                            .font(.pretendard(size: 14, weight: .regular))
                            .foregroundColor(Color("grey700"))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(2)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("white"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NoticeDetailView(
        title: "12월 업데이트 안내",
        dateText: "2024. 12. 01. 16:00",
        content: "새로운 기능이 추가되었습니다! 독서 카드 꾸미기 기능을 확인해보세요."
    )
    .environmentObject(DIContainer())
}
