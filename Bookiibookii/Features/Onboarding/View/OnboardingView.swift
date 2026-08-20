import SwiftUI
import PhotosUI
import Kingfisher

// 안드로이드 OnbStepScreen 대응 — 4단계 통합 온보딩 (프로필 · 인생책 · 기록방식 · 자기소개)
struct OnboardingView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: OnboardingViewModel

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showPhotoSheet = false
    @State private var showCamera = false
    @State private var showDateSheet = false
    @State private var showBookSearch = false
    @State private var editingSlot = 0

    init(userService: UserService, groupService: GroupService) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            userService: userService, groupService: groupService
        ))
    }

    var body: some View {
        ZStack {
            Color("uiBg").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                progressBar
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: viewModel.currentStep == 3 ? 8 : 20) {
                        subHeadCard
                        stepContent
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                FooterButton(
                    text: viewModel.isLastStep ? "완료" : "다음",
                    style: .dark,
                    enabled: viewModel.canGoNext,
                    isLoading: viewModel.isSubmitting,
                    action: viewModel.goNext
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }

            // 인생 책 검색 다이얼로그 (안드로이드 LifeBookSearchDialog 대응)
            if showBookSearch {
                bookSearchDialog
            }

            if showPhotoSheet {
                photoSheetOverlay
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showPhotoSheet)
        .toolbar(.hidden, for: .navigationBar)
        .dismissKeyboardOnTap()
        .onChange(of: photoPickerItem) { _, item in
            guard item != nil else { return }
            viewModel.consumePhotosPickerItem(item)
            photoPickerItem = nil
            showPhotoSheet = false
        }
        .onChange(of: viewModel.isCompleted) { _, completed in
            guard completed else { return }
            PushNotificationManager.shared.registerAfterLogin()
            container.navigationRouter.hardReset(to: .mainTab)
            PushNotificationManager.shared.handlePendingRedirectIfNeeded()
        }
        .sheet(isPresented: $showDateSheet) {
            birthDateSheet
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(20)
        }
        .alert("사진을 불러오지 못했습니다", isPresented: Binding(
            get: { viewModel.photoImportError != nil },
            set: { if !$0 { viewModel.photoImportError = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.photoImportError = nil }
        } message: {
            Text(viewModel.photoImportError ?? "")
        }
        .cameraPicker(isPresented: $showCamera) { image in
            viewModel.setCapturedImage(image)
        }
        // 푸터 버튼(56 + 상하 여백 16)을 가리지 않도록 하단 여백을 키운다
        .toast($viewModel.toast, bottomPadding: 112)
    }

    // MARK: - 헤더 (뒤로 + 중앙 워드마크 + 구분선)
    private var header: some View {
        VStack(spacing: 0) {
            ZStack {
                Image("ic_logo_wordmark")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 204, height: 22)
                    .foregroundColor(Color("main200"))

                HStack {
                    Button(action: handleBack) {
                        Image("ic_chevron")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    .frame(width: 40, height: 40)
                    Spacer()
                }
            }
            .frame(height: 68)
            .padding(.horizontal, 16)
            .background(Color("white"))

            Rectangle().fill(Color("grey200")).frame(height: 1)
        }
    }

    // MARK: - 진행 바 (완료 단계=점, 남은 단계=막대)
    // 막대→점 전환을 애니메이션하려면 두 모양이 같은 뷰여야 해서, Capsule 하나로 두고 폭만 계산해 바꾼다.
    private var progressBar: some View {
        let total = OnboardingViewModel.totalSteps
        let spacing: CGFloat = 12
        let dot: CGFloat = 8

        return GeometryReader { geo in
            let done = min(max(viewModel.currentStep, 0), total)
            let remaining = total - done
            let barWidth = remaining > 0
                ? max(0, geo.size.width - spacing * CGFloat(total - 1) - dot * CGFloat(done)) / CGFloat(remaining)
                : dot

            HStack(spacing: spacing) {
                ForEach(1...total, id: \.self) { step in
                    let isDone = step <= done
                    Capsule()
                        .fill(isDone ? Color("main200") : Color("grey200"))
                        .frame(width: isDone ? dot : barWidth, height: dot)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: dot)
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }

    // MARK: - 서브헤드 카드 (안드로이드 OnbSubHeadCard 대응)
    @ViewBuilder
    private var subHeadCard: some View {
        switch viewModel.currentStep {
        case 1:
            OnbSubHeadCard(title: "만나서 반가워요!",
                           description: "부키부키에서 사용할 정보를 알려주세요")
        case 2:
            OnbSubHeadCard(label: "필수 문항",
                           title: "나의 인생 책을 골라주세요",
                           description: "어떤 책이든 좋아요, 지금 떠오르는 책이면 충분해요!")
        case 3:
            OnbSubHeadCard(label: "필수 문항", secondLabel: "중복 선택 가능",
                           title: "마음에 콕! 박히는 문장을 만났을 때",
                           description: "나의 평소 독서 습관은 어떤가요?")
        case 4:
            OnbSubHeadCard(label: "선택 문항",
                           title: "나를 표현하는 한 문장을 적어주세요",
                           description: "나는 어떤 사람인가요?")
        default: EmptyView()
        }
    }

    // MARK: - 단계 콘텐츠
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 1: profileStep
        case 2: lifeBooksStep
        case 3: recordMethodStep
        case 4: introStep
        default: EmptyView()
        }
    }

    // MARK: - Step 1: 프로필
    private var profileStep: some View {
        VStack(spacing: 20) {
            profileImageButton
                .frame(maxWidth: .infinity, alignment: .center)
            nicknameSection
            genderSection
            birthSection
        }
    }

    private var profileImageButton: some View {
        Button(action: { showPhotoSheet = true }) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image).resizable().scaledToFill()
                            .frame(width: 128, height: 128)
                            .clipShape(SquircleShape())
                    } else {
                        Image("ic_profile_placeholder").resizable().scaledToFill()
                            .frame(width: 128, height: 128)
                    }
                }

                ZStack {
                    Circle().fill(Color("grey600")).frame(width: 32, height: 32)
                    Image("ic_camera")
                        .renderingMode(.template).resizable().scaledToFit()
                        .frame(width: 20, height: 20).foregroundColor(Color("white"))
                }
            }
        }
    }

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            requiredLabel("닉네임").padding(.bottom, 8)

            HStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    if viewModel.nickname.isEmpty {
                        Text("닉네임을 입력해주세요")
                            .font(.pretendard(size: 16))
                            .foregroundColor(Color("grey500"))
                    }
                    TextField("", text: $viewModel.nickname)
                        .font(.pretendard(size: 16))
                        .foregroundColor(Color("grey900"))
                        .tint(Color("main200"))
                        .onChange(of: viewModel.nickname) { _, newValue in
                            if newValue.count > 10 { viewModel.nickname = String(newValue.prefix(10)) }
                            viewModel.onNicknameChanged()
                        }
                }

                nicknameCheckButton
            }
            .padding(.leading, 12)
            .padding(.trailing, 8)
            .frame(height: 54)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color("grey300"), lineWidth: 1)
            )

            Text("한글, 영문, 숫자 공백 포함 10자 이내")
                .pretendardText(size: 12)
                .foregroundColor(Color("grey500"))
                .padding(.top, 8)
                .padding(.bottom, 4)

            if viewModel.nicknameState.showsValidation {
                Text(viewModel.nicknameState.message)
                    .pretendardText(size: 12)
                    .foregroundColor(viewModel.nicknameState.isAvailable ? Color("pointGreen200") : Color("pointRed"))
                    .padding(.bottom, 4)
            }
        }
    }

    private var nicknameCheckButton: some View {
        let isLoading: Bool = { if case .loading = viewModel.nicknameState { return true } else { return false } }()
        return Button(action: viewModel.checkNickname) {
            Group {
                if isLoading {
                    ProgressView().tint(Color("grey100"))
                } else {
                    Text("중복 확인")
                        .pretendardText(size: 14, weight: .medium)
                        .foregroundColor(isLoading ? Color("grey100") : Color("white"))
                }
            }
            .frame(height: 40)
            .padding(.horizontal, 16)
            .background(isLoading ? Color("grey400") : Color("grey900"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isLoading)
    }

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            requiredLabel("성별")
            HStack(spacing: 12) {
                genderButton(.female)
                genderButton(.male)
                genderButton(.unspecified)
            }
            .frame(height: 48)
        }
    }

    // 세 버튼이 가로 영역을 1:1:1로 균등 분할한다.
    private func genderButton(_ item: Gender) -> some View {
        let isSelected = viewModel.gender == item
        return Button(action: { viewModel.gender = item }) {
            Text(item.displayName)
                .pretendardText(size: 15)
                .foregroundColor(isSelected ? Color("main200") : Color("grey500"))
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .background(isSelected ? Color("main100") : Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isSelected ? Color("main105") : Color("grey300"), lineWidth: 1)
                )
        }
    }

    private var birthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            requiredLabel("생년월일")
            Button(action: { showDateSheet = true }) {
                HStack {
                    Text(birthDisplayText)
                        .pretendardText(size: 16)
                        .foregroundColor(viewModel.birthDate == nil ? Color("grey500") : Color("grey900"))
                    Spacer()
                    Image("ic_calender").resizable().scaledToFit().frame(width: 24, height: 24)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color("white"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color("grey300"), lineWidth: 1)
                )
            }
        }
    }

    private func requiredLabel(_ title: String) -> some View {
        HStack(spacing: 4) {
            Text(title).pretendardText(size: 16, weight: .medium).foregroundColor(Color("grey900"))
            Text("*").pretendardText(size: 16, weight: .medium).foregroundColor(Color("main200"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var birthDisplayText: String {
        guard let date = viewModel.birthDate else { return "0000.00.00." }
        return Self.displayFormatter.string(from: date) + "."
    }

    // MARK: - Step 2: 인생책 (3슬롯)
    private var lifeBooksStep: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(0..<3, id: \.self) { index in
                lifeBookSlot(index)
            }
        }
    }

    @ViewBuilder
    private func lifeBookSlot(_ index: Int) -> some View {
        let book = viewModel.lifeBooks[index]
        if let book {
            let isSingle = viewModel.selectedBookCount == 1
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color("grey200"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .overlay(
                        KFImage(URL(string: book.image))
                            .resizable()
                            .scaledToFill()
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        Button(action: {
                            if isSingle { openBookSearch(index) } else { viewModel.removeBook(at: index) }
                        }) {
                            ZStack {
                                Circle().fill(Color("grey100")).frame(width: 24, height: 24)
                                Image(isSingle ? "ic_edit" : "ic_x")
                                    .renderingMode(.template).resizable().scaledToFit()
                                    .frame(width: 16, height: 16).foregroundColor(Color("grey700"))
                            }
                        }
                        .padding(.trailing, 8)
                        .padding(.top, 8)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title.stripBookSubtitle())
                        .pretendardText(size: 14, weight: .semibold)
                        .foregroundColor(Color("grey900"))
                        .lineLimit(1)
                    Text("\(book.author) (\(book.categoryLabel))")
                        .pretendardText(size: 14)
                        .foregroundColor(Color("grey700"))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Button(action: { openBookSearch(index) }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color("grey200"))
                    ZStack {
                        Circle().fill(Color("grey400")).frame(width: 40, height: 40)
                        Image("ic_plus")
                            .renderingMode(.template).resizable().scaledToFit()
                            .frame(width: 24, height: 24).foregroundColor(Color("white"))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 170)
            }
        }
    }

    private func openBookSearch(_ index: Int) {
        editingSlot = index
        viewModel.clearBookSearch()
        showBookSearch = true
    }

    // MARK: - Step 3: 기록 방식
    private var recordMethodStep: some View {
        VStack(spacing: 8) {
            ForEach(RecordMethod.allCases, id: \.self) { method in
                recordMethodItem(
                    icon: method.iconAsset,
                    title: method.displayName,
                    selected: viewModel.recordMethods.contains(method),
                    action: { viewModel.toggleMethod(method) }
                )
            }
            recordMethodItem(
                icon: "ic_question",
                title: "아직 잘 모르겠어요.",
                selected: viewModel.isUnknownMethod,
                action: { viewModel.toggleUnknownMethod() }
            )
        }
    }

    private func recordMethodItem(icon: String, title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(selected ? Color("main105") : Color("main100")).frame(width: 28, height: 28)
                    Image(icon)
                        .renderingMode(.template).resizable().scaledToFit()
                        .frame(width: 20, height: 20).foregroundColor(Color("main200"))
                }
                Text(title)
                    .pretendardText(size: 15)
                    .foregroundColor(selected ? Color("main200") : Color("grey900"))
                    .multilineTextAlignment(.leading)   // 줄바꿈되면 좌측 정렬
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 56)
            .frame(maxWidth: .infinity)
            .background(selected ? Color("main100") : Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? Color("main105") : Color("grey200"), lineWidth: 1)
            )
        }
    }

    // MARK: - Step 4: 자기소개 (최대 50자, 선택)
    private var introStep: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if viewModel.introduction.isEmpty {
                    Text("나를 표현하는 한 문장을 적어주세요.")
                        .font(.pretendard(size: 15))
                        .foregroundColor(Color("grey500"))
                        .padding(16)
                }
                TextField("", text: $viewModel.introduction, axis: .vertical)
                    .font(.pretendard(size: 15))
                    .foregroundColor(Color("grey900"))
                    .tint(Color("main200"))
                    .lineLimit(1...5)
                    .padding(16)
                    .onChange(of: viewModel.introduction) { _, newValue in
                        if newValue.count > OnboardingViewModel.introMaxLength {
                            viewModel.introduction = String(newValue.prefix(OnboardingViewModel.introMaxLength))
                        }
                    }
            }
            .frame(maxWidth: .infinity)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color("grey300"), lineWidth: 1)
            )

            Text("\(viewModel.introduction.count)/\(OnboardingViewModel.introMaxLength)")
                .pretendardText(size: 12)
                .foregroundColor(Color("grey500"))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.vertical, 8)
        }
    }

    // MARK: - 프로필 사진 액션시트
    private var photoSheetOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { showPhotoSheet = false }

            ProfilePhotoBottomSheet(
                photoPickerItem: $photoPickerItem,
                onTakePhoto: {
                    showPhotoSheet = false
                    // 시트 닫힘과 카메라 표시 충돌 방지
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { showCamera = true }
                },
                onSelectDefault: {
                    viewModel.selectDefaultImage()
                    showPhotoSheet = false
                },
                onCancel: { showPhotoSheet = false }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - 생년월일 바텀시트
    private var birthDateSheet: some View {
        BirthDatePickerSheet(
            initialDate: viewModel.birthDate ?? Self.defaultBirthDate,
            onConfirm: { date in
                viewModel.birthDate = date
                showDateSheet = false
            }
        )
    }

    // MARK: - 인생 책 검색 다이얼로그
    private var bookSearchDialog: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { showBookSearch = false }

            VStack(spacing: 16) {
                HStack {
                    Text("나의 인생 책")
                        .pretendardText(size: 20, weight: .semibold)
                        .foregroundColor(Color("grey900"))
                    Spacer()
                    Button(action: { showBookSearch = false }) {
                        ZStack {
                            Circle().fill(Color("grey100")).frame(width: 32, height: 32)
                            Image("ic_x").renderingMode(.template).resizable().scaledToFit()
                                .frame(width: 24, height: 24).foregroundColor(Color("grey900"))
                        }
                    }
                }

                bookSearchInput

                if viewModel.isSearching {
                    ProgressView().tint(Color("main200"))
                        .frame(maxWidth: .infinity).frame(height: 80)
                } else if !viewModel.searchResults.isEmpty {
                    VStack(spacing: 0) {
                        Rectangle().fill(Color("grey100")).frame(height: 1)
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(viewModel.searchResults) { book in
                                    bookResultItem(book)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .frame(maxHeight: 360)
                    }
                } else if !viewModel.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                    VStack(spacing: 0) {
                        Rectangle().fill(Color("grey100")).frame(height: 1)
                        Text("검색 결과가 없습니다.")
                            .pretendardText(size: 16)
                            .foregroundColor(Color("grey600"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                }
            }
            .padding(20)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 20)
        }
    }

    private var bookSearchInput: some View {
        HStack(spacing: 8) {
            Button(action: { viewModel.onSearchQueryChanged() }) {
                Image("ic_search").renderingMode(.template).resizable().scaledToFit()
                    .frame(width: 24, height: 24).foregroundColor(Color("grey500"))
            }
            ZStack(alignment: .leading) {
                if viewModel.searchQuery.isEmpty {
                    Text("도서명, 저자명 검색")
                        .font(.pretendard(size: 16))
                        .foregroundColor(Color("grey500"))
                }
                TextField("", text: $viewModel.searchQuery)
                    .font(.pretendard(size: 16))
                    .foregroundColor(Color("grey900"))
                    .tint(Color("main200"))
                    .submitLabel(.search)
                    .onChange(of: viewModel.searchQuery) { _, _ in viewModel.onSearchQueryChanged() }
            }
            if !viewModel.searchQuery.isEmpty {
                Button(action: { viewModel.searchQuery = ""; viewModel.onSearchQueryChanged() }) {
                    Image("ic_x").renderingMode(.template).resizable().scaledToFit()
                        .frame(width: 16, height: 16).foregroundColor(Color("grey900"))
                }
            }
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color("grey300"), lineWidth: 1)
        )
    }

    private func bookResultItem(_ book: BookItem) -> some View {
        Button(action: {
            viewModel.setLifeBook(book, at: editingSlot)
            showBookSearch = false
        }) {
            HStack(alignment: .top, spacing: 12) {
                KFImage(URL(string: book.image))
                    .resizable().scaledToFit()
                    .frame(width: 64, height: 95)
                    .background(Color("grey200"))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title.stripBookSubtitle())
                        .pretendardText(size: 18, weight: .medium)
                        .foregroundColor(Color("grey800"))
                        .lineLimit(1)
                    Text("\(book.author) (\(book.categoryLabel))")
                        .pretendardText(size: 16)
                        .foregroundColor(Color("grey600"))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
    }

    // MARK: - 뒤로가기
    private func handleBack() {
        if !viewModel.goBack() {
            Task { await logoutToLogin() }
        }
    }

    // 1단계에서 뒤로가기 = 다른 계정으로 로그인. 로그인 직후라 토큰만 있고 온보딩은 미완료 상태이므로,
    // 그냥 pop하면 갈 곳이 없어 다시 온보딩으로 돌아온다. 설정의 로그아웃과 동일한 시퀀스를 태운다.
    private func logoutToLogin() async {
        await PushNotificationManager.shared.deactivateOnLogout()

        if let token = TokenManager.shared.accessToken {
            await container.api.auth.logout(accessToken: token)
        }
        TokenManager.shared.clear()
        container.navigationRouter.hardReset(to: .login)
    }

    // MARK: - 날짜 포맷
    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()

    private static let defaultBirthDate: Date = {
        var comp = DateComponents()
        comp.year = 2000; comp.month = 1; comp.day = 1
        return Calendar(identifier: .gregorian).date(from: comp) ?? Date()
    }()
}

