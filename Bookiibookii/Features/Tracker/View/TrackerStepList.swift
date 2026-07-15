import SwiftUI

// 트래커 상세 단계 리스트. 진행중이 맨 위, 완료가 아래로 쌓임(순서는 mapper가 이미 구성).
struct TrackerStepList: View {
    let steps: [TrackerStep]

    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(step.title)
                                .pretendardText(size: 16, weight: isCompleted(step) ? .regular : .medium)
                                .foregroundColor(isCompleted(step) ? Color("grey600") : Color("grey900"))
                            Spacer(minLength: 8)
                            stepChip(step.status)
                        }
                        Text(step.description)
                            .pretendardText(size: 14)
                            .foregroundColor(Color("grey500"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if index < steps.count - 1 {
                        Rectangle().fill(Color("grey100")).frame(height: 1).padding(.top, 16)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func isCompleted(_ step: TrackerStep) -> Bool {
        if case .completed = step.status { return true }
        return false
    }

    @ViewBuilder
    private func stepChip(_ status: TrackerStepStatus) -> some View {
        switch status {
        case let .inProgress(chipText):
            Text(chipText)
                .pretendardText(size: 11)
                .foregroundColor(Color("main200"))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color("white")))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color("main105"), lineWidth: 1))
        case .completed:
            Text("완료")
                .pretendardText(size: 11)
                .foregroundColor(Color("grey500"))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color("grey200")))
        }
    }
}
