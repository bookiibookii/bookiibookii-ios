# 부키부키(Bookii Bookii) iOS 재구현 프로젝트

## 프로젝트 개요

안드로이드 앱 **부키부키**를 iOS로 재구현하는 프로젝트입니다.

- **안드로이드 원본 프로젝트 경로:** `/Users/qhrtj07/StudioProjects/bookiibookii-android`
- **iOS 프로젝트 경로:** `/Users/qhrtj07/Desktop/xcode_test/HelloWorld`
- **앱 설명:** 도서 교환 및 함께읽기 소셜 플랫폼 (그룹 독서, 도서 거래 추적, 독서카드 등)

## 작업 원칙

- 모든 결과값과 설명은 **한글**로 작성한다.
- 코드 구현 전 반드시 안드로이드 원본 코드를 참고하여 기능을 파악한 후 iOS로 재구현한다.
- 안드로이드 로직을 그대로 옮기되, iOS/Swift 관용적인 방식으로 재작성한다.

---

## 안드로이드 원본 앱 기능 요약

### 메인 탭 구조 (5개 탭)
| 탭 | 기능 |
|----|------|
| HOME | 홈 피드, 추천 그룹, 부키메이트 추천 |
| GROUP | 그룹 탐색/생성/상세 |
| TRACKER | 책 거래 추적 (함께읽기/이어읽기, Host/Guest 역할) |
| LIBRARY | 내 도서관, 독서카드 |
| MY | 마이페이지 설정 |

### 핵심 기능 목록
1. **소셜 로그인** - Google OAuth, Kakao OAuth / JWT 토큰 기반 세션 관리
2. **도서 그룹** - 그룹 생성(함께읽기/이어읽기), 배송/직거래 선택, 그룹 검색/신청
3. **독서 라이브러리** - 도서 목록, 독서카드(페이지/메모/사진), 북마크, 댓글, 별점
4. **도서 거래 추적(Tracker)** - Host/Guest 역할, 배송사진, 직거래 지원
5. **리뷰 시스템** - 함께읽기/이어읽기 리뷰, 별점
6. **알림 시스템** - 시스템 알림, 키워드 알림
7. **소셜 기능** - 사용자 프로필, 부키메이트 추천, 친구 요청
8. **마이페이지** - 프로필 편집, 신고/문의, 공지사항, 계정 관리
9. **도서 검색** - 알라딘 API 연동, ISBN 기반 도서 정보

---

## 안드로이드 기술 스택 → iOS 대응 가이드

| 영역 | 안드로이드 | iOS 권장 |
|------|-----------|---------|
| 언어 | Kotlin | Swift |
| 아키텍처 | MVVM + Repository | MVVM + Repository |
| UI 프레임워크 | Android View / XML | SwiftUI (우선) |
| 네트워크 | Retrofit2 + OkHttp3 | URLSession / Alamofire |
| JSON 파싱 | Gson | Codable (Swift 기본) |
| 이미지 로딩 | Glide, Coil | Kingfisher / SDWebImage |
| 비동기 처리 | Coroutines + LiveData | async/await + Combine |
| 상태 관리 | LiveData / ViewModel | @StateObject / @ObservableObject |
| 로컬 저장소 | SharedPreferences | UserDefaults / Keychain |
| 소셜 로그인 | Google Auth, Kakao SDK | Google Sign-In SDK, KakaoOpenSDK |
| 이미지 업로드 | S3Uploader | AWS SDK / Presigned URL |

---

## API 정보

- **Base URL:** `https://bookii.gyeonseo.com/`
- **인증 방식:** JWT (Access Token + Refresh Token)
- **토큰 저장:** Access Token, Refresh Token, User ID, 온보딩 완료 여부
- **토큰 만료 처리:** 401 응답 시 Refresh Token으로 자동 갱신 후 재요청

### 주요 엔드포인트
```
POST /api/auth/login          - 로그인
POST /api/auth/logout         - 로그아웃
POST /api/auth/refresh        - 토큰 갱신
GET/PUT /api/users/*          - 사용자 정보
GET/POST /api/groups/*        - 그룹
GET/POST /api/cards/*         - 독서카드
GET/POST /api/library/*       - 라이브러리
GET/POST /api/reviews/*       - 리뷰
GET/POST /api/notifications/* - 알림
GET/POST /api/keywords/*      - 키워드 알림
POST /api/report/*            - 신고
POST /api/inquiry/*           - 문의
GET /api/notice/*             - 공지사항
GET /api/recommendations/*    - 그룹/북메이트 추천
```

### 공통 응답 형식
```swift
struct CommonResponse<T: Codable>: Codable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: T?
}
```

---

## 데이터 모델 주요 구조 (안드로이드 → Swift 변환 참고)

### 인증
```swift
struct LoginRequest: Codable { let socialType: String; let socialToken: String }
struct LoginResult: Codable { let accessToken: String; let refreshToken: String; let userId: Int; let isNewUser: Bool }
```

### 그룹
```swift
struct GroupItemDto: Codable { let groupId: Int; let title: String; let bookTitle: String; /* ... */ }
```

### 도서
```swift
struct BookItem: Codable { let isbn: String; let title: String; let author: String; let cover: String; /* ... */ }
```

---

## 아키텍처 가이드

