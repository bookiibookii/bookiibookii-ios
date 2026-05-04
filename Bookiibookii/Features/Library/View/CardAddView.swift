import PhotosUI
import SwiftUI
import UIKit

struct CardAddView: View {
    private static let photoPreviewWidth: CGFloat = 364
    private static let photoPreviewHeight: CGFloat = 400

    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: CardAddViewModel

    @State private var showAddPicker = false
    @State private var addPickerItem: PhotosPickerItem?

    @State private var showReplacePicker = false
    @State private var replacePickerItem: PhotosPickerItem?
    @State private var replaceHadSelection = false

    init(userBookId: Int, libraryService: LibraryService) {
        _viewModel = StateObject(wrappedValue: CardAddViewModel(userBookId: userBookId, libraryService: libraryService))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        photoSection
                        fieldLabel("페이지")
                        TextField("", text: $viewModel.pageText)
                            .keyboardType(.numberPad)
                            .font(.pretendard(size: 14, weight: .regular))
                            .foregroundColor(Color("grey900"))
                            .padding(.horizontal, 20)
                            .frame(height: 48)
                            .background(Color("white"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color("grey300"), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        fieldLabel("메모")
                        ZStack(alignment: .topLeading) {
                            if viewModel.memo.isEmpty {
                                Text("메모를 입력해 주세요 (선택)")
                                    .font(.pretendard(size: 14, weight: .regular))
                                    .foregroundColor(Color("grey400"))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 20)
                            }
                            TextEditor(text: $viewModel.memo)
                                .font(.pretendard(size: 14, weight: .regular))
                                .foregroundColor(Color("grey900"))
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(minHeight: 120)
                        }
                        .background(Color("white"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color("grey300"), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }

            submitButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

            if viewModel.isUploading || viewModel.isSubmitting {
                Color.black.opacity(0.12).ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .photosPicker(isPresented: $showAddPicker, selection: $addPickerItem, matching: .images)
        .onChange(of: addPickerItem) { _, new in
            guard let new else { return }
            Task {
                await consumePickerItem(new, isReplace: false)
                addPickerItem = nil
            }
        }
        .photosPicker(isPresented: $showReplacePicker, selection: $replacePickerItem, matching: .images)
        .onChange(of: replacePickerItem) { _, new in
            guard let new else { return }
            replaceHadSelection = true
            Task {
                await consumePickerItem(new, isReplace: true)
                replacePickerItem = nil
            }
        }
        .onChange(of: showReplacePicker) { old, new in
            guard old && !new else { return }
            if !replaceHadSelection {
                viewModel.restoreReplaceBackupIfNeeded()
            }
            replaceHadSelection = false
        }
        .alert("알림", isPresented: Binding(
            get: { viewModel.toastMessage != nil },
            set: { if !$0 { viewModel.toastMessage = nil } }
        )) {
            Button("확인", role: .cancel) { viewModel.toastMessage = nil }
        } message: {
            Text(viewModel.toastMessage ?? "")
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        HStack {
            Button {
                container.navigationRouter.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("grey900"))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()
            Text("카드 추가")
                .font(.pretendard(size: 20, weight: .medium))
                .foregroundColor(Color("grey900"))
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

    private var photoSection: some View {
        Group {
            if let data = viewModel.previewImageData,
               let uiImage = UIImage(data: data) {
                HStack {
                    Spacer(minLength: 0)
                    ZStack(alignment: .topTrailing) {
                        Color("grey100")
                            .frame(width: Self.photoPreviewWidth, height: Self.photoPreviewHeight)

                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: Self.photoPreviewWidth, height: Self.photoPreviewHeight)

                        Button {
                            viewModel.beginReplacePhotoSession()
                            replaceHadSelection = false
                            showReplacePicker = true
                        } label: {
                            Image("pencil")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .padding(4)
                                .frame(width: 32, height: 32)
                                .background(Color("white"))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color("grey200"), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .padding(16)
                    }
                    .frame(width: Self.photoPreviewWidth, height: Self.photoPreviewHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("grey300"), lineWidth: 1)
                    )
                    Spacer(minLength: 0)
                }
            } else {
                Button {
                    showAddPicker = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(Color("grey800"))
                        Text("사진 업로드")
                            .font(.pretendard(size: 14, weight: .regular))
                            .foregroundColor(Color("grey800"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color("grey200"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("grey300"), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.pretendard(size: 16, weight: .regular))
            .foregroundColor(Color("grey900"))
    }

    private var submitButton: some View {
        Button {
            Task {
                let ok = await viewModel.submit()
                if ok {
                    container.navigationRouter.pop()
                }
            }
        } label: {
            Text("등록하기")
                .font(.pretendard(size: 18, weight: viewModel.canSubmit ? .medium : .regular))
                .foregroundColor(viewModel.canSubmit ? Color("grey100") : Color("grey500"))
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(viewModel.canSubmit ? Color("grey900") : Color("grey200"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit)
    }

    private func consumePickerItem(_ item: PhotosPickerItem, isReplace: Bool) async {
        do {
            let jpeg = try await PhotosPickerImageLoader.jpegData(from: item)
            await viewModel.handlePickedJPEG(jpeg, isReplace: isReplace)
        } catch {
            viewModel.toastMessage = error.localizedDescription
        }
    }
}

#Preview {
    CardAddView(
        userBookId: 1,
        libraryService: LibraryService(interceptor: AuthInterceptor(authService: AuthService()))
    )
    .environmentObject(DIContainer())
}
