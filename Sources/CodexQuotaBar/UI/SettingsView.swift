import SwiftUI

struct SettingsView: View {
    @AppStorage(AppPreferences.Keys.refreshInterval) private var refreshInterval = AppPreferences.defaultRefreshInterval
    @AppStorage(AppPreferences.Keys.autoCloseOtherInstances) private var autoCloseOtherInstances = true

    let onCloseOtherInstances: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        Form {
            Section("刷新") {
                Picker("刷新频率", selection: $refreshInterval) {
                    ForEach(AppPreferences.supportedRefreshIntervals, id: \.self) { interval in
                        Text("\(Int(interval)) 秒").tag(interval)
                    }
                }
                .pickerStyle(.menu)

                Text("菜单栏和详情面板会按这个频率重新读取本地 Codex 会话日志。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("行为") {
                Toggle("启动时自动关闭其他实例", isOn: $autoCloseOtherInstances)

                Text("建议保持开启，这样误开的调试版或旧版本会被自动收掉，不会在菜单栏出现两个图标。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("维护") {
                Button("立即关闭其他实例", action: onCloseOtherInstances)
                Button("打开日志文件夹", action: onOpenLogs)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 420, height: 300)
        .onChange(of: refreshInterval) { _ in
            AppPreferences.notifyDidChange()
        }
        .onChange(of: autoCloseOtherInstances) { _ in
            AppPreferences.notifyDidChange()
        }
    }
}
