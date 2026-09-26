# syntax=docker/dockerfile:1.7
FROM node:22-bookworm-slim AS base
RUN npm install -g --force corepack@latest && corepack enable
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./


FROM base AS deps
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile


FROM deps AS dev
EXPOSE 5173 24678
CMD ["pnpm", "exec", "vite", "dev", "--host", "0.0.0.0"]


FROM deps AS builder
COPY . .
RUN pnpm run build
RUN pnpm prune --prod


FROM gcr.io/distroless/nodejs22-debian12:nonroot AS production
WORKDIR /app
COPY --from=builder --chown=nonroot:nonroot /app/build ./build
COPY --from=builder --chown=nonroot:nonroot /app/node_modules ./node_modules
COPY --from=builder --chown=nonroot:nonroot /app/package.json ./
EXPOSE 3000
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000
CMD ["build/index.js"]
