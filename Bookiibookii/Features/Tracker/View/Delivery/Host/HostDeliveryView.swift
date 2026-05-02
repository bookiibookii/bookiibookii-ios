import SwiftUI

// 안드 HostActivity 대응. ViewModel이 phase / 시트 / 액션을 관리.
struct HostDeliveryView: View {
    @StateObject private var vm: HostDeliveryViewModel
    private let onBack: () -> Void

    init(groupId: Int, service: TrackerService, onBack: @escaping () -> Void = {}) {
        _vm = StateObject(wrappedValue: HostDeliveryViewModel(groupId: groupId, service: service))
        self.onBack = onBack
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Rectangle()
                .fill(Color(red: 0xEE/255, green: 0xEE/255, blue: 0xEE/255))
                .frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    statusTitle.padding(.leading, 20).padding(.top, 24)
                    statusCard.padding(.horizontal, 20).padding(.top, 16)
                }
                .padding(.bottom, 50)
            }
        }
        .background(Color("grey100"))
        .task { await vm.onAppear() }
        .sheet(item: $vm.activeSheet, onDismiss: { /* 자동 dismiss 시 별도 처리 없음 */ }) { sheet in
            sheetView(for: sheet)
        }
        .overlay {
            if vm.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(ProgressView().tint(.white))
            }
        }
        .toast($vm.toastMessage)
    }

    // MARK: - 툴바

    private var toolbar: some View {
        ZStack {
            Text(vm.detail?.bookTitle ?? "")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(Color("black"))
                .lineLimit(1)
                .padding(.horizontal, 60)

            HStack {
                Button(action: onBack) {
                    Image("ic_back")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color("black"))
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)

                Spacer()

                Button { vm.tapStep(.groupManage) } label: {
                    Image("ic_more")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
    }

    // MARK: - 상태 카드

    private var statusTitle: some View {
        HStack(spacing: 0) {
            Text(vm.detail?.partnerNickname ?? "")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(Color("main200"))
            Text(" 님과의 현황")
                .font(.pretendard(size: 18))
                .foregroundColor(Color("black"))
        }
    }

    private var statusCard: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                let row = rows[index]
                Button {
                    if let sheet = row.sheet { vm.tapStep(sheet) }
                } label: {
                    TradeStatusRow(item: row.step)
                }
                .buttonStyle(.plain)
                if index != rows.count - 1 {
                    Rectangle()
                        .fill(Color("grey100"))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// 현재 phase에 맞춰 7단계 row를 생성. 안드로이드 TrackerDataMapper.buildRows 대응(간소화 버전).
    private var rows: [DeliveryRow] {
        let p = vm.phase
        return [
            DeliveryRow(step: .init(title: "호스트 독서", description: "책을 읽고 있어요",
                                    badge: badge(for: p, threshold: .hostReading)),
                        sheet: .reading),
            DeliveryRow(step: .init(title: "게스트에게 발송", description: "운송장 등록 후 발송",
                                    badge: badge(for: p, threshold: .hostShipped)),
                        sheet: .shippingInput),
            DeliveryRow(step: .init(title: "게스트 수령", description: "게스트가 책을 수령",
                                    badge: badge(for: p, threshold: .guestReading)),
                        sheet: .readingStatus),
            DeliveryRow(step: .init(title: "게스트 독서", description: "게스트가 책을 읽는 중",
                                    badge: badge(for: p, threshold: .guestReading)),
                        sheet: .readingStatus),
            DeliveryRow(step: .init(title: "호스트에게 회수", description: "게스트가 발송",
                                    badge: badge(for: p, threshold: .guestShipped)),
                        sheet: .shippingStatus),
            DeliveryRow(step: .init(title: "호스트 수령", description: "수령 사진 등록",
                                    badge: badge(for: p, threshold: .guestShipped)),
                        sheet: .receiveConfirm),
            DeliveryRow(step: .init(title: "거래 종료", description: "리뷰 작성",
                                    badge: badge(for: p, threshold: .finished)),
                        sheet: .tradeFinish),
        ]
    }

    private func badge(for phase: DeliveryPhase, threshold: DeliveryPhase) -> String {
        let order: [DeliveryPhase] = [
            .initState, .hostReading, .hostShippingReady, .hostShipped,
            .guestReading, .guestShippingReady, .guestShipped, .finished
        ]
        let current = order.firstIndex(of: phase) ?? 0
        let target = order.firstIndex(of: threshold) ?? 0
        if current > target { return "완료" }
        if current == target { return "진행중" }
        return "대기"
    }

    // MARK: - 시트 라우팅 (Task 12~17에서 case별 시트 채움)

    @ViewBuilder
    private func sheetView(for sheet: DeliverySheet) -> some View {
        switch sheet {
        default:
            // 임시 placeholder — Task 12~17에서 각 시트로 교체
            Text("시트: \(sheet.rawValue)")
                .padding(40)
                .presentationDetents([.medium])
        }
    }
}

private struct DeliveryRow {
    let step: TradeStepRow
    let sheet: DeliverySheet?
}

// MARK: - Preview용 더미 의존성

#Preview("HostDelivery") {
    HostDeliveryView(
        groupId: 1,
        service: TrackerService(interceptor: AuthInterceptor(authService: AuthService()))
    )
}

// MARK: - 단계 행 (안드 item_trade_status.xml + TradeStatusItem 대응)

struct TradeStepRow: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let badge: String
}

private struct TradeStatusRow: View {
    let item: TradeStepRow

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.pretendard(size: 16, weight: .medium))
                    .foregroundColor(Color("grey900"))
                Text(item.description)
                    .font(.pretendard(size: 12))
                    .foregroundColor(Color("grey500"))
            }
            Spacer()
            Text(item.badge)
                .font(.pretendard(size: 12))
                .foregroundColor(Color("grey500"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color("grey200"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
