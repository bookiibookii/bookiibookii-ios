import AuthenticationServices
import UIKit

// ASAuthorizationController의 delegate 콜백을 async 인터페이스로 감싼 컨트롤러
final class AppleSignInController: NSObject {
    private var continuation: CheckedContinuation<String, Error>?
    // ASAuthorizationController는 delegate를 weak로 참조하므로 요청이 끝날 때까지 self를 붙잡아 둔다
    private var retainedSelf: AppleSignInController?

    // 애플 로그인 시트를 띄우고 identityToken(JWT) 문자열을 반환
    func requestIdentityToken() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.retainedSelf = self

            let request = ASAuthorizationAppleIDProvider().createRequest()
            // 서버가 토큰의 sub만 사용하므로 이름·이메일은 요청하지 않는다
            request.requestedScopes = []

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    private func finish(_ result: Result<String, Error>) {
        continuation?.resume(with: result)
        continuation = nil
        retainedSelf = nil
    }
}

extension AppleSignInController: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            finish(.failure(AppleSignInError.missingIdentityToken))
            return
        }
        finish(.success(identityToken))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            finish(.failure(AppleSignInError.canceled))
            return
        }
        finish(.failure(error))
    }
}

extension AppleSignInController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

enum AppleSignInError: LocalizedError {
    case canceled
    case missingIdentityToken

    var errorDescription: String? {
        switch self {
        case .canceled: return "애플 로그인이 취소되었습니다."
        case .missingIdentityToken: return "애플 로그인 토큰을 가져오지 못했습니다."
        }
    }
}
