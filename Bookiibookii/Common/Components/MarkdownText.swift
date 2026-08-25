import SwiftUI

/// 서버에서 마크다운으로 내려오는 본문(공지사항 등)을 렌더링한다.
/// 안드로이드 `NoticeDetailScreen`의 Markdown 타이포그래피와 크기를 맞췄다.
/// (본문 14 / h1 22 · h2 20 · h3 18 · h4 16 · h5 15 · h6 14 / 코드 13)
struct MarkdownText: View {
    let markdown: String
    var bodySize: CGFloat = 14
    var bodyColor: Color = Color("grey700")
    var headingColor: Color = Color("grey900")
    var linkColor: Color = Color("main200")

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(MarkdownBlock.parse(markdown).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Blocks

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            let size = headingSize(for: level)
            inlineText(text, size: size, weight: .semibold, color: headingColor)
                .pretendardMetrics(size: size)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, level <= 2 ? 6 : 2)

        case .paragraph(let text):
            inlineText(text, size: bodySize, weight: .regular, color: bodyColor)
                .pretendardMetrics(size: bodySize)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .listItem(let marker, let text, let depth):
            HStack(alignment: .top, spacing: 6) {
                Text(marker)
                    .pretendardText(size: bodySize)
                    .foregroundColor(bodyColor)
                inlineText(text, size: bodySize, weight: .regular, color: bodyColor)
                    .pretendardMetrics(size: bodySize)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, CGFloat(depth) * 14)

        case .quote(let text):
            HStack(alignment: .top, spacing: 8) {
                Rectangle()
                    .fill(Color("grey200"))
                    .frame(width: 3)
                inlineText(text, size: bodySize, weight: .regular, color: Color("grey600"))
                    .pretendardMetrics(size: bodySize)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .fixedSize(horizontal: false, vertical: true)

        case .codeBlock(let code):
            Text(code)
                .font(.system(size: bodySize - 1, design: .monospaced))
                .foregroundColor(bodyColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color("grey100"))
                .clipShape(RoundedRectangle(cornerRadius: 8))

        case .divider:
            Divider().overlay(Color("grey200"))
        }
    }

    /// 안드로이드와 동일한 단계별 크기 차이 (h1 = 본문 + 8 … h6 = 본문)
    private func headingSize(for level: Int) -> CGFloat {
        let deltas: [CGFloat] = [8, 6, 4, 2, 1, 0]
        let index = min(max(level, 1), deltas.count) - 1
        return bodySize + deltas[index]
    }

    // MARK: - Inline (굵게 / 기울임 / 인라인 코드 / 링크)

    private func inlineText(
        _ raw: String,
        size: CGFloat,
        weight: Font.Weight,
        color: Color
    ) -> Text {
        Text(inlineAttributed(raw, size: size, weight: weight, color: color))
    }

    private func inlineAttributed(
        _ raw: String,
        size: CGFloat,
        weight: Font.Weight,
        color: Color
    ) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: true,
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        var result = (try? AttributedString(markdown: raw, options: options)) ?? AttributedString(raw)

        // 런을 순회하며 바로 수정하면 인덱스가 무효화되므로 먼저 범위를 모아둔다
        let runs = result.runs.map { ($0.range, $0.inlinePresentationIntent, $0.link != nil) }

        for (range, intent, isLink) in runs {
            let isCode = intent?.contains(.code) ?? false
            let isStrong = intent?.contains(.stronglyEmphasized) ?? false
            let isEmphasized = intent?.contains(.emphasized) ?? false

            var font: Font = isCode
                ? .system(size: size - 1, design: .monospaced)
                : .pretendard(size: size, weight: isStrong ? .semibold : weight)
            if isEmphasized { font = font.italic() }

            result[range].font = font
            result[range].foregroundColor = isLink ? linkColor : color
            if isLink { result[range].underlineStyle = .single }
        }
        return result
    }
}

// MARK: - Parsing

