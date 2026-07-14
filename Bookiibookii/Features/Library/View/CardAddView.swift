import PhotosUI
import SwiftUI
import UIKit

struct CardAddView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: CardAddViewModel

    @State private var showAddPicker = false
    @State private var addPickerItem: PhotosPickerItem?
    @State private var showReplacePicker = false
    @State private var replacePickerItem: PhotosPickerItem?
    @State private var replaceHadSelection = false
    @State private var isPreviewPresented = false

    init(
        mode: CardAddMode,
        bookTitle: String,
        libraryService: LibraryService,
        userService: UserService
    ) {
        _viewModel = StateObject(
            wrappedValue: CardAddViewModel(
                mode: mode,
                bookTitle: bookTitle,
                libraryService: libraryService,
                userService: userService
            )
        )
    }

    init(
        userBookId: Int,
        cardType: LibraryCardType,
        bookTitle: String,
        libraryService: LibraryService,
        userService: UserService
    ) {
        self.init(
            mode: .create(userBookId: userBookId, cardType: cardType),
            bookTitle: bookTitle,
            libraryService: libraryService,
            userService: userService
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("uiBg").ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    formContent
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 104)
                }
            }

            footer

            if viewModel.isUploading || viewModel.isSubmitting {
                Color.black.opacity(0.12).ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.2)
            }

            if isPreviewPresented {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPreviewPresented = false
                    }

                cardPreview
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .center
                    )
            }
        }
        .photosPicker(
            isPresented: $showAddPicker,
            selection: $addPickerItem,
            matching: .images
        )
        .onChange(of: addPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await consumePickerItem(newItem, isReplace: false)
                addPickerItem = nil
            }
        }
        .photosPicker(
            isPresented: $showReplacePicker,
            selection: $replacePickerItem,
            matching: .images
        )
        .onChange(of: replacePickerItem) { _, newItem in
            guard let newItem else { return }
            replaceHadSelection = true
            Task {
                await consumePickerItem(newItem, isReplace: true)
                replacePickerItem = nil
            }
        }
        .onChange(of: showReplacePicker) { oldValue, newValue in
            guard oldValue && !newValue else { return }
            if !replaceHadSelection {
                viewModel.restoreReplaceBackupIfNeeded()
            }
            replaceHadSelection = false
        }
        .onChange(of: viewModel.pageText) { _, value in
            let filtered = value.filter(\.isNumber)
            if filtered != value {
                viewModel.pageText = filtered
            }
        }
        .onChange(of: viewModel.quotation) { _, value in
            if value.count > 140 {
                viewModel.quotation = String(value.prefix(140))
            }
        }
        .onChange(of: viewModel.memo) { _, value in
            if value.count > 110 {
                viewModel.memo = String(value.prefix(110))
            }
        }
        .alert(
            "알림",
            isPresented: Binding(
                get: { viewModel.toastMessage != nil },
                set: { if !$0 { viewModel.toastMessage = nil } }
            )
        ) {
            Button("확인", role: .cancel) {
                viewModel.toastMessage = nil
            }
        } message: {
            Text(viewModel.toastMessage ?? "")
        }
        .task {
            await viewModel.loadEditInitialStateIfNeeded()
            await viewModel.loadAuthorIdentifier()
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private var formContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.cardType == .image {
                photoSection
                pageField
                memoField
            } else {
                quotationField
                pageField
                memoField
            }
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            HStack {
                Button {
                    container.navigationRouter.pop()
                } label: {
                    Image("ic_back")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
            }
            .frame(width: 88)

            Spacer(minLength: 0)

            Text(viewModel.navigationTitle)
                .pretendardText(size: 20, weight: .medium)
                .foregroundColor(Color("grey900"))

            Spacer(minLength: 0)

            Color.clear
                .frame(width: 88, height: 40)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color("white"))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("grey200"))
                .frame(height: 1)
        }
    }

    private var photoSection: some View {
        Group {
            if let data = viewModel.previewImageData,
               let image = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 442)
                        .clipped()

                    Button {
                        viewModel.beginReplacePhotoSession()
                        replaceHadSelection = false
                        showReplacePicker = true
                    } label: {
                        Image("ic_edit")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .frame(width: 32, height: 32)
                            .background(Color("white"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(16)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("grey300"), lineWidth: 1)
                }
            } else {
                Button {
                    showAddPicker = true
                } label: {
                    VStack(spacing: 0) {
                        Image("ic_upload")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)

                        Text("사진 업로드")
                            .pretendardText(size: 16)
                            .foregroundColor(Color("grey600"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color("grey200"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("grey300"), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var quotationField: some View {
        VStack(alignment: .leading, spacing: 0) {
            fieldLabel(
                "인용구",
                required: true,
                count: "\(viewModel.quotation.count)/140"
            )

            multilineField(
                text: $viewModel.quotation,
                placeholder: "인상 깊은 문장을 작성해주세요",
                height: viewModel.quotation.isEmpty ? 52 : 118
            )

            if viewModel.quotation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("인용구를 입력해주세요")
                    .pretendardText(size: 12)
                    .foregroundColor(Color("pointRed"))
                    .padding(.top, 8)
            }
        }
    }

    private var pageField: some View {
        VStack(alignment: .leading, spacing: 0) {
            fieldLabel("페이지", required: true)

            TextField(
                "",
                text: $viewModel.pageText,
                prompt: Text("페이지를 입력해주세요")
                    .foregroundColor(Color("grey500"))
            )
            .keyboardType(.numberPad)
            .pretendardText(size: 15)
            .foregroundColor(Color("grey800"))
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color("white"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("grey300"), lineWidth: 1)
            }
        }
    }

    private var memoField: some View {
        VStack(alignment: .leading, spacing: 0) {
            fieldLabel(
                "메모",
                count: "\(viewModel.memo.count)/110"
            )

            multilineField(
                text: $viewModel.memo,
                placeholder: "어떤 책을 읽어볼까요?",
                height: viewModel.memo.isEmpty ? 52 : 96
            )
        }
    }

    private func fieldLabel(
        _ title: String,
        required: Bool = false,
        count: String? = nil
    ) -> some View {
        HStack {
            HStack(spacing: 4) {
                Text(title)
                    .foregroundColor(Color("grey900"))

                if required {
                    Text("*")
                        .foregroundColor(Color("main200"))
                }
            }
            .pretendardText(size: 16, weight: .medium)

            Spacer()

            if let count {
                Text(count)
                    .pretendardText(size: 12)
                    .foregroundColor(Color("grey500"))
            }
        }
        .padding(.bottom, 8)
    }

    private func multilineField(
        text: Binding<String>,
        placeholder: String,
        height: CGFloat
    ) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey500"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 15)
            }

            TextEditor(text: text)
                .pretendardText(size: 16)
                .foregroundColor(Color("grey800"))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
        }
        .frame(height: height)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("grey300"), lineWidth: 1)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                isPreviewPresented = true
            } label: {
                Text("미리보기")
                    .pretendardText(size: 16)
                    .foregroundColor(Color("grey900"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("grey200"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSubmit)

            Button {
                Task {
                    let succeeded = await viewModel.submit()
                    if succeeded {
                        NotificationCenter.default.post(
                            name: .libraryCardMutationFinished,
                            object: nil
                        )
                        container.navigationRouter.pop()
                    }
                }
            } label: {
                Text(viewModel.submitButtonTitle)
                    .pretendardText(size: 16)
                    .foregroundColor(Color("white"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color("grey900"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSubmit)
        }
        .padding(16)
        .background(Color("uiBg"))
    }

    private var cardPreview: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if viewModel.cardType == .image,
                   let data = viewModel.previewImageData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 320, height: 372)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [
                            Color(red: 1, green: 0.31, blue: 0.09),
                            Color("main200"),
                            Color(red: 1, green: 0.79, blue: 0.64)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        previewBookChip

                        Image("ic_quote")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color("white"))
                            .frame(width: 28, height: 28)
                            .padding(.top, 12)

                        Text("\"\(viewModel.quotation)\"")
                            .font(.custom("MaruBuri-Bold", size: 20, relativeTo: .title3))
                            .foregroundColor(Color("white"))
                            .lineSpacing(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                }

                if viewModel.cardType == .image {
                    previewBookChip
                        .padding(20)
                }
            }
            .frame(width: 320, height: 372)

            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.memo)
                    .pretendardText(size: 15)
                    .foregroundColor(Color("grey900"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(5)

                Spacer(minLength: 0)

                Text("by. \(viewModel.authorIdentifier)")
                    .pretendardText(size: 14)
                    .foregroundColor(Color("grey400"))
            }
            .padding(20)
            .frame(width: 320, height: 148)
            .background(Color("white"))
        }
        .frame(width: 320, height: 520)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.1), radius: 10)
        .onTapGesture {}
    }

    private var previewBookChip: some View {
        HStack(spacing: 6) {
            Image("ic_logo_symbol")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color("white"))
                .frame(width: 16, height: 16)

            Text(viewModel.bookTitle)
                .pretendardText(size: 16, weight: .medium)
                .foregroundColor(Color("white"))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            viewModel.cardType == .image
                ? Color("main200")
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            if viewModel.cardType == .text {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("main100"), lineWidth: 1)
            }
        }
    }

    private func consumePickerItem(
        _ item: PhotosPickerItem,
        isReplace: Bool
    ) async {
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
        cardType: .text,
        bookTitle: "나는 당신을 편애합니다",
        libraryService: LibraryService(
            interceptor: AuthInterceptor(authService: AuthService())
        ),
        userService: UserService(
            interceptor: AuthInterceptor(authService: AuthService())
        )
    )
    .environmentObject(DIContainer())
}
