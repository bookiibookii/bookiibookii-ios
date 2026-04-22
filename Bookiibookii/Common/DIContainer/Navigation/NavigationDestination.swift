import Foundation

/// `navigationDestination(for:)` 라우팅에 사용할 화면 식별자입니다.
/// 기능 추가 시 case만 늘리고 `NavigationRoutingView`의 switch를 맞추면 됩니다.
enum NavigationDestination: Hashable {
    case loginIntro
    case login
    case onboardingProfile
    case onboardingSteps(name: String, s3Key: String?)
    case mainTab
}
