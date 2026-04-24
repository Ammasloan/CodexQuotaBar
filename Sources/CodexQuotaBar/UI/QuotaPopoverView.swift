import AppKit
import SwiftUI

struct QuotaPopoverView: View {
    @ObservedObject var store: CodexUsageStore
    let onRefresh: () -> Void
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    let onCloseOtherInstances: () -> Void
    let onQuit: () -> Void

    private var snapshot: CodexSnapshot {
        store.snapshot
    }

    private var fiveHourAccent: Color {
        Color(nsColor: RingImageRenderer.statusColor(for: snapshot.primaryQuota.remainingPercent))
    }

    private let weekAccent = Color(nsColor: .systemBlue)

    var body: some View {
        VStack(spacing: 0) {
            header
            hairline

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    quotaSection
                    usageSection
                    detailsSection
                }
                .padding(14)
            }
            .scrollIndicators(.never)

            hairline
            commandBar
        }
        .frame(width: 440, height: 560)
        .background {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.34),
                        Color(nsColor: .windowBackgroundColor).opacity(0.48),
                        Color(nsColor: .controlAccentColor).opacity(0.08),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(fiveHourAccent)
                .frame(width: 28, height: 28)
                .glassSurface(cornerRadius: 14, tint: fiveHourAccent.opacity(0.18))

            VStack(alignment: .leading, spacing: 1) {
                Text("Codex 使用情况")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(snapshot.subtitleLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            iconButton(systemImage: "arrow.clockwise", label: "刷新", action: onRefresh)
            iconButton(systemImage: "gearshape", label: "设置", action: onOpenSettings)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var hairline: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.36),
                        Color(nsColor: .separatorColor).opacity(0.22),
                        Color.white.opacity(0.20),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    private var quotaSection: some View {
        panel(title: "额度") {
            VStack(spacing: 10) {
                quotaRow(
                    title: "5 小时额度",
                    quota: snapshot.primaryQuota,
                    accent: fiveHourAccent
                )

                quotaRow(
                    title: "7 天额度",
                    quota: snapshot.secondaryQuota,
                    accent: weekAccent
                )
            }
        }
    }

    private func quotaRow(title: String, quota: QuotaWindow, accent: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 7)

                Circle()
                    .trim(from: 0, to: CGFloat(quota.remainingFraction ?? 0))
                    .stroke(accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text(quota.remainingNumberLabel)
                    .font(.system(size: 18, weight: .semibold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text("剩余 \(quota.compactRemainingLabel)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accent)
                        .monospacedDigit()
                        .lineLimit(1)
                }

                ProgressView(value: quota.remainingFraction ?? 0)
                    .tint(accent)
                    .controlSize(.small)

                HStack(spacing: 8) {
                    Text("已用 \(quota.compactUsedLabel)")
                    Text("重置 \(quota.resetCountdown(from: snapshot.refreshedAt))")
                    Spacer(minLength: 4)
                    Text(quota.resetAbsoluteText)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            }
        }
        .padding(12)
        .glassSurface(cornerRadius: 12, tint: accent.opacity(0.12))
    }

    private var usageSection: some View {
        panel(title: "最近使用") {
            VStack(spacing: 8) {
                metricRow(
                    title: "最近 5 小时 Token",
                    value: MetricFormatters.abbreviatedTokens(snapshot.fiveHourTokens.totalTokens),
                    detail: "输入 \(MetricFormatters.abbreviatedTokens(snapshot.fiveHourTokens.inputTokens)) · 输出 \(MetricFormatters.abbreviatedTokens(snapshot.fiveHourTokens.outputTokens))"
                )

                metricRow(
                    title: "最近一次请求",
                    value: snapshot.lastRequestTokens.map { MetricFormatters.abbreviatedTokens($0.totalTokens) } ?? "暂无",
                    detail: snapshot.lastRequestTokens.map { "输入 \(MetricFormatters.abbreviatedTokens($0.inputTokens)) · 输出 \(MetricFormatters.abbreviatedTokens($0.outputTokens))" } ?? "等待新的请求数据"
                )

                metricRow(
                    title: "当前会话累计",
                    value: snapshot.latestSessionTotalTokens.map { MetricFormatters.abbreviatedTokens($0.totalTokens) } ?? "暂无",
                    detail: sessionDetailText
                )
            }
        }
    }

    private var detailsSection: some View {
        panel(title: "状态") {
            VStack(spacing: 8) {
                cleanRow(label: "最近事件", value: MetricFormatters.fullDate(snapshot.latestEventAt))
                cleanRow(label: "计划", value: snapshot.planType.map(CodexSnapshot.prettyPlanName) ?? "未知")
                cleanRow(label: "模型", value: snapshot.modelName ?? "未知")
            }
        }
    }

    private var commandBar: some View {
        HStack(spacing: 10) {
            toolbarButton(systemImage: "folder", title: "日志", action: onOpenLogs)
            toolbarButton(systemImage: "square.stack.3d.up.slash", title: "多开", action: onCloseOtherInstances)
            toolbarButton(systemImage: "power", title: "退出", action: onQuit)
        }
        .padding(14)
        .background(.thinMaterial)
    }

    private var sessionDetailText: String {
        let input = snapshot.latestSessionTotalTokens.map { MetricFormatters.abbreviatedTokens($0.inputTokens) } ?? "--"
        let output = snapshot.latestSessionTotalTokens.map { MetricFormatters.abbreviatedTokens($0.outputTokens) } ?? "--"
        let cache = MetricFormatters.cacheRatio(snapshot.latestSessionTotalTokens) ?? "--"
        return "输入 \(input) · 输出 \(output) · 缓存率 \(cache)"
    }

    private func metricRow(title: String, value: String, detail: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 10)

            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(10)
        .glassSurface(cornerRadius: 10, tint: Color.white.opacity(0.12))
    }

    private func cleanRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 12)

            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .lineLimit(1)
                .truncationMode(.middle)
                .minimumScaleFactor(0.82)
        }
    }

    private func panel<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            content()
        }
        .padding(12)
        .glassSurface(cornerRadius: 14, tint: Color.white.opacity(0.18))
    }

    private func iconButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .glassButtonStyle()
        .help(label)
    }

    private func toolbarButton(systemImage: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity, minHeight: 30)
                .contentShape(Rectangle())
        }
        .glassButtonStyle()
    }
}

private extension View {
    @ViewBuilder
    func glassSurface(cornerRadius: CGFloat, tint: Color) -> some View {
        if #available(macOS 26.0, *) {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                )
                .glassEffect(.regular.tint(tint), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.62),
                                    Color.white.opacity(0.14),
                                    Color.black.opacity(0.08),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.10), radius: 14, x: 0, y: 8)
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.regularMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.opacity(0.20))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.34), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        }
    }

    @ViewBuilder
    func glassButtonStyle() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self
                .buttonStyle(.plain)
                .padding(.horizontal, 2)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.regularMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.32), lineWidth: 1)
                )
        }
    }
}
