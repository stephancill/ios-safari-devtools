# Safari Mobile DevTools - Cursor Rules

See the [README.md](README.md) for more information about the project architecture and how it works.

## Package Manager

This project uses **pnpm** for package management. Always use `pnpm` commands instead of `npm` or `yarn`.

## After Making Changes to TypeScript/JavaScript Files

Always run lint after modifying any `.ts`, `.tsx`, or `.js` files in `popup-app/`:

```bash
cd popup-app && pnpm run check
```

This runs Biome to lint and format the code.

## After Making Changes to Swift Files

Check for build errors without a full build:

```bash
xcodebuild -scheme devtools -destination 'generic/platform=iOS' build 2>&1 | grep -E "(error:|warning:)"
```

Using `generic/platform=iOS` skips simulator-specific compilation and is faster than specifying a device.

## Project Structure

- `Shared/` - Swift code shared between host app and extension (Settings, SwiftData models)
- `devtools/` - SwiftUI host app
- `devtools Extension/` - Safari extension
- `popup-app/` - Vite + React + TypeScript popup UI source
- `test-app/` - Test web app for development

## Build Commands

```bash
# Build all web files (popup, content script, inject script)
cd popup-app && pnpm run build

# Lint and format
cd popup-app && pnpm run check

# Run test app
cd test-app && pnpm dev
```

## Key Swift Files

- `Shared/Settings.swift` - Shared settings via App Group UserDefaults
- `Shared/DebugLog.swift` - SwiftData model for console logs
- `Shared/NetworkLog.swift` - SwiftData model for network requests
- `devtools/DevToolsApp.swift` - SwiftUI app entry point with SwiftData container
- `devtools/ContentView.swift` - Main TabView (Setup, Console, Network, Settings)
- `devtools/DebugView.swift` - Console log viewer with filtering
- `devtools/NetworkView.swift` - Network request viewer with detail sheet
- `devtools/SettingsView.swift` - App settings (limits, retention, clear data)
- `devtools Extension/SafariWebExtensionHandler.swift` - Handles native messages, stores logs

## Key Web Files

- `popup-app/src/inject.ts` - Runs in page context, intercepts console/network
- `popup-app/src/content.ts` - Content script, bridges page and extension
- `popup-app/src/App.tsx` - Main popup UI component
- `devtools Extension/Resources/background.js` - Message broker, sends to native handler
- `devtools Extension/Resources/manifest.json` - Extension manifest

## App Group

The host app and extension share data via App Group: `group.co.za.stephancill.devtools`

- Settings are stored in `UserDefaults(suiteName:)`
- Logs are stored in SwiftData at the App Group container

## iOS Deployment Target

This project requires **iOS 17+** for SwiftData support.

## Xcode Build

The Xcode project has a build phase that automatically runs `pnpm build` before compiling the iOS app.
