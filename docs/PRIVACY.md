# Privacy

CodexQuotaBar is local-first.

## Files Read

The app reads:

- `~/.codex/sessions/**/*.jsonl`
- `~/.codex/config.toml`
- Any additional sessions folders and config files you explicitly add in Settings.

It uses those files to find local Codex quota and token-count events.

## Network

The app does not make network requests.

## Data Sent

The app does not upload, transmit, or sync usage logs. All parsing and aggregation happen in-process on the user's Mac.

## Data Stored

The app stores only small user preferences through `UserDefaults`, such as refresh interval, language, duplicate-instance behavior, monitor target paths, optional subscription details, and optional token-pricing settings.

For local troubleshooting, the app also writes `~/Library/Application Support/CodexQuotaBar/debug-status.json` with the current status item value, latest parsed quota event time, process id, and app path. This file stays on the local Mac and can be deleted safely.
