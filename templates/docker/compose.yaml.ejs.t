<%_
  // "@su/My.App" → "su-my-app" (compose allows [a-z0-9_-])
  const name = pkg.name.toLowerCase().replace(/^@/, '').replace(/[^a-z0-9_-]/g, '-')
-%>
# yaml-language-server: $schema=https://raw.githubusercontent.com/compose-spec/compose-spec/main/schema/compose-spec.json
# Services are opt-in via profiles, enable them in .env: COMPOSE_PROFILES=db
# .env example: https://github.com/suzel/postgrest-example/blob/master/.env
name: <%- name %>

services:
  postgrest:
    profiles: [db]
    image: postgrest/postgrest:v16.4
    ports:
      - "127.0.0.1:3000:3000"
    env_file: ../.env
    depends_on:
      postgres:
        condition: service_healthy

  postgres:
    profiles: [db]
    image: postgres:18-alpine
    ports:
      - "127.0.0.1:5432:5432"
    env_file: ../.env
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 5s
      retries: 10
    volumes:
      - postgres-api:/var/lib/postgresql
      - ./sql/init.sql:/docker-entrypoint-initdb.d/init.sql:ro

  pgweb:
    profiles: [db]
    image: sosedoff/pgweb:0.17.0
    restart: unless-stopped
    ports:
      - "127.0.0.1:8081:8081"
    environment:
      DATABASE_URL: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?sslmode=disable
    depends_on:
      postgres:
        condition: service_healthy

# every service joins the default network, so no per-service `networks:` needed
networks:
  default:
    name: <%- name %>

volumes:
  postgres-api:
