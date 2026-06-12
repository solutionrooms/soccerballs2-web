import { defineConfig } from 'vite';

export default defineConfig({
  root: '.',
  base: '/soccerballs2/',
  build: {
    outDir: 'dist',
    target: 'es2020',
  },
});
