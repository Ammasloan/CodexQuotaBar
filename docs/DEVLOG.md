# Development Log

## 2026-05-07 20:52 CST

- Completed: investigated a second mismatch where the menu bar stayed at `93%` while the latest local logs had moved to about `87%` remaining.
- Completed: confirmed the latest default Codex log event had `primary.used_percent = 13.0`, meaning the stale value came from the app refresh path rather than the scanner formula.
- Completed: replaced the run-loop-based refresh timer with a Swift concurrency `Task.sleep` loop so periodic status-bar refreshes are not dependent on menu/popover UI run-loop state.
- Modified files: `CHANGELOG.md`, `docs/DEVLOG.md`, `Sources/CodexQuotaBar/Data/CodexUsageStore.swift`.
- Tests/checks run: `swift build`; `git diff --check`; `./scripts/build_app.sh`; relaunched `dist/CodexQuotaBar.app`.
- Current result: the rebuilt app starts from the latest parsed local event and should continue refreshing independently of the UI run loop.
- Remaining issues: automated reading of the macOS LSUIElement menu-bar title is blocked by accessibility/automation limits, so final visual confirmation needs a manual glance at the menu bar.
- Next step: if any mismatch remains, add an explicit on-screen data timestamp/debug row so we can distinguish stale local logs from stale app state instantly.

## 2026-05-07 20:20 CST

- Completed: investigated a reported mismatch where the menu bar showed `96%` while the live quota display showed about `94%`.
- Completed: confirmed the app uses local `token_count` log events, and the latest parsed local event during investigation showed `primary.used_percent = 7.0`, or `93%` remaining.
- Completed: improved freshness by refreshing before showing the popover and adding the periodic refresh timer to the run loop's `.common` modes.
- Modified files: `CHANGELOG.md`, `docs/DEVLOG.md`, `Sources/CodexQuotaBar/App/AppCoordinator.swift`, `Sources/CodexQuotaBar/Data/CodexUsageStore.swift`.
- Tests/checks run: `swift build`; `git diff --check`.
- Current result: opening the menu bar popover now forces a fresh log scan, and the timer is less likely to pause during menu/popover event tracking.
- Remaining issues: CodexQuotaBar still reads local logs only, so it can lag behind any server-side UI until Codex writes the next local `token_count` event.
- Next step: consider showing a small "data age" hint in the menu bar tooltip if stale-data confusion continues.

## 2026-05-07 19:32 CST

- Completed: narrowed the OpenUsage-style popover from `640x760` to `500x760` and compacted the rail, typography, padding, and footer spacing.
- Modified files: `CHANGELOG.md`, `docs/DEVLOG.md`, `Sources/CodexQuotaBar/App/AppCoordinator.swift`, `Sources/CodexQuotaBar/UI/QuotaPopoverView.swift`.
- Tests/checks run: `swift build`; `git diff --check`; `./scripts/build_app.sh`; relaunched `dist/CodexQuotaBar.app`.
- Current result: the popover now reads as a taller menu-bar panel instead of a wide dashboard.
- Remaining issues: visual confirmation still depends on manually opening the LSUIElement menu-bar popover.
- Next step: tune individual rows if any user-specific labels feel cramped at the narrower width.

## 2026-05-07 19:22 CST

- Completed: restyled the popover toward the referenced OpenUsage layout with a left monitor rail, dark status progress bars, compact credits/cost stats, and footer actions.
- Completed: added configurable monitor targets for multiple local accounts or agents, including name, SF Symbol icon, color, sessions folder, config file, and enabled state.
- Completed: made the menu bar ring display the enabled monitor with the lowest 5-hour quota remaining.
- Modified files: `README.md`, `CHANGELOG.md`, `docs/ARCHITECTURE.md`, `docs/PRIVACY.md`, `docs/DEVLOG.md`, `Sources/CodexQuotaBar/App/AppCoordinator.swift`, `Sources/CodexQuotaBar/Data/CodexLogScanner.swift`, `Sources/CodexQuotaBar/Data/CodexUsageStore.swift`, `Sources/CodexQuotaBar/Data/Models.swift`, `Sources/CodexQuotaBar/Support/AppPreferences.swift`, `Sources/CodexQuotaBar/Support/AppText.swift`, `Sources/CodexQuotaBar/UI/QuotaPopoverView.swift`, `Sources/CodexQuotaBar/UI/SettingsView.swift`.
- Tests/checks run: `swift build`; `./scripts/build_app.sh`; relaunched `dist/CodexQuotaBar.app`.
- Current result: the rebuilt app can switch between enabled monitor targets in the popover and Settings can customize which targets are monitored.
- Remaining issues: each monitor currently reads Codex-style local JSONL logs; non-Codex agents need compatible log folders or a future adapter.
- Next step: manually inspect the larger popover layout from the menu bar and tune spacing if any local data row overflows.

