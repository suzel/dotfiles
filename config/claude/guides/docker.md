# Docker

- Use multi-stage builds. Ship only the runtime artifacts.
- Pin base images to a version tag, never `latest`.
- Run as a non-root user.
- Copy dependency manifests before source to keep the layer cache.
