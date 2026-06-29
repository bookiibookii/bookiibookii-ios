import SwiftUI

// 스플래시 인트로(4~7) 기능 미리보기 목업 카드들.
// 피그마 디자인 + 안드로이드 intro 샘플 이미지(intro_*) 사용.

private let previewCardWidth: CGFloat = 280

// MARK: - 공통 요소

private func introCover(_ name: String, width: CGFloat, height: CGFloat, corner: CGFloat = 6) -> some View {
    Image(name)
        .resizable()
        .scaledToFill()
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
}

private func introProfile(_ name: String, size: CGFloat) -> some View {
    Image(name)
        .resizable()
        .scaledToFill()
        .frame(width: size, height: size)
        .clipShape(Circle())
}

private func previewChip(_ text: String, bg: Color, fg: Color) -> some View {
    Text(text)
        .font(.pretendard(size: 8, weight: .medium))
        .foregroundColor(fg)
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(bg)
        .clipShape(Capsule())
}

private func previewSectionHeader(_ title: String, _ subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        Text(title).font(.pretendard(size: 12, weight: .semibold)).foregroundColor(Color("grey900"))
        Text(subtitle).font(.pretendard(size: 9)).foregroundColor(Color("grey400"))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

private let mainPale = Color(red: 1.0, green: 234/255, blue: 219/255)   // #FFEADB
private let subPale = Color(red: 212/255, green: 237/255, blue: 1.0)    // #D4EDFF

// MARK: - 프레임 4: 그룹/홈 미리보기 (node 3834-85823)
struct GroupPreviewCard: View {
    private let newBooks: [(String, String, String)] = [
        ("intro_book_hello", "안녕이라 그랬어", "김애란"),
        ("intro_book_torrent", "급류", "정대건"),
        ("intro_book_honmono", "혼모노", "성해나"),
        ("intro_book_goethe", "괴테는 모든 것을 말했다", "스즈키 유이"),
        ("intro_book_contradiction", "모순", "양귀자"),
        ("intro_book_granny", "할매", "황석영")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                previewSectionHeader("신규 그룹을 확인해보세요", "오늘 만들어진 따끈따끈한 그룹들만 모았어요")
                groupCard
            }
            VStack(alignment: .leading, spacing: 8) {
                previewSectionHeader("새로운 책이 도착했어요", "이번 달 신간들을 함께 읽어볼까요?")
                bookGrid
            }
        }
        .padding(12)
        .frame(width: previewCardWidth)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color("grey200"), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.1), radius: 14, x: 0, y: 0)
    }

    private var groupCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                introCover("intro_book_cant_bear", width: 52, height: 74)
                VStack(alignment: .leading, spacing: 4) {
                    previewChip("택배", bg: mainPale, fg: Color("main200"))
                    Text("고전 완독하실 분 구해요")
                        .font(.pretendard(size: 11, weight: .medium)).foregroundColor(Color("grey900"))
                    Text("참을 수 없는 존재의 가벼움")
                        .font(.pretendard(size: 9)).foregroundColor(Color("grey700")).lineLimit(1)
                    Text("밀란 쿤데라 · 소설")
                        .font(.pretendard(size: 8)).foregroundColor(Color("grey500"))
                    HStack(spacing: 4) {
                        introProfile("intro_profile_sayo", size: 14)
                        Text("sayo").font(.pretendard(size: 8)).foregroundColor(Color("grey500"))
                    }
                }
                Spacer(minLength: 0)
            }
            Text("자세히 보기")
                .font(.pretendard(size: 10, weight: .medium)).foregroundColor(Color("main200"))
                .frame(maxWidth: .infinity).frame(height: 30)
                .background(mainPale)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(10)
        .background(Color("uiBg"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var bookGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 10) {
            ForEach(newBooks, id: \.0) { book in
                VStack(spacing: 4) {
                    Image(book.0).resizable().scaledToFill()
                        .frame(height: 82).frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text(book.1).font(.pretendard(size: 8, weight: .medium))
                        .foregroundColor(Color("grey900")).lineLimit(1)
                    Text(book.2).font(.pretendard(size: 7))
                        .foregroundColor(Color("grey500")).lineLimit(1)
                }
            }
        }
    }
}

