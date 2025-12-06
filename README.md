# Safari Mobile DevTools

A Safari extension for iOS that provides developer console functionality similar to desktop browser DevTools.

## Features

- **Console**: View `console.log`, `console.warn`, `console.error`, and `console.info` output
- **JavaScript Execution**: Run arbitrary JavaScript on the current page
- **Error Tracking**: Capture runtime errors and unhandled promise rejections
- **Network Monitoring**: Inspect fetch and XMLHttpRequest calls with request/response details

## Tech Stack

- **Popup UI**: Vite + React + TypeScript + Tailwind CSS
- **Icons**: Lucide React
- **Linting/Formatting**: Biome

## Project Structure

```
devtools/
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
│   └── Info.plist
├── devtools/                     # iOS app container
└── devtools.xcodeproj/
```

## Requirements

- Xcode 16+
- Node.js 18+
- pnpm

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

1. **Content Script** (`content.ts`): Injected into every page, bridges communication between the page and extension
2. **Inject Script** (`inject.ts`): Runs in page context, intercepts `console.*`, `fetch`, and `XMLHttpRequest`
3. **Background Script** (`background.js`): Stores captured logs/requests and relays messages
4. **Popup** (`App.tsx`): React UI that displays logs and network requests

Communication flow:

```
Page → inject.js → (postMessage) → content.js → (runtime.sendMessage) → background.js → popup
```
