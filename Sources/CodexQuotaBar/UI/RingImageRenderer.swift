import AppKit

enum RingImageRenderer {
    static func makeStatusImage(for snapshot: CodexSnapshot) -> NSImage {
        let size = NSSize(width: 17, height: 17)
        let image = NSImage(size: size)
        image.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        let rect = CGRect(x: 1.7, y: 1.7, width: 13.6, height: 13.6)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2
        let color = statusColor(for: snapshot.primaryQuota.remainingPercent)

        context.setLineWidth(2.15)
        context.setLineCap(.round)
        context.setStrokeColor(NSColor.labelColor.withAlphaComponent(0.16).cgColor)
        context.strokeEllipse(in: rect)

        if let fraction = snapshot.primaryQuota.remainingFraction, fraction > 0 {
            let startAngle = CGFloat.pi / 2
            let endAngle = startAngle - (CGFloat.pi * 2 * CGFloat(fraction))
            let arc = CGMutablePath()
            arc.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

            context.addPath(arc)
            context.setStrokeColor(color.cgColor)
            context.strokePath()
        }

        let innerRect = rect.insetBy(dx: 5.0, dy: 5.0)
        context.setFillColor(NSColor.labelColor.withAlphaComponent(0.10).cgColor)
        context.fillEllipse(in: innerRect)

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    static func statusColor(for remainingPercent: Double?) -> NSColor {
        guard let remainingPercent else {
            return NSColor.systemGray
        }

        switch remainingPercent {
        case 60...:
            return NSColor.systemGreen
        case 25..<60:
            return NSColor.systemOrange
        default:
            return NSColor.systemRed
        }
    }
}
