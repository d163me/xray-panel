export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    allowedHosts: ['hydrich.online'], // ✅ Добавили домен
  },
});
