import { defineConfig } from "vite";
import { resolve } from "path";

// Build content script
export default defineConfig({
  build: {
    outDir: resolve(__dirname, "../devtools Extension/Resources"),
    emptyOutDir: false,
    lib: {
      entry: resolve(__dirname, "src/content.ts"),
      name: "DevToolsContent",
      formats: ["iife"],
      fileName: () => "content.js",
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
});
