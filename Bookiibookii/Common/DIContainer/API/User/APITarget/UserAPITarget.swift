import Foundation

enum UserAPITarget: APITargetType {
    case checkNickname(String)
    case presignedURL
    case completeOnboarding(OnboardingRequest)
    case mypage
    case updateMypage(MypageUpdateRequest)
    case updateIntroduction(UpdateIntroductionRequest)
    case bookshelf
    case deleteRepresentativeBook(userBookId: Int)
    case reorderRepresentativeBooks(ReorderRepresentativeRequest)
    case addFavoriteBook(FavoriteBookISBNRequest)
    case replaceFavoriteBook(userBookId: Int, request: FavoriteBookISBNRequest)
    case deleteFavoriteBook(userBookId: Int)
    case mypageWrittenReviews(page: Int, size: Int)
    case mypageReceivedReviews(page: Int, size: Int)
    case profileChangeInfo
    case updateProfileChangeInfo(ProfileChangeUpdateRequest)
    case getUserProfile(nickname: String)

    var path: String {
        switch self {
        case .checkNickname:
            return API.Path.users + "/name-validation"
        case .presignedURL:
            return API.Path.users + "/me/image/presigned-url"
        case .completeOnboarding:
            return API.Path.onboarding
        case .mypage, .updateMypage:
            return API.Path.mypage
        case .updateIntroduction:
            return API.Path.mypageIntroduction
        case .bookshelf:
            return API.Path.mypageBookshelf
        case .deleteRepresentativeBook(let userBookId):
            return API.Path.mypageBookshelfRepresentative(userBookId: userBookId)
        case .reorderRepresentativeBooks:
            return API.Path.mypageBookshelfRepresentativesOrder
        case .addFavoriteBook:
            return API.Path.mypageBookshelfFavorites
        case .replaceFavoriteBook(let userBookId, _):
            return API.Path.mypageBookshelfFavorite(userBookId: userBookId)
        case .deleteFavoriteBook(let userBookId):
            return API.Path.mypageBookshelfFavorite(userBookId: userBookId)
        case .mypageWrittenReviews:
            return API.Path.mypageReviewsWritten
        case .mypageReceivedReviews:
            return API.Path.mypageReviewsReceived
        case .profileChangeInfo, .updateProfileChangeInfo:
            return API.Path.users + "/me/profile-change"
        case .getUserProfile(let nickname):
            return API.Path.userProfile(nickname: nickname)
        }
    }

    var method: HTTPMethod {
        switch self {
        case .mypage, .profileChangeInfo, .getUserProfile, .bookshelf,
             .mypageWrittenReviews, .mypageReceivedReviews: return .get
        case .updateMypage, .updateIntroduction, .reorderRepresentativeBooks, .replaceFavoriteBook: return .patch
        case .deleteRepresentativeBook, .deleteFavoriteBook: return .delete
        case .updateProfileChangeInfo: return .put
        case .checkNickname, .presignedURL, .completeOnboarding, .addFavoriteBook: return .post
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .checkNickname(let nickname):
            return [URLQueryItem(name: "nickname", value: nickname)]
        case .mypageWrittenReviews(let page, let size),
             .mypageReceivedReviews(let page, let size):
            return [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "size", value: String(size))
            ]
        default:
            return []
        }
    }

    var body: Data? {
        switch self {
        case .completeOnboarding(let request):
            return try? JSONEncoder().encode(request)
        case .updateMypage(let request):
            return try? JSONEncoder().encode(request)
        case .updateIntroduction(let request):
            return try? JSONEncoder().encode(request)
        case .reorderRepresentativeBooks(let request):
            return try? JSONEncoder().encode(request)
        case .addFavoriteBook(let request), .replaceFavoriteBook(_, let request):
            return try? JSONEncoder().encode(request)
        case .updateProfileChangeInfo(let request):
            return try? JSONEncoder().encode(request)
        default:
            return nil
        }
    }

    var headers: [String: String] {
        switch self {
        case .presignedURL, .completeOnboarding, .updateMypage, .updateIntroduction, .updateProfileChangeInfo, .reorderRepresentativeBooks, .addFavoriteBook, .replaceFavoriteBook:
            return ["Content-Type": "application/json"]
        default:
            return [:]
        }
    }
}