// MARK: - 프레임 5: 트래커 미리보기 (node 3834-86049)
struct TrackerPreviewCard: View {
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("sayo").foregroundColor(Color("main200"))
                    Text("님의").foregroundColor(Color("grey900"))
                }
                Text("교환독서 현황을 알려드려요").foregroundColor(Color("grey900"))
            }
            .font(.pretendard(size: 16, weight: .medium))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(Color.white)
            .overlay(Rectangle().fill(Color("grey100")).frame(height: 0.7), alignment: .bottom)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("D-2").font(.pretendard(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.216, green: 0.667, blue: 1.0))
                    Spacer()
                    HStack(spacing: 3) {
                        Circle().fill(Color("grey500")).frame(width: 5, height: 5)
                        Circle().fill(Color("grey200")).frame(width: 5, height: 5)
                        Circle().fill(Color("grey200")).frame(width: 5, height: 5)
                    }
                }
                (Text("살인자의 기억법").foregroundColor(Color("grey900"))
                 + Text("을 읽고 후기를 작성해주세요").foregroundColor(Color("grey700"))).font(.pretendard(size: 9))
                Text("독서카드를 남기면 교환독서가 더욱 즐거워져요")
                    .font(.pretendard(size: 8)).foregroundColor(Color("grey400"))
            }
            .padding(.horizontal, 16).padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading).background(Color.white)

            VStack(spacing: 8) {
                countBoard
                trackerCard
            }
            .padding(11).background(Color("uiBg"))
        }
        .frame(width: previewCardWidth)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color("grey200"), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.1), radius: 14, x: 0, y: 0)
    }

    private var countBoard: some View {
        HStack(spacing: 0) {
            countItem("전체", "3", dimmed: false); divider
            countItem("읽는 중", "1", dimmed: false); divider
            countItem("교환 중", "2", dimmed: false); divider
            countItem("후기", "0", dimmed: true)
        }
        .padding(8).frame(maxWidth: .infinity).background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func countItem(_ label: String, _ value: String, dimmed: Bool) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.pretendard(size: 9)).foregroundColor(Color("grey700"))
            Text(value).font(.pretendard(size: 16)).foregroundColor(dimmed ? Color("grey300") : Color("grey900"))
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View { Rectangle().fill(Color("grey100")).frame(width: 1, height: 30) }

    private var trackerCard: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("김영하 도장깨기 하실 분").font(.pretendard(size: 11, weight: .medium)).foregroundColor(Color("grey800"))
                    HStack(spacing: 3) {
                        Text("살인자의 기억법"); Text("·"); Text("읽는 중")
                    }.font(.pretendard(size: 9)).foregroundColor(Color("grey500"))
                }
                Spacer()
                Text("D-2").font(.pretendard(size: 8, weight: .medium)).foregroundColor(Color("grey700"))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Color("grey100")).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.bottom, 5)
            .overlay(Rectangle().fill(Color("grey100")).frame(height: 0.5), alignment: .bottom)

            HStack(alignment: .top, spacing: 10) {
                trackerColumn(cover: "intro_book_killer", profile: "intro_profile_sayo_tracker",
                              name: "나", title: "살인자의 기억법", percent: "59%", myBook: true)
                trackerColumn(cover: "intro_book_farewell", profile: "intro_profile_noshel",
                              name: "noshel", title: "작별인사", percent: "30%", myBook: false)
            }

            HStack(spacing: 8) {
                Text("독서카드 작성").font(.pretendard(size: 11)).foregroundColor(Color("grey900"))
                    .frame(maxWidth: .infinity).frame(height: 32).background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(Color("grey200"), lineWidth: 0.7))
                Text("진행률 기록").font(.pretendard(size: 11)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 32).background(Color("main200"))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
        }
        .padding(11).background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func trackerColumn(cover: String, profile: String, name: String, title: String, percent: String, myBook: Bool) -> some View {
        VStack(spacing: 5) {
            ZStack(alignment: .bottomTrailing) {
                introCover(cover, width: 68, height: 90, corner: 8)
                if myBook {
                    Text("내 책").font(.pretendard(size: 7)).foregroundColor(Color("grey900"))
                        .padding(.horizontal, 3).padding(.vertical, 1)
                        .background(Color("grey200").opacity(0.75)).clipShape(RoundedRectangle(cornerRadius: 4)).padding(3)
                }
            }
            VStack(spacing: 3) {
                Text(name).font(.pretendard(size: 9)).foregroundColor(Color("grey700"))
                Text(title).font(.pretendard(size: 11, weight: .medium)).foregroundColor(Color("grey800")).lineLimit(1)
            }
            VStack(alignment: .leading, spacing: 4) {
                Rectangle().fill(Color("grey200")).frame(height: 2)
                Text(percent).font(.pretendard(size: 9)).foregroundColor(Color("grey800"))
            }
            .padding(.horizontal, 3)
            introProfile(profile, size: 28)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 프레임 6: 서재 미리보기 (node 3834-86089)
struct LibraryPreviewCard: View {
    var body: some View {
        VStack(spacing: 10) {
            bookHeader
            filterRow
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                readingCard(profile: "intro_profile_noshel_lib2", name: "noshel",
                            comment: "좋은 사람이 결국 행복해지는 이야기를 어떻게 사랑하지 않을 수 있겠어...", page: "p.506",
                            quote: "“너랑 나는 좋은 사람.” 로키가 말한다. “그러게.” 나는 미소 짓는다.", photo: nil)
                readingCard(profile: "intro_profile_sayo_lib", name: "sayo",
                            comment: "인생에서 나 지켜봐 줄 에리디언 너무 필요함", page: "p.299",
                            quote: nil, photo: "intro_reading_card_photo1")
                readingCard(profile: "intro_profile_sayo_lib4", name: "sayo",
                            comment: "나 행복. 너 안 죽음. 행성들을 구하자! 아름다워...ㅜㅜ", page: "p.97",
                            quote: nil, photo: "intro_reading_card_photo4")
                readingCard(profile: "intro_profile_noshel_lib3", name: "noshel",
                            comment: "말 한마디 없이 아프다는 걸 알아채는 거, 이게 진짜 우정이지 않을까?", page: "p.97",
                            quote: "\"인간은 슬프면 눈에서 물이 흘러나와.\" \"나는 네가 물이 새지 않을 때까지 지켜본다.\"", photo: nil)
            }
        }
        .padding(11).frame(width: previewCardWidth).background(Color("uiBg"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color("grey200"), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.1), radius: 14, x: 0, y: 0)
    }

    private var bookHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            introCover("intro_book_hail_mary", width: 60, height: 86, corner: 7)
            VStack(alignment: .leading, spacing: 3) {
                Text("영화 보고 뒤늦게 책 읽는 모임").font(.pretendard(size: 9)).foregroundColor(Color("grey600"))
                Text("프로젝트 헤일메리").font(.pretendard(size: 10, weight: .semibold)).foregroundColor(Color("grey900"))
                Text("앤디 위어 (소설)").font(.pretendard(size: 9)).foregroundColor(Color("grey900"))
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < 4 ? "star.fill" : "star").font(.system(size: 8))
                            .foregroundColor(i < 4 ? Color("main200") : Color("grey300"))
                    }
                }
                Spacer(minLength: 4)
                Text("2026. 05. 09. ~ 2026. 05. 31.").font(.pretendard(size: 9)).foregroundColor(Color("grey500"))
            }
            Spacer(minLength: 0)
        }
        .padding(11).frame(maxWidth: .infinity, alignment: .leading).background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var filterRow: some View {
        HStack {
            HStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5).fill(subPale).frame(width: 14, height: 14)
                    Image(systemName: "checkmark").font(.system(size: 7, weight: .bold)).foregroundColor(Color("main200"))
                }
                Text("내 독서카드만 보기").font(.pretendard(size: 9, weight: .medium)).foregroundColor(Color("grey500"))
            }
            Spacer()
            HStack(spacing: 3) {
                Text("최신순").font(.pretendard(size: 9, weight: .semibold)).foregroundColor(Color("grey800"))
                Text("|").font(.pretendard(size: 9)).foregroundColor(Color("grey500"))
                Text("페이지순").font(.pretendard(size: 9)).foregroundColor(Color("grey500"))
            }
        }
    }

    private func readingCard(profile: String, name: String, comment: String, page: String, quote: String?, photo: String?) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    introProfile(profile, size: 16)
                    Text(name).font(.pretendard(size: 9, weight: .medium)).foregroundColor(Color("grey800"))
                    Spacer()
                    Image(systemName: "bookmark.fill").font(.system(size: 7)).foregroundColor(Color("main200"))
                        .padding(3).background(mainPale).clipShape(Circle())
                }
                Text(comment).font(.pretendard(size: 9)).foregroundColor(Color("grey800"))
                    .lineLimit(3).frame(height: 38, alignment: .topLeading)
                HStack {
                    Image(systemName: "heart.fill").font(.system(size: 9)).foregroundColor(Color("grey300"))
                    Spacer()
                    Text(page).font(.pretendard(size: 9)).foregroundColor(Color("grey400"))
                }
            }
            .padding(8)

            // 하단 밴드는 고정 높이 (사진이 공간을 과하게 먹지 않도록)
            Group {
                if let quote {
                    VStack(alignment: .leading, spacing: 3) {
                        Image(systemName: "quote.opening").font(.system(size: 8)).foregroundColor(.white)
                        Text(quote).font(.maruburi(size: 8, weight: .bold)).foregroundColor(.white).lineLimit(3)
                        Spacer(minLength: 0)
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(
                        LinearGradient(colors: [Color(red: 1.0, green: 78/255, blue: 24/255), Color("main200"), Color(red: 1.0, green: 201/255, blue: 164/255)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                } else if let photo {
                    Image(photo).resizable().scaledToFill()
                } else {
                    Color.clear
                }
            }
            .frame(height: 84)
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

// MARK: - 프레임 7: 리뷰 미리보기 (node 3834-86128)
struct ReviewPreviewCard: View {
    var body: some View {
        VStack(spacing: 14) {
            chatReviewCard
            bookReviewCard
        }
        .padding(11).frame(width: previewCardWidth).background(Color("uiBg"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color("grey200"), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.1), radius: 14, x: 0, y: 0)
    }

    private var chatReviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text("김영하 도장깨기 하실 분").font(.pretendard(size: 11, weight: .medium)).foregroundColor(Color("grey900"))
                Text("2026. 04. 29. ~ 2026. 05. 17.").font(.pretendard(size: 9)).foregroundColor(Color("grey500"))
            }
            .padding(.bottom, 5).frame(maxWidth: .infinity, alignment: .leading)
            .overlay(Rectangle().fill(Color("grey100")).frame(height: 0.5), alignment: .bottom)

            VStack(alignment: .trailing, spacing: 5) {
                nameRow("intro_profile_noshel_review", "noshel", trailing: true)
                HStack(alignment: .bottom, spacing: 5) {
                    Spacer(minLength: 20)
                    ZStack {
                        Circle().fill(mainPale).frame(width: 19, height: 19).overlay(Circle().strokeBorder(Color("main200"), lineWidth: 0.4))
                        Image(systemName: "hand.thumbsup.fill").font(.system(size: 8)).foregroundColor(Color("main200"))
                    }
                    bubble("같은 책을 읽었다는 것만으로 왠지 이 사람이 궁금해졌습니다. 기회가 되면 여쭤보고 싶네요.", bg: Color("grey100"), align: .trailing)
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                nameRow("intro_profile_sayo_review", "sayo", trailing: false)
                bubble("이 책을 읽은 분이라면 분명 할 말이 많을 것 같아서, 한번쯤 이야기 나눠보고 싶었습니다.", bg: subPale, align: .leading)
            }
        }
        .padding(11).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var bookReviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                introCover("intro_book_destroy", width: 44, height: 62, corner: 8)
                VStack(alignment: .leading, spacing: 3) {
                    Text("나는 나를 파괴할 권리가 있다").font(.pretendard(size: 10, weight: .semibold)).foregroundColor(Color("grey900"))
                    Text("김영하").font(.pretendard(size: 10, weight: .medium)).foregroundColor(Color("grey700"))
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 5)
            .overlay(Rectangle().fill(Color("grey100")).frame(height: 0.5), alignment: .bottom)

            VStack(alignment: .trailing, spacing: 5) {
                nameRow("intro_profile_noshel_review", "noshel", trailing: true)
                ratedBubble(date: "2026. 04. 05.", stars: 4, text: "제목부터가 선전포고였다. 읽는 내내 불편했는데, 그 불편함이 오래 남는다.", dateLeading: false)
            }
            VStack(alignment: .leading, spacing: 5) {
                nameRow("intro_profile_sayo_review", "sayo", trailing: false)
                ratedBubble(date: "2026. 04. 15.", stars: 4, text: "죽음을 직업으로 삼는 사람의 이야기인데, 오히려 '살고 싶다'는 감각이 선명해졌다.", dateLeading: true)
            }
        }
        .padding(11).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func nameRow(_ profile: String, _ name: String, trailing: Bool) -> some View {
        HStack(spacing: 5) {
            if trailing { Spacer() }
            introProfile(profile, size: 13)
            Text(name).font(.pretendard(size: 8, weight: .medium)).foregroundColor(Color("grey800"))
            if !trailing { Spacer() }
        }
    }

    private func bubble(_ text: String, bg: Color, align: HorizontalAlignment) -> some View {
        Text(text)
            .font(.pretendard(size: 9)).foregroundColor(Color("grey900"))
            .multilineTextAlignment(align == .trailing ? .trailing : .leading)
            .padding(10).frame(maxWidth: 190, alignment: align == .trailing ? .trailing : .leading)
            .background(bg).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .frame(maxWidth: .infinity, alignment: align == .trailing ? .trailing : .leading)
    }

    private func ratedBubble(date: String, stars: Int, text: String, dateLeading: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if dateLeading {
                    starRow(stars); Spacer(); Text(date).font(.pretendard(size: 9)).foregroundColor(Color("grey500"))
                } else {
                    Text(date).font(.pretendard(size: 9)).foregroundColor(Color("grey500")); Spacer(); starRow(stars)
                }
            }
            Text(text).font(.pretendard(size: 9)).foregroundColor(Color("grey900"))
        }
        .padding(10).frame(maxWidth: 200).background(Color("grey100"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: .infinity, alignment: dateLeading ? .leading : .trailing)
    }

    private func starRow(_ filled: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: i < filled ? "star.fill" : "star").font(.system(size: 8))
                    .foregroundColor(i < filled ? Color("main200") : Color("grey300"))
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            GroupPreviewCard()
            TrackerPreviewCard()
            LibraryPreviewCard()
            ReviewPreviewCard()
        }
        .padding()
    }
    .background(Color("uiBg"))
}
