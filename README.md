# AI 開發環境 (Podman)

此目錄包含使用 Podman 建立 claude code/gemini cli/opencode 開發環境所需的容器設定。

## 快速開始（使用 Just 推薦）

### 安裝 Just

首先安裝 Just 指令執行器，用於簡化建置和執行流程。

**Linux/WSL2**:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
```

**macOS**:
```bash
brew install just
```

**其他平台**：參見 [Just 官方安裝指南](https://github.com/casey/just#installation)

### 使用 Just 快速開始

```bash
# 列出所有可用指令
just

# 常用指令
just build           # 建置映像（自動匹配主機使用者）
just run             # 執行容器（Podman rootless）
just rebuild         # 清理並重新建置後執行
just info            # 顯示映像資訊
just clean           # 清理映像
```

### 傳統指令行操作（不使用 Just）

如果不想使用 Just，可使用原始的容器指令：

#### 1. 建置映像檔

**使用預設值（推薦用於 CI/CD 和快速測試）**

```bash
cd ~/projects/ai-dev
podman build -t ai-dev .
```

**自訂使用者（推薦用於本地開發）**

匹配主機使用者以避免檔案權限問題：

```bash
podman build \
  --build-arg USERNAME=$(whoami) \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  -t ai-dev .
```

#### 2. 執行開發容器

**Podman rootless 模式（推薦）**

```bash
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd)":/workspace:Z \
  ai-dev
```

**Docker Desktop（macOS/Windows）**

```bash
docker run -it --rm \
  -v "$(pwd)":/workspace:cached \
  ai-dev
```

**標準執行**

```bash
podman run -it --rm \
  -v "$(pwd)":/workspace:Z \
  ai-dev
```

> **使用者配置**: 自 v2.0.0 起，Containerfile 支援可配置的非 root 使用者。預設值為 `devuser` (UID 1000)，可在建置時自訂以匹配主機使用者。

## 進階用法

### 使用自訂使用者配置

如果容器建置時未使用 `--build-arg` 自訂，可在執行時檢查使用者設置：

```bash
# 檢查容器內的使用者
podman run --rm ai-dev whoami

# 檢查 UID/GID
podman run --rm ai-dev id

# 檢查 HOME 目錄
podman run --rm ai-dev echo $HOME
```

### 掛載 API Key 設定

如果您需要在容器內使用 LLM API（如 OpenAI、Anthropic），可以掛載設定檔：

```bash
podman run -it --rm \
  --userns=keep-id \
  -v "$(pwd)":/workspace:Z \
  -v ~/.opencode:/home/devuser/.opencode:Z \
  ai-dev
```

> 注意：如果使用自訂使用者，請將 `/home/devuser` 替換為 `/home/${USERNAME}`

### 使用 VS Code Dev Containers

1. 安裝 VS Code 的 **Dev Containers** 擴充套件
2. 在 VS Code 設定中指定使用 Podman：
   ```json
   {
     "dev.containers.dockerPath": "podman",
     "dev.containers.dockerComposePath": "podman-compose"
   }
   ```
3. 開啟 `opencode_repo` 資料夾並選擇「在容器中重新開啟」

## 需求

- **Linux/WSL2**: Podman 4.x+ 或 Docker 20.10+
- **macOS**: Docker Desktop 或 Podman Desktop
- **Windows**: WSL2 + Podman 或 Docker Desktop
- 足夠的磁碟空間 (約 2GB 給映像檔)

## 跨平台支援

Containerfile 現已支援多個環境：

| 環境 | 建置命令 | 執行命令 |
|------|--------|--------|
| **Linux (Podman rootless)** | `podman build -t ai-dev .` | `podman run --userns=keep-id -v $(pwd):/workspace:Z ai-dev` |
| **Linux (標準)** | `podman build -t ai-dev .` | `podman run -v $(pwd):/workspace:Z ai-dev` |
| **WSL2 + Podman** | 同 Linux | 同 Linux |
| **macOS (Docker Desktop)** | `docker build -t ai-dev .` | `docker run -v $(pwd):/workspace:cached ai-dev` |
| **Windows (Docker Desktop)** | `docker build -t ai-dev .` | `docker run -v $(pwd):/workspace ai-dev` |

> **提示**: 本地開發時，使用 `--build-arg USERNAME=$(whoami)` 以匹配主機使用者，避免檔案權限問題。
