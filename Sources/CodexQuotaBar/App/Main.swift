import AppKit

@main
@MainActor
struct CodexQuotaBarMain {
    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        application.delegate = delegate

        withExtendedLifetime(delegate) {
            application.run()
        }
    }
}
