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
