# CodexQuotaBar

CodexQuotaBar is a lightweight macOS menu bar app for keeping an eye on local Codex usage. It reads `token_count` events from your local `~/.codex/sessions` logs and turns them into a small status-ring icon plus a click-to-open quota dashboard.

The app is designed for quick scanning: the menu bar item shows the remaining 5-hour quota, and the popover opens to the two quota windows that matter most: 5 hours and 7 days.

<p>
  <img src="docs/assets/codexquotabar-preview.png" width="100%" alt="CodexQuotaBar bilingual product preview">
</p>

## Features

- Menu bar ring icon with remaining 5-hour quota.
- OpenUsage-inspired popover with a left rail for multiple monitored accounts or agents.
- Configurable monitor targets with custom name, icon, color, sessions folder, and config file.
- Popover dashboard for session and weekly quota windows.
- Rolling token totals for the last 5 hours and 7 days.
- Latest request and active-session token summaries.
- Optional manual subscription tracking for remaining plan time.
- Optional token pricing estimates and subscription savings calculation.
- Right-click menu with settings, refresh, log folder, single-instance cleanup, and quit.
- Language setting with Chinese and fully English UI modes.
- Native macOS SwiftUI UI with a compact OpenUsage-inspired status layout.
- Local-only data access: no server, account token, or network request is needed to read usage.

## Requirements

- macOS 13 or newer.
- Swift 6.2 or newer for building from source.
- Codex desktop/CLI usage logs under `~/.codex/sessions`.

The popover is intentionally compact and status-first, with a left rail for switching configured monitors.

## Build

```bash
./scripts/build_app.sh
```

The app bundle is written to:

```text
dist/CodexQuotaBar.app
```

Launch it with:

```bash
open dist/CodexQuotaBar.app
```

For development builds:

```bash
swift build
swift run CodexQuotaBar
```

## How It Works

Codex writes local JSONL session logs. Some lines include `payload.type == "token_count"` and carry:

- `rate_limits.primary`: the 5-hour usage window.
- `rate_limits.secondary`: the 7-day usage window.
- `info.last_token_usage`: the most recent request token counts.
- `info.total_token_usage`: the active session's accumulated token counts.

CodexQuotaBar scans recent session files, picks the latest rate-limit event, and aggregates recent `last_token_usage` events for rolling token totals.

More detail: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Multiple Monitors

Settings includes a Monitors section. Each monitor points to a Codex sessions folder and config file, so you can track separate local Codex accounts, agent folders, or copied log directories side by side.

When multiple monitors are enabled, the menu bar ring surfaces the target with the lowest 5-hour quota remaining so the tightest limit is visible at a glance.

The default monitor reads:

- `~/.codex/sessions`
- `~/.codex/config.toml`

## Manual Cost Tracking

OpenAI does not expose ChatGPT subscription renewal details through the local Codex logs that this app reads, so subscription tracking is manual. In Settings you can enter:

- Subscription start date, duration, cost, and currency symbol.
- Token prices per 1M uncached input, cached input, and output tokens.

When both are configured, the popover estimates token-equivalent cost for recent usage and compares the current subscription cycle's token value against your plan cost.

## Privacy

CodexQuotaBar only reads local files from:

```text
~/.codex/sessions
~/.codex/config.toml
```

It does not upload logs, call OpenAI APIs, or send telemetry. The GitHub project intentionally excludes build output and local Codex data.

More detail: [docs/PRIVACY.md](docs/PRIVACY.md)

## Project Layout

```text
Sources/CodexQuotaBar/
  App/       app lifecycle, menu bar coordinator, popover behavior
  Data/      log scanning, usage store, data models
  UI/        SwiftUI popover, settings, ring rendering
  Support/   preferences and single-instance helpers
scripts/    build scripts
docs/       architecture and privacy notes
```

## License

MIT. See [LICENSE](LICENSE).
