# syntax=docker/dockerfile:1

ARG GODOT_VERSION=4.6.2
ARG GODOT_STATUS=stable
ARG GODOT_RELEASE=${GODOT_VERSION}-${GODOT_STATUS}

FROM debian:bookworm-slim AS godot-builder

ARG GODOT_VERSION
ARG GODOT_STATUS
ARG GODOT_RELEASE
ARG GODOT_VERSION_DIR=${GODOT_VERSION}.${GODOT_STATUS}

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates unzip wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/godot

RUN wget -q --tries=5 --timeout=30 "https://github.com/godotengine/godot/releases/download/${GODOT_RELEASE}/Godot_v${GODOT_RELEASE}_linux.x86_64.zip" -O godot.zip \
    && unzip -q godot.zip \
    && find . -maxdepth 1 -type f -name "Godot_v${GODOT_RELEASE}_linux.x86_64*" ! -name "*.zip" -exec mv {} /usr/local/bin/godot \; \
    && chmod +x /usr/local/bin/godot \
    && wget -q --tries=5 --timeout=30 "https://github.com/godotengine/godot/releases/download/${GODOT_RELEASE}/Godot_v${GODOT_RELEASE}_export_templates.tpz" -O export_templates.tpz \
    && mkdir -p "/root/.local/share/godot/export_templates/${GODOT_VERSION_DIR}" \
    && unzip -q export_templates.tpz -d export_templates \
    && cp export_templates/templates/* "/root/.local/share/godot/export_templates/${GODOT_VERSION_DIR}/"

WORKDIR /workspace
COPY src/ ./src/

RUN mkdir -p dist/web \
    && godot --headless --path src --import \
    && godot --headless --path src --export-release Web ../dist/web/index.html

FROM nginx:1.27-alpine AS runtime

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=godot-builder /workspace/dist/web/ /usr/share/nginx/html/

EXPOSE 80
