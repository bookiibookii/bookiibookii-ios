import SwiftUI

struct MyPageView: View {
    var body: some View {
        VStack {
            Text("마이페이지")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("grey100"))
    }
}

#Preview {
    MyPageView()
}
