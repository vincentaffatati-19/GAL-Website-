import { defineConfig } from 'vite';

export default defineConfig({
  base: '/portal/',
  build: {
    assetsInlineLimit: 20000,
  },
});
