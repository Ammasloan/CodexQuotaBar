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
    @State private var selectedMonitorID: String?

    let onRefresh: () -> Void
    let onOpenSettings: () -> Void
    let onOpenLogs: (MonitorTarget) -> Void
    let onCloseOtherInstances: () -> Void
    let onQuit: () -> Void

    private var language: AppLanguage {
        AppLanguage.resolved(languageCode)
    }

    private var text: AppText {
        AppText(language)
    }

    private var monitorSnapshots: [MonitorSnapshot] {
        store.monitorSnapshots
    }

    private var selectedMonitor: MonitorSnapshot? {
        if let selectedMonitorID,
           let monitor = monitorSnapshots.first(where: { $0.id == selectedMonitorID }) {
            return monitor
        }

        return monitorSnapshots.first
    }

    private var snapshot: CodexSnapshot {
        selectedMonitor?.snapshot ?? .empty
    }

    private var selectedTarget: MonitorTarget? {
        selectedMonitor?.target
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

    var body: some View {
        HStack(spacing: 0) {
            sidebar

            Divider()

            if let selectedMonitor {
                content(for: selectedMonitor)
            } else {
                emptyState
            }
        }
        .frame(width: 500, height: 760)
        .background(Color.white.opacity(0.98))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .onAppear {
            ensureSelectedMonitor()
        }
        .onChange(of: monitorSnapshots) { _ in
            ensureSelectedMonitor()
        }
    }

    private var sidebar: some View {
        VStack(spacing: 15) {
            ForEach(monitorSnapshots) { monitor in
                monitorButton(monitor)
            }

            Spacer()

            railIcon(systemImage: "questionmark.circle", color: .secondary) {
                onOpenSettings()
            }

            railIcon(systemImage: "gearshape", color: .secondary) {
                onOpenSettings()
            }
        }
        .padding(.vertical, 26)
        .frame(width: 60)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.50))
    }

    private func monitorButton(_ monitor: MonitorSnapshot) -> some View {
        let isSelected = monitor.id == selectedMonitor?.id
        let color = Color(hex: monitor.target.colorHex) ?? .primary

        return Button {
            selectedMonitorID = monitor.id
        } label: {
            ZStack(alignment: .leading) {
                if isSelected {
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: 3, height: 36)
                        .offset(x: -11)
                }

                Image(systemName: monitor.target.systemImage)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(isSelected ? color : color.opacity(0.58))
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .help(monitor.target.name)
    }

    private func railIcon(systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func content(for monitor: MonitorSnapshot) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header(for: monitor)

                VStack(spacing: 22) {
                    quotaLine(title: text.sessionQuotaTitle, quota: monitor.snapshot.primaryQuota)
                    quotaLine(title: text.weeklyQuotaTitle, quota: monitor.snapshot.secondaryQuota)

                    if subscriptionSettings.isConfigured {
                        quotaLine(
                            title: text.subscriptionPanelTitle,
                            progress: subscriptionSettings.elapsedFraction(at: monitor.snapshot.refreshedAt),
                            leftLabel: subscriptionRemainingValue(for: monitor.snapshot),
                            rightLabel: text.subscriptionEndsLabel + " " + MetricFormatters.fullDate(subscriptionSettings.endDate, language: language)
                        )
                    }
                }

                creditsSection(for: monitor.snapshot)

                footer(for: monitor)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 26)
        }
        .scrollIndicators(.never)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func header(for monitor: MonitorSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(monitor.target.name)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Text(monitor.snapshot.planType.map(CodexSnapshot.prettyPlanName) ?? text.unknown)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
            }

            HStack(spacing: 10) {
                topButton(title: text.statusButtonTitle, systemImage: "arrow.up.right.square", action: onRefresh)
                topButton(title: text.usageDashboardButtonTitle, systemImage: "arrow.up.right.square", action: onOpenSettings)
            }
        }
    }

    private func topButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func quotaLine(title: String, quota: QuotaWindow) -> some View {
        quotaLine(
            title: title,
            progress: quota.remainingFraction ?? 0,
            leftLabel: language == .zhHans ? text.remaining(quota.compactRemainingLabel) : "\(quota.compactRemainingLabel) left",
            rightLabel: text.reset(quota.resetCountdown(from: snapshot.refreshedAt, language: language))
        )
    }

    private func quotaLine(title: String, progress: Double, leftLabel: String, rightLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                Circle()
                    .fill(Color.green)
                    .frame(width: 9, height: 9)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.045))
                    Capsule()
                        .fill(Color(red: 0.04, green: 0.07, blue: 0.12))
                        .frame(width: max(0, proxy.size.width * min(max(progress, 0), 1)))
                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 2)
                        .offset(x: max(0, proxy.size.width * 0.94))
                }
            }
            .frame(height: 16)

            HStack {
                Text(leftLabel)
                Spacer()
                Text(rightLabel)
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
    }

    private func creditsSection(for snapshot: CodexSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(text.creditsTitle)
                .font(.system(size: 20, weight: .bold))

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.045))
                    Capsule()
                        .fill(Color(red: 0.04, green: 0.07, blue: 0.12))
                        .frame(width: max(0, proxy.size.width * savingsProgress))
                }
            }
            .frame(height: 16)

            HStack {
                Text(creditsLeftText)
                Spacer()
                Text(subscriptionSettings.isConfigured ? MetricFormatters.money(subscriptionSettings.cost, symbol: resolvedCurrencySymbol) : text.noData)
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                usageStatRow(title: text.todayLabel, totals: snapshot.todayTokens)
                usageStatRow(title: text.yesterdayLabel, totals: snapshot.yesterdayTokens)
                usageStatRow(title: text.lastThirtyDaysLabel, totals: snapshot.thirtyDayTokens)
            }
            .padding(.top, 8)
        }
    }

    private func usageStatRow(title: String, totals: TokenTotals) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(costOrPlaceholder(for: totals)) · \(MetricFormatters.abbreviatedTokens(totals.totalTokens)) tokens")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .font(.system(size: 15, weight: .medium))
    }

    private func footer(for monitor: MonitorSnapshot) -> some View {
        VStack(spacing: 16) {
            Divider()

            HStack {
                Text("CodexQuotaBar")
                Spacer()
                Text("\(text.nextUpdatePrefix) \(Int(AppPreferences.refreshInterval))s")
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                footerButton(systemImage: "folder", title: text.logsButtonTitle) {
                    onOpenLogs(monitor.target)
                }
                footerButton(systemImage: "square.stack.3d.up.slash", title: text.multipleInstancesButtonTitle, action: onCloseOtherInstances)
                footerButton(systemImage: "power", title: text.quitButtonTitle, action: onQuit)
            }
        }
    }

    private func footerButton(systemImage: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.secondary)
            Text(text.noMonitorData)
                .font(.system(size: 18, weight: .semibold))
            Button(text.settingsHelp, action: onOpenSettings)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var savingsProgress: Double {
        guard subscriptionSettings.isConfigured, tokenPricing.isConfigured, subscriptionSettings.cost > 0 else {
            return 0
        }

        return min(max(subscriptionCycleValue / subscriptionSettings.cost, 0), 1)
    }

    private var subscriptionCycleValue: Double {
        tokenPricing.cost(for: snapshot.subscriptionCycleTokens)
    }

    private var creditsLeftText: String {
        guard subscriptionSettings.isConfigured, tokenPricing.isConfigured else {
            return text.noData
        }

        let savings = subscriptionCycleValue - subscriptionSettings.cost
        if savings >= 0 {
            return "\(text.savingsTitle) \(MetricFormatters.money(savings, symbol: resolvedCurrencySymbol)) \(MetricFormatters.savingsEmoji(savings))"
        }

        return "\(text.paybackTitle) \(MetricFormatters.money(abs(savings), symbol: resolvedCurrencySymbol))"
    }

    private func subscriptionRemainingValue(for snapshot: CodexSnapshot) -> String {
        let remaining = subscriptionSettings.remainingInterval(at: snapshot.refreshedAt)
        guard remaining > 0 else {
            return text.expired
        }

        return MetricFormatters.compactDuration(remaining, language: language)
    }

    private func costOrPlaceholder(for totals: TokenTotals) -> String {
        guard tokenPricing.isConfigured else {
            return text.noData
        }

        return MetricFormatters.money(tokenPricing.cost(for: totals), symbol: resolvedCurrencySymbol)
    }

    private func ensureSelectedMonitor() {
        if let selectedMonitorID,
           monitorSnapshots.contains(where: { $0.id == selectedMonitorID }) {
            return
        }

        selectedMonitorID = monitorSnapshots.first?.id
    }
}

private extension Color {
    init?(hex: String) {
        var rawValue = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawValue.hasPrefix("#") {
            rawValue.removeFirst()
        }

        guard rawValue.count == 6,
              let value = Int(rawValue, radix: 16) else {
            return nil
        }

        let red = Double((value >> 16) & 0xff) / 255
        let green = Double((value >> 8) & 0xff) / 255
        let blue = Double(value & 0xff) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
