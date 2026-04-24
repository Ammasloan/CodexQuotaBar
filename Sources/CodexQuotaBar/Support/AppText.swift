import Foundation

struct AppText {
    let language: AppLanguage

    init(_ language: AppLanguage = AppPreferences.language) {
        self.language = language
    }

    var codexUsageTitle: String {
        switch language {
        case .zhHans: "Codex 使用情况"
        case .english: "Codex Usage"
        }
    }

    var quotaSectionTitle: String {
        switch language {
        case .zhHans: "额度"
        case .english: "Quota"
        }
    }

    var fiveHourQuotaTitle: String {
        switch language {
        case .zhHans: "5 小时额度"
        case .english: "5-Hour Quota"
        }
    }

    var sevenDayQuotaTitle: String {
        switch language {
        case .zhHans: "7 天额度"
        case .english: "7-Day Quota"
        }
    }

    var usageSectionTitle: String {
        switch language {
        case .zhHans: "最近使用"
        case .english: "Recent Usage"
        }
    }

    var recentFiveHourTokensTitle: String {
        switch language {
        case .zhHans: "最近 5 小时 Token"
        case .english: "Last 5 Hours Tokens"
        }
    }

    var latestRequestTitle: String {
        switch language {
        case .zhHans: "最近一次请求"
        case .english: "Latest Request"
        }
    }

    var currentSessionTotalTitle: String {
        switch language {
        case .zhHans: "当前会话累计"
        case .english: "Current Session Total"
        }
    }

    var statusSectionTitle: String {
        switch language {
        case .zhHans: "状态"
        case .english: "Status"
        }
    }

    var latestEventLabel: String {
        switch language {
        case .zhHans: "最近事件"
        case .english: "Latest Event"
        }
    }

    var planLabel: String {
        switch language {
        case .zhHans: "计划"
        case .english: "Plan"
        }
    }

    var modelLabel: String {
        switch language {
        case .zhHans: "模型"
        case .english: "Model"
        }
    }

    var logsButtonTitle: String {
        switch language {
        case .zhHans: "日志"
        case .english: "Logs"
        }
    }

    var multipleInstancesButtonTitle: String {
        switch language {
        case .zhHans: "多开"
        case .english: "Instances"
        }
    }

    var quitButtonTitle: String {
        switch language {
        case .zhHans: "退出"
        case .english: "Quit"
        }
    }

    var refreshHelp: String {
        switch language {
        case .zhHans: "刷新"
        case .english: "Refresh"
        }
    }

    var settingsHelp: String {
        switch language {
        case .zhHans: "设置"
        case .english: "Settings"
        }
    }

    var settingsMenuTitle: String {
        switch language {
        case .zhHans: "设置…"
        case .english: "Settings..."
        }
    }

    var refreshMenuTitle: String {
        refreshHelp
    }

    var openLogsMenuTitle: String {
        switch language {
        case .zhHans: "打开日志"
        case .english: "Open Logs"
        }
    }

    var closeOtherInstancesMenuTitle: String {
        switch language {
        case .zhHans: "关闭其他实例"
        case .english: "Close Other Instances"
        }
    }

    var quitMenuTitle: String {
        quitButtonTitle
    }

    var settingsWindowTitle: String {
        settingsHelp
    }

    var refreshSectionTitle: String {
        switch language {
        case .zhHans: "刷新"
        case .english: "Refresh"
        }
    }

    var refreshFrequencyLabel: String {
        switch language {
        case .zhHans: "刷新频率"
        case .english: "Refresh Frequency"
        }
    }

    var refreshExplanation: String {
        switch language {
        case .zhHans: "菜单栏和详情面板会按这个频率重新读取本地 Codex 会话日志。"
        case .english: "The menu bar item and detail panel re-read local Codex session logs at this interval."
        }
    }

    var languageSectionTitle: String {
        switch language {
        case .zhHans: "语言"
        case .english: "Language"
        }
    }

    var interfaceLanguageLabel: String {
        switch language {
        case .zhHans: "界面语言"
        case .english: "Interface Language"
        }
    }

    var languageExplanation: String {
        switch language {
        case .zhHans: "切换后，弹窗、菜单、设置和提示文字会立即使用所选语言。"
        case .english: "Changing this updates the popover, menus, settings, and tooltip copy immediately."
        }
    }

    var behaviorSectionTitle: String {
        switch language {
        case .zhHans: "行为"
        case .english: "Behavior"
        }
    }

