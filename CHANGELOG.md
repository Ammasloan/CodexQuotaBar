# Changelog

## Unreleased

- Added a language setting with Chinese and English interface modes.
- Added configurable multi-monitor targets for multiple local accounts or agents.
- Restyled the popover with an OpenUsage-inspired left rail and status layout.
- Tuned the popover proportions into a narrower vertical menu-bar panel.
- Updated the menu bar ring to surface the enabled monitor with the lowest 5-hour quota remaining.
- Improved quota freshness by refreshing before opening the popover and running the periodic refresh with a Swift concurrency sleep loop outside the UI run loop.
- Reworked log scanning to use faster byte-level parsing over recent active logs and added a local debug status file for verifying the live menu-bar value.
- Forced menu-bar status item redraws by updating attributed title, width, layout, and display together.
- Added manual subscription remaining-time tracking.
- Added configurable token pricing, cost estimates, and savings display.
- Updated the README preview to use a single bilingual product hero image.

## 1.0.0

- Initial open-source release.
- Menu bar quota ring for the 5-hour Codex window.
- Popover dashboard for 5-hour and 7-day quotas.
- Rolling token usage summaries.
- Native settings window and right-click menu.
- Single-instance cleanup.
