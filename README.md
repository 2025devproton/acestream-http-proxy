# AceStream HTTP Proxy
[![Build and push Docker image to DockerHub](https://github.com/martinbjeldbak/acestream-http-proxy/actions/workflows/build-and-push-docker.yml/badge.svg)](https://github.com/martinbjeldbak/acestream-http-proxy/actions/workflows/build-and-push-docker.yml)
[![Lint](https://github.com/martinbjeldbak/acestream-http-proxy/actions/workflows/lint-dockerfile.yml/badge.svg)](https://github.com/martinbjeldbak/acestream-http-proxy/actions/workflows/lint-dockerfile.yml)

This Docker image runs the AceStream Engine and exposes its [HTTP
API](https://docs.acestream.net/en/developers/connect-to-engine/).

As a result, you will be able to watch AceStreams over HLS or MPEG-TS, without
needing to install the AceStream player or any other dependencies locally.

This is especially useful for Desktop and NAS usage for anyone who wants to
tune in to AceStream channels, and who don't want to go through the trouble of
installing AceStream and its dependencies natively.

## Supported Architectures

This image supports multiple architectures:

- **linux/amd64** (x86_64): Uses native Linux AceStream binaries
- **linux/arm64** (aarch64): Uses Android ARMv8 (64-bit) binaries adapted for Linux

The correct image for your architecture will be automatically pulled when you run the container.

### ARM64 Notes

ARM64 support uses AceStream's Android ARMv8 binaries running in a Linux environment. This approach has been successfully used by the community and should work on:

- Raspberry Pi 4 and newer (64-bit OS)
- Apple Silicon Macs (M1, M2, M3, etc.)
- AWS Graviton instances
- Other ARM64-based servers and NAS devices

## Usage

```console
docker run -t -p 6878:6878 ghcr.io/martinbjeldbak/acestream-http-proxy
```

You are then able to access AceStreams by pointing your favorite media player
(VLC, IINA, etc.) to either of the below URLs, depending on the desired
streaming protocol.

For HLS:
```console
http://127.0.0.1:6878/ace/manifest.m3u8?id=dd1e67078381739d14beca697356ab76d49d1a2
```

For MPEG-TS:

```console
http://127.0.0.1:6878/ace/getstream?id=dd1e67078381739d14beca697356ab76d49d1a2
```

where `dd1e67078381739d14beca697356ab76d49d1a2d` is the ID of the AceStream channel.

This image can also be deployed to a server, where it can proxy AceStream
content over HTTP.

## Environment Variables

The following environment variables are available to configure the AceStream Engine:

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `HTTP_PORT` | HTTP port for the AceStream engine | `6878` | `6878` |
| `HTTPS_PORT` | HTTPS port for the AceStream engine (must be different from HTTP_PORT) | Not set | `6879` |
| `P2P_PORT` | Port for P2P connections (useful for port forwarding) | Not set | `8621` |
| `BIND_ALL` | Bind to all network interfaces (set to any non-empty value to enable) | Not set | `true` |
| `INTERNAL_BUFFERING` | Enable internal buffering (set to a non-empty value to enable) | Not set | `true` |
| `CACHE_LIMIT` | Cache size limit in GB | Not set | `5` |

### Docker Compose Example

You can run it using docker-compose with:

```yaml
---
services:
  acestream-http-proxy:
    image: ghcr.io/martinbjeldbak/acestream-http-proxy
    container_name: acestream-http-proxy
    ports:
      - 6878:6878
    environment:
      - HTTP_PORT=6878
      - HTTPS_PORT=6879
      - P2P_PORT=8621
      - BIND_ALL=true
      - CACHE_LIMIT=5
```

For an example, see the [docker-compose.yml](./docker-compose.yml) file in this repository.

## Contributing

First of all, thanks!

Ensure you have Docker installed with support for docker-compose, as outlined
above. This image is simply a simplified wrapper around the
[AceStream][acestream] HTTP API in order to make it more user friendly to get
running. All options supported by the AceStream Engine are supported in this
project. Any contributions to support more configuration is greatly
appreciated!

Dockerfile steps are roughly guided by <https://wiki.acestream.media/Install_Ubuntu>.

For a list of AceStream versions, see here: <https://docs.acestream.net/products/#linux>

For convenience of easy image rebuilding, this repository contains a
[`docker-compose.yml`](./docker-compose.yml) file. You can then build & run the
image locally by running the following command:

```console
docker-compose up --build
```

The image will now be running, with the following ports exposed:

- **6878**: AceStream engine port. Docs for command line arguments and debugging
can be found [here][acestream]


[acestream]: https://docs.acestream.net/en/developers/
