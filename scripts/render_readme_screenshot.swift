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

let popoverCanvas = Canvas(width: 450, height: 570)
let menuBarCanvas = Canvas(width: 104, height: 32)
let popoverURL = URL(fileURLWithPath: "docs/assets/codexquotabar-preview.png")
let menuBarURL = URL(fileURLWithPath: "docs/assets/codexquotabar-menubar.png")

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

func drawRing(center: CGPoint, radius: CGFloat, lineWidth: CGFloat, fraction: CGFloat, accent: NSColor, trackAlpha: CGFloat = 0.12) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    context.setLineWidth(lineWidth)
    context.setLineCap(.round)
    context.setStrokeColor(NSColor.labelColor.withAlphaComponent(trackAlpha).cgColor)
    context.addArc(center: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
    context.strokePath()

    context.setStrokeColor(accent.cgColor)
    let start = CGFloat.pi / 2
    let end = start - CGFloat.pi * 2 * fraction
    context.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: true)
    context.strokePath()
    context.restoreGState()
}

func drawGlassPanel(_ rect: NSRect, radius: CGFloat) {
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
    shadow.shadowBlurRadius = 22
    shadow.shadowOffset = NSSize(width: 0, height: -8)

    fillRounded(
        rect,
        radius: radius,
        fill: NSColor(calibratedWhite: 0.98, alpha: 0.90),
        stroke: NSColor.white.withAlphaComponent(0.85),
        lineWidth: 1,
        shadow: shadow
    )

    NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.70),
        NSColor(calibratedRed: 0.90, green: 0.93, blue: 0.95, alpha: 0.58),
        NSColor(calibratedRed: 0.82, green: 0.87, blue: 0.90, alpha: 0.40),
    ])?.draw(in: rounded(rect.insetBy(dx: 1, dy: 1), radius: radius - 1), angle: -90)
}

func drawSection(_ canvas: Canvas, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, title: String) -> NSRect {
    let rect = canvas.rect(x, y, width, height)
    fillRounded(
        rect,
        radius: 14,
        fill: NSColor.white.withAlphaComponent(0.62),
        stroke: NSColor.white.withAlphaComponent(0.90)
    )
    drawText(title, in: canvas.rect(x + 12, y + 13, width - 24, 18), size: 12, weight: .semibold, color: .secondaryLabelColor)
    return rect
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
    let row = canvas.rect(30, y, 390, 82)
    fillRounded(row, radius: 11, fill: tint, stroke: accent.withAlphaComponent(0.16))

    let ringCenter = CGPoint(x: row.minX + 38, y: row.midY)
    drawRing(center: ringCenter, radius: 28, lineWidth: 7, fraction: fraction, accent: accent, trackAlpha: 0.08)
    drawText(number, in: NSRect(x: ringCenter.x - 20, y: ringCenter.y - 12, width: 40, height: 24), size: 20, weight: .bold, alignment: .center)

    drawText(title, in: NSRect(x: row.minX + 84, y: row.maxY - 31, width: 150, height: 20), size: 14, weight: .bold)
    drawText("剩余 \(remaining)", in: NSRect(x: row.maxX - 102, y: row.maxY - 31, width: 90, height: 20), size: 14, weight: .bold, color: accent, alignment: .right)

    let bar = NSRect(x: row.minX + 84, y: row.midY - 2, width: row.width - 130, height: 5)
    fillRounded(bar, radius: 3, fill: NSColor.labelColor.withAlphaComponent(0.08))
    fillRounded(NSRect(x: bar.minX, y: bar.minY, width: bar.width * fraction, height: bar.height), radius: 3, fill: accent)

    drawText("已用 \(used)", in: NSRect(x: row.minX + 84, y: row.minY + 14, width: 70, height: 16), size: 11, color: .secondaryLabelColor)
    drawText("重置 \(reset)", in: NSRect(x: row.minX + 154, y: row.minY + 14, width: 120, height: 16), size: 11, color: .secondaryLabelColor)
    drawText(resetAt, in: NSRect(x: row.maxX - 54, y: row.minY + 14, width: 42, height: 16), size: 11, color: .secondaryLabelColor, alignment: .right)
}

func drawMetricRow(_ canvas: Canvas, y: CGFloat, title: String, detail: String, value: String) {
    let row = canvas.rect(30, y, 390, 53)
    fillRounded(row, radius: 10, fill: NSColor(calibratedWhite: 0.97, alpha: 0.72), stroke: NSColor.white.withAlphaComponent(0.80))
    drawText(title, in: NSRect(x: row.minX + 10, y: row.maxY - 27, width: 210, height: 18), size: 13, weight: .bold)
    drawText(detail, in: NSRect(x: row.minX + 10, y: row.minY + 11, width: 250, height: 16), size: 10.5, color: .secondaryLabelColor)
    drawText(value, in: NSRect(x: row.maxX - 105, y: row.midY - 13, width: 92, height: 26), size: 20, weight: .bold, alignment: .right)
}

func drawCodexMark(center: CGPoint, radius: CGFloat, color: NSColor) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    context.setFillColor(color.cgColor)
    for index in 0..<6 {
        let angle = CGFloat(index) * CGFloat.pi / 3
        let dotCenter = CGPoint(
            x: center.x + cos(angle) * radius * 0.48,
            y: center.y + sin(angle) * radius * 0.48
        )
        context.fillEllipse(in: CGRect(x: dotCenter.x - radius * 0.16, y: dotCenter.y - radius * 0.16, width: radius * 0.32, height: radius * 0.32))
    }
    context.fillEllipse(in: CGRect(x: center.x - radius * 0.14, y: center.y - radius * 0.14, width: radius * 0.28, height: radius * 0.28))
    context.restoreGState()
}