### 폴더 구조 (권장)
```
HelloWorld/
├── App/                    # AppDelegate, SceneDelegate, Entry Point
├── Common/                 # 공통 컴포넌트, 유틸리티, Extension
│   ├── Components/
│   ├── Extensions/
│   └── Utils/
├── Data/
│   ├── API/                # NetworkManager, APIService, AuthInterceptor
│   ├── Models/             # Codable 데이터 모델
│   └── Repositories/       # Repository 인터페이스 및 구현
├── Features/               # 기능별 모듈 (화면 단위)
│   ├── Onboarding/         # 로그인 및 온보딩
│   ├── Home/               # 홈 피드
│   ├── Group/              # 그룹
│   ├── Tracker/            # 거래 추적 (Host/Guest)
│   ├── Library/            # 내 도서관
│   └── MyPage/             # 마이페이지
└── Resources/              # Assets, Fonts, Localizable
```

### 각 Feature 내부 구조
```
Features/Home/
├── Views/          # SwiftUI View 또는 UIViewController
├── ViewModels/     # ObservableObject ViewModel
└── Models/         # 화면 전용 UI 모델
```

---

## 개발 가이드라인

### 네트워크 레이어
- `TokenManager`: Keychain에 토큰 저장/조회/삭제
- `AuthInterceptor`: 401 응답 시 토큰 자동 갱신 → 원래 요청 재시도
- 인증 필요 요청과 불필요 요청 클라이언트 분리

### 상태 관리
- `@StateObject` / `@ObservableObject`로 ViewModel 관리
- `async/await` + `Combine`으로 비동기 처리
- 에러 상태를 명확히 표현 (로딩/성공/실패)

### 로컬 저장소
- **Keychain:** Access Token, Refresh Token (보안 필요 데이터)
- **UserDefaults:** User ID, 온보딩 완료 여부, 검색 히스토리

### 이미지 처리
- 프로필/책 커버 이미지: Kingfisher로 URL 기반 비동기 로딩
- 이미지 업로드: S3 Presigned URL 방식

---

## 안드로이드 원본 참고 방법

새로운 기능 구현 시 아래 순서로 안드로이드 코드 참고:
1. `/Users/qhrtj07/StudioProjects/bookiibookii-android/app/src/main/java/com/bookiibookii/bookiibookii/` 에서 해당 기능 폴더 탐색
2. Activity/Fragment에서 UI 흐름 파악
3. ViewModel에서 비즈니스 로직 파악
4. `data/api/ApiService.kt`에서 API 엔드포인트 확인
5. `data/model/`에서 데이터 모델 확인
6. iOS 방식으로 재구현

---

## 외부 SDK

- **알라딘 API:** 도서 검색 (`https://www.aladin.co.kr/ttb/api/`)
- **Kakao SDK:** iOS용 `KakaoOpenSDK` 사용
- **Google Sign-In:** `GoogleSignIn-iOS` SDK 사용

---

## 아이콘 변환 방식 (Android Vector Drawable → iOS SVG)

### 변환 원칙

Android Vector Drawable (`.xml`)은 iOS에서 직접 사용 불가. 아래 방식으로 변환한다.

**변환 방법: SVG 파일 → Assets.xcassets template 이미지**

1. Android `pathData` 속성값을 SVG `d` 속성에 그대로 재사용 (포맷 호환)
2. `fillColor="#ffffff"` (흰색 채우기)는 `fill="none"`으로 변경 → outline 스타일 통일
3. `strokeColor` 속성은 `stroke="black"`으로 고정 (실제 색상은 코드에서 제어)
4. `Assets.xcassets` 내 `imageset`으로 저장, `Contents.json`에 template 렌더링 설정

### Android → SVG 속성 매핑

| Android 속성 | SVG 속성 |
|---|---|
| `android:pathData` | `d` |
| `android:strokeWidth` | `stroke-width` |
| `android:strokeLineCap` | `stroke-linecap` |
| `android:strokeLineJoin` | `stroke-linejoin` |
| `android:fillColor="#ffffff"` | `fill="none"` (outline 통일) |
| `android:fillColor="#00000000"` | `fill="none"` |
| `android:strokeColor` | `stroke="black"` (코드에서 색상 제어) |

### Contents.json 설정 (template 렌더링)

```json
{
  "images": [{ "filename": "아이콘.svg", "idiom": "universal" }],
  "info": { "author": "xcode", "version": 1 },
  "properties": {
    "preserves-vector-representation": true,
    "template-rendering-intent": "template"
  }
}
```

### SwiftUI에서 색상 적용 방법

```swift
// 선택 색상: #242322 (안드로이드 grey_900)
// 미선택 색상: #A4A3A0 (안드로이드 grey_400)
Image("ic_tab_home")
    .renderingMode(.template)
    .foregroundColor(isSelected ? .tabSelected : .tabUnselected)
```

### 저장 위치

```
Assets.xcassets/TabIcons/
├── ic_tab_home.imageset/
│   ├── ic_tab_home.svg
│   └── Contents.json
├── ic_tab_group.imageset/
├── ic_tab_tracker.imageset/
├── ic_tab_library.imageset/
└── ic_tab_mypage.imageset/
```

### 주의사항

- `fillColor="#ffffff"` (흰색 채우기)를 살리면 template 모드에서 내부도 아이콘 색으로 채워짐 → outline 스타일로 통일하는 것이 올바름
- 다중 색상(흰색 배경 + 컬러 선)이 필요한 경우 selected/unselected 이미지 2벌을 별도로 만들어 코드에서 이름으로 전환하는 방식을 사용
