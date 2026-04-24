import AppKit
import Foundation

let canvasWidth: CGFloat = 1280
let canvasHeight: CGFloat = 900
let scale: CGFloat = 2
let outputURL = URL(fileURLWithPath: "docs/assets/codexquotabar-preview.png")

func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
    NSRect(x: x, y: canvasHeight - y - height, width: width, height: height)
}

func rounded(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func color(_ white: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedWhite: white, alpha: alpha)
}

func drawText(_ text: String, in rect: NSRect, size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor = .labelColor, alignment: NSTextAlignment = .left) {
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

func drawRoundedFill(_ rect: NSRect, radius: CGFloat, fill: NSColor, stroke: NSColor = .clear, lineWidth: CGFloat = 1, shadow: NSShadow? = nil) {
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

func drawGlassSurface(_ rect: NSRect, radius: CGFloat, tint: NSColor = .white, shadowRadius: CGFloat = 18) {
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.14)
    shadow.shadowBlurRadius = shadowRadius
    shadow.shadowOffset = NSSize(width: 0, height: -8)

    drawRoundedFill(
        rect,
        radius: radius,
        fill: NSColor.white.withAlphaComponent(0.46),
        stroke: NSColor.white.withAlphaComponent(0.66),
        lineWidth: 1,
        shadow: shadow
    )

    let overlay = rounded(rect.insetBy(dx: 1, dy: 1), radius: max(radius - 1, 1))
    NSGradient(colors: [
        tint.withAlphaComponent(0.22),
        NSColor.white.withAlphaComponent(0.07),
        NSColor.black.withAlphaComponent(0.035),
    ])?.draw(in: overlay, angle: -35)
}

func drawRing(center: CGPoint, radius: CGFloat, lineWidth: CGFloat, fraction: CGFloat, accent: NSColor) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    context.setLineWidth(lineWidth)
    context.setLineCap(.round)
    context.setStrokeColor(NSColor.black.withAlphaComponent(0.08).cgColor)
    context.addArc(center: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
    context.strokePath()

    context.setStrokeColor(accent.cgColor)
    let start = CGFloat.pi / 2
    let end = start - CGFloat.pi * 2 * fraction
    context.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: true)
    context.strokePath()
    context.restoreGState()
}

func drawQuotaRow(y: CGFloat, title: String, remaining: String, used: String, reset: String, resetAt: String, fraction: CGFloat, accent: NSColor) {
    let row = rect(438, y, 404, 96)
    drawGlassSurface(row, radius: 18, tint: accent, shadowRadius: 10)

    let ringCenter = CGPoint(x: row.minX + 54, y: row.midY)
    drawRing(center: ringCenter, radius: 28, lineWidth: 7, fraction: fraction, accent: accent)
    drawText(remaining.replacingOccurrences(of: "%", with: ""), in: NSRect(x: ringCenter.x - 20, y: ringCenter.y - 11, width: 40, height: 24), size: 17, weight: .semibold, alignment: .center)

    drawText(title, in: NSRect(x: row.minX + 98, y: row.maxY - 34, width: 160, height: 22), size: 15, weight: .semibold)
    drawText("剩余 \(remaining)", in: NSRect(x: row.maxX - 130, y: row.maxY - 34, width: 110, height: 22), size: 15, weight: .semibold, color: accent, alignment: .right)

    let bar = NSRect(x: row.minX + 98, y: row.midY - 3, width: row.width - 122, height: 6)
    drawRoundedFill(bar, radius: 3, fill: NSColor.black.withAlphaComponent(0.08))
    drawRoundedFill(NSRect(x: bar.minX, y: bar.minY, width: bar.width * fraction, height: bar.height), radius: 3, fill: accent.withAlphaComponent(0.88))

    drawText("已用 \(used)", in: NSRect(x: row.minX + 98, y: row.minY + 15, width: 80, height: 18), size: 11.5, color: .secondaryLabelColor)
    drawText("重置 \(reset)", in: NSRect(x: row.minX + 178, y: row.minY + 15, width: 110, height: 18), size: 11.5, color: .secondaryLabelColor)
    drawText(resetAt, in: NSRect(x: row.maxX - 100, y: row.minY + 15, width: 82, height: 18), size: 11.5, color: .secondaryLabelColor, alignment: .right)
}

