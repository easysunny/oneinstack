#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://linuxeye.com
#
# Notes: OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack
# https://blog.csdn.net/yimtcode/article/details/143192479

Install_Docker() {
  pushd ${oneinstack_dir}/include > /dev/null
  echo "${CMSG}Installing Docker...${CEND}"



  # Remove old versions if exists
  if command -v docker >/dev/null 2>&1; then
    echo "${CWARNING}Docker already installed! ${CEND}"
    return 0
  fi

  chmod +x ./install-docker.sh
    # 根据地区选择是否使用镜像安装Docker
  if [ "${OUTIP_STATE}"x == "China"x ]; then
    echo "${CMSG}检测到中国地区，使用阿里云镜像安装Docker...${CEND}"
    ./install-docker.sh --version ${docker_ce_ver}  --mirror Aliyun 
    cat > /etc/docker/daemon.json <<-'EOF'
    {
        "registry-mirrors": [
        "https://docker.m.daocloud.io",
        "https://docker.imgdb.de",
        "http://mirror.azure.cn",
        "https://docker.hlmirror.com",
        "http://mirrors.ustc.edu.cn"
        ]
    }
EOF
  else
    echo "${CMSG}使用官方源安装Docker...${CEND}"
    ./install-docker.sh --version ${docker_ce_ver} 
  fi

  # 启动并启用Docker服务
  systemctl enable docker
  systemctl start docker
  # 验证安装
  if command -v docker >/dev/null 2>&1; then
    docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo "${CSUCCESS}Docker ${docker_version} installed successfully! ${CEND}"
    
  else
    echo "${CFAILURE}Docker installation failed! ${CEND}"
    return 1
  fi
}