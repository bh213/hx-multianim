import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { resolve } from 'path'
import { watch } from 'fs'

// Custom plugin to watch Haxe output and trigger reload
function haxeHotReload() {
  return {
    name: 'haxe-hot-reload',
    configureServer(server: any) {
      const playgroundJsPath = resolve(__dirname, 'public/playground.js')

      // Watch for changes to playground.js (Haxe output)
      const watcher = watch(playgroundJsPath, (eventType) => {
        if (eventType === 'change') {
          console.log('\n🔄 Haxe rebuild detected, reloading...\n')
          // Send full reload signal to all connected clients
          server.ws.send({
            type: 'full-reload',
            path: '*'
          })
        }
      })

      // Cleanup watcher on server close
      server.httpServer?.on('close', () => {
        watcher.close()
      })
    }
  }
}

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss(), haxeHotReload()],
  base: './',
  root: 'react_src',
  server: {
    port: 5000,
    open: true,
    watch: {
      // Also watch public directory for manim/anim file changes
      ignored: ['!**/public/**']
    }
  },
  build: {
    outDir: '../dist',
    sourcemap: true
  },
  publicDir: '../public',
  optimizeDeps: {
    include: ['react', 'react-dom']
  },
  assetsInclude: [
    '**/*.manim',
    '**/*.anim'
  ],
  // Ensure proper handling of raw imports for text files
  define: {
    __VITE_RAW_IMPORTS__: true
  }
})
