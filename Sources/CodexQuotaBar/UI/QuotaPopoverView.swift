import AppKit
import SwiftUI

struct QuotaPopoverView: View {
    @ObservedObject var store: CodexUsageStore
    @AppStorage(AppPreferences.Keys.language) private var languageCode = AppLanguage.defaultLanguage.rawValue
    @AppStorage(AppPreferences.Keys.subscriptionStartAt) private var subscriptionStartAt = Date().timeIntervalSince1970
    @AppStorage(AppPreferences.Keys.subscriptionDurationDays) private var subscriptionDurationDays = 0.0
    @AppStorage(AppPreferences.Keys.subscriptionCost) private var subscriptionCost = 0.0
    @AppStorage(AppPreferences.Keys.currencySymbol) private var currencySymbol = AppPreferences.defaultCurrencySymbol
    @AppStorage(AppPreferences.Keys.tokenInputCostPerMillion) private var tokenInputCostPerMillion = 0.0
    @AppStorage(AppPreferences.Keys.tokenCachedInputCostPerMillion) private var tokenCachedInputCostPerMillion = 0.0
    @AppStorage(AppPreferences.Keys.tokenOutputCostPerMillion) private var tokenOutputCostPerMillion = 0.0

    let onRefresh: () -> Void
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    let onCloseOtherInstances: () -> Void
    let onQuit: () -> Void

    private var snapshot: CodexSnapshot {
        store.snapshot
    }

    private var language: AppLanguage {
        AppLanguage.resolved(languageCode)
    }

    private var text: AppText {
        AppText(language)
    }

    private var subscriptionSettings: SubscriptionSettings {
        SubscriptionSettings(
            startDate: Date(timeIntervalSince1970: subscriptionStartAt),
            durationDays: subscriptionDurationDays,
            cost: subscriptionCost,
            currencySymbol: resolvedCurrencySymbol
        )
    }

    private var tokenPricing: TokenPricing {
        TokenPricing(
            inputCostPerMillion: tokenInputCostPerMillion,
            cachedInputCostPerMillion: tokenCachedInputCostPerMillion,
            outputCostPerMillion: tokenOutputCostPerMillion
        )
    }

