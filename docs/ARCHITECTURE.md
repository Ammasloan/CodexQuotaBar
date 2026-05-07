# Architecture

CodexQuotaBar is a small Swift Package executable that runs as a macOS menu bar accessory app.

## Source Layout

- `App/`: app lifecycle, menu bar item, popover behavior, context menu, settings window coordination.
- `Data/`: local Codex log scanning, multi-monitor usage aggregation, observable store, and data models.
- `UI/`: SwiftUI popover, settings view, monitor rail, and menu bar ring rendering.
- `Support/`: user preferences, monitor target configuration, lightweight UI copy localization, and single-instance cleanup helpers.

## Data Flow

1. `CodexUsageStore` refreshes enabled monitor targets on launch and then on the configured interval.
2. Each `CodexLogScanner` scans recent JSONL files from that monitor's configured sessions folder.
3. The scanner decodes only `token_count` event lines.
4. The latest rate-limit event drives the 5-hour and 7-day quota UI.
5. Recent `last_token_usage` events are summed for rolling 5-hour and 7-day token totals.
6. If manual subscription settings are configured, events since the configured subscription start date are summed for cycle-level cost estimates.
7. SwiftUI views observe all monitor snapshots, render the left monitor rail, and update the menu bar item from the enabled target with the lowest 5-hour quota remaining.

## UI Behavior

- Left-click the menu bar item to toggle the quota popover.
- Right-click or Control-click to open the context menu.
- Clicking outside the popover closes it via local/global event monitoring.
- Launching the app can terminate other `CodexQuotaBar` instances to avoid duplicate menu bar icons.
- The popover uses a left rail for switching between configured monitor targets.
- The language setting is stored in `UserDefaults` and updates the popover, settings window, context menu, and tooltip text.
- Monitor targets, manual subscription, and token-pricing settings are stored in `UserDefaults`; they are local-only estimates/configuration and are not read from a subscription API.

## Build Output

`scripts/build_app.sh` builds the release executable and wraps it in a minimal `.app` bundle under `dist/`.

Build output is intentionally ignored by git.
