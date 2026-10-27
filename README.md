# 부키부키 ios팀 README
<img width="7680" height="4320" alt="배너2" src="https://github.com/user-attachments/assets/bd0d766f-fce3-45df-ab09-5defda749bb1" />

<br><br>

## 🔎 About the Project
![x배너 (1)](https://github.com/user-attachments/assets/40112447-e22d-4cb8-b611-8395f2274232)
> design by loverlikewater@gmail.com / @aoree.lim

<br><br>

## 🤝 Team
| 이중희 | 한태빈 |
|:------:|:------:|
| <img src="이미지주소" width="120"/> | <img src="이미지주소" width="120"/> |
| [@jungee123213](https://github.com/jungee123213) | [@taebin2](https://github.com/taebin2) |

<br/>

## 🛠 Tech Stack
**Language**: Swift<br/>
**Framework**: SwiftUI<br/>
<br>

## 🌿 Branch Strategy
GitHub Flow — `main` 단일 브랜치
- `main` : 기본 브랜치. 항상 릴리즈 가능한 상태, 직접 커밋 금지
- 작업 브랜치 : `main`에서 분기 → `main`으로 PR, 병합 후 삭제

**{type}/#Issue Number-{작업 내용}** => 공백은 - 로 연결
> feat/#1-kakao-login<br>
> mod/#15-mypage-dto

<br>

## 🚀 Release
- 릴리즈
  - `main`에서 버전(MARKETING_VERSION / CURRENT_PROJECT_VERSION)을 올리는 PR 병합
  - 병합 커밋에 `v<버전>` 태그 + GitHub Release 생성
  - 스토어 제출 빌드는 태그 시점에서 아카이브
- Hotfix (출시 버전 긴급 수정)
  - 출시 태그에서 `release/<버전>` 분기 → 수정 후 패치 버전 태그 + Release
  - 같은 수정을 `main`에도 PR로 반영

<br>

## 📖 Pull Request Convention
**[type] 이슈 제목**
> [Feat] 로그인 기능 구현
- PR 생성 시 24시간 이내에 확인을 요합니다.

<br>

## 📖 Commit Convention
**[type] #Issue Number 제목(작업 내용)**
본문 (한줄로 설명 가능한 경우 본문은 생략) 
- `Feat` : 새로운 기능 구현
- `Mod` : 코드 및 내부 파일 수정
- `Add` : feat 이외의 부수적인 코드, 파일, 라이브러리 추가
- `Delete` : 불필요한 코드나 파일 삭제
- `Fix` : 버그 및 오류 해결
- `Chore` : 의존성 추가, 패키지 구조, 함수 및 변수명 변경 등의 작은 작업
- `HOTFIX` : 배포된 버전에 이슈 발생 시, 긴급하게 수정 작업
- `Rename` : 파일이나 폴더명 수정
- `Docs` : README나 Wiki 등의 문서 작업
- `Refactor` : 로직 변경 없이 기존의 코드를 개선하는 리팩터링
- `Comment` : 필요한 주석 추가 및 변경
> [Feat] #11 로그인 서버 연동
