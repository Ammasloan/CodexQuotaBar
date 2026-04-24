# Development Log

## 2026-04-24 10:42 CST

- Completed: added a README preview image for the public GitHub project using sample data, plus a reproducible renderer script.
- Modified files: `README.md`, `.gitignore`, `docs/assets/codexquotabar-preview.png`, `scripts/render_readme_screenshot.swift`, `docs/DEVLOG.md`.
- Tests/checks run: `swift scripts/render_readme_screenshot.swift`; visually inspected the generated PNG.
- Current result: the README now shows a privacy-safe CodexQuotaBar effect image without exposing local quota or token data.
- Remaining issues: no live desktop screenshot is committed because real usage data may be sensitive.
- Next step: optionally add release assets or signed app packaging when publishing binaries.