func drawMetric(y: CGFloat, title: String, value: String, detail: String) {
    let row = rect(438, y, 404, 60)
    drawGlassSurface(row, radius: 14, tint: .white, shadowRadius: 7)
    drawText(title, in: NSRect(x: row.minX + 14, y: row.maxY - 26, width: 190, height: 20), size: 13, weight: .medium)
    drawText(detail, in: NSRect(x: row.minX + 14, y: row.minY + 12, width: 260, height: 18), size: 11.5, color: .secondaryLabelColor)
    drawText(value, in: NSRect(x: row.maxX - 120, y: row.midY - 12, width: 104, height: 26), size: 19, weight: .semibold, alignment: .right)
}

let image = NSImage(size: NSSize(width: canvasWidth, height: canvasHeight))
image.lockFocus()

NSGradient(colors: [
    NSColor(calibratedRed: 0.78, green: 0.86, blue: 0.94, alpha: 1),
    NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.98, alpha: 1),
    NSColor(calibratedRed: 0.88, green: 0.94, blue: 0.91, alpha: 1),
])?.draw(in: NSRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight), angle: -35)

drawRoundedFill(rect(0, 0, canvasWidth, 48), radius: 0, fill: NSColor.white.withAlphaComponent(0.42))
drawText("CodexQuotaBar", in: rect(34, 15, 180, 20), size: 13, weight: .semibold)
drawText("90%", in: rect(1104, 13, 44, 22), size: 13, weight: .semibold, alignment: .right)

let menuRingCenter = CGPoint(x: 1086, y: canvasHeight - 24)
drawRing(center: menuRingCenter, radius: 8, lineWidth: 2, fraction: 0.90, accent: .systemGreen)
drawText("Fri 10:30", in: rect(1170, 14, 82, 20), size: 12, color: .secondaryLabelColor, alignment: .right)

let panel = rect(400, 102, 480, 646)
drawGlassSurface(panel, radius: 28, tint: NSColor.systemGreen, shadowRadius: 30)

drawText("Codex 使用情况", in: NSRect(x: panel.minX + 62, y: panel.maxY - 48, width: 180, height: 24), size: 16, weight: .semibold)
drawText("Pro Lite · gpt-5.4 · 更新于 1m ago", in: NSRect(x: panel.minX + 62, y: panel.maxY - 70, width: 270, height: 18), size: 11.5, color: .secondaryLabelColor)
drawRing(center: CGPoint(x: panel.minX + 34, y: panel.maxY - 42), radius: 12, lineWidth: 3, fraction: 0.90, accent: .systemGreen)

drawText("额度", in: NSRect(x: panel.minX + 32, y: panel.maxY - 108, width: 80, height: 20), size: 13, weight: .semibold, color: .secondaryLabelColor)
drawQuotaRow(y: 230, title: "5 小时额度", remaining: "90%", used: "10%", reset: "1h 42m", resetAt: "12:13", fraction: 0.90, accent: .systemGreen)
drawQuotaRow(y: 338, title: "7 天额度", remaining: "84%", used: "16%", reset: "5d 18h", resetAt: "Apr 29", fraction: 0.84, accent: .systemBlue)

drawText("最近使用", in: NSRect(x: panel.minX + 32, y: panel.maxY - 354, width: 120, height: 20), size: 13, weight: .semibold, color: .secondaryLabelColor)
drawMetric(y: 476, title: "最近 5 小时 Token", value: "3.2M", detail: "输入 3.1M · 输出 37k")
drawMetric(y: 546, title: "最近一次请求", value: "77.8k", detail: "输入 76.4k · 输出 1.4k")
drawMetric(y: 616, title: "当前会话累计", value: "3.2M", detail: "输入 3.2M · 输出 37k · 缓存率 95%")

drawText("效果预览使用示例数据", in: NSRect(x: panel.minX, y: panel.minY - 34, width: panel.width, height: 20), size: 11.5, color: NSColor.secondaryLabelColor, alignment: .center)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [.compressionFactor: 0.92]) else {
    fatalError("Failed to render preview image")
}

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: outputURL)
print(outputURL.path)
