FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# ---------------------------
# 使用者配置參數
# ---------------------------
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

# ---------------------------
# Base system
# ---------------------------
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    wget \
    git \
    unzip \
    zip \
    bash \
    jq \
    gnupg \
    build-essential \
    software-properties-common \
    vim \
    openssh-client \
    openjdk-25-jdk \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------
# Node.js 22 (from NodeSource)
# ---------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------
# Python 3 + uv
# ---------------------------
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# uv (官方安裝)
# uv (install to /usr/local/bin)
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" bash

# ---------------------------
# Go
# ---------------------------
ARG GO_VERSION=1.25.6
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    | tar -C /usr/local -xz

ENV PATH="/usr/local/go/bin:${PATH}"

# ---------------------------
# 建立非 root 使用者
# ---------------------------
RUN bash -c ' \
    # 刪除 ubuntu:24.04 預設的 ubuntu 使用者和群組
    userdel -r ubuntu 2>/dev/null || true; \
    groupdel ubuntu 2>/dev/null || true; \
    # 建立新使用者
    groupadd --gid ${USER_GID} ${USERNAME}; \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME}; \
    '

# ---------------------------
# 建立並設定 workspace 目錄權限
# ---------------------------
RUN mkdir -p /workspace \
    && chown -R ${USER_UID}:${USER_GID} /workspace

# ---------------------------
# 切換至非 root 使用者
# ---------------------------
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# ---------------------------
# 配置 readline (.inputrc) - 使用者級配置
# ---------------------------
RUN { \
    echo '# 歷史搜尋增強'; \
    echo '"\e[A": history-search-backward'; \
    echo '"\e[B": history-search-forward'; \
    echo '"\C-p": history-search-backward'; \
    echo '"\C-n": history-search-forward'; \
    echo ''; \
    echo '# 自動完成優化'; \
    echo 'set completion-ignore-case On'; \
    echo 'set completion-map-case On'; \
    echo 'set show-all-if-ambiguous On'; \
    echo 'set show-all-if-unmodified On'; \
    echo 'set menu-complete-display-prefix On'; \
    echo 'set skip-completed-text On'; \
    echo 'set completion-query-items -1'; \
    echo ''; \
    echo '# 視覺增強'; \
    echo 'set colored-stats On'; \
    echo 'set colored-completion-prefix On'; \
    echo 'set visible-stats On'; \
    echo 'set mark-symlinked-directories On'; \
    echo 'set completion-prefix-display-length 3'; \
    echo ''; \
    echo '# 其他設定'; \
    echo 'set bell-style none'; \
    echo 'set expand-tilde On'; \
    echo 'set enable-bracketed-paste On'; \
    echo 'set input-meta On'; \
    echo 'set output-meta On'; \
    echo 'set blink-matching-paren On'; \
    echo ''; \
    echo '# 鍵綁定'; \
    echo '"\e[1;5C": forward-word'; \
    echo '"\e[1;5D": backward-word'; \
    echo '"\e[5C": forward-word'; \
    echo '"\e[5D": backward-word'; \
    echo '"\e[1~": beginning-of-line'; \
    echo '"\e[4~": end-of-line'; \
    echo '"\e[3~": delete-char'; \
    echo '"\e[2~": quoted-insert'; \
    } > $HOME/.inputrc

# ---------------------------
# Bun
# ---------------------------
# Install Bun (default to ~/.bun)
RUN curl -fsSL https://bun.sh/install | bash

ENV BUN_INSTALL="/home/${USERNAME}/.bun"
ENV PATH="$BUN_INSTALL/bin:${PATH}"

# ---------------------------
# Scala + Mill
# ---------------------------

# Install Scala with cs setup
# Install Coursier and Scala to user local bin
RUN mkdir -p $HOME/.local/bin \
    && curl -fL https://github.com/coursier/coursier/releases/latest/download/cs-x86_64-pc-linux.gz \
    | gzip -d > $HOME/.local/bin/cs && chmod +x $HOME/.local/bin/cs \
    && $HOME/.local/bin/cs install --install-dir $HOME/.local/bin scala scalac

# Install mill to user local bin
RUN curl -fL https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/1.1.0-RC4/mill-dist-1.1.0-RC4-mill.sh \
    -o $HOME/.local/bin/mill \
    && chmod +x $HOME/.local/bin/mill

ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# ---------------------------
# LLM CLI common deps
# ---------------------------
RUN bun install -g \
    @anthropic-ai/claude-code \
    @google/gemini-cli \
    opencode-ai

WORKDIR /workspace

CMD ["bash"]
