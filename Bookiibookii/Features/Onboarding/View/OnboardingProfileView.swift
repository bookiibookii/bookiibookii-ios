import Combine
import PhotosUI
import SwiftUI

struct OnboardingProfileView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: OnboardingProfileViewModel

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showPhotoSheet = false

    init(userService: UserService) {
        _viewModel = StateObject(wrappedValue: OnboardingProfileViewModel(userService: userService))
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                logoSection

                profileImageSection
                    .padding(.top, 36)

                nicknameInputSection
                    .padding(.top, 40)
                    .padding(.horizontal, 24)

                if viewModel.nicknameState.showsValidation {
                    validationSection
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                }

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
        .onChange(of: viewModel.readyToAdvance) { _, data in
            guard let data else { return }
            container.navigationRouter.push(to: .onboardingSteps(name: data.name, s3Key: data.s3Key))
        }
        .sheet(isPresented: $showPhotoSheet) {
            photoBottomSheet
                .presentationDetents([.height(232)])
                .presentationDragIndicator(.hidden)
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
    }

    // MARK: - 로고
    private var logoSection: some View {
        Image("ic_bookii_text")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 204, height: 22)
            .foregroundColor(Color("main200"))
            .padding(.top, 36)
    }

    // MARK: - 프로필 이미지
    private var profileImageSection: some View {
        Button(action: { showPhotoSheet = true }) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image("ic_profile_placeholder")
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(width: 128, height: 128)
                .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))

                ZStack {
                    Circle()
                        .fill(Color("grey600"))
                        .frame(width: 32, height: 32)
                    Image("ic_camera")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - 닉네임 입력
    private var nicknameInputSection: some View {
        HStack(spacing: 0) {
            TextField("닉네임을 입력해주세요", text: $viewModel.nickname)
                .font(.system(size: 15))
                .foregroundColor(Color("grey900"))
                .tint(Color("main200"))
                .onChange(of: viewModel.nickname) { _, _ in
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
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20, bottomLeadingRadius: 20,
                bottomTrailingRadius: 30, topTrailingRadius: 30,
                style: .continuous
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 20, bottomLeadingRadius: 20,
                bottomTrailingRadius: 30, topTrailingRadius: 30,
                style: .continuous
            )
            .strokeBorder(Color("grey300"), lineWidth: 0.5)
        )
    }

    // MARK: - 유효성 메시지
    private var validationSection: some View {
        let style = viewModel.nicknameState.validationStyle
        return HStack(spacing: 8) {
            Image(style.iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(style.textColor)

            Text(viewModel.nicknameState.message)
                .font(.system(size: 14))
                .foregroundColor(style.textColor)

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

    // MARK: - 다음 버튼
    private var footerButton: some View {
        Button(action: viewModel.complete) {
            Group {
                if viewModel.isCompleting {
                    ProgressView().tint(.white)
                } else {
                    Text("다음")
                        .font(.system(size: 18, weight: viewModel.nicknameState.isAvailable ? .medium : .regular))
                        .foregroundColor(viewModel.nicknameState.isAvailable ? .white : Color("grey500"))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(viewModel.nicknameState.isAvailable ? Color("grey900") : Color("grey200"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .disabled(!viewModel.nicknameState.isAvailable || viewModel.isCompleting)
    }

    // MARK: - 사진 선택 바텀시트
    private var photoBottomSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            RoundedRectangle(cornerRadius: 300)
                .fill(Color("grey200"))
                .frame(width: 44, height: 4)
                .frame(maxWidth: .infinity)

            Text("프로필 사진 변경")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))

            VStack(spacing: 12) {
                // 사진 촬영 (현재 미지원, 추후 구현)
                Button(action: { showPhotoSheet = false }) {
                    HStack(spacing: 10) {
                        Image("ic_camera")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color("grey100"))
                        Text("사진 촬영")
                            .font(.system(size: 15))
                            .foregroundColor(Color("grey100"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                // 앨범에서 선택
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    HStack(spacing: 10) {
                        Image("ic_album")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color("grey900"))
                        Text("앨범에서 선택")
                            .font(.system(size: 15))
                            .foregroundColor(Color("grey900"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
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
}

#Preview {
    OnboardingProfileView(userService: UserService(interceptor: AuthInterceptor(authService: AuthService())))
        .environmentObject(DIContainer())
}