    private var resolvedCurrencySymbol: String {
        let trimmed = currencySymbol.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? AppPreferences.defaultCurrencySymbol : trimmed
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
                    if subscriptionSettings.isConfigured {
                        subscriptionSection
                    }
                    usageSection
                    detailsSection
                }
                .padding(14)
            }
            .scrollIndicators(.never)

            hairline
            commandBar
        }
        .frame(width: 440, height: 600)
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
                Text(text.codexUsageTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(snapshot.subtitleLine(language: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            iconButton(systemImage: "arrow.clockwise", label: text.refreshHelp, action: onRefresh)
            iconButton(systemImage: "gearshape", label: text.settingsHelp, action: onOpenSettings)
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
        panel(title: text.quotaSectionTitle) {
            VStack(spacing: 10) {
                quotaRow(
                    title: text.fiveHourQuotaTitle,
                    quota: snapshot.primaryQuota,
                    accent: fiveHourAccent
                )

                quotaRow(
                    title: text.sevenDayQuotaTitle,
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

                    Text(text.remaining(quota.compactRemainingLabel))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accent)
                        .monospacedDigit()
                        .lineLimit(1)
                }

                ProgressView(value: quota.remainingFraction ?? 0)
                    .tint(accent)
                    .controlSize(.small)

                HStack(spacing: 8) {
                    Text(text.used(quota.compactUsedLabel))
                    Text(text.reset(quota.resetCountdown(from: snapshot.refreshedAt, language: language)))
                    Spacer(minLength: 4)
                    Text(quota.resetAbsoluteText(language: language))
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
        panel(title: text.usageSectionTitle) {
            VStack(spacing: 8) {
                metricRow(
                    title: text.recentFiveHourTokensTitle,
                    value: MetricFormatters.abbreviatedTokens(snapshot.fiveHourTokens.totalTokens),
                    detail: text.tokenDetailWithCost(
                        input: snapshot.fiveHourTokens.inputTokens,
                        output: snapshot.fiveHourTokens.outputTokens,
                        cost: costLabel(for: snapshot.fiveHourTokens)
                    )
                )

                metricRow(
                    title: text.latestRequestTitle,
                    value: snapshot.lastRequestTokens.map { MetricFormatters.abbreviatedTokens($0.totalTokens) } ?? text.noData,
                    detail: snapshot.lastRequestTokens.map {
                        text.tokenDetailWithCost(
                            input: $0.inputTokens,
                            output: $0.outputTokens,
                            cost: costLabel(for: $0)
                        )
                    } ?? text.waitingForRequestData
                )

                metricRow(
                    title: text.currentSessionTotalTitle,
                    value: snapshot.latestSessionTotalTokens.map { MetricFormatters.abbreviatedTokens($0.totalTokens) } ?? text.noData,
                    detail: sessionDetailText
                )

                if let savingsMetric {
                    metricRow(
                        title: savingsMetric.title,
                        value: savingsMetric.value,
                        detail: savingsMetric.detail
                    )
                }
            }
        }
    }

    private var subscriptionSection: some View {
        panel(title: text.subscriptionPanelTitle) {
            VStack(spacing: 8) {
                metricRow(
                    title: text.subscriptionRemainingTitle,
                    value: subscriptionRemainingValue,
                    detail: text.subscriptionRemainingDetail(
                        endsAt: MetricFormatters.fullDate(subscriptionSettings.endDate, language: language),
                        cost: MetricFormatters.money(subscriptionSettings.cost, symbol: resolvedCurrencySymbol)
                    )
                )

                if tokenPricing.isConfigured {
                    metricRow(
                        title: text.subscriptionValueLabel,
                        value: MetricFormatters.money(subscriptionCycleValue, symbol: resolvedCurrencySymbol),
                        detail: text.inputOutputDetail(
                            input: snapshot.subscriptionCycleTokens.inputTokens,
                            output: snapshot.subscriptionCycleTokens.outputTokens
                        )
                    )
                }
            }
        }
    }

    private var detailsSection: some View {
        panel(title: text.statusSectionTitle) {
            VStack(spacing: 8) {
                cleanRow(label: text.latestEventLabel, value: MetricFormatters.fullDate(snapshot.latestEventAt, language: language))
                cleanRow(label: text.planLabel, value: snapshot.planType.map(CodexSnapshot.prettyPlanName) ?? text.unknown)
                cleanRow(label: text.modelLabel, value: snapshot.modelName ?? text.unknown)
            }
        }
    }

    private var commandBar: some View {
        HStack(spacing: 10) {
            toolbarButton(systemImage: "folder", title: text.logsButtonTitle, action: onOpenLogs)
            toolbarButton(systemImage: "square.stack.3d.up.slash", title: text.multipleInstancesButtonTitle, action: onCloseOtherInstances)
            toolbarButton(systemImage: "power", title: text.quitButtonTitle, action: onQuit)
        }
        .padding(14)
        .background(.thinMaterial)
    }

    private var sessionDetailText: String {
        let input = snapshot.latestSessionTotalTokens.map { MetricFormatters.abbreviatedTokens($0.inputTokens) } ?? "--"
        let output = snapshot.latestSessionTotalTokens.map { MetricFormatters.abbreviatedTokens($0.outputTokens) } ?? "--"
        let cache = MetricFormatters.cacheRatio(snapshot.latestSessionTotalTokens) ?? "--"
        let cost = snapshot.latestSessionTotalTokens.flatMap { costLabel(for: $0) }
        return text.sessionDetailWithCost(input: input, output: output, cache: cache, cost: cost)
    }

    private var subscriptionRemainingValue: String {
        let remaining = subscriptionSettings.remainingInterval(at: snapshot.refreshedAt)
        guard remaining > 0 else {
            return text.expired
        }

        return MetricFormatters.compactDuration(remaining, language: language)
    }

    private var subscriptionCycleValue: Double {
        tokenPricing.cost(for: snapshot.subscriptionCycleTokens)
    }

    private var savingsMetric: (title: String, value: String, detail: String)? {
        guard subscriptionSettings.isConfigured, tokenPricing.isConfigured else {
            return nil
        }

        let cycleValue = subscriptionCycleValue
        let savings = cycleValue - subscriptionSettings.cost
        let title = savings >= 0 ? text.savingsTitle : text.paybackTitle
        let value = "\(MetricFormatters.money(abs(savings), symbol: resolvedCurrencySymbol)) \(MetricFormatters.savingsEmoji(savings))"
        let detail = text.savingsDetail(
            cycleValue: MetricFormatters.money(cycleValue, symbol: resolvedCurrencySymbol),
            planCost: MetricFormatters.money(subscriptionSettings.cost, symbol: resolvedCurrencySymbol)
        )
        return (title, value, detail)
    }

    private func costLabel(for totals: TokenTotals) -> String? {
        guard tokenPricing.isConfigured else {
            return nil
        }

        return MetricFormatters.money(tokenPricing.cost(for: totals), symbol: resolvedCurrencySymbol)
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
