import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react(),  tailwindcss()],
  base: './',
  root: 'react_src',
  server: {
    port: 3000,
    open: true
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