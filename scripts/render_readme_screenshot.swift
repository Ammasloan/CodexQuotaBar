import AppKit
import Foundation

struct Canvas {
    let width: CGFloat
    let height: CGFloat

    var size: NSSize {
        NSSize(width: width, height: height)
    }

    func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
        NSRect(x: x, y: self.height - y - height, width: width, height: height)
    }
}

enum PreviewLanguage {
    case english
    case chinese
}

struct PreviewCopy {
    let title: String
    let subtitle: String
    let quotaTitle: String
    let fiveHourTitle: String
    let fiveHourRemaining: String
    let fiveHourUsed: String
    let fiveHourReset: String
    let fiveHourResetAt: String
    let sevenDayTitle: String
    let sevenDayRemaining: String
    let sevenDayUsed: String
    let sevenDayReset: String
    let sevenDayResetAt: String
    let usageTitle: String
    let fiveHourTokensTitle: String
    let fiveHourTokensDetail: String
    let fiveHourTokensValue: String
    let latestRequestTitle: String
    let latestRequestDetail: String
    let latestRequestValue: String
    let sessionTotalTitle: String
    let sessionTotalDetail: String
    let sessionTotalValue: String
    let logsButton: String
    let instancesButton: String
    let quitButton: String

    static func copy(for language: PreviewLanguage) -> PreviewCopy {
        switch language {
        case .english:
            PreviewCopy(
                title: "Codex Usage",
                subtitle: "Pro Lite  ·  gpt-5.5  ·  Updated 2s ago",
                quotaTitle: "Quota",
                fiveHourTitle: "5-Hour Quota",
                fiveHourRemaining: "81% left",
                fiveHourUsed: "Used 19%",
                fiveHourReset: "Resets 3h 43m",
                fiveHourResetAt: "2:45 PM",
                sevenDayTitle: "7-Day Quota",
                sevenDayRemaining: "77% left",
                sevenDayUsed: "Used 23%",
                sevenDayReset: "Resets 118h 29m",
                sevenDayResetAt: "9:31 AM",
                usageTitle: "Recent Usage",
                fiveHourTokensTitle: "Last 5 Hours Tokens",
                fiveHourTokensDetail: "Input 21.0M · Output 96.0k",
                fiveHourTokensValue: "21.1M",
                latestRequestTitle: "Latest Request",
                latestRequestDetail: "Input 97.6k · Output 37",
                latestRequestValue: "97.7k",
                sessionTotalTitle: "Current Session Total",
                sessionTotalDetail: "Input 25.0M · Output 112.4k",
                sessionTotalValue: "25.1M",
                logsButton: "Logs",
                instancesButton: "Instances",
                quitButton: "Quit"
            )
        case .chinese:
            PreviewCopy(
                title: "Codex 使用情况",
                subtitle: "Pro Lite  ·  gpt-5.5  ·  更新于 10 秒前",
                quotaTitle: "额度",
                fiveHourTitle: "5 小时额度",
                fiveHourRemaining: "剩余 81%",
                fiveHourUsed: "已用 19%",
                fiveHourReset: "重置 3h 43m",
                fiveHourResetAt: "14:45",
                sevenDayTitle: "7 天额度",
                sevenDayRemaining: "剩余 77%",
                sevenDayUsed: "已用 23%",
                sevenDayReset: "重置 118h 29m",
                sevenDayResetAt: "09:31",
                usageTitle: "最近使用",
                fiveHourTokensTitle: "最近 5 小时 Token",
                fiveHourTokensDetail: "输入 21.2M · 输出 96.5k",
                fiveHourTokensValue: "21.3M",
                latestRequestTitle: "最近一次请求",
                latestRequestDetail: "输入 98.2k · 输出 275",
                latestRequestValue: "98.4k",
                sessionTotalTitle: "当前会话累计",
                sessionTotalDetail: "输入 25.2M · 输出 112.8k",
                sessionTotalValue: "25.3M",
                logsButton: "日志",
                instancesButton: "多开",
                quitButton: "退出"
            )
        }
    }
}

let canvas = Canvas(width: 440, height: 560)
let englishURL = URL(fileURLWithPath: "docs/assets/codexquotabar-preview-en.png")
let chineseURL = URL(fileURLWithPath: "docs/assets/codexquotabar-preview-zh.png")
let legacyURL = URL(fileURLWithPath: "docs/assets/codexquotabar-preview.png")

