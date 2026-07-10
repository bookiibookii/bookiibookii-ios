import SwiftUI

struct LegalDocumentView: View {
    @EnvironmentObject private var container: DIContainer

    let documentType: LegalDocumentType

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: true) {
                    Text(LegalDocumentContent.text(for: documentType))
                        .pretendardText(size: 14, weight: .regular)
                        .foregroundColor(Color("grey700"))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .padding(.trailing, 32)
                        .padding(.vertical, 20)
                        .background(Color("white"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        HStack {
            Button { container.navigationRouter.pop() } label: {
                Image("ic_back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(documentType.navigationTitle)
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Divider().overlay(Color("grey200"))
        }
    }
}

#Preview {
    LegalDocumentView(documentType: .termsOfService)
        .environmentObject(DIContainer())
}
