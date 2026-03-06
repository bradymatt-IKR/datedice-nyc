import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['icons/*.png'],
      manifest: {
        name: 'Date Dice NYC',
        short_name: 'Date Dice',
        description: 'Roll the dice. Let NYC surprise you. A couples\' date night generator powered by live search.',
        start_url: '/',
        display: 'standalone',
        theme_color: '#0c0c18',
        background_color: '#0c0c18',
        icons: [
          { src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png' },
          { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
        ],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,png,svg,ico}'],
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/api\.open-meteo\.com\/.*/i,
            handler: 'NetworkFirst',
            options: { cacheName: 'weather-cache', expiration: { maxEntries: 5, maxAgeSeconds: 1800 } },
          },
        ],
      },
    }),
  ],
  server: {
    proxy: {
      '/api': {
        target: process.env.VITE_API_PROXY || 'https://datedice-nyc.vercel.app',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
  },
});