func rounded(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func fillRounded(_ rect: NSRect, radius: CGFloat, fill: NSColor, stroke: NSColor = .clear, lineWidth: CGFloat = 1, shadow: NSShadow? = nil) {
    NSGraphicsContext.saveGraphicsState()
    shadow?.set()
    let path = rounded(rect, radius: radius)
    fill.setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    if stroke.alphaComponent > 0 {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func drawText(
    _ text: String,
    in rect: NSRect,
    size: CGFloat,
    weight: NSFont.Weight = .regular,
    color: NSColor = .labelColor,
    alignment: NSTextAlignment = .left
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byTruncatingTail

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph,
    ]

    (text as NSString).draw(in: rect, withAttributes: attributes)
}

func drawRing(center: CGPoint, radius: CGFloat, lineWidth: CGFloat, fraction: CGFloat, accent: NSColor) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    context.setLineWidth(lineWidth)
    context.setLineCap(.round)
    context.setStrokeColor(NSColor.labelColor.withAlphaComponent(0.08).cgColor)
    context.addArc(center: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
    context.strokePath()

    context.setStrokeColor(accent.cgColor)
    let start = CGFloat.pi / 2
    let end = start - CGFloat.pi * 2 * fraction
    context.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: true)
    context.strokePath()
    context.restoreGState()
}

func drawCodexMark(center: CGPoint, radius: CGFloat) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    context.setFillColor(NSColor.systemGreen.cgColor)

    for index in 0..<6 {
        let angle = CGFloat(index) * CGFloat.pi / 3
        let dotCenter = CGPoint(
            x: center.x + cos(angle) * radius * 0.46,
            y: center.y + sin(angle) * radius * 0.46
        )
        context.fillEllipse(in: CGRect(x: dotCenter.x - radius * 0.15, y: dotCenter.y - radius * 0.15, width: radius * 0.30, height: radius * 0.30))
    }

    context.fillEllipse(in: CGRect(x: center.x - radius * 0.13, y: center.y - radius * 0.13, width: radius * 0.26, height: radius * 0.26))
    context.restoreGState()
}

func drawGlassShell(_ canvas: Canvas) {
    NSGradient(colors: [
        NSColor(calibratedRed: 0.83, green: 0.72, blue: 0.92, alpha: 1),
        NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.98, alpha: 1),
    ])?.draw(in: NSRect(origin: .zero, size: canvas.size), angle: -85)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowBlurRadius = 22
    shadow.shadowOffset = NSSize(width: 0, height: -8)

    let panel = canvas.rect(0, 3, 440, 557)
    fillRounded(panel, radius: 18, fill: NSColor(calibratedWhite: 0.98, alpha: 0.92), stroke: NSColor.white.withAlphaComponent(0.90), shadow: shadow)
    NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.76),
        NSColor(calibratedRed: 0.91, green: 0.92, blue: 0.95, alpha: 0.58),
        NSColor(calibratedRed: 0.80, green: 0.84, blue: 0.87, alpha: 0.36),
    ])?.draw(in: rounded(panel.insetBy(dx: 1, dy: 1), radius: 17), angle: -90)
}

func drawHeader(_ canvas: Canvas, copy: PreviewCopy) {
    drawCodexMark(center: CGPoint(x: 27, y: canvas.height - 29), radius: 17)
    drawText(copy.title, in: canvas.rect(52, 16, 190, 20), size: 16, weight: .bold)
    drawText(copy.subtitle, in: canvas.rect(52, 38, 260, 16), size: 11, color: .secondaryLabelColor)

    fillRounded(canvas.rect(311, 10, 54, 37), radius: 7, fill: NSColor.white.withAlphaComponent(0.78), stroke: NSColor.white.withAlphaComponent(0.86))
    fillRounded(canvas.rect(374, 10, 52, 37), radius: 7, fill: NSColor.white.withAlphaComponent(0.78), stroke: NSColor.white.withAlphaComponent(0.86))
    drawText("↻", in: canvas.rect(329, 18, 18, 20), size: 20, weight: .medium, alignment: .center)
    drawText("⚙", in: canvas.rect(390, 18, 20, 20), size: 18, weight: .medium, alignment: .center)
}

func drawSection(_ canvas: Canvas, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, title: String) {
    let rect = canvas.rect(x, y, width, height)
    fillRounded(rect, radius: 14, fill: NSColor.white.withAlphaComponent(0.62), stroke: NSColor.white.withAlphaComponent(0.90))
    drawText(title, in: canvas.rect(x + 12, y + 13, width - 24, 18), size: 12, weight: .semibold, color: .secondaryLabelColor)
}

func drawQuotaRow(
    _ canvas: Canvas,
    y: CGFloat,
    title: String,
    number: String,
    remaining: String,
    used: String,
    reset: String,
    resetAt: String,
    fraction: CGFloat,
    accent: NSColor,
    tint: NSColor
) {
    let row = canvas.rect(26, y, 388, 81)
    fillRounded(row, radius: 11, fill: tint, stroke: accent.withAlphaComponent(0.14))

    let ringCenter = CGPoint(x: row.minX + 39, y: row.midY)
    drawRing(center: ringCenter, radius: 28, lineWidth: 7, fraction: fraction, accent: accent)
    drawText(number, in: NSRect(x: ringCenter.x - 20, y: ringCenter.y - 12, width: 40, height: 24), size: 20, weight: .bold, alignment: .center)

    drawText(title, in: NSRect(x: row.minX + 84, y: row.maxY - 31, width: 155, height: 20), size: 14, weight: .bold)
    drawText(remaining, in: NSRect(x: row.maxX - 112, y: row.maxY - 31, width: 100, height: 20), size: 14, weight: .bold, color: accent, alignment: .right)

    let bar = NSRect(x: row.minX + 84, y: row.midY - 2, width: row.width - 128, height: 5)
    fillRounded(bar, radius: 3, fill: NSColor.labelColor.withAlphaComponent(0.08))
    fillRounded(NSRect(x: bar.minX, y: bar.minY, width: bar.width * fraction, height: bar.height), radius: 3, fill: accent)

    drawText(used, in: NSRect(x: row.minX + 84, y: row.minY + 13, width: 78, height: 16), size: 11, color: .secondaryLabelColor)
    drawText(reset, in: NSRect(x: row.minX + 162, y: row.minY + 13, width: 132, height: 16), size: 11, color: .secondaryLabelColor)
    drawText(resetAt, in: NSRect(x: row.maxX - 72, y: row.minY + 13, width: 60, height: 16), size: 11, color: .secondaryLabelColor, alignment: .right)
}