    var autoCloseOtherInstancesLabel: String {
        switch language {
        case .zhHans: "启动时自动关闭其他实例"
        case .english: "Close other instances on launch"
        }
    }

    var autoCloseExplanation: String {
        switch language {
        case .zhHans: "建议保持开启，这样误开的调试版或旧版本会被自动收掉，不会在菜单栏出现两个图标。"
        case .english: "Keep this on to remove accidentally launched debug or older builds, avoiding duplicate menu bar icons."
        }
    }

    var maintenanceSectionTitle: String {
        switch language {
        case .zhHans: "维护"
        case .english: "Maintenance"
        }
    }

    var closeOtherInstancesNowTitle: String {
        switch language {
        case .zhHans: "立即关闭其他实例"
        case .english: "Close Other Instances Now"
        }
    }

    var openLogsFolderTitle: String {
        switch language {
        case .zhHans: "打开日志文件夹"
        case .english: "Open Logs Folder"
        }
    }

    var noData: String {
        switch language {
        case .zhHans: "暂无"
        case .english: "N/A"
        }
    }

    var unknown: String {
        switch language {
        case .zhHans: "未知"
        case .english: "Unknown"
        }
    }

    var waitingForRequestData: String {
        switch language {
        case .zhHans: "等待新的请求数据"
        case .english: "Waiting for new request data"
        }
    }

    var readingLocalLogs: String {
        switch language {
        case .zhHans: "正在读取本地 Codex 会话日志"
        case .english: "Reading local Codex session logs"
        }
    }

    var waitingForLiveQuota: String {
        switch language {
        case .zhHans: "正在等待 Codex 实时额度数据"
        case .english: "Waiting for live Codex quota data"
        }
    }

    var waitingForQuotaEvent: String {
        switch language {
        case .zhHans: "正在等待 Codex 配额数据"
        case .english: "Waiting for Codex quota data"
        }
    }

    func languageName(for option: AppLanguage) -> String {
        switch option {
        case .zhHans:
            return language == .english ? "Chinese" : "中文"
        case .english:
            return "English"
        }
    }

    func secondsLabel(_ seconds: Double) -> String {
        switch language {
        case .zhHans: "\(Int(seconds)) 秒"
        case .english: "\(Int(seconds)) sec"
        }
    }

    func remaining(_ value: String) -> String {
        switch language {
        case .zhHans: "剩余 \(value)"
        case .english: "\(value) left"
        }
    }

    func used(_ value: String) -> String {
        switch language {
        case .zhHans: "已用 \(value)"
        case .english: "Used \(value)"
        }
    }

    func reset(_ value: String) -> String {
        switch language {
        case .zhHans: "重置 \(value)"
        case .english: "Resets \(value)"
        }
    }

    func inputOutputDetail(input: Int, output: Int) -> String {
        inputOutputDetail(
            input: MetricFormatters.abbreviatedTokens(input),
            output: MetricFormatters.abbreviatedTokens(output)
        )
    }

    func inputOutputDetail(input: String, output: String) -> String {
        switch language {
        case .zhHans: "输入 \(input) · 输出 \(output)"
        case .english: "Input \(input) · Output \(output)"
        }
    }

    func sessionDetail(input: String, output: String, cache: String) -> String {
        switch language {
        case .zhHans: "输入 \(input) · 输出 \(output) · 缓存率 \(cache)"
        case .english: "Input \(input) · Output \(output) · Cache \(cache)"
        }
    }

    func updatedAt(_ eventDate: Date, relativeTo refreshedAt: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = language.locale
        formatter.unitsStyle = .abbreviated
        let relative = formatter.localizedString(for: eventDate, relativeTo: refreshedAt)

        return switch language {
        case .zhHans: "更新于 \(relative)"
        case .english: "Updated \(relative)"
        }
    }

    func fiveHourWindowRemaining(_ percent: Int) -> String {
        switch language {
        case .zhHans: "5 小时窗口剩余 \(percent)%"
        case .english: "5-hour window \(percent)% remaining"
        }
    }

    func quotaTooltip(remaining: Int, used: Int, resetAt: String) -> String {
        switch language {
        case .zhHans:
            return "5 小时额度剩余 \(remaining)%，已用 \(used)%，\(resetAt) 重置"
        case .english:
            return "5-hour quota \(remaining)% remaining, \(used)% used, resets at \(resetAt)"
        }
    }
}
