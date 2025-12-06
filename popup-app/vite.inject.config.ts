import { resolve } from "node:path"
import { defineConfig } from "vite"

// Build inject script (runs in page context)
export default defineConfig({
  build: {
    outDir: resolve(__dirname, "../devtools Extension/Resources"),
    emptyOutDir: false,
    lib: {
      entry: resolve(__dirname, "src/inject.ts"),
      name: "DevToolsInject",
      formats: ["iife"],
      fileName: () => "inject.js",
    },
    rollupOptions: {
      output: {
        inlineDynamicImports: true,
      },
    },
    sourcemap: false,
    minify: false,
    target: "es2020",
  },
})