func renderPopover() -> NSImage {
    let canvas = popoverCanvas
    let image = NSImage(size: canvas.size)
    image.lockFocus()

    NSGradient(colors: [
        NSColor(calibratedRed: 0.86, green: 0.74, blue: 0.93, alpha: 1),
        NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.98, alpha: 1),
    ])?.draw(in: NSRect(origin: .zero, size: canvas.size), angle: -80)

    let panel = canvas.rect(4, 5, 442, 560)
    drawGlassPanel(panel, radius: 18)

    drawCodexMark(center: CGPoint(x: 31, y: canvas.height - 31), radius: 17, color: .systemGreen)
    drawText("Codex 使用情况", in: canvas.rect(56, 18, 180, 20), size: 16, weight: .bold)
    drawText("Pro Lite  ·  gpt-5.5  ·  更新于 3 分钟前", in: canvas.rect(56, 40, 230, 16), size: 11, color: .secondaryLabelColor)

    fillRounded(canvas.rect(316, 14, 52, 37), radius: 7, fill: NSColor.white.withAlphaComponent(0.78), stroke: NSColor.white.withAlphaComponent(0.86))
    fillRounded(canvas.rect(378, 14, 52, 37), radius: 7, fill: NSColor.white.withAlphaComponent(0.78), stroke: NSColor.white.withAlphaComponent(0.86))
    drawText("↻", in: canvas.rect(333, 22, 18, 20), size: 20, weight: .medium, alignment: .center)
    drawText("⚙", in: canvas.rect(394, 22, 20, 20), size: 18, weight: .medium, alignment: .center)

    _ = drawSection(canvas, x: 18, y: 76, width: 412, height: 221, title: "额度")
    drawQuotaRow(
        canvas,
        y: 112,
        title: "5 小时额度",
        number: "89",
        remaining: "89%",
        used: "11%",
        reset: "3h 59m",
        resetAt: "14:45",
        fraction: 0.89,
        accent: .systemGreen,
        tint: NSColor(calibratedRed: 0.88, green: 0.96, blue: 0.90, alpha: 0.78)
    )
    drawQuotaRow(
        canvas,
        y: 204,
        title: "7 天额度",
        number: "78",
        remaining: "78%",
        used: "22%",
        reset: "118h 45m",
        resetAt: "9:31",
        fraction: 0.78,
        accent: .systemBlue,
        tint: NSColor(calibratedRed: 0.87, green: 0.93, blue: 0.99, alpha: 0.80)
    )

    _ = drawSection(canvas, x: 18, y: 311, width: 412, height: 206, title: "最近使用")
    drawMetricRow(canvas, y: 347, title: "最近 5 小时 Token", detail: "输入 15.7M · 输出 60.7k", value: "15.8M")
    drawMetricRow(canvas, y: 405, title: "最近一次请求", detail: "输入 39.5k · 输出 804", value: "40.3k")
    drawMetricRow(canvas, y: 463, title: "当前会话累计", detail: "输入 19.9M · 输出 74.2k", value: "20.0M")

    let toolbar = canvas.rect(18, 500, 412, 52)
    fillRounded(toolbar, radius: 12, fill: NSColor(calibratedWhite: 0.94, alpha: 0.86), stroke: NSColor.white.withAlphaComponent(0.88))
    let buttonWidth: CGFloat = 130
    for (index, item) in [("▱  日志", 0), ("◫  多开", 1), ("⏻  退出", 2)] {
        let x = 20 + CGFloat(item) * (buttonWidth + 10)
        fillRounded(canvas.rect(x, 513, buttonWidth, 37), radius: 6, fill: NSColor.white.withAlphaComponent(0.78), stroke: NSColor.white.withAlphaComponent(0.84))
        drawText(index, in: canvas.rect(x, 524, buttonWidth, 15), size: 12, weight: .medium, alignment: .center)
    }

    image.unlockFocus()
    return image
}

func renderMenuBar() -> NSImage {
    let canvas = menuBarCanvas
    let image = NSImage(size: canvas.size)
    image.lockFocus()

    fillRounded(NSRect(origin: .zero, size: canvas.size), radius: 0, fill: NSColor(calibratedRed: 0.86, green: 0.87, blue: 0.89, alpha: 1))
    drawRing(center: CGPoint(x: 20, y: canvas.height - 16), radius: 7.2, lineWidth: 2.2, fraction: 0.89, accent: .systemGreen, trackAlpha: 0.18)
    drawText("89%", in: canvas.rect(31, 8, 31, 16), size: 11, weight: .semibold)

    let iconRect = canvas.rect(76, 7, 17, 17)
    fillRounded(iconRect, radius: 5, fill: NSColor(calibratedWhite: 0.08, alpha: 1))
    drawText("›", in: canvas.rect(80, 7, 8, 17), size: 14, weight: .bold, color: .white, alignment: .center)

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

try writePNG(renderPopover(), to: popoverURL)
try writePNG(renderMenuBar(), to: menuBarURL)
print(popoverURL.path)
print(menuBarURL.path)