## 2026-05-06 16:45 CST

- Completed: added manual subscription tracking, configurable token pricing, cost estimates, and savings/payback display in the popover.
- Modified files: `README.md`, `CHANGELOG.md`, `docs/ARCHITECTURE.md`, `docs/PRIVACY.md`, `docs/DEVLOG.md`, `Sources/CodexQuotaBar/App/AppCoordinator.swift`, `Sources/CodexQuotaBar/Data/CodexLogScanner.swift`, `Sources/CodexQuotaBar/Data/CodexUsageStore.swift`, `Sources/CodexQuotaBar/Data/Models.swift`, `Sources/CodexQuotaBar/Support/AppPreferences.swift`, `Sources/CodexQuotaBar/Support/AppText.swift`, `Sources/CodexQuotaBar/UI/QuotaPopoverView.swift`, `Sources/CodexQuotaBar/UI/SettingsView.swift`.
- Tests/checks run: `swift build`; `./scripts/build_app.sh`; relaunched `dist/CodexQuotaBar.app`; verified the built binary contains the new subscription/savings text.
- Current result: Settings can store subscription start date, duration, cost, currency symbol, and per-1M token prices; the rebuilt local menu bar app is running and the popover shows remaining subscription time, token cost estimates, and savings when enough inputs are configured.
- Remaining issues: subscription renewal/end dates are manual because local Codex logs do not expose reliable subscription lifecycle data.
- Next step: manually verify the new settings sections and popover layout in the accessory app.

## 2026-04-24 11:11 CST

- Completed: replaced the README preview with the generated horizontal CodexQuotaBar bilingual hero image and removed the previous two separate preview references from README.
- Modified files: `README.md`, `CHANGELOG.md`, `docs/assets/codexquotabar-preview.png`, `docs/DEVLOG.md`.
- Tests/checks run: inspected the generated image with `view_image`; checked image dimensions with `file`; reviewed README preview markup.
- Current result: README uses one wide bilingual product preview image.
- Remaining issues: previous preview asset files are still present but no longer referenced; they were not deleted to avoid removing tracked assets without explicit confirmation.
- Next step: optionally confirm deletion of unused preview assets if you want the repository asset folder fully cleaned.

## 2026-04-24 11:04 CST

- Completed: replaced README showcase images with separate English and Chinese popover previews based on the latest approved screenshots.
- Modified files: `README.md`, `CHANGELOG.md`, `docs/assets/codexquotabar-preview-en.png`, `docs/assets/codexquotabar-preview-zh.png`, `docs/assets/codexquotabar-preview.png`, `scripts/render_readme_screenshot.swift`, `docs/DEVLOG.md`.
- Tests/checks run: `swift scripts/render_readme_screenshot.swift`; visually inspected both generated PNG assets.
- Current result: README now shows the English preview first and the Chinese preview second.
- Remaining issues: old unused menu-bar preview asset remains in the repository to avoid deleting tracked files without an explicit delete request.
- Next step: if desired, explicitly remove unused legacy preview assets in a cleanup commit.

## 2026-04-24 11:01 CST

- Completed: diagnosed why the language setting was not visible locally; the menu bar app was still running an old process from before the language-setting build.
- Modified files: `docs/DEVLOG.md`.
- Tests/checks run: checked `SettingsView.swift`; compared process start time with app binary modification time; restarted `CodexQuotaBar.app` with `open -n`; verified the running binary contains `Interface Language`.
- Current result: local menu bar process is now the rebuilt app version, so Settings should show the language section.
- Remaining issues: `Computer Use` still cannot inspect the LSUIElement menu bar app window directly, so final visual confirmation needs a manual click.
- Next step: open Settings from the menu bar item and confirm the `语言 / Language` section appears between refresh and behavior.

## 2026-04-24 11:22 CST

- Completed: removed the standalone `Preview Images` section from `README.md` while keeping the product screenshots near the top.
- Modified files: `README.md`, `docs/DEVLOG.md`.
- Tests/checks run: documentation-only change; checked README content with `sed`.
- Current result: README no longer calls out preview image generation as a separate section.
- Remaining issues: none.
- Next step: keep README focused on user-facing install, usage, and project overview content.

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
