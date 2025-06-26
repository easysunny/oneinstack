#!/bin/bash

# Docker 和 Docker Compose 安装脚本
# 适用于 Amazon Linux 2, CentOS, RHEL 等基于 yum 的系统

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以 root 用户运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要以 root 用户权限运行"
        log_info "请使用: sudo bash $0"
        exit 1
    fi
}

# 检查系统是否支持
check_system() {
    if ! command -v yum &> /dev/null; then
        log_error "此脚本仅支持基于 yum 的系统 (Amazon Linux, CentOS, RHEL 等)"
        exit 1
    fi
    
    log_info "检测到支持的系统，继续安装..."
}

# 检查网络连接
check_network() {
    log_info "检查网络连接..."
    if ! ping -c 1 baidu.com &> /dev/null && ! ping -c 1 github.com &> /dev/null; then
        log_error "网络连接失败，请检查网络设置"
        exit 1
    fi
    log_info "网络连接正常"
}

# 安装 Docker
install_docker() {
    log_info "开始安装 Docker..."
    
    # 更新 yum 包索引
    if ! yum update -y; then
        log_error "更新软件包索引失败"
        exit 1
    fi
    
    # 安装 Docker
    if ! yum install docker -y; then
        log_error "Docker 安装失败"
        exit 1
    fi
    
    log_info "Docker 安装成功"
}

# 启动并配置 Docker 服务
configure_docker() {
    log_info "配置 Docker 服务..."
    
    # 启用 Docker 服务开机自启
    if ! systemctl enable docker; then
        log_error "Docker 服务启用失败"
        exit 1
    fi
    
    # 启动 Docker 服务
    if ! systemctl start docker; then
        log_error "Docker 服务启动失败"
        exit 1
    fi
    
    # 验证 Docker 服务状态
    if ! systemctl is-active --quiet docker; then
        log_error "Docker 服务未正常运行"
        exit 1
    fi
    
    log_info "Docker 服务配置完成"
}

# 安装 Docker Compose
install_docker_compose() {
    log_info "开始安装 Docker Compose..."
    
    DOCKER_COMPOSE_VERSION="v2.37.3"
    ARCH=$(uname -m)
    OS=$(uname -s)
    
    # 构建下载 URL
    DOWNLOAD_URL="https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$OS-$ARCH"
    
    log_info "下载 Docker Compose $DOCKER_COMPOSE_VERSION..."
    
    # 下载 Docker Compose
    if ! curl -L "$DOWNLOAD_URL" -o /usr/local/bin/docker-compose --connect-timeout 30 --max-time 300; then
        log_error "Docker Compose 下载失败"
        log_info "尝试手动下载: $DOWNLOAD_URL"
        exit 1
    fi
    
    # 设置执行权限
    if ! chmod +x /usr/local/bin/docker-compose; then
        log_error "设置 Docker Compose 执行权限失败"
        exit 1
    fi
    
    log_info "Docker Compose 安装成功"
}

# 验证安装
verify_installation() {
    log_info "验证安装结果..."
    
    # 验证 Docker
    if ! docker --version &> /dev/null; then
        log_error "Docker 验证失败"
        exit 1
    fi
    
    # 验证 Docker Compose
    if ! docker-compose --version &> /dev/null; then
        log_error "Docker Compose 验证失败"
        exit 1
    fi
    
    # 运行 Docker 测试
    log_info "运行 Docker 测试..."
    if docker run --rm hello-world &> /dev/null; then
        log_info "Docker 测试成功"
    else
        log_warn "Docker 测试失败，但 Docker 已安装。可能需要重新登录或重启系统"
    fi
    
    # 显示版本信息
    echo
    log_info "安装完成！版本信息："
    echo "Docker: $(docker --version)"
    echo "Docker Compose: $(docker-compose --version)"
}



# 清理函数
cleanup() {
    if [[ $? -ne 0 ]]; then
        log_error "安装过程中出现错误，脚本已退出"
    fi
}

# 设置错误处理
trap cleanup EXIT

# 主函数
main() {
    echo "==============================================="
    echo "        Docker & Docker Compose 安装脚本"
    echo "==============================================="
    echo
    
    check_root
    check_system
    check_network
    install_docker
    configure_docker
    install_docker_compose
    verify_installation
    
    echo
    log_info "所有组件安装完成！"
    log_info "如果是第一次安装，建议重新登录以确保权限生效"
    echo "==============================================="
}

# 运行主函数
main "$@"
