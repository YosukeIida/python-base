# 使用するPythonのバージョンを指定
ARG PYTHON_VERSION=3.12.9
ARG USERNAME=uvpython
ARG FIXUID_VER=0.6.0


### ----- Base Stage -----
FROM python:${PYTHON_VERSION}-slim AS base
WORKDIR /workspace/app
ARG USERNAME

### ----- Dependencies Stage -----
FROM ghcr.io/astral-sh/uv:python${PYTHON_VERSION%.*}-bookworm-slim AS deps
WORKDIR /workspace/app
ARG USERNAME

# UV_LINK_MODE: wheelからパッケージをコピーしてインストールする
# UV_COMPILE_BYTECODE: インストール後にソースファイルをバイトコードにコンパイルする
# UV_PYTHON_DOWNLOADS: コンテナのpython環境を使うためuvにはpythonをダウンロードさせない
# UV_PYTHON: uvを操作する際にpythonを指定する
ENV UV_SYSTEM_PYTHON=1 \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_DOWNLOADS=never \
    UV_PYTHON=python${PYTHON_VERSION%.*}

# 依存解決に必要なのは pyproject.toml と uv.lock のみ
COPY app/pyproject.toml ./
# uv.lockがある場合のみコピー（初回ビルド対応）
COPY app/uv.lock* ./
RUN --mount=type=cache,target=/root/.cache \
    if [ -f uv.lock ]; then \
        echo "Using existing uv.lock file"; \
        uv sync --frozen --no-install-project; \
    else \
        echo "No uv.lock found, creating one"; \
        uv lock && uv sync --frozen --no-install-project; \
    fi && \
    uv pip check


### ----- Build Stage -----
FROM deps AS build
WORKDIR /workspace/app
# プロジェクト全体をコピー
COPY app/ /workspace/app
# プロジェクト自身をeditableモード, 仮想環境なしにインストール
RUN --mount=type=cache,target=/root/.cache \
    uv pip install --system -e .


### ----- Development Stage -----
FROM base AS dev
ARG USERNAME

# 開発用 CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    openssh-client \
    poppler-utils \
    curl \
    make \
    tar \
    && rm -rf /var/lib/apt/lists/*

# uv のバイナリをコピー
COPY --from=deps /usr/local/bin/uv /usr/local/bin/uv

# 仮 UID=1000 でユーザ作成 & fixuid 導入
ARG FIXUID_VER

RUN set -eux; \
    groupadd -g 1000 "$USERNAME" && useradd -u 1000 -g 1000 -m "$USERNAME"; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64)  arch=amd64; ver="$FIXUID_VER" ;; \
      aarch64) arch=arm64; ver="$FIXUID_VER" ;; \
      *) echo "Unsupported arch: $arch"; exit 1 ;; \
    esac; \
    url="https://github.com/boxboat/fixuid/releases/download/v${ver}/fixuid-${ver}-linux-${arch}.tar.gz"; \
    curl -fsSL "$url" | tar -xz -C /usr/local/bin && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: %s\ngroup: %s\n" "$USERNAME" "$USERNAME" > /etc/fixuid/config.yml

# build 成果物取り込み
COPY --from=build --chown=uvpython:uvpython /usr/local /usr/local/
COPY --from=build --chown=uvpython:uvpython /workspace/app /workspace/app/

ENV PYTHONPATH=/workspace/app/src
USER $USERNAME
ENTRYPOINT ["fixuid","-q","--","tail","-f","/dev/null"]
EXPOSE 8000


### ----- Production Stage -----
FROM base AS prod
ARG USERNAME
ARG FIXUID_VER

# 仮 UID=1000 でユーザ作成 & fixuid 導入
RUN set -eux; \
    groupadd -g 1000 "$USERNAME" && useradd -u 1000 -g 1000 -m "$USERNAME"; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64)  arch=amd64; ver="$FIXUID_VER" ;; \
      aarch64) arch=arm64; ver="$FIXUID_VER" ;; \
      *) echo "Unsupported arch: $arch"; exit 1 ;; \
    esac; \
    url="https://github.com/boxboat/fixuid/releases/download/v${ver}/fixuid-${ver}-linux-${arch}.tar.gz"; \
    curl -fsSL "$url" | tar -xz -C /usr/local/bin && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: %s\ngroup: %s\n" "$USERNAME" "$USERNAME" > /etc/fixuid/config.yml

COPY --from=build /usr/local /usr/local/
COPY --from=build /workspace/app /workspace/app/
ENV PYTHONPATH=/workspace/app/src
WORKDIR /workspace/app
USER $USERNAME
ENTRYPOINT ["fixuid","-q","--","tail","-f","/dev/null"]
EXPOSE 8000
