# Safari Mobile DevTools

A Safari extension for iOS that provides developer console functionality similar to desktop browser DevTools.

## Features

- **Console**: View `console.log`, `console.warn`, `console.error`, and `console.info` output
- **JavaScript Execution**: Run arbitrary JavaScript on the current page
- **Error Tracking**: Capture runtime errors and unhandled promise rejections
- **Network Monitoring**: Inspect fetch and XMLHttpRequest calls with request/response details
- **In-App Log Viewer**: View captured logs directly in the host app, organized by tab

## Tech Stack

- **Host App**: SwiftUI + SwiftData (iOS 17+)
- **Popup UI**: Vite + React + TypeScript + Tailwind CSS
- **Icons**: Lucide React
- **Linting/Formatting**: Biome

## Project Structure

```
devtools/
├── Shared/                       # Code shared between app and extension
│   ├── Settings.swift           # Shared settings (App Group UserDefaults)
│   ├── DebugLog.swift           # SwiftData model for console logs
│   └── NetworkLog.swift         # SwiftData model for network requests
├── popup-app/                    # Vite + React + TypeScript popup UI
│   ├── src/
│   │   ├── App.tsx              # Main app with tab navigation
│   │   ├── index.css            # Tailwind + custom DevTools styles
│   │   ├── components/
│   │   │   ├── Console.tsx      # Console logs + JS execution
│   │   │   └── Network.tsx      # Network requests viewer
│   │   ├── content.ts           # Content script (bridges page ↔ extension)
│   │   ├── inject.ts            # Injected script (intercepts console/network)
│   │   └── types.ts             # TypeScript definitions
│   ├── vite.config.ts           # Popup build config
│   ├── vite.content.config.ts   # Content script build config
│   └── vite.inject.config.ts    # Inject script build config
├── devtools Extension/
│   ├── Resources/               # Built extension files (gitignored)
│   │   ├── popup.html
│   │   ├── popup.js
│   │   ├── popup.css
│   │   ├── content.js
│   │   ├── inject.js
│   │   ├── background.js
│   │   └── manifest.json
│   ├── SafariWebExtensionHandler.swift  # Native message handler
│   └── Info.plist
├── devtools/                     # iOS SwiftUI app
│   ├── DevToolsApp.swift        # App entry point
│   ├── ContentView.swift        # Main TabView
│   ├── SetupView.swift          # Extension setup instructions
│   ├── DebugView.swift          # Console log viewer
│   ├── NetworkView.swift        # Network request viewer
│   └── SettingsView.swift       # App settings
└── devtools.xcodeproj/
```

## Requirements

- Xcode 16+
- iOS 17+ deployment target
- Node.js 18+
- pnpm

## Xcode Setup (Required)

### 1. Add Shared Files to Both Targets

In Xcode, add the files in `Shared/` to both the `devtools` and `devtools Extension` targets:

- `Shared/Settings.swift`
- `Shared/DebugLog.swift`
- `Shared/NetworkLog.swift`

### 2. Configure App Groups

1. Select the `devtools` target → Signing & Capabilities → + Capability → App Groups
2. Add: `group.co.za.stephancill.devtools`
3. Repeat for the `devtools Extension` target with the same group name

### 3. Update Deployment Target

1. Select the project in the navigator
2. Set iOS Deployment Target to 17.0 for both targets

### 4. Add New Swift Files to Target

Add these new files to the `devtools` target:

- `devtools/DevToolsApp.swift`
- `devtools/ContentView.swift`
- `devtools/SetupView.swift`
- `devtools/DebugView.swift`
- `devtools/NetworkView.swift`
- `devtools/SettingsView.swift`

### 5. Remove Deleted Files from Project

Remove these files from the Xcode project (they've been deleted from disk):

- `devtools/AppDelegate.swift`
- `devtools/SceneDelegate.swift`
- `devtools/ViewController.swift`
- `devtools/Base.lproj/Main.storyboard`

## Development

### Install dependencies

```bash
cd popup-app
pnpm install
```

### Build web files

```bash
cd popup-app
pnpm build
```

This builds:

- `popup.html`, `popup.js`, `popup.css` - React popup UI
- `content.js` - Content script
- `inject.js` - Page injection script

### Build iOS app

Open `devtools.xcodeproj` in Xcode and build. The Xcode build phase automatically runs `pnpm build` before compiling.

### Test app

A test web app is included for testing the extension:

```bash
cd test-app
pnpm install
pnpm dev
```

Then open http://localhost:5173 in Safari and use the extension.

## How It Works

### Extension Flow

1. **Content Script** (`content.ts`): Injected into every page, bridges communication between the page and extension
2. **Inject Script** (`inject.ts`): Runs in page context, intercepts `console.*`, `fetch`, and `XMLHttpRequest`
3. **Background Script** (`background.js`): Stores captured logs/requests, relays messages, and sends to native handler
4. **Popup** (`App.tsx`): React UI that displays logs and network requests

Communication flow:

```
Page → inject.js → (postMessage) → content.js → (runtime.sendMessage) → background.js → popup
                                                                              ↓
                                                               (sendNativeMessage)
                                                                              ↓
                                                        SafariWebExtensionHandler → SwiftData
                                                                              ↓
                                                                    Host App (reads & displays)
```

### Data Management

- **Storage**: SwiftData with shared App Group container
- **Limits**: Configurable max logs/requests per tab (default 500/200)
- **Cleanup**:
  - Immediate cleanup when tabs close
  - Periodic sync every 5 minutes to catch missed events
  - Time-based expiry (default 24 hours)
