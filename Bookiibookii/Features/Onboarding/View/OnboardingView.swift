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
    @State private var bookSearchSlot: BookSlot?

    private let highlightBg = Color(red: 1.0, green: 234/255, blue: 219/255)

    init(userService: UserService, groupService: GroupService) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            userService: userService, groupService: groupService
        ))
    }

    private struct BookSlot: Identifiable { let id: Int }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                CustomNavigationBar(title: "온보딩", onBack: handleBack, rightButton: .none)

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
        .onChange(of: photoPickerItem) { _, item in
            guard item != nil else { return }
            viewModel.consumePhotosPickerItem(item)
            photoPickerItem = nil
            showPhotoSheet = false
        }
        .onChange(of: viewModel.isCompleted) { _, completed in
            guard completed else { return }
            container.navigationRouter.hardReset(to: .mainTab)
        }
        .sheet(isPresented: $showPhotoSheet) {
            photoBottomSheet
                .presentationDetents([.height(296)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showDateSheet) {
            birthDateSheet
                .presentationDetents([.height(340)])
                .presentationCornerRadius(24)
        }
        .sheet(item: $bookSearchSlot) { slot in
            bookSearchSheet(slot: slot.id)
                .presentationDetents([.large])
                .presentationCornerRadius(24)
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
    }

    // MARK: - 진행 바 (4단계)
    private var progressSection: some View {
        HStack(spacing: 12) {
            ForEach(1...OnboardingViewModel.totalSteps, id: \.self) { step in
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

                if viewModel.currentStep == 3 {
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
        case 1: return "만나서 반가워요!"
        case 2: return "나의 인생 책을\n골라주세요"
        case 3: return "마음에 콕! 박히는\n문장을 만났을 때"
        case 4: return "나를 표현하는\n한 문장을 적어주세요"
        default: return ""
        }
    }

    private var questionSubtitle: String {
        switch viewModel.currentStep {
        case 1: return "프로필 정보를 입력해주세요."
        case 2: return "최대 3권까지 선택할 수 있어요."
        case 3: return "나의 평소 독서 습관은 어떤가요?"
        case 4: return "선택 항목이에요. 건너뛰어도 좋아요."
        default: return ""
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
        VStack(spacing: 24) {
            profileImageButton
            nicknameInputSection
            if viewModel.nicknameState.showsValidation {
                validationSection
            }
            genderSection
            birthSection
        }
        .padding(.horizontal, 24)
    }

    private var profileImageButton: some View {
        Button(action: { showPhotoSheet = true }) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Image("ic_profile_placeholder").resizable().scaledToFill()
                    }
                }
                .frame(width: 128, height: 128)
                .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))

                ZStack {
                    Circle().fill(Color("grey600")).frame(width: 32, height: 32)
                    Image("ic_camera")
                        .renderingMode(.template).resizable().scaledToFit()
                        .frame(width: 20, height: 20).foregroundColor(.white)
                }
            }
        }
    }

    private var nicknameInputSection: some View {
        HStack(spacing: 0) {
            TextField("닉네임을 입력해주세요", text: $viewModel.nickname)
                .font(.system(size: 15))
                .foregroundColor(Color("grey900"))
                .tint(Color("main200"))
                .onChange(of: viewModel.nickname) { _, newValue in
                    if newValue.count > 10 { viewModel.nickname = String(newValue.prefix(10)) }
                    viewModel.onNicknameChanged()
                }
                .padding(.leading, 20)

            Button(action: viewModel.checkNickname) {
                Group {
                    if case .loading = viewModel.nicknameState {
                        ProgressView().tint(Color("grey100"))
                    } else {
                        Text("중복확인")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("grey100"))
                    }
                }
                .frame(width: 100, height: 40)
                .background(viewModel.nickname.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color("grey300") : Color("grey900"))
                .clipShape(Capsule())
            }
            .disabled(viewModel.nickname.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.trailing, 5)
            .padding(.vertical, 4)
        }
        .frame(height: 48)
        .background(Color.white)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 20, bottomLeadingRadius: 20,
            bottomTrailingRadius: 30, topTrailingRadius: 30, style: .continuous))
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 20, bottomLeadingRadius: 20,
                bottomTrailingRadius: 30, topTrailingRadius: 30, style: .continuous)
            .strokeBorder(Color("grey300"), lineWidth: 0.5)
        )
    }

    private var validationSection: some View {
        let style = viewModel.nicknameState.validationStyle
        return HStack(spacing: 8) {
            Image(style.iconName)
                .renderingMode(.template).resizable().scaledToFit()
                .frame(width: 24, height: 24).foregroundColor(style.textColor)
            Text(viewModel.nicknameState.message)
                .font(.system(size: 14)).foregroundColor(style.textColor)
            Spacer()
        }
        .padding(16)
        .background(style.bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(style.borderColor, lineWidth: 1)
        )
    }

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("성별")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color("grey900"))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                ForEach(Gender.allCases, id: \.self) { item in
                    let isSelected = viewModel.gender == item
                    Button(action: { viewModel.gender = item }) {
                        Text(item.displayName)
                            .font(.system(size: 15))
                            .foregroundColor(isSelected ? Color("main200") : Color("grey900"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(isSelected ? highlightBg : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(isSelected ? Color("main200") : Color("grey200"), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    private var birthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("생년월일")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color("grey900"))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { showDateSheet = true }) {
                HStack {
                    Text(viewModel.birthDate.map(Self.displayFormatter.string(from:)) ?? "생년월일을 선택해주세요")
                        .font(.system(size: 15))
                        .foregroundColor(viewModel.birthDate == nil ? Color("grey400") : Color("grey900"))
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(Color("grey500"))
                }
                .padding(.horizontal, 20)
                .frame(height: 48)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color("grey200"), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Step 2: 인생책
    private var lifeBooksStep: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { slot in
                bookSlotCard(slot: slot)
            }
        }
        .padding(.horizontal, 24)
    }

    private func bookSlotCard(slot: Int) -> some View {
        let book = viewModel.lifeBooks[slot]
        return Button(action: {
            if book == nil { bookSearchSlot = BookSlot(id: slot) }
        }) {
            HStack(spacing: 16) {
                if let book {
                    KFImage(URL(string: book.image))
                        .resizable().scaledToFill()
                        .frame(width: 56, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(book.title).font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color("grey900")).lineLimit(2)
                        Text(book.author).font(.system(size: 13))
                            .foregroundColor(Color("grey500")).lineLimit(1)
                    }
                    Spacer()
                    Button(action: { viewModel.removeBook(at: slot) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("grey500"))
                    }
                } else {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(Color("grey400"))
                    Text("인생 책 추가하기")
                        .font(.system(size: 15))
                        .foregroundColor(Color("grey400"))
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 104)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(book == nil ? Color("grey200") : Color("main200"), lineWidth: 1)
            )
        }
    }

    // MARK: - Step 3: 기록 방식
    private var recordMethodStep: some View {
        VStack(spacing: 12) {
            methodListCard
            methodSpecialCard(
                method: .any,
                isSelected: viewModel.recordMethods.contains(.any),
                action: { viewModel.toggleMethod(.any) }
            )
            unknownMethodCard
        }
        .padding(.horizontal, 24)
    }

    private var methodListCard: some View {
        let methods: [RecordMethod] = [.memo, .postit, .photo]
        return VStack(spacing: 0) {
            ForEach(0..<methods.count, id: \.self) { index in
                let method = methods[index]
                let isSelected = viewModel.recordMethods.contains(method)
                Button(action: { viewModel.toggleMethod(method) }) {
                    HStack(spacing: 12) {
                        methodIconCircle(name: method.iconSystemName)
                        Text(method.displayName)
                            .font(.system(size: 15))
                            .foregroundColor(isSelected ? Color("main200") : Color("grey900"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                if index != methods.count - 1 {
                    Rectangle().fill(Color("grey200")).frame(height: 1).padding(.horizontal, 8)
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

    private func methodSpecialCard(method: RecordMethod, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                methodIconCircle(name: method.iconSystemName)
                Text(method.displayName)
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

    private var unknownMethodCard: some View {
        Button(action: { viewModel.toggleUnknownMethod() }) {
            HStack(spacing: 12) {
                methodIconCircle(name: "questionmark")
                Text("잘 모르겠어요.")
                    .font(.system(size: 15))
                    .foregroundColor(viewModel.isUnknownMethod ? Color("main200") : Color("grey900"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(viewModel.isUnknownMethod ? Color("main200") : Color("grey200"), lineWidth: 1)
            )
        }
    }

    private func methodIconCircle(name: String) -> some View {
        ZStack {
            Circle().fill(highlightBg).frame(width: 28, height: 28)
            Image(systemName: name)
                .font(.system(size: 13))
                .foregroundColor(Color("main200"))
        }
    }

    // MARK: - Step 4: 자기소개
    private var introStep: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if viewModel.introduction.isEmpty {
                    Text("나를 표현하는 한 문장을 적어주세요.")
                        .font(.system(size: 15))
                        .foregroundColor(Color("grey400"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                }
                TextEditor(text: $viewModel.introduction)
                    .font(.system(size: 15))
                    .foregroundColor(Color("grey900"))
                    .tint(Color("main200"))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(height: 120)
                    .onChange(of: viewModel.introduction) { _, newValue in
                        if newValue.count > OnboardingViewModel.introMaxLength {
                            viewModel.introduction = String(newValue.prefix(OnboardingViewModel.introMaxLength))
                        }
                    }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color("grey200"), lineWidth: 1)
            )

            Text("\(viewModel.introduction.count)/\(OnboardingViewModel.introMaxLength)")
                .font(.system(size: 13))
                .foregroundColor(Color("grey400"))
        }
        .padding(.horizontal, 24)
    }

    // MARK: - 다음/완료 버튼
    private var footerButton: some View {
        FooterButton(
            text: viewModel.isLastStep ? "완료" : "다음",
            style: .dark,
            enabled: viewModel.canGoNext,
            isLoading: viewModel.isSubmitting,
            action: viewModel.goNext
        )
    }

    // MARK: - 사진 선택 바텀시트
    private var photoBottomSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            RoundedRectangle(cornerRadius: 300)
                .fill(Color("grey200")).frame(width: 44, height: 4)
                .frame(maxWidth: .infinity)

            Text("프로필 사진 변경")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))

            VStack(spacing: 12) {
                // 사진 촬영 (카메라)
                Button(action: {
                    showPhotoSheet = false
                    // 바텀시트 닫힘과 카메라 표시 충돌 방지
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showCamera = true }
                }) {
                    HStack(spacing: 10) {
                        Image("ic_camera")
                            .renderingMode(.template).resizable().scaledToFit()
                            .frame(width: 24, height: 24).foregroundColor(Color("grey100"))
                        Text("사진 촬영")
                            .font(.system(size: 15)).foregroundColor(Color("grey100"))
                    }
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                // 앨범에서 선택
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    HStack(spacing: 10) {
                        Image("ic_album")
                            .renderingMode(.template).resizable().scaledToFit()
                            .frame(width: 24, height: 24).foregroundColor(Color("grey900"))
                        Text("앨범에서 선택")
                            .font(.system(size: 15)).foregroundColor(Color("grey900"))
                    }
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color("grey200"), lineWidth: 1)
                    )
                }
            }
        }
        .padding(24)
        .background(Color.white)
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

    // MARK: - 인생책 검색 바텀시트
    private func bookSearchSheet(slot: Int) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color("grey400"))
                TextField("책 제목을 검색해주세요", text: $viewModel.searchQuery)
                    .font(.system(size: 15))
                    .tint(Color("main200"))
                    .submitLabel(.search)
                    .onChange(of: viewModel.searchQuery) { _, _ in viewModel.onSearchQueryChanged() }
                if !viewModel.searchQuery.isEmpty {
                    Button(action: { viewModel.searchQuery = ""; viewModel.onSearchQueryChanged() }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(Color("grey300"))
                    }
                }
            }
            .padding(.horizontal, 16).frame(height: 48)
            .background(Color("grey100"))
            .clipShape(Capsule())
            .padding(20)

            if viewModel.isSearching {
                Spacer(); ProgressView().tint(Color("main200")); Spacer()
            } else if viewModel.searchResults.isEmpty {
                Spacer()
                Text(viewModel.searchQuery.isEmpty ? "책을 검색해보세요" : "검색 결과가 없어요")
                    .font(.system(size: 14)).foregroundColor(Color("grey400"))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.searchResults) { book in
                            Button(action: {
                                viewModel.selectBook(book, at: slot)
                                bookSearchSlot = nil
                            }) {
                                HStack(spacing: 12) {
                                    KFImage(URL(string: book.image))
                                        .resizable().scaledToFill()
                                        .frame(width: 44, height: 62)
                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(book.title).font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color("grey900")).lineLimit(2)
                                        Text(book.author).font(.system(size: 12))
                                            .foregroundColor(Color("grey500")).lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 20).padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                        }
                    }
                }
            }
        }
        .background(Color.white)
    }

    // MARK: - 뒤로가기
    private func handleBack() {
        if !viewModel.goBack() {
            container.navigationRouter.pop()
        }
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

// MARK: - 생년월일 휠 피커 시트
private struct BirthDatePickerSheet: View {
    let initialDate: Date
    let onConfirm: (Date) -> Void
    @State private var date: Date

    init(initialDate: Date, onConfirm: @escaping (Date) -> Void) {
        self.initialDate = initialDate
        self.onConfirm = onConfirm
        _date = State(initialValue: initialDate)
    }

    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 300)
                .fill(Color("grey200")).frame(width: 44, height: 4)
                .padding(.top, 12)

            Text("생년월일")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color("grey900"))

            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ko_KR"))

            BottomSheetTwoBtnShort(text: "확인", style: .dark, action: { onConfirm(date) })
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(Color.white)
    }
}

#Preview {
    OnboardingView(
        userService: UserService(interceptor: AuthInterceptor(authService: AuthService())),
        groupService: GroupService(interceptor: AuthInterceptor(authService: AuthService()))
    )
    .environmentObject(DIContainer())
}
