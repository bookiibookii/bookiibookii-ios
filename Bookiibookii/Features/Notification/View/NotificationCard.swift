import SwiftUI

// 안드로이드 item_hom_notification.xml 대응
// 흰 라운드 카드 + 40 원형 아이콘(읽음상태별 색상) + 제목/뱃지dot + 본문 + 시간·책제목 메타.
struct NotificationCard: View {
    let item: NotificationItemDto
    let bookTitle: String
    var onTap: () -> Void = {}

    private var isUnread: Bool { !item.isRead }
    private var timeText: String { TimeAgoFormatter.format(item.createdAt) }

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            icon
            VStack(alignment: .leading, spacing: 0) {
                titleRow
                Text(item.message)
                    .font(.pretendard(size: 12))
                    .foregroundColor(Color("grey700"))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)

                metaRow
                    .padding(.top, 8)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("white"))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var icon: some View {
        Image(systemName: "book")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(isUnread ? Color("main200") : Color("white"))
            .frame(width: 40, height: 40)
            .background(
                Circle().fill(isUnread ? Color("main100") : Color("grey200"))
            )
    }

    private var titleRow: some View {
        HStack(spacing: 6) {
            Text(item.title)
                .font(.pretendard(size: 14, weight: .bold))
                .foregroundColor(Color("grey900"))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if isUnread {
                Circle()
                    .fill(Color("main200"))
                    .frame(width: 6, height: 6)
            }
        }
    }

    @ViewBuilder
    private var metaRow: some View {
        let hasBook = !bookTitle.isEmpty
        HStack(spacing: 4) {
            Text(timeText)
                .font(.pretendard(size: 11))
                .foregroundColor(Color("grey400"))
            if hasBook {
                Text("·")
                    .font(.pretendard(size: 11))
                    .foregroundColor(Color("grey400"))
                Text(bookTitle)
                    .font(.pretendard(size: 11))
                    .foregroundColor(Color("grey400"))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
}

struct NotificationEmptyCard: View {
    var body: some View {
        Text("새로운 알림이 없습니다.")
            .font(.pretendard(size: 14))
            .foregroundColor(Color("grey500"))
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("white"))
            )
    }
}

#Preview {
    VStack(spacing: 12) {
        NotificationCard(
            item: NotificationItemDto(
                id: 1,
                type: "GROUP_JOIN_REQUEST",
                title: "똑똑! 새로운 참여 요청이 왔어요",
                message: "닉네임 님이 책 제목 그룹에 함께하고 싶어 해요. 프로필을 확인해볼까요?",
                isRead: false,
                createdAt: "2026-04-24T09:25:00",
                readAt: nil,
                payload: nil
            ),
            bookTitle: "책 제목"
        )
        NotificationCard(
            item: NotificationItemDto(
                id: 2,
                type: "GROUP_COMMENT_CREATED",
                title: "새로운 댓글이 달렸어요",
                message: "닉네임 님이 책 제목 그룹에 댓글을 남겼어요. 확인해볼까요?",
                isRead: true,
                createdAt: "2026-04-24T05:25:00",
                readAt: nil,
                payload: nil
            ),
            bookTitle: "책 제목"
        )
        NotificationEmptyCard()
    }
    .padding(20)
    .background(Color("grey100"))
}
