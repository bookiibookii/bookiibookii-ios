import SwiftUI

struct OnboardingStepsView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: OnboardingStepsViewModel

    init(name: String, s3Key: String?, userService: UserService) {
        _viewModel = StateObject(wrappedValue: OnboardingStepsViewModel(
            name: name, s3Key: s3Key, userService: userService
        ))
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        progressSection.padding(.horizontal, 24)
                        questionCard.padding(.horizontal, 24)
                        stepContent
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 104)
                }
            }

            VStack {
                Spacer()
                footerButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel.isCompleted) { _, completed in
            guard completed else { return }
            container.navigationRouter.hardReset(to: .mainTab)
        }
    }

    // MARK: - 헤더 (뒤로가기 + 로고)

    private var headerSection: some View {
        HStack {
            Button(action: handleBack) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("grey900"))
                    )
            }

            Spacer()

            Image("ic_title")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 204, height: 22)
                .foregroundColor(Color("main200"))

            Spacer()

            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("grey100"))
    }

    // MARK: - 진행 바 (3단계)

    private var progressSection: some View {
        HStack(spacing: 12) {
            ForEach(1...3, id: \.self) { step in
                Capsule()
                    .fill(step <= viewModel.currentStep ? Color("sub105") : Color("grey200"))
                    .frame(height: 8)
            }
        }
    }

    // MARK: - 질문 카드

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(questionTitle)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(Color("grey900"))

            VStack(alignment: .leading, spacing: 4) {
                Text(questionSubtitle)
                    .font(.system(size: 14))
                    .foregroundColor(Color("grey500"))

                if viewModel.currentStep == 2 {
                    Text("중복 선택 가능")
                        .font(.system(size: 12))
                        .foregroundColor(Color("grey400"))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var questionTitle: String {
        switch viewModel.currentStep {
        case 1: return "어떤 책을 펼칠 때\n가장 설레나요?"
        case 2: return "마음에 콕! 박히는\n문장을 만났을 때"
        case 3: return "한 권을 완독하는\n나만의 페이스는?"
        default: return ""
        }
    }

    private var questionSubtitle: String {
        switch viewModel.currentStep {
        case 1: return "좋아하는 분야를 3개까지 골라주세요."
        case 2: return "나의 평소 독서 습관은 어떤가요?"
        case 3: return "비슷한 속도의 부키 메이트를 찾아드릴게요!"
        default: return ""
        }
    }

    // MARK: - 단계별 콘텐츠

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 1: step1View
        case 2: step2View
        case 3: step3View
        default: EmptyView()
        }
    }

    // MARK: - Step 1: 장르 칩 선택 (최대 3개)

    private var step1View: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(StepGenre.rows, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { genre in
                        let isSelected = viewModel.selectedGenres.contains(genre)
                        Button(action: { viewModel.toggleGenre(genre) }) {
                            Text(genre.displayName)
                                .font(.system(size: 14))
                                .foregroundColor(isSelected ? Color("main200") : Color("grey900"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    isSelected
                                        ? Color(red: 1.0, green: 234/255, blue: 219/255)
                                        : Color.white
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            isSelected ? Color("main200") : Color("grey200"),
                                            lineWidth: 1
                                        )
                                )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    // MARK: - Step 2: 독서 기록 방식 선택

    private var step2View: some View {
        VStack(spacing: 12) {
            methodListCard

            methodSpecialCard(
                icon: "heart.fill",
                title: "모든 방식을 환영해요",
                isSelected: viewModel.isAllMethodsSelected,
                action: { viewModel.toggleAllMethods() }
            )
            methodSpecialCard(
                icon: "questionmark",
                title: "아직 잘 모르겠어요",
                isSelected: viewModel.isMethodUnknown,
                action: { viewModel.toggleMethodUnknown() }
            )
        }
        .padding(.horizontal, 24)
    }

    private var methodListCard: some View {
        let methods = StepMethod.allCases
        return VStack(spacing: 0) {
            ForEach(0..<methods.count, id: \.self) { index in
                let method = methods[index]
                let isSelected = viewModel.selectedMethods.contains(method)
                let isLast = index == methods.count - 1

                Button(action: { viewModel.toggleMethod(method) }) {
                    HStack(spacing: 12) {
                        methodIconCircle(systemName: method.iconSystemName)
                        Text(method.displayName)
                            .font(.system(size: 15))
                            .foregroundColor(isSelected ? Color("main200") : Color("grey900"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }

                if !isLast {
                    Rectangle()
                        .fill(Color("grey200"))
                        .frame(height: 1)
                        .padding(.horizontal, 8)
                }
            }
        }
        .padding(.vertical, 4)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color("grey200"), lineWidth: 1)
        )
    }

    private func methodSpecialCard(icon: String, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                methodIconCircle(systemName: icon)
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(isSelected ? Color("main200") : Color("grey900"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? Color("main200") : Color("grey200"), lineWidth: 1)
            )
        }
    }

    private func methodIconCircle(systemName: String) -> some View {
        ZStack {
            Circle()
                .fill(Color(red: 1.0, green: 234/255, blue: 219/255))
                .frame(width: 28, height: 28)
            Image(systemName: systemName)
                .font(.system(size: 13))
                .foregroundColor(Color("main200"))
        }
    }

    // MARK: - Step 3: 독서 페이스 선택 (단일)

    private var step3View: some View {
        VStack(spacing: 12) {
            ForEach(StepPace.allCases, id: \.self) { pace in
                let isSelected = viewModel.selectedPace == pace
                Button(action: { viewModel.selectPace(pace) }) {
                    HStack(spacing: 12) {
                        if let badge = pace.badge {
                            Text(badge)
                                .font(.system(size: 15))
                                .foregroundColor(Color("main200"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color(red: 1.0, green: 234/255, blue: 219/255))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color(red: 1.0, green: 201/255, blue: 164/255), lineWidth: 1)
                                )
                        }
                        Text(pace.displayName)
                            .font(.system(size: 15))
                            .foregroundColor(Color("grey900"))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                isSelected ? Color("main200") : Color("grey200"),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - 다음 버튼

    private var footerButton: some View {
        Button(action: viewModel.goNext) {
            Group {
                if viewModel.isCompleting {
                    ProgressView().tint(.white)
                } else {
                    Text("다음")
                        .font(.system(size: 18, weight: viewModel.canGoNext ? .medium : .regular))
                        .foregroundColor(viewModel.canGoNext ? .white : Color("grey500"))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(viewModel.canGoNext ? Color("grey900") : Color("grey200"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .disabled(!viewModel.canGoNext || viewModel.isCompleting)
    }

    // MARK: - 뒤로가기

    private func handleBack() {
        if !viewModel.goBack() {
            container.navigationRouter.pop()
        }
    }
}

#Preview {
    OnboardingStepsView(
        name: "홍길동",
        s3Key: nil,
        userService: UserService(interceptor: AuthInterceptor(authService: AuthService()))
    )
    .environmentObject(DIContainer())
}
