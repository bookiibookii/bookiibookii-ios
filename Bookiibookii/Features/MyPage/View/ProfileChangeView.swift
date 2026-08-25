import PhotosUI
import SwiftUI
import Kingfisher

struct ProfileChangeView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: ProfileChangeViewModel
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showPhotoSheet = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showDateSheet = false

    init(userService: UserService) {
        _viewModel = StateObject(wrappedValue: ProfileChangeViewModel(userService: userService))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        profileImageSection
                            .padding(.top, 24)

                        VStack(spacing: 32) {
                            nicknameField
                            genderSection
                            birthSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120)
                }
            }

            saveButton

            if showPhotoSheet {
                photoSheetOverlay
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showPhotoSheet)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.load() }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: photoPickerItem) { _, item in
            guard let item else { return }
            Task {
                await viewModel.loadProfilePhoto(from: item)
                photoPickerItem = nil
            }
        }
        .sheet(isPresented: $showDateSheet) {
            BirthDatePickerSheet(
                initialDate: viewModel.birthDate ?? Self.defaultBirthDate,
                onConfirm: { date in
                    viewModel.birthDate = date
                    showDateSheet = false
                }
            )
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(20)
        }
        .cameraPicker(isPresented: $showCamera) { image in
            viewModel.setCapturedImage(image)
        }
        .alert("알림", isPresented: Binding(
            get: { viewModel.saveMessage != nil },
            set: { if !$0 { viewModel.clearSaveMessage() } }
        )) {
            Button("확인") {
                let shouldPop = viewModel.didSaveSuccessfully
                viewModel.clearSaveMessage()
                if shouldPop {
                    container.navigationRouter.pop()
                }
            }
        } message: {
            Text(viewModel.saveMessage ?? "")
        }
        .alert("사진을 불러오지 못했습니다", isPresented: Binding(
            get: { viewModel.photoImportError != nil },
            set: { if !$0 { viewModel.photoImportError = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.photoImportError = nil }
        } message: {
            Text(viewModel.photoImportError ?? "")
        }
    }

    // MARK: - Header

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

            Text("내 프로필")
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color("grey200")).frame(height: 1)
        }
    }

    // MARK: - Profile Image

    private var profileImageSection: some View {
        Button { showPhotoSheet = true } label: {
            ZStack(alignment: .bottomTrailing) {
                profileImage
                    .frame(width: 128, height: 128)
                    .clipShape(ProfileSquircle())

                ZStack {
                    Circle()
                        .fill(Color("grey600"))
                        .frame(width: 32, height: 32)
                    Image("ic_camera")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("white"))
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var profileImage: some View {
        if viewModel.isUsingDefaultImage {
            profilePlaceholder
        } else if let selected = viewModel.selectedImage {
            Image(uiImage: selected)
                .resizable()
                .scaledToFill()
                } else if let url = viewModel.profileImageURL {
            KFImage(url)
                .placeholder { profilePlaceholder }
                .resizable()
                .scaledToFill()
                .id(url.absoluteString)
        } else {
            profilePlaceholder
        }
    }

    private var photoSheetOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { showPhotoSheet = false }

            ProfilePhotoBottomSheet(
                onTakePhoto: {
                    showPhotoSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showCamera = true
                    }
                },
                onSelectAlbum: {
                    showPhotoSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showPhotoPicker = true
                    }
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

    private var profilePlaceholder: some View {
        Image("ic_profile_placeholder")
            .resizable()
            .scaledToFill()
    }

    // MARK: - Fields

    private var nicknameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("닉네임")

            HStack(spacing: 8) {
                TextField("닉네임을 입력해주세요", text: Binding(
                    get: { viewModel.nickname },
                    set: { viewModel.onNicknameChanged($0) }
                ))
                .pretendardText(size: 15, weight: .medium)
                .foregroundColor(Color("grey800"))
                .tint(Color("main200"))

                nicknameCheckButton
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(Color("white"))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("grey300"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if !viewModel.nicknameValidationState.message.isEmpty {
                Text(viewModel.nicknameValidationState.message)
                    .pretendardText(size: 12, weight: .regular)
                    .foregroundColor(
                        viewModel.nicknameValidationState.isAvailable
                            ? Color("pointGreen200")
                            : Color("pointRed")
                    )
            }
        }
    }

    private var nicknameCheckButton: some View {
        let isLoading = viewModel.nicknameValidationState == .loading
        let enabled = viewModel.isNicknameCheckEnabled && !isLoading
        return Button {
            viewModel.checkNicknameDuplicated()
        } label: {
            Group {
                if isLoading {
                    ProgressView().tint(Color("grey100"))
                } else {
                    Text("중복 확인")
                        .pretendardText(size: 14, weight: .medium)
                        .foregroundColor(enabled ? Color("white") : Color("grey100"))
                }
            }
            .frame(height: 40)
            .padding(.horizontal, 16)
            .background(enabled ? Color("grey900") : Color("grey400"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("성별")

            HStack(spacing: 12) {
                genderButton(.female, width: 119)
                genderButton(.male, width: 119)
                genderButton(.unspecified, width: nil)
            }
            .frame(height: 48)
        }
    }

    private func genderButton(_ item: Gender, width: CGFloat?) -> some View {
        let isSelected = viewModel.gender == item
        return Button { viewModel.gender = item } label: {
            Text(item.displayName)
                .pretendardText(size: 15, weight: .regular)
                .foregroundColor(isSelected ? Color("main200") : Color("grey500"))
                .frame(maxWidth: width == nil ? .infinity : nil)
                .frame(width: width)
                .frame(maxHeight: .infinity)
                .background(isSelected ? Color("main100") : Color("white"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color("main105") : Color("grey300"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var birthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("생년월일")

            Button { showDateSheet = true } label: {
                HStack {
                    Text(birthDisplayText)
                        .pretendardText(size: 15, weight: .medium)
                        .foregroundColor(viewModel.birthDate == nil ? Color("grey500") : Color("grey800"))
                    Spacer()
                    Image("ic_calender")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color("white"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("grey300"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    private var birthDisplayText: String {
        guard let date = viewModel.birthDate else { return "0000.00.00." }
        return Self.displayFormatter.string(from: date) + "."
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .pretendardText(size: 16, weight: .medium)
            .foregroundColor(Color("grey900"))
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            Task { await viewModel.saveChanges() }
        } label: {
            Text("수정")
                .pretendardText(size: 18, weight: .medium)
                .foregroundColor(Color("white"))
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(Color("grey900"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit || !viewModel.hasChanges || viewModel.isSaving)
        .opacity(viewModel.canSubmit && viewModel.hasChanges && !viewModel.isSaving ? 1 : 0.45)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    private static let defaultBirthDate: Date = {
        var comp = DateComponents()
        comp.year = 2000
        comp.month = 1
        comp.day = 1
        return Calendar(identifier: .gregorian).date(from: comp) ?? Date()
    }()
}

#Preview {
    ProfileChangeView(userService: UserService(interceptor: AuthInterceptor(authService: AuthService())))
        .environmentObject(DIContainer())
}
