# Z2 Lite

Z2 Lite is a lightweight Windows desktop application for managing Zapret through a compact graphical interface.

## Features

- Start, stop and restart Zapret
- Select and manage Zapret configurations
- Game Filter and IPSet management
- IPSet updates
- Zapret download and update checks
- Zapret automatic startup management
- Windows application auto-start
- Minimalistic desktop interface
- Dark and light themes
- Smooth scrolling and lightweight UI animations
- Russian and English localization
- Built-in update support
- Maya architecture for application, process, filter and update management

## Requirements

- Windows 10 or newer
- Internet connection for downloading and updating components

For building from source:

- Flutter SDK
- Visual Studio with the Windows desktop development workload
- Windows SDK

## Build

Clone the repository:

```bash
git clone https://github.com/Ank01rd/z2-lite.git
cd z2-lite
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run -d windows
```

Build a release:

```bash
flutter build windows --release
```

The release output is generated in:

```text
build/windows/x64/runner/Release/
```

## Project structure

```text
assets/      # UI assets
lib/
├── core/    # Settings, theme, localization and utilities
├── maya/    # Maya application architecture
├── services/ # Zapret services and process management
└── ui/      # Pages and reusable widgets
windows/     # Windows runner
```

## Current version

**1.0.5**

The changelog is maintained in:

```text
lib/core/changelog.dart
```

## Repository policy

The repository is intended to contain source code and project resources.

Build artifacts and local backups should not be committed to Git. Release archives belong in GitHub Releases rather than in the source tree.

The current source release **does not include TG WS Proxy**. That feature is being developed separately and is not part of this source update.

## License

See the `LICENSE` file included with the repository.
