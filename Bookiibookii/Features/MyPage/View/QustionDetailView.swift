import SwiftUI

struct QustionDetailView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: QustionDetailViewModel
    @State private var showFailAlert = false

    init(inquiryService: InquiryService) {
        _viewModel = StateObject(wrappedValue: QustionDetailViewModel(inquiryService: inquiryService))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("grey100").ignoresSafeArea()
            VStack(spacing: 0) {
                CustomNavigationBar(title: "문의하기", onBack: { container.navigationRouter.pop() }, rightButton: .none)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        guideBanner
                        fieldTitle("제목")
                        TextField("제목을 입력해주세요", text: $viewModel.title)
                            .padding(.horizontal, 20)
                            .frame(height: 48)
                            .background(Color("white"))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey400"), lineWidth: 0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        fieldTitle("문의내용")
                        ZStack(alignment: .topLeading) {
                            if viewModel.content.isEmpty {
                                Text("문의 내용을 입력해주세요.")
                                    .pretendardText(size: 15, weight: .regular)
                                    .foregroundColor(Color("grey500"))
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                            }
                            TextEditor(text: $viewModel.content)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                                .padding(.bottom, 14)
                        }
                        .frame(height: 200)
                        .background(Color("white"))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("grey400"), lineWidth: 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }

            Button {
                Task {
                    let success = await viewModel.submit()
                    if success { container.navigationRouter.pop() }
                    else { showFailAlert = true }
                }
            } label: {
                Text(viewModel.isSubmitting ? "전송 중..." : "문의 전송")
                    .pretendardText(size: 18, weight: .medium)
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(viewModel.canSubmit ? Color("grey900") : Color("grey500"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .alert("문의 전송 실패", isPresented: $showFailAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("잠시 후 다시 시도해주세요.")
        }
    }

    private var guideBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            Text("부키부키 팀에서 문의사항을 확인한 후, 통상 7일 내에 답변 드립니다.")
                .pretendardText(size: 14, weight: .regular)
                .foregroundColor(.green)
        }
        .padding(16)
        .background(Color(red: 0.906, green: 1.0, blue: 0.918))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.455, green: 0.824, blue: 0.498), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func fieldTitle(_ text: String) -> some View {
        Text(text).pretendardText(size: 16, weight: .medium).foregroundColor(Color("grey900"))
    }
}
