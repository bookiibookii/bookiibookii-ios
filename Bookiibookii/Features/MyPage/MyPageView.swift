import SwiftUI

struct MyPageView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("마이페이지")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("마이페이지")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    MyPageView()
}
