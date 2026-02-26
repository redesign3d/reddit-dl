# reddit-dl

Archive your Reddit Saved content on desktop without developer tokens. Import a
Reddit data ZIP, sync via old.reddit.com, and download media into a structured,
offline-first library.

## Features
- ZIP backfill import (saved_posts.csv + saved_comments.csv).
- old.reddit.com session sync with permalink + `.json` enrichment.
- Media downloads: images, GIFs, Reddit video (DASH merge), external tools.
- Resumable HTTP downloads with per-asset resume metadata and `.part` files.
- Tokenized folder templates + arr-like layout modes.
- Markdown export for text posts, saved comments, and thread comments.
- Tray support so downloads continue when the window closes.

## Download resume behavior
- HTTP media downloads write to `<target>.part` and atomically rename on success.
- Resume uses saved `etag` / `last-modified` validators when available.
- If validators mismatch or Range is unsupported, partial data is discarded and
  the asset restarts cleanly.

## Build
```sh
flutter pub get
flutter run -d macos
flutter run -d windows
flutter run -d linux
```

Release builds:
```sh
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

## External tools
The app will detect tools on PATH or via manual overrides in Settings.

macOS:
- `brew install yt-dlp`
- `pipx install gallery-dl`

Windows:
- `winget install yt-dlp.yt-dlp`
- `pipx install gallery-dl`

Linux:
- `apt install yt-dlp` (or distro equivalent)
- `pipx install gallery-dl`

ffmpeg is managed by the app and downloaded on first use.

## Platform notes
- Linux WebView: install WebKitGTK and GTK3 if login shows a blank view.
- Windows: long paths can cause failures; enable long paths if needed.
- macOS: downloads are limited to user-selected folders via picker.

## Versioning
SemVer + build number in `pubspec.yaml` (example: `0.1.0+1`).
