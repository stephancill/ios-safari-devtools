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

## Project Structure

- `popup-app/` - Vite + React + TypeScript popup UI source
- `devtools Extension/Resources/` - Built extension files (gitignored)
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

## Key Files

- `popup-app/src/inject.ts` - Runs in page context, intercepts console/network
- `popup-app/src/content.ts` - Content script, bridges page and extension
- `popup-app/src/App.tsx` - Main popup UI component
- `devtools Extension/Resources/manifest.json` - Extension manifest

## Xcode Build

The Xcode project has a build phase that automatically runs `pnpm build` before compiling the iOS app.
