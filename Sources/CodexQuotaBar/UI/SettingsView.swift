import SwiftUI

struct SettingsView: View {
    @AppStorage(AppPreferences.Keys.refreshInterval) private var refreshInterval = AppPreferences.defaultRefreshInterval
    @AppStorage(AppPreferences.Keys.autoCloseOtherInstances) private var autoCloseOtherInstances = true
    @AppStorage(AppPreferences.Keys.language) private var languageCode = AppLanguage.defaultLanguage.rawValue
    @AppStorage(AppPreferences.Keys.subscriptionStartAt) private var subscriptionStartAt = Date().timeIntervalSince1970
    @AppStorage(AppPreferences.Keys.subscriptionDurationDays) private var subscriptionDurationDays = 0.0
    @AppStorage(AppPreferences.Keys.subscriptionCost) private var subscriptionCost = 0.0
    @AppStorage(AppPreferences.Keys.currencySymbol) private var currencySymbol = AppPreferences.defaultCurrencySymbol
    @AppStorage(AppPreferences.Keys.tokenInputCostPerMillion) private var tokenInputCostPerMillion = 0.0
    @AppStorage(AppPreferences.Keys.tokenCachedInputCostPerMillion) private var tokenCachedInputCostPerMillion = 0.0
    @AppStorage(AppPreferences.Keys.tokenOutputCostPerMillion) private var tokenOutputCostPerMillion = 0.0
    @State private var monitorTargets = AppPreferences.monitorTargets

    let onCloseOtherInstances: () -> Void
    let onOpenLogs: () -> Void

    private var language: AppLanguage {
        AppLanguage.resolved(languageCode)
    }

    private var text: AppText {
        AppText(language)
    }

    private var subscriptionStartDate: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: subscriptionStartAt) },
            set: { subscriptionStartAt = $0.timeIntervalSince1970 }
        )
    }

    var body: some View {
        Form {
            Section(text.refreshSectionTitle) {
                Picker(text.refreshFrequencyLabel, selection: $refreshInterval) {
                    ForEach(AppPreferences.supportedRefreshIntervals, id: \.self) { interval in
                        Text(text.secondsLabel(interval)).tag(interval)
                    }
                }
                .pickerStyle(.menu)

                Text(text.refreshExplanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(text.languageSectionTitle) {
                Picker(text.interfaceLanguageLabel, selection: $languageCode) {
                    ForEach(AppLanguage.allCases) { option in
                        Text(text.languageName(for: option)).tag(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Text(text.languageExplanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(text.monitorsSectionTitle) {
                ForEach($monitorTargets) { $target in
                    monitorEditor(target: $target)
                }

                HStack {
                    Button(text.addMonitorTitle) {
                        monitorTargets.append(MonitorTarget.makeCustom(index: monitorTargets.count + 1))
                    }

                    Spacer()

                    Button(text.resetMonitorsTitle) {
                        monitorTargets = AppPreferences.defaultMonitorTargets
                    }
                }

                Text(text.monitorsExplanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(text.subscriptionSettingsSectionTitle) {
                DatePicker(text.subscriptionStartDateLabel, selection: subscriptionStartDate, displayedComponents: .date)

                numericSettingRow(
                    label: text.subscriptionDurationDaysLabel,
                    value: $subscriptionDurationDays,
                    suffix: language == .zhHans ? "天" : "days"
                )

                HStack {
                    Text(text.subscriptionCostLabel)
                    Spacer()
                    TextField("", value: $subscriptionCost, format: .number.precision(.fractionLength(0...2)))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                    Text(currencySymbol)
                        .foregroundStyle(.secondary)
                        .frame(width: 34, alignment: .leading)
                }

                HStack {
                    Text(text.currencySymbolLabel)
                    Spacer()
                    TextField("", text: $currencySymbol)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                }

                Text(text.subscriptionSettingsExplanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(text.tokenPricingSectionTitle) {
                priceSettingRow(label: text.inputTokenPriceLabel, value: $tokenInputCostPerMillion)
                priceSettingRow(label: text.cachedInputTokenPriceLabel, value: $tokenCachedInputCostPerMillion)
                priceSettingRow(label: text.outputTokenPriceLabel, value: $tokenOutputCostPerMillion)

                Text(text.tokenPricingExplanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(text.behaviorSectionTitle) {
                Toggle(text.autoCloseOtherInstancesLabel, isOn: $autoCloseOtherInstances)

                Text(text.autoCloseExplanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(text.maintenanceSectionTitle) {
                Button(text.closeOtherInstancesNowTitle, action: onCloseOtherInstances)
                Button(text.openLogsFolderTitle, action: onOpenLogs)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 500, height: 660)
        .onChange(of: refreshInterval) { _ in
            AppPreferences.notifyDidChange()
        }
        .onChange(of: autoCloseOtherInstances) { _ in
            AppPreferences.notifyDidChange()
        }
        .onChange(of: languageCode) { _ in
            AppPreferences.notifyDidChange()
        }
        .onChange(of: subscriptionStartAt) { _ in
            AppPreferences.notifyDidChange()
        }
        .onChange(of: subscriptionDurationDays) { _ in
            AppPreferences.notifyDidChange()
        }
        .onChange(of: subscriptionCost) { _ in
            AppPreferences.notifyDidChange()
        }
        .onChange(of: currencySymbol) { _ in
            AppPreferences.notifyDidChange()
        }
        .onChange(of: tokenInputCostPerMillion) { _ in
            AppPreferences.notifyDidChange()
        }
        .onChange(of: tokenCachedInputCostPerMillion) { _ in
            AppPreferences.notifyDidChange()
        }
        .onChange(of: tokenOutputCostPerMillion) { _ in
            AppPreferences.notifyDidChange()
        }
        .onChange(of: monitorTargets) { newValue in
            AppPreferences.monitorTargets = newValue
        }
    }

    private func monitorEditor(target: Binding<MonitorTarget>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(text.enabledLabel, isOn: target.isEnabled)

            textSettingRow(label: text.monitorNameLabel, value: target.name)
            textSettingRow(label: text.monitorIconLabel, value: target.systemImage)
            textSettingRow(label: text.monitorColorLabel, value: target.colorHex)

            pathSettingRow(label: text.monitorSessionsPathLabel, value: target.sessionsPath)
            pathSettingRow(label: text.monitorConfigPathLabel, value: target.configPath)

            if monitorTargets.count > 1 {
                Button(role: .destructive) {
                    monitorTargets.removeAll { $0.id == target.wrappedValue.id }
                } label: {
                    Text(text.removeMonitorTitle)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 6)
    }

    private func textSettingRow(label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", text: value)
                .multilineTextAlignment(.trailing)
                .frame(width: 230)
        }
    }

    private func pathSettingRow(label: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .foregroundStyle(.secondary)
            TextField("", text: value)
                .font(.system(.caption, design: .monospaced))
        }
    }

    private func numericSettingRow(label: String, value: Binding<Double>, suffix: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", value: value, format: .number.precision(.fractionLength(0...2)))
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            Text(suffix)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
        }
    }

    private func priceSettingRow(label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", value: value, format: .number.precision(.fractionLength(0...4)))
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            Text("\(currencySymbol) \(text.pricePerMillionSuffix)")
                .foregroundStyle(.secondary)
                .frame(width: 105, alignment: .leading)
        }
    }
}
