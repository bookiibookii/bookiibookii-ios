import PhotosUI
import SwiftUI

struct ProfileChangeView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: ProfileChangeViewModel
    @State private var showRegionSearch = false
    @State private var selectedRegion = RegionSelection.all
    @State private var photoPickerItem: PhotosPickerItem?

    init(userService: UserService) {
        _viewModel = StateObject(wrappedValue: ProfileChangeViewModel(userService: userService))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("grey100").ignoresSafeArea()
            VStack(spacing: 0) {
                CustomNavigationBar(title: "프로필 설정", onBack: { container.navigationRouter.pop() }, rightButton: .none)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        profileSection
                        addressSection
                        exchangeSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, viewModel.hasChanges ? 120 : 24)
                }
            }

            if viewModel.hasChanges && viewModel.canSubmit {
                Button {
                    Task { await viewModel.saveChanges() }
                } label: {
                    Text("수정하기")
                        .font(.pretendard(size: 18, weight: .medium))
                        .foregroundColor(Color("white"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(Color("grey900"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .disabled(viewModel.isSaving)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.load()
            selectedRegion = regionSelection(from: viewModel.exchangeRegion)
        }
        .alert("알림", isPresented: Binding(get: { viewModel.saveMessage != nil }, set: { if !$0 { viewModel.clearSaveMessage() } })) {
            Button("확인") { viewModel.clearSaveMessage() }
        } message: {
            Text(viewModel.saveMessage ?? "")
        }
        .background(
            NavigationLink(isActive: $showRegionSearch) {
                RegionSearchView(preSelected: selectedRegion) { selection in
                    selectedRegion = selection
                    viewModel.exchangeRegion = displayText(for: selection)
                } onClose: {
                    showRegionSearch = false
                }
                .environmentObject(container)
            } label: { EmptyView() }
            .hidden()
        )
    }

    private var profileSection: some View {
        VStack(spacing: 32) {
            ZStack(alignment: .bottomTrailing) {
                profileImage
                    .frame(width: 128, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 38))

                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Image("camera")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: 6)
            }
            .onChange(of: photoPickerItem) { _, newValue in
                viewModel.consumePhotosPickerItem(newValue)
                photoPickerItem = nil
            }

            VStack(alignment: .leading, spacing: 8) {
                NicknameField(
                    text: Binding(
                        get: { viewModel.nickname },
                        set: { viewModel.onNicknameChanged($0) }
                    ),
                    actionTitle: viewModel.nicknameValidationState == .loading ? "확인중..." : "중복확인",
                    isActionEnabled: viewModel.nicknameValidationState != .loading && !viewModel.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    onActionTap: { viewModel.checkNicknameDuplicated() }
                )

                if !viewModel.nicknameValidationState.message.isEmpty {
                    Text(viewModel.nicknameValidationState.message)
                        .font(.pretendard(size: 12, weight: .regular))
                        .foregroundColor(viewModel.nicknameValidationState.isAvailable ? Color.green : Color.red)
                        .padding(.horizontal, 8)
                }
            }
        }
    }

    @ViewBuilder
    private var profileImage: some View {
        if let selected = viewModel.selectedImage {
            Image(uiImage: selected)
                .resizable()
                .scaledToFill()
        } else if let url = viewModel.profileImageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    RoundedRectangle(cornerRadius: 38)
                        .fill(Color("grey300"))
                }
            }
        } else {
            RoundedRectangle(cornerRadius: 38)
                .fill(Color("grey300"))
        }
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("배송지 정보").font(.pretendard(size: 16, weight: .regular)).foregroundColor(Color("grey900"))
            BasicField(text: $viewModel.name, placeholder: "이름")
            BasicField(
                text: Binding(
                    get: { viewModel.phone },
                    set: { viewModel.updatePhone($0) }
                ),
                placeholder: "연락처"
            )
            SearchField(text: $viewModel.zipCode, placeholder: "우편 번호", actionTitle: "검색하기")
            BasicField(text: $viewModel.address, placeholder: "주소")
            BasicField(text: $viewModel.detailAddress, placeholder: "상세주소")
        }
    }

    private var exchangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("직접 교환 정보").font(.pretendard(size: 16, weight: .regular)).foregroundColor(Color("grey900"))
            SearchField(text: $viewModel.exchangeRegion, placeholder: "시/도 시/군/구", actionTitle: "검색하기", onActionTap: { showRegionSearch = true })
        }
    }

    private func displayText(for selection: RegionSelection) -> String {
        if selection.isAll { return "" }
        if selection.isCityAll { return selection.city }
        return "\(selection.city) " + selection.districts.joined(separator: " · ")
    }

    private func regionSelection(from text: String) -> RegionSelection {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .all }
        let cityNames = Set(RegionData.cities.map(\.name))
        let components = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
        guard let city = components.first, cityNames.contains(city) else { return .all }
        guard components.count > 1 else { return RegionSelection(city: city, districts: []) }
        let districts = components[1].split(separator: "·").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return RegionSelection(city: city, districts: districts)
    }
}

private struct BasicField: View {
    @Binding var text: String
    let placeholder: String
    var body: some View {
        TextField(placeholder, text: $text)
            .font(.pretendard(size: 15, weight: .regular))
            .foregroundColor(Color("grey900"))
            .padding(.horizontal, 20)
            .frame(height: 48)
            .background(Color("white"))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color("grey300"), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct NicknameField: View {
    @Binding var text: String
    let actionTitle: String
    let isActionEnabled: Bool
    var onActionTap: () -> Void = {}
    var body: some View {
        HStack {
            TextField("텍스트 입력 전", text: $text)
                .font(.pretendard(size: 15, weight: .regular))
                .foregroundColor(Color("grey900"))
                .padding(.leading, 20)
            Button(actionTitle) { onActionTap() }
                .font(.pretendard(size: 14, weight: .medium))
                .foregroundColor(Color("grey100"))
                .frame(width: 100, height: 40)
                .background(isActionEnabled ? Color("grey900") : Color("grey300"))
                .clipShape(Capsule())
                .padding(.trailing, 4)
                .disabled(!isActionEnabled)
        }
        .frame(height: 48)
        .background(Color("white"))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("grey300"), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    let actionTitle: String
    var onActionTap: () -> Void = {}
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .font(.pretendard(size: 15, weight: .regular))
                .foregroundColor(Color("grey900"))
                .padding(.leading, 20)
            Button(actionTitle) { onActionTap() }
                .font(.pretendard(size: 14, weight: .medium))
                .foregroundColor(Color("grey100"))
                .frame(width: 100, height: 40)
                .background(Color("grey900"))
                .clipShape(Capsule())
                .padding(.trailing, 4)
        }
        .frame(height: 48)
        .background(Color("white"))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("grey300"), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ProfileChangeView(userService: UserService(interceptor: AuthInterceptor(authService: AuthService())))
        .environmentObject(DIContainer())
}
