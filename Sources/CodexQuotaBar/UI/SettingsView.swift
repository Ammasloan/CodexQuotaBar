import SwiftUI

struct SettingsView: View {
    @AppStorage(AppPreferences.Keys.refreshInterval) private var refreshInterval = AppPreferences.defaultRefreshInterval
    @AppStorage(AppPreferences.Keys.autoCloseOtherInstances) private var autoCloseOtherInstances = true
    @AppStorage(AppPreferences.Keys.language) private var languageCode = AppLanguage.defaultLanguage.rawValue

    let onCloseOtherInstances: () -> Void
    let onOpenLogs: () -> Void

    private var language: AppLanguage {
        AppLanguage.resolved(languageCode)
    }

    private var text: AppText {
        AppText(language)
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
        .frame(width: 440, height: 390)
        .onChange(of: refreshInterval) { _ in
            AppPreferences.notifyDidChange()
        }
        .onChange(of: autoCloseOtherInstances) { _ in
            AppPreferences.notifyDidChange()
        }
        .onChange(of: languageCode) { _ in
            AppPreferences.notifyDidChange()
        }
    }
}
