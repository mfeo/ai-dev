# AI 開發環境 Just 腳本
# 簡化容器建置和執行流程（Podman rootless 最佳實踐）

# 預設映像名稱
image_name := "ai-dev"

# 預設顯示幫助
default:
    @just --list

# 建置映像（自動匹配主機使用者）
build:
    @echo "建置映像（匹配主機使用者 `whoami`）..."
    podman build \
        --build-arg USERNAME=`whoami` \
        --build-arg USER_UID=`id -u` \
        --build-arg USER_GID=`id -g` \
        -t {{image_name}} .
    @echo "✓ 建置完成: {{image_name}}"

# 執行容器（Podman rootless，可指定掛載路徑，預設為目前目錄）
run path=invocation_directory():
    @echo "執行容器（掛載: {{path}} -> /workspace）..."
    podman run -it --rm \
        --userns=keep-id \
        -v "{{path}}":/workspace:Z \
        {{image_name}}

# 清理映像
clean:
    @echo "清理映像..."
    podman rmi {{image_name}} || true
    @echo "✓ 清理完成"

# 快速重建並執行
rebuild: clean build run

# 顯示映像資訊
info:
    @echo "映像名稱: {{image_name}}"
    @podman images {{image_name}}
