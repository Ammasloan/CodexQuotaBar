# Development Log

## 2026-04-24 11:10 CST

- Completed: replaced README preview assets with the approved popover and menu-bar compositions, and added an app language setting for Chinese or fully English UI.
- Modified files: `README.md`, `CHANGELOG.md`, `docs/ARCHITECTURE.md`, `docs/assets/codexquotabar-preview.png`, `docs/assets/codexquotabar-menubar.png`, `scripts/render_readme_screenshot.swift`, `Sources/CodexQuotaBar/App/AppCoordinator.swift`, `Sources/CodexQuotaBar/Data/Models.swift`, `Sources/CodexQuotaBar/Support/AppPreferences.swift`, `Sources/CodexQuotaBar/Support/AppText.swift`, `Sources/CodexQuotaBar/UI/QuotaPopoverView.swift`, `Sources/CodexQuotaBar/UI/SettingsView.swift`.
- Tests/checks run: `swift build`; `swift scripts/render_readme_screenshot.swift`; `./scripts/build_app.sh`; relaunched `dist/CodexQuotaBar.app`; visual inspection of both generated PNG assets.
- Current result: settings now include a language picker, README shows the two compact product screenshots, and the rebuilt local menu bar app is running.
- Remaining issues: README preview images are privacy-safe rendered assets based on the provided screenshots rather than raw user telemetry screenshots; language toggle was build-verified but not interactively clicked through in the accessory app.
- Next step: manually switch Settings → Language → English and scan the popover for any remaining Chinese copy.

## 2026-04-24 10:42 CST

- Completed: added a README preview image for the public GitHub project using sample data, plus a reproducible renderer script.
- Modified files: `README.md`, `.gitignore`, `docs/assets/codexquotabar-preview.png`, `scripts/render_readme_screenshot.swift`, `docs/DEVLOG.md`.
- Tests/checks run: `swift scripts/render_readme_screenshot.swift`; visually inspected the generated PNG.
- Current result: the README now shows a privacy-safe CodexQuotaBar effect image without exposing local quota or token data.
- Remaining issues: no live desktop screenshot is committed because real usage data may be sensitive.
- Next step: optionally add release assets or signed app packaging when publishing binaries.
