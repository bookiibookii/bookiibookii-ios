import SwiftUI
import UIKit

/// 카메라 촬영용 UIKit `UIImagePickerController` 브리지 (재사용 공통 컴포넌트).
/// 앨범 선택은 SwiftUI `PhotosPicker`로 충분하지만, 카메라 촬영은 UIKit 래퍼가 필요하다.
/// 결과는 `UIImage`로 전달되어 앨범 경로(`PhotosPickerImageLoader.uiImage`)와 동일하게 수렴한다.
struct CameraPicker: UIViewControllerRepresentable {
    var allowsEditing: Bool = true
    let onCapture: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = allowsEditing
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage) {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

extension View {
    /// 카메라 촬영 시트를 표시하고 촬영 결과 `UIImage`를 콜백으로 전달한다.
    /// 카메라가 없는 환경(시뮬레이터 등)에서는 표시되지 않아 크래시를 방지한다.
    func cameraPicker(
        isPresented: Binding<Bool>,
        allowsEditing: Bool = true,
        onCapture: @escaping (UIImage) -> Void
    ) -> some View {
        fullScreenCover(isPresented: Binding(
            get: { isPresented.wrappedValue && UIImagePickerController.isSourceTypeAvailable(.camera) },
            set: { isPresented.wrappedValue = $0 }
        )) {
            CameraPicker(allowsEditing: allowsEditing, onCapture: onCapture)
                .ignoresSafeArea()
        }
    }
}