// MARK: - 서브헤드 카드 (안드로이드 OnbSubHeadCard 대응)
private struct OnbSubHeadCard: View {
    var label: String? = nil
    var secondLabel: String? = nil
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                if let label {
                    HStack(spacing: 8) {
                        Text(label).pretendardText(size: 12, weight: .medium).foregroundColor(Color("main200"))
                        if let secondLabel {
                            Text(secondLabel).pretendardText(size: 12).foregroundColor(Color("grey400"))
                        }
                    }
                }
                Text(title).pretendardText(size: 24, weight: .medium).foregroundColor(Color("grey900"))
            }
            Text(description).pretendardText(size: 16).foregroundColor(Color("grey500"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - 스퀴클(squircle) 클립 (안드로이드 SquircleShape 대응)
struct SquircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 128
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 64 * s))
        p.addCurve(to: CGPoint(x: 64 * s, y: 0),
                   control1: CGPoint(x: 0, y: 11.296 * s), control2: CGPoint(x: 11.296 * s, y: 0))
        p.addCurve(to: CGPoint(x: w, y: 64 * s),
                   control1: CGPoint(x: 116.704 * s, y: 0), control2: CGPoint(x: w, y: 11.296 * s))
        p.addCurve(to: CGPoint(x: 64 * s, y: h),
                   control1: CGPoint(x: w, y: 116.704 * s), control2: CGPoint(x: 116.704 * s, y: h))
        p.addCurve(to: CGPoint(x: 0, y: 64 * s),
                   control1: CGPoint(x: 11.296 * s, y: h), control2: CGPoint(x: 0, y: 116.704 * s))
        p.closeSubpath()
        return p
    }
}

#Preview {
    OnboardingView(
        userService: UserService(interceptor: AuthInterceptor(authService: AuthService())),
        groupService: GroupService(interceptor: AuthInterceptor(authService: AuthService()))
    )
    .environmentObject(DIContainer())
}
