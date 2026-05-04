import SwiftUI
import Combine

struct ReportView: View {
    @EnvironmentObject private var container: DIContainer
    @StateObject private var viewModel: ReportViewModel
    let onTapReportButton: (() -> Void)?

    init(
        viewModel: ReportViewModel = ReportViewModel(reportFetcher: {
            await ReportLocalStore.shared.reports
        }),
        onTapReportButton: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onTapReportButton = onTapReportButton
    }

    var body: some View {
        ZStack {
            Color("grey100").ignoresSafeArea()

            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: "신고 내역",
                    onBack: { container.navigationRouter.pop() },
                    rightButton: .none
                )

                ScrollView(showsIndicators: false) {
                    contentSection
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                }
            }

            VStack {
                Spacer()
                reportButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Task {
                await viewModel.loadReports()
            }
        }
        .onReceive(ReportLocalStore.shared.$reports) { reports in
            viewModel.updateReports(reports)
        }
        .task {
            await viewModel.loadReports()
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 48)
        } else if viewModel.reports.isEmpty {
            emptyView
        } else {
            reportListView
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Text("아직 신고 내역이 없어요 😊")
                .font(.pretendard(size: 16, weight: .medium))
                .foregroundColor(Color("grey900"))

            Text("모두가 안심하고 대화할 수 있는 독서 공간을 만들어가요")
                .font(.pretendard(size: 14, weight: .regular))
                .foregroundColor(Color("grey600"))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var reportListView: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.reports) { report in
                ReportCardView(report: report)
            }
        }
    }

    private var reportButton: some View {
        Button {
            if let onTapReportButton {
                onTapReportButton()
            } else {
                container.navigationRouter.push(to: .reportDetail)
            }
        } label: {
            Text("신고하기")
                .font(.pretendard(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(Color("grey900"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

final class ReportViewModel: ObservableObject {
    typealias ReportFetcher = () async throws -> [ReportItem]

    @Published var reports: [ReportItem]
    @Published var isLoading = false

    private let reportFetcher: ReportFetcher?

    init(
        reports: [ReportItem] = [],
        reportFetcher: ReportFetcher? = nil
    ) {
        self.reports = reports
        self.reportFetcher = reportFetcher
    }

    func loadReports() async {
        guard let reportFetcher else { return }

        await MainActor.run { isLoading = true }

        do {
            let fetched = try await reportFetcher()
            await MainActor.run {
                reports = fetched
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }

    func updateReports(_ reports: [ReportItem]) {
        self.reports = reports
    }
}

struct ReportItem: Identifiable, Equatable {
    let id: UUID
    let reporterName: String
    let createdDate: String
    let bookTitle: String
    let reportReason: String
    let reportContent: String
    let response: ReportResponse?
}

struct ReportResponse: Equatable {
    let responderName: String
    let createdDate: String
    let content: String
}

private struct ReportCardView: View {
    let report: ReportItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            topRow

            VStack(alignment: .leading, spacing: 8) {
                titleRow
                Text(report.reportContent)
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey700"))
                    .lineSpacing(2)
            }

            statusOrResponseBox
        }
        .padding(16)
        .background(Color("white"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var topRow: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color("grey100"))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image("chat")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    )

                Text(report.reporterName)
                    .font(.pretendard(size: 11, weight: .medium))
                    .foregroundColor(Color("grey900"))
            }

            Spacer()

            Text(report.createdDate)
                .font(.pretendard(size: 11, weight: .regular))
                .foregroundColor(Color("grey400"))
        }
    }

    private var titleRow: some View {
        HStack(spacing: 4) {
            Text(report.bookTitle)
                .font(.pretendard(size: 14, weight: .medium))
                .foregroundColor(Color("grey900"))

            Text("(\(report.reportReason))")
                .font(.pretendard(size: 14, weight: .regular))
                .foregroundColor(Color("grey900"))
        }
    }

    @ViewBuilder
    private var statusOrResponseBox: some View {
        if let response = report.response {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(response.responderName)
                        .font(.pretendard(size: 12, weight: .regular))
                        .foregroundColor(Color("main200"))
                    Spacer()
                    Text(response.createdDate)
                        .font(.pretendard(size: 11, weight: .regular))
                        .foregroundColor(Color("grey400"))
                }
                Text(response.content)
                    .font(.pretendard(size: 14, weight: .regular))
                    .foregroundColor(Color("grey900"))
                    .lineSpacing(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("grey100"))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("grey200"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            Text("답변 대기 중입니다")
                .font(.pretendard(size: 14, weight: .regular))
                .foregroundColor(Color("grey500"))
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color("grey100"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("grey200"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

extension ReportItem {
    static let previewPending = ReportItem(
        id: UUID(),
        reporterName: "noshel",
        createdDate: "2024. 11. 29.",
        bookTitle: "괴테는 모든 것을 말했다",
        reportReason: "욕설/비방",
        reportContent: "책에 코멘트로 욕설을 너무 많이 달아서 책 돌려받았을 때 기분이 너무 나빴어요ㅠ",
        response: nil
    )

    static let previewAnswered = ReportItem(
        id: UUID(),
        reporterName: "noshel",
        createdDate: "2024. 11. 29.",
        bookTitle: "괴테는 모든 것을 말했다",
        reportReason: "욕설/비방",
        reportContent: "책에 코멘트로 욕설을 너무 많이 달아서 책 돌려받았을 때 기분이 너무 나빴어요ㅠ",
        response: ReportResponse(
            responderName: "부키부키 팀",
            createdDate: "2024.11.29",
            content: "기분이 나쁘셨겠어요ㅠㅠ 바로 noshel님의 매너온도를 -1000000하겠습니다 어쩌고 저쩌고"
        )
    )
}

@MainActor
final class ReportLocalStore: ObservableObject {
    static let shared = ReportLocalStore()

    @Published private(set) var reports: [ReportItem] = []

    private init() {}

    func submit(
        groupTitle: String,
        reason: ReportReason,
        content: String
    ) {
        reports.insert(
            ReportItem(
                id: UUID(),
                reporterName: "noshel",
                createdDate: Self.dateFormatter.string(from: Date()),
                bookTitle: groupTitle,
                reportReason: reason.displayText,
                reportContent: content,
                response: nil
            ),
            at: 0
        )
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd."
        return formatter
    }()
}

#Preview("신고내역 있음") {
    ReportView(
        viewModel: ReportViewModel(reports: [
            .previewPending,
            .previewAnswered
        ])
    )
    .environmentObject(DIContainer())
}

#Preview("신고내역 없음") {
    ReportView(
        viewModel: ReportViewModel(reports: [])
    )
    .environmentObject(DIContainer())
}