/// 공지 본문에서 쓰이는 범위의 마크다운만 블록 단위로 끊어낸다.
enum MarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case listItem(marker: String, text: String, depth: Int)
    case quote(String)
    case codeBlock(String)
    case divider

    static func parse(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraphLines: [String] = []
        var codeLines: [String] = []
        var isInCodeFence = false

        // 문단 안의 줄바꿈은 그대로 살린다. 공지는 작성자가 넣은 줄바꿈이 의미를 갖는 경우가 많다
        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            blocks.append(.paragraph(paragraphLines.joined(separator: "\n")))
            paragraphLines.removeAll()
        }

        for rawLine in markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("```") {
                if isInCodeFence {
                    blocks.append(.codeBlock(codeLines.joined(separator: "\n")))
                    codeLines.removeAll()
                }
                isInCodeFence.toggle()
                continue
            }
            if isInCodeFence {
                codeLines.append(rawLine)
                continue
            }

            if line.isEmpty {
                flushParagraph()
                continue
            }

            if isDivider(line) {
                flushParagraph()
                blocks.append(.divider)
                continue
            }

            if let heading = headingBlock(line) {
                flushParagraph()
                blocks.append(heading)
                continue
            }

            if let item = listItemBlock(rawLine) {
                flushParagraph()
                blocks.append(item)
                continue
            }

            if line.hasPrefix(">") {
                flushParagraph()
                let text = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                blocks.append(.quote(text))
                continue
            }

            paragraphLines.append(line)
        }

        flushParagraph()
        if isInCodeFence, !codeLines.isEmpty {
            blocks.append(.codeBlock(codeLines.joined(separator: "\n")))
        }
        return blocks
    }

    /// `---`, `***`, `___` (3자 이상)
    private static func isDivider(_ line: String) -> Bool {
        guard line.count >= 3 else { return false }
        return ["-", "*", "_"].contains { symbol in
            line.allSatisfy { String($0) == symbol }
        }
    }

    /// `#` ~ `######`
    private static func headingBlock(_ line: String) -> MarkdownBlock? {
        let hashes = line.prefix { $0 == "#" }
        guard (1...6).contains(hashes.count) else { return nil }
        let rest = line.dropFirst(hashes.count)
        guard rest.first == " " else { return nil }
        return .heading(
            level: hashes.count,
            text: rest.trimmingCharacters(in: .whitespaces)
        )
    }

    /// `- `, `* `, `+ ` 및 `1. `, `1) `
    private static func listItemBlock(_ rawLine: String) -> MarkdownBlock? {
        let indent = rawLine.prefix { $0 == " " || $0 == "\t" }.count
        let depth = min(indent / 2, 3)
        let line = rawLine.trimmingCharacters(in: .whitespaces)

        if let bullet = line.first, "-*+".contains(bullet), line.dropFirst().first == " " {
            return .listItem(
                marker: "•",
                text: line.dropFirst(2).trimmingCharacters(in: .whitespaces),
                depth: depth
            )
        }

        let digits = line.prefix { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        let afterDigits = line.dropFirst(digits.count)
        guard let separator = afterDigits.first, separator == "." || separator == ")",
              afterDigits.dropFirst().first == " " else { return nil }
        return .listItem(
            marker: "\(digits)\(separator)",
            text: afterDigits.dropFirst(2).trimmingCharacters(in: .whitespaces),
            depth: depth
        )
    }
}

#Preview("Markdown Sample") {
    ScrollView {
        MarkdownText(markdown: """
        # 부키부키 업데이트 안내
        안녕하세요, **부키부키 팀**입니다.

        ## 새로 추가된 기능
        - 독서카드 공유
        - 그룹 신청 알림
          - 하위 항목도 들여씁니다

        ### 개선 사항
        1. 로그인 속도 개선
        2. *일부* 오류 수정

        > 문의는 카카오 채널로 남겨주세요.

        ---
        자세한 내용은 [공식 사이트](https://www.bookiibookii.com)를 확인해 주세요.
        """)
        .padding(20)
    }
    .background(Color("grey100"))
}
