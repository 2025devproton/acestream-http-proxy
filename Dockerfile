# syntax=docker/dockerfile:1

FROM docker.io/library/python:3.10-slim-bookworm@sha256:034724ef64585eeb0e82385e9aabcbeabfe5f7cae2c2dcedb1da95114372b6d7

# Build arguments for multi-arch support
ARG TARGETARCH

LABEL \
    maintainer="Martin Bjeldbak Madsen <me@martinbjeldbak.com>" \
    org.opencontainers.image.title="acestream-http-proxy" \
    org.opencontainers.image.description="Stream AceStream sources without needing to install AceStream player" \
    org.opencontainers.image.authors="Martin Bjeldbak Madsen <me@martinbjeldbak.com>" \
    org.opencontainers.image.url="https://github.com/martinbjeldbak/acestream-http-proxy" \
    org.opencontainers.image.vendor="https://martinbjeldbak.com"

ENV DEBIAN_FRONTEND="noninteractive" \
    CRYPTOGRAPHY_DONT_BUILD_RUST=1 \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_ROOT_USER_ACTION=ignore \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_NO_CACHE=true \
    UV_SYSTEM_PYTHON=true \
    PYTHON_EGG_CACHE=/.cache

ENV ALLOW_REMOTE_ACCESS="no" \
    EXTRA_FLAGS=''

USER root
WORKDIR /app

# hadolint ignore=DL4006,DL3008,DL3013
RUN \
    apt-get update \
    && \
    apt-get install --no-install-recommends --no-install-suggests -y \
        bash \
        ca-certificates \
        catatonit \
        curl \
        nano \
        libgirepository1.0-dev \
        unzip \
    && groupadd --gid 1000 appuser \
    && useradd --uid 1000 --gid 1000 -m appuser \
    && mkdir -p /app \
    && mkdir -p /.cache \
    && \
    # Download and install AceStream based on architecture
    if [ "$TARGETARCH" = "arm64" ]; then \
        # For ARM64, use Android ARMv8 (64-bit) binaries
        echo "Installing AceStream for ARM64 (using Android ARMv8 binaries)..." && \
        curl -fsSL "https://download.acestream.media/products/acestream-engine/android/armv8_64/latest" -o /tmp/acestream.apk && \
        unzip -q /tmp/acestream.apk -d /tmp/acestream && \
        \
        # Set up Android filesystem structure
        mkdir -p /app/androidfs/system/lib && \
        mkdir -p /app/androidfs/project && \
        mkdir -p /app/acestream && \
        \
        # Copy ARM64 libraries
        if [ -d /tmp/acestream/lib/arm64-v8a ]; then \
            cp -r /tmp/acestream/lib/arm64-v8a/* /app/androidfs/system/lib/ 2>/dev/null || true; \
        fi && \
        \
        # Copy assets and Python files
        if [ -d /tmp/acestream/assets ]; then \
            cp -r /tmp/acestream/assets/* /app/acestream/ 2>/dev/null || true; \
        fi && \
        \
        # Clean up temporary files
        rm -rf /tmp/acestream /tmp/acestream.apk && \
        \
        # Create start-engine wrapper script for ARM64
        printf '#!/bin/bash\n' > /app/start-engine && \
        printf '# AceStream Engine wrapper for ARM64 (Android binaries)\n\n' >> /app/start-engine && \
        printf 'export ANDROID_DATA=/app/androidfs\n' >> /app/start-engine && \
        printf 'export ANDROID_ROOT=/app/androidfs/system\n' >> /app/start-engine && \
        printf 'export LD_LIBRARY_PATH=/app/androidfs/system/lib:${LD_LIBRARY_PATH}\n\n' >> /app/start-engine && \
        printf 'cd /app/acestream || cd /app\n\n' >> /app/start-engine && \
        printf 'if [ -f /app/androidfs/system/lib/libacestream.so ]; then\n' >> /app/start-engine && \
        printf '    exec /app/androidfs/system/lib/libacestream.so "$@"\n' >> /app/start-engine && \
        printf 'elif [ -f /app/androidfs/system/lib/acestreamengine.so ]; then\n' >> /app/start-engine && \
        printf '    exec /app/androidfs/system/lib/acestreamengine.so "$@"\n' >> /app/start-engine && \
        printf 'else\n' >> /app/start-engine && \
        printf '    echo "Error: AceStream engine binary not found"\n' >> /app/start-engine && \
        printf '    echo "Available files in /app/androidfs/system/lib:"\n' >> /app/start-engine && \
        printf '    ls -la /app/androidfs/system/lib/ || echo "Directory not found"\n' >> /app/start-engine && \
        printf '    exit 1\n' >> /app/start-engine && \
        printf 'fi\n' >> /app/start-engine && \
        chmod +x /app/start-engine && \
        \
        # Create minimal requirements.txt for ARM64
        printf '# Minimal Python requirements for ARM64\n' > /app/requirements.txt && \
        printf '# The Android binaries include most dependencies\n' >> /app/requirements.txt && \
        echo "ARM64 setup complete"; \
    else \
        # For AMD64, use traditional Linux x86_64 binaries
        echo "Installing AceStream for AMD64 (using Linux x86_64 binaries)..." && \
        VERSION="3.2.3_ubuntu_22.04_x86_64_py3.10" && \
        curl -fsSL "https://download.acestream.media/linux/acestream_${VERSION}.tar.gz" \
            | tar xzf - -C /app && \
        echo "AMD64 setup complete"; \
    fi \
    && pip install uv \
    && uv pip install --requirement /app/requirements.txt \
    && chown -R appuser:appuser /.cache /app && chmod -R 755 /app \
    && pip uninstall --yes uv \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/

COPY . /

USER appuser

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]

EXPOSE 6878/tcp

