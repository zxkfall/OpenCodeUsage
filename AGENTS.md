# AGENTS.md

## Project Overview

This is an OpenCode AI workspace containing:
1. **Gold trading analysis pipeline** (`codex_jin/`) - Python scripts for market data analysis
2. **OpenCode Go usage widget** (`widget/`) - macOS menu bar app tracking API usage
3. **Codex migration tool** (`migrate_codex.py`) - Imports chat history from Codex to OpenCode

## Conventions

### Python
- Python 3.x, standard library preferred
- Type hints not required unless complex
- Use `os.path.expanduser()` for home-relative paths
- Scripts in `codex_jin/` output JSON to `outputs/` subdirectory

### Swift (widget/)
- Target: macOS 14.0+, SwiftUI, MenuBarExtra
- Compiled with `swiftc` directly (no Xcode project needed)
- Python scripts embedded in app bundle as Resources
- Build: `bash widget/build.sh`

### Git
- Commit messages in English, short and descriptive
- Large output files (*.json, *.log) can be omitted
- No secrets or API keys committed

### File Organization
- New scripts go in appropriate subdirectory or `widget/`
- Analysis outputs in `codex_jin/outputs/`
- Generated `.app` bundles are committed for convenience

## Constraints

1. **Do not modify files without explicit permission** - ask first
2. **When user says "先分析" (analyze first), only analyze, do NOT write code** - do not call Edit/Write tools until user explicitly says to proceed
3. **Think before asking** - gather context, then ask if needed
4. **Log key decisions** in `DECISIONS.md`
5. **Commit major changes** to git promptly

## Widget Architecture

```
widget/
├── opencode_usage.py          # Queries ~/.local/share/opencode/opencode.db
├── OpenCodeUsageBar.swift     # SwiftUI MenuBarExtra app
├── build.sh                   # Compiles .app bundle
└── OpenCodeUsageWidget/       # WidgetKit extension (Xcode required)
```

The menu bar app:
- Runs Python script to read SQLite usage data
- Displays cost in menu bar with color-coded status
- "Pin Widget Panel" opens a floating NSPanel
- Auto-refreshes every 60 seconds