func drawMetricRow(_ canvas: Canvas, y: CGFloat, title: String, detail: String, value: String) {
    let row = canvas.rect(26, y, 388, 51)
    fillRounded(row, radius: 10, fill: NSColor(calibratedWhite: 0.97, alpha: 0.72), stroke: NSColor.white.withAlphaComponent(0.80))
    drawText(title, in: NSRect(x: row.minX + 10, y: row.maxY - 27, width: 220, height: 18), size: 13, weight: .bold)
    drawText(detail, in: NSRect(x: row.minX + 10, y: row.minY + 10, width: 250, height: 16), size: 10.5, color: .secondaryLabelColor)
    drawText(value, in: NSRect(x: row.maxX - 106, y: row.midY - 13, width: 92, height: 26), size: 20, weight: .bold, alignment: .right)
}

func drawToolbar(_ canvas: Canvas, copy: PreviewCopy) {
    let toolbar = canvas.rect(14, 493, 412, 54)
    fillRounded(toolbar, radius: 12, fill: NSColor(calibratedWhite: 0.94, alpha: 0.88), stroke: NSColor.white.withAlphaComponent(0.88))

    let items = [("▱  \(copy.logsButton)", 14.0), ("◫  \(copy.instancesButton)", 154.0), ("⏻  \(copy.quitButton)", 294.0)]
    for item in items {
        fillRounded(canvas.rect(item.1, 508, 132, 38), radius: 6, fill: NSColor.white.withAlphaComponent(0.78), stroke: NSColor.white.withAlphaComponent(0.84))
        drawText(item.0, in: canvas.rect(item.1, 520, 132, 15), size: 12, weight: .medium, alignment: .center)
    }
}

func renderPreview(language: PreviewLanguage) -> NSImage {
    let copy = PreviewCopy.copy(for: language)
    let image = NSImage(size: canvas.size)
    image.lockFocus()

    drawGlassShell(canvas)
    drawHeader(canvas, copy: copy)

    drawSection(canvas, x: 14, y: 71, width: 412, height: 222, title: copy.quotaTitle)
    drawQuotaRow(
        canvas,
        y: 107,
        title: copy.fiveHourTitle,
        number: "81",
        remaining: copy.fiveHourRemaining,
        used: copy.fiveHourUsed,
        reset: copy.fiveHourReset,
        resetAt: copy.fiveHourResetAt,
        fraction: 0.81,
        accent: .systemGreen,
        tint: NSColor(calibratedRed: 0.88, green: 0.96, blue: 0.90, alpha: 0.78)
    )
    drawQuotaRow(
        canvas,
        y: 200,
        title: copy.sevenDayTitle,
        number: "77",
        remaining: copy.sevenDayRemaining,
        used: copy.sevenDayUsed,
        reset: copy.sevenDayReset,
        resetAt: copy.sevenDayResetAt,
        fraction: 0.77,
        accent: .systemBlue,
        tint: NSColor(calibratedRed: 0.87, green: 0.93, blue: 0.99, alpha: 0.82)
    )

    drawSection(canvas, x: 14, y: 306, width: 412, height: 210, title: copy.usageTitle)
    drawMetricRow(canvas, y: 342, title: copy.fiveHourTokensTitle, detail: copy.fiveHourTokensDetail, value: copy.fiveHourTokensValue)
    drawMetricRow(canvas, y: 403, title: copy.latestRequestTitle, detail: copy.latestRequestDetail, value: copy.latestRequestValue)
    drawMetricRow(canvas, y: 464, title: copy.sessionTotalTitle, detail: copy.sessionTotalDetail, value: copy.sessionTotalValue)

    drawToolbar(canvas, copy: copy)

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [.compressionFactor: 0.94]) else {
        fatalError("Failed to render \(url.lastPathComponent)")
    }

    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try png.write(to: url)
}

let english = renderPreview(language: .english)
let chinese = renderPreview(language: .chinese)

try writePNG(english, to: englishURL)
try writePNG(chinese, to: chineseURL)
try writePNG(chinese, to: legacyURL)

print(englishURL.path)
print(chineseURL.path)
