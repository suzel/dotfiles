services:
  # App
  app:
    build:
      target: dev
    command: pnpm exec vite dev --host 0.0.0.0
    ports:
      - '5173:5173'
      - '24678:24678'
    environment:
      NODE_ENV: development
      ORIGIN: http://localhost:5173
    volumes:
      - ../:/app
      - /app/node_modules
      - /app/.svelte-kit