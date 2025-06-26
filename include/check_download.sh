#!/bin/bash
# Author:  Alpha Eva <kaneawk AT gmail.com>
#
# Notes: OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack

checkDownload() {
  pushd ${oneinstack_dir}/src > /dev/null


  # General system utils
  if [ "${with_old_openssl_flag}" == 'y' ]; then
    echo "Download openSSL..."
    src_url=${mirror_link}/oneinstack/src/openssl-${openssl_ver}.tar.gz && Download_src
    echo "Download cacert.pem..."
    src_url=https://curl.se/ca/cacert.pem && Download_src
  fi

  # openssl1.1
  if [[ ${nginx_option} =~ ^[1-3]$ ]]; then
      echo "Download openSSL1.1..."
      src_url=${mirror_link}/oneinstack/src/openssl-${openssl11_ver}.tar.gz && Download_src
  fi

  # jemalloc
  if [[ ${nginx_option} =~ ^[1-3]$ ]] || [[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]]; then
    echo "Download jemalloc..."
    src_url=${mirror_link}/oneinstack/src/jemalloc-${jemalloc_ver}.tar.bz2 && Download_src
  fi

  # pcre
  if [[ "${nginx_option}" =~ ^[1-3]$ ]] || [ "${apache_flag}" == 'y' ]; then
    echo "Download pcre..."
    src_url=${mirror_link}/oneinstack/src/pcre-${pcre_ver}.tar.gz && Download_src
  fi

  # nginx/tengine/openresty
  case "${nginx_option}" in
    1)
      echo "Download nginx..."
      src_url=https://nginx.org/download/nginx-${nginx_ver}.tar.gz && Download_src
      ;;
    2)
      echo "Download tengine..."
      #src_url=http://tengine.taobao.org/download/tengine-${tengine_ver}.tar.gz && Download_src
      src_url=${mirror_link}/oneinstack/src/tengine-${tengine_ver}.tar.gz && Download_src
      ;;
    3)
      echo "Download openresty..."
      src_url=${mirror_link}/oneinstack/src/openresty-${openresty_ver}.tar.gz && Download_src
      ;;
  esac

  # if nginx_option=4 download caddy
  if [ "${nginx_option}" == '4' ]; then
    echo "Download caddy ${caddy_ver}"
    src_url=${mirror_link}/caddy/v${caddy_ver}/caddy-${caddy_ver}.tar.gz  && Download_src
  fi

  # caddy
  if [ "${caddy_flag}" == 'y' ]; then
    echo "Download caddy ${caddy_ver}"
    src_url=${mirror_link}/caddy/v${caddy_ver}/caddy-${caddy_ver}.tar.gz  && Download_src
  fi


  # tomcat
  case "${tomcat_option}" in
    1)
      echo "Download tomcat 11..."
      src_url=${mirror_link}/apache/tomcat/v${tomcat11_ver}/apache-tomcat-${tomcat11_ver}.tar.gz && Download_src
      ;;
    2)
      echo "Download tomcat 10..."
      src_url=${mirror_link}/apache/tomcat/v${tomcat10_ver}/apache-tomcat-${tomcat10_ver}.tar.gz && Download_src
      ;;
    3)
      echo "Download tomcat 9..."
      src_url=${mirror_link}/apache/tomcat/v${tomcat9_ver}/apache-tomcat-${tomcat9_ver}.tar.gz && Download_src
      ;;
    4)
      echo "Download tomcat 8..."
      src_url=${mirror_link}/apache/tomcat/v${tomcat8_ver}/apache-tomcat-${tomcat8_ver}.tar.gz && Download_src
      ;;
    5)
      echo "Download tomcat 7..."
      src_url=${mirror_link}/apache/tomcat/v${tomcat7_ver}/apache-tomcat-${tomcat7_ver}.tar.gz && Download_src
      src_url=${mirror_link}/apache/tomcat/v${tomcat7_ver}/catalina-jmx-remote.jar && Download_src
      ;;
  esac

  # jdk apr
  if [[ "${jdk_option}"  =~ ^[1-2]$ ]]; then
    echo "Download apr..."
    src_url=http://archive.apache.org/dist/apr/apr-${apr_ver}.tar.gz && Download_src
  fi

  if [[ "${db_option}" =~ ^[1-9]$|^1[0-4]$ ]]; then
    if [[ "${db_option}" =~ ^[1,2,5,6,7,9]$|^10$ ]] && [ "${dbinstallmethod}" == "2" ]; then
      [[ "${db_option}" =~ ^[2,5,6,7]$|^10$ ]] && boost_ver=${boost_oldver}
      [[ "${db_option}" =~ ^9$ ]] && boost_ver=${boost_percona_ver}
      echo "Download boost..."
      [ "${OUTIP_STATE}"x == "China"x ] && DOWN_ADDR_BOOST=${mirror_link}/oneinstack/src || DOWN_ADDR_BOOST=https://downloads.sourceforge.net/project/boost/boost/${boost_ver}
      boostVersion2=$(echo ${boost_ver} | awk -F. '{print $1"_"$2"_"$3}')
      src_url=${DOWN_ADDR_BOOST}/boost_${boostVersion2}.tar.gz && Download_src
    fi

    case "${db_option}" in
      1)
        # MySQL 8.0
        if [ "${OUTIP_STATE}"x == "China"x ]; then
          DOWN_ADDR_MYSQL=https://mirrors.aliyun.com/mysql/MySQL-8.0
        else
          DOWN_ADDR_MYSQL==https://mirrors.dotsrc.org/mysql/Downloads/MySQL-8.0
        fi

        if [ "${dbinstallmethod}" == '1' ]; then
          echo "Download MySQL 8.0 binary package..."
          FILE_NAME=mysql-${mysql80_ver}-linux-glibc2.12-x86_64.tar.xz
        elif [ "${dbinstallmethod}" == '2' ]; then
          echo "Download MySQL 8.0 source package..."
          FILE_NAME=mysql-${mysql80_ver}.tar.gz
        fi
        # start download
        src_url=${DOWN_ADDR_MYSQL}/${FILE_NAME} && Download_src
        src_url=${DOWN_ADDR_MYSQL}/${FILE_NAME}.md5 && Download_src
        # verifying download
        MYSQL_TAR_MD5=$(awk '{print $1}' ${FILE_NAME}.md5)
        [ -z "${MYSQL_TAR_MD5}" ] && MYSQL_TAR_MD5=$(curl -s ${DOWN_ADDR_MYSQL_BK}/${FILE_NAME}.md5 | grep ${FILE_NAME} | awk '{print $1}')
        tryDlCount=0
        while [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" != "${MYSQL_TAR_MD5}" ]; do
          wget -c --no-check-certificate ${DOWN_ADDR_MYSQL_BK}/${FILE_NAME};sleep 1
          let "tryDlCount++"
          [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" == "${MYSQL_TAR_MD5}" -o "${tryDlCount}" == '6' ] && break || continue
        done
        if [ "${tryDlCount}" == '6' ]; then
          echo "${CFAILURE}${FILE_NAME} download failed, Please contact the author! ${CEND}"
          kill -9 $$; exit 1;
        fi
        ;;
      2)
        # MySQL 5.7
        if [ "${OUTIP_STATE}"x == "China"x ]; then
          DOWN_ADDR_MYSQL=https://cdn.mysql.com/Downloads/MySQL-5.7
          DOWN_ADDR_MYSQL_BK=https://mirrors.aliyun.com/mysql/MySQL-5.7
          DOWN_ADDR_MYSQL_BK2=http://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-5.7
        else
          DOWN_ADDR_MYSQL=https://cdn.mysql.com/Downloads/MySQL-5.7
          DOWN_ADDR_MYSQL_BK=https://mirrors.dotsrc.org/mysql/Downloads/MySQL-5.7
        fi

        if [ "${dbinstallmethod}" == '1' ]; then
          echo "Download MySQL 5.7 binary package..."
          FILE_NAME=mysql-${mysql57_ver}-linux-glibc2.12-x86_64.tar.gz
        elif [ "${dbinstallmethod}" == '2' ]; then
          echo "Download MySQL 5.7 source package..."
          FILE_NAME=mysql-${mysql57_ver}.tar.gz
        fi
        # start download
        src_url=${DOWN_ADDR_MYSQL}/${FILE_NAME} && Download_src
        src_url=${DOWN_ADDR_MYSQL}/${FILE_NAME}.md5 && Download_src
        # verifying download
        MYSQL_TAR_MD5=$(awk '{print $1}' ${FILE_NAME}.md5)
        [ -z "${MYSQL_TAR_MD5}" ] && MYSQL_TAR_MD5=$(curl -s ${DOWN_ADDR_MYSQL_BK}/${FILE_NAME}.md5 | grep ${FILE_NAME} | awk '{print $1}')
        tryDlCount=0
        while [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" != "${MYSQL_TAR_MD5}" ]; do
          wget -c --no-check-certificate ${DOWN_ADDR_MYSQL_BK}/${FILE_NAME};sleep 1
          let "tryDlCount++"
          [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" == "${MYSQL_TAR_MD5}" -o "${tryDlCount}" == '6' ] && break || continue
        done
        if [ "${tryDlCount}" == '6' ]; then
          echo "${CFAILURE}${FILE_NAME} download failed, Please contact the author! ${CEND}"
          kill -9 $$; exit 1;
        fi
        ;;
      3)
        # MySQL 5.6
        if [ "${OUTIP_STATE}"x == "China"x ]; then
          DOWN_ADDR_MYSQL=http://mirrors.aliyun.com/mysql/MySQL-5.6
          DOWN_ADDR_MYSQL_BK=http://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-5.6
          DOWN_ADDR_MYSQL_BK2=https://mirrors.aliyun.com/mysql/MySQL-5.6
        else
          DOWN_ADDR_MYSQL=https://cdn.mysql.com/Downloads/MySQL-5.6
          DOWN_ADDR_MYSQL_BK=https://mirrors.dotsrc.org/mysql/Downloads/MySQL-5.6
        fi

        if [ "${dbinstallmethod}" == '1' ]; then
          echo "Download MySQL 5.6 binary package..."
          FILE_NAME=mysql-${mysql56_ver}-linux-glibc2.12-x86_64.tar.gz
        elif [ "${dbinstallmethod}" == '2' ]; then
          echo "Download MySQL 5.6 source package..."
          FILE_NAME=mysql-${mysql56_ver}.tar.gz
        fi
        # start download
        src_url=${DOWN_ADDR_MYSQL}/${FILE_NAME} && Download_src
        src_url=${DOWN_ADDR_MYSQL}/${FILE_NAME}.md5 && Download_src
        # verifying download
        MYSQL_TAR_MD5=$(awk '{print $1}' ${FILE_NAME}.md5)
        [ -z "${MYSQL_TAR_MD5}" ] && MYSQL_TAR_MD5=$(curl -s ${DOWN_ADDR_MYSQL_BK}/${FILE_NAME}.md5 | grep ${FILE_NAME} | awk '{print $1}')
        tryDlCount=0
        while [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" != "${MYSQL_TAR_MD5}" ]; do
          wget -c --no-check-certificate ${DOWN_ADDR_MYSQL_BK}/${FILE_NAME};sleep 1
          let "tryDlCount++"
          [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" == "${MYSQL_TAR_MD5}" -o "${tryDlCount}" == '6' ] && break || continue
        done
        if [ "${tryDlCount}" == '6' ]; then
          echo "${CFAILURE}${FILE_NAME} download failed, Please contact the author! ${CEND}"
          kill -9 $$; exit 1;
        fi
        ;;
      4)
        # MySQL 5.5
        if [ "${OUTIP_STATE}"x == "China"x ]; then
          DOWN_ADDR_MYSQL=http://mirrors.aliyun.com/mysql/MySQL-5.5
          DOWN_ADDR_MYSQL_BK=http://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-5.5
          DOWN_ADDR_MYSQL_BK2=https://mirrors.aliyun.com/mysql/MySQL-5.5
        else
          DOWN_ADDR_MYSQL=https://cdn.mysql.com/Downloads/MySQL-5.5
          DOWN_ADDR_MYSQL_BK=https://mirrors.dotsrc.org/mysql/Downloads/MySQL-5.5
        fi

        if [ "${dbinstallmethod}" == '1' ]; then
          echo "Download MySQL 5.5 binary package..."
          FILE_NAME=mysql-${mysql55_ver}-linux-glibc2.12-x86_64.tar.gz
        elif [ "${dbinstallmethod}" == '2' ]; then
          echo "Download MySQL 5.5 source package..."
          FILE_NAME=mysql-${mysql55_ver}.tar.gz
          src_url=${mirror_link}/oneinstack/src/mysql-5.5-fix-arm-client_plugin.patch && Download_src
        fi
        # start download
        src_url=${DOWN_ADDR_MYSQL}/${FILE_NAME} && Download_src
        src_url=${DOWN_ADDR_MYSQL}/${FILE_NAME}.md5 && Download_src
        # verifying download
        MYSQL_TAR_MD5=$(awk '{print $1}' ${FILE_NAME}.md5)
        [ -z "${MYSQL_TAR_MD5}" ] && MYSQL_TAR_MD5=$(curl -s ${DOWN_ADDR_MYSQL_BK}/${FILE_NAME}.md5 | grep ${FILE_NAME} | awk '{print $1}')
        tryDlCount=0
        while [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" != "${MYSQL_TAR_MD5}" ]; do
          wget -c --no-check-certificate ${DOWN_ADDR_MYSQL_BK}/${FILE_NAME};sleep 1
          let "tryDlCount++"
          [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" == "${MYSQL_TAR_MD5}" -o "${tryDlCount}" == '6' ] && break || continue
        done
        if [ "${tryDlCount}" == '6' ]; then
          echo "${CFAILURE}${FILE_NAME} download failed, Please contact the author! ${CEND}"
          kill -9 $$; exit 1;
        fi
        ;;
      [5-8])
	case "${db_option}" in
          5)
            mariadb_ver=${mariadb1011_ver}
	    ;;
          6)
            mariadb_ver=${mariadb105_ver}
	    ;;
          7)
            mariadb_ver=${mariadb104_ver}
	    ;;
          8)
            mariadb_ver=${mariadb55_ver}
	    ;;
        esac

        if [ "${dbinstallmethod}" == '1' ]; then
          FILE_NAME=mariadb-${mariadb_ver}-linux-systemd-x86_64.tar.gz
	  FILE_TYPE=bintar-linux-systemd-x86_64
        elif [ "${dbinstallmethod}" == '2' ]; then
          FILE_NAME=mariadb-${mariadb_ver}.tar.gz
	  FILE_TYPE=source
        fi

        if [ "${OUTIP_STATE}"x == "China"x ]; then
          DOWN_ADDR_MARIADB=${mirror_link}/oneinstack/src/mariadb/mariadb-${mariadb_ver}/${FILE_TYPE}
        else
          DOWN_ADDR_MARIADB=${mirror_link}/oneinstack/src/mariadb/mariadb-${mariadb_ver}/${FILE_TYPE}
          DOWN_ADDR_MARIADB_BK=${mirror_link}/oneinstack/src/mariadb/mariadb-${mariadb_ver}/${FILE_TYPE}
        fi

        if [ "${db_option}" == '8' ]; then
          DOWN_ADDR_MARIADB=https://archive.mariadb.org/mariadb-${mariadb_ver}/${FILE_TYPE}
          DOWN_ADDR_MARIADB_BK=${DOWN_ADDR_MARIADB}
        fi

        echo "Download MariaDB ${FILE_NAME} package..."
        src_url=${DOWN_ADDR_MARIADB}/${FILE_NAME} && Download_src
        wget --tries=6 -c --no-check-certificate ${DOWN_ADDR_MARIADB}/md5sums.txt -O ${FILE_NAME}.md5
        MARAIDB_TAR_MD5=$(awk '{print $1}' ${FILE_NAME}.md5)
        [ -z "${MARAIDB_TAR_MD5}" ] && MARAIDB_TAR_MD5=$(curl -s ${DOWN_ADDR_MARIADB_BK}/md5sums.txt | grep ${FILE_NAME} | awk '{print $1}')
        tryDlCount=0
        while [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" != "${MARAIDB_TAR_MD5}" ]; do
          wget -c --no-check-certificate ${DOWN_ADDR_MARIADB_BK}/${FILE_NAME};sleep 1
          let "tryDlCount++"
          [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" == "${MARAIDB_TAR_MD5}" -o "${tryDlCount}" == '6' ] && break || continue
        done
        if [ "${tryDlCount}" == '6' ]; then
          echo "${CFAILURE}${FILE_NAME} download failed, Please contact the author! ${CEND}"
          kill -9 $$; exit 1;
        fi
        ;;
      9)
        # Percona 8.0
        if [ "${dbinstallmethod}" == '1' ]; then
          echo "Download Percona 8.0 binary package..."
          FILE_NAME=Percona-Server-${percona80_ver}-Linux.x86_64.glibc2.28.tar.gz
          DOWN_ADDR_PERCONA=https://downloads.percona.com/downloads/Percona-Server-8.0/Percona-Server-${percona80_ver}/binary/tarball
        elif [ "${dbinstallmethod}" == '2' ]; then
          echo "Download Percona 8.0 source package..."
          FILE_NAME=percona-server-${percona80_ver}.tar.gz
          if [ "${OUTIP_STATE}"x == "China"x ]; then
            DOWN_ADDR_PERCONA=${mirror_link}/oneinstack/src
          else
            DOWN_ADDR_PERCONA=https://downloads.percona.com/downloads/Percona-Server-8.0/Percona-Server-${percona80_ver}/source/tarball
          fi
        fi
        # start download
        src_url=${DOWN_ADDR_PERCONA}/${FILE_NAME} && Download_src
        src_url=${mirror_link}/oneinstack/src/${FILE_NAME}.md5sum && Download_src
        # verifying download
        PERCONA_TAR_MD5=$(awk '{print $1}' ${FILE_NAME}.md5sum)
        [ -z "${PERCONA_TAR_MD5}" ] && PERCONA_TAR_MD5=$(curl -s ${mirror_link}/oneinstack/src/${FILE_NAME}.md5sum | grep ${FILE_NAME} | awk '{print $1}')
        tryDlCount=0
        while [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" != "${PERCONA_TAR_MD5}" ]; do
          wget -c --no-check-certificate ${DOWN_ADDR_PERCONA}/${FILE_NAME}; sleep 1
          let "tryDlCount++"
          [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" == "${PERCONA_TAR_MD5}" -o "${tryDlCount}" == '6' ] && break || continue
        done
        if [ "${tryDlCount}" == '6' ]; then
          echo "${CFAILURE}${FILE_NAME} download failed, Please contact the author! ${CEND}"
          kill -9 $$; exit 1;
        fi
        ;;
      10)
        # Precona 5.7
        if [ "${dbinstallmethod}" == '1' ]; then
          echo "Download Percona 5.7 binary package..."
          FILE_NAME=Percona-Server-${percona57_ver}-Linux.x86_64.glibc2.17.tar.gz
          DOWN_ADDR_PERCONA=https://downloads.percona.com/downloads/Percona-Server-5.7/Percona-Server-${percona57_ver}/binary/tarball
        elif [ "${dbinstallmethod}" == '2' ]; then
          echo "Download Percona 5.7 source package..."
          FILE_NAME=percona-server-${percona57_ver}.tar.gz
          if [ "${OUTIP_STATE}"x == "China"x ]; then
            DOWN_ADDR_PERCONA=${mirror_link}/oneinstack/src
          else
            DOWN_ADDR_PERCONA=https://downloads.percona.com/downloads/Percona-Server-5.7/Percona-Server-${percona57_ver}/source/tarball
          fi
        fi
        # start download
        src_url=${DOWN_ADDR_PERCONA}/${FILE_NAME} && Download_src
        src_url=${mirror_link}/oneinstack/src/${FILE_NAME}.md5sum && Download_src
        # verifying download
        PERCONA_TAR_MD5=$(awk '{print $1}' ${FILE_NAME}.md5sum)
        [ -z "${PERCONA_TAR_MD5}" ] && PERCONA_TAR_MD5=$(curl -s ${mirror_link}/oneinstack/src/${FILE_NAME}.md5sum | grep ${FILE_NAME} | awk '{print $1}')
        tryDlCount=0
        while [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" != "${PERCONA_TAR_MD5}" ]; do
          wget -c --no-check-certificate ${DOWN_ADDR_PERCONA}/${FILE_NAME}; sleep 1
          let "tryDlCount++"
          [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" == "${PERCONA_TAR_MD5}" -o "${tryDlCount}" == '6' ] && break || continue
        done
        if [ "${tryDlCount}" == '6' ]; then
          echo "${CFAILURE}${FILE_NAME} download failed, Please contact the author! ${CEND}"
          kill -9 $$; exit 1;
        fi
        ;;
      11)
        # Precona 5.6
        if [ "${dbinstallmethod}" == '1' ]; then
          echo "Download Percona 5.6 binary package..."
          perconaVerStr1=$(echo ${percona56_ver} | sed "s@-@-rel@")
          FILE_NAME=Percona-Server-${perconaVerStr1}-Linux.x86_64.${sslLibVer}.tar.gz
          DOWN_ADDR_PERCONA=https://downloads.percona.com/downloads/Percona-Server-5.6/Percona-Server-${percona56_ver}/binary/tarball
        elif [ "${dbinstallmethod}" == '2' ]; then
          echo "Download Percona 5.6 source package..."
          FILE_NAME=percona-server-${percona56_ver}.tar.gz
          if [ "${OUTIP_STATE}"x == "China"x ]; then
            DOWN_ADDR_PERCONA=${mirror_link}/oneinstack/src
          else
            DOWN_ADDR_PERCONA=https://downloads.percona.com/downloads/Percona-Server-5.6/Percona-Server-${percona56_ver}/source/tarball
          fi
        fi
        # start download
        src_url=${DOWN_ADDR_PERCONA}/${FILE_NAME} && Download_src
        src_url=${mirror_link}/oneinstack/src/${FILE_NAME}.md5sum && Download_src
        # verifying download
        PERCONA_TAR_MD5=$(awk '{print $1}' ${FILE_NAME}.md5sum)
        [ -z "${PERCONA_TAR_MD5}" ] && PERCONA_TAR_MD5=$(curl -s ${mirror_link}/oneinstack/src/${FILE_NAME}.md5sum | grep ${FILE_NAME} | awk '{print $1}')
        tryDlCount=0
        while [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" != "${PERCONA_TAR_MD5}" ]; do
          wget -c --no-check-certificate ${DOWN_ADDR_PERCONA}/${FILE_NAME}; sleep 1
          let "tryDlCount++"
          [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" == "${PERCONA_TAR_MD5}" -o "${tryDlCount}" == '6' ] && break || continue
        done
        if [ "${tryDlCount}" == '6' ]; then
          echo "${CFAILURE}${FILE_NAME} download failed, Please contact the author! ${CEND}"
          kill -9 $$; exit 1;
        fi
        ;;
      12)
        # Percona 5.5
        if [ "${dbinstallmethod}" == '1' ]; then
          echo "Download Percona 5.5 binary package..."
          perconaVerStr1=$(echo ${percona55_ver} | sed "s@-@-rel@")
          FILE_NAME=Percona-Server-${perconaVerStr1}-Linux.x86_64.${sslLibVer}.tar.gz
          DOWN_ADDR_PERCONA=https://downloads.percona.com/downloads/Percona-Server-5.5/Percona-Server-${percona55_ver}/binary/tarball
        elif [ "${dbinstallmethod}" == '2' ]; then
          echo "Download Percona 5.5 source package..."
          FILE_NAME=percona-server-${percona55_ver}.tar.gz
          if [ "${OUTIP_STATE}"x == "China"x ]; then
            DOWN_ADDR_PERCONA=${mirror_link}/oneinstack/src
          else
            DOWN_ADDR_PERCONA=https://downloads.percona.com/downloads/Percona-Server-5.5/Percona-Server-${percona55_ver}/source/tarball
          fi
        fi
        # start download
        src_url=${DOWN_ADDR_PERCONA}/${FILE_NAME} && Download_src
        src_url=${mirror_link}/oneinstack/src/${FILE_NAME}.md5sum && Download_src
        # verifying download
        PERCONA_TAR_MD5=$(awk '{print $1}' ${FILE_NAME}.md5sum)
        [ -z "${PERCONA_TAR_MD5}" ] && PERCONA_TAR_MD5=$(curl -s ${mirror_link}/oneinstack/src/${FILE_NAME}.md5sum | grep ${FILE_NAME} | awk '{print $1}')
        tryDlCount=0
        while [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" != "${PERCONA_TAR_MD5}" ]; do
          wget -c --no-check-certificate ${DOWN_ADDR_PERCONA}/${FILE_NAME}; sleep 1
          let "tryDlCount++"
          [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" == "${PERCONA_TAR_MD5}" -o "${tryDlCount}" == '6' ] && break || continue
        done
        if [ "${tryDlCount}" == '6' ]; then
          echo "${CFAILURE}${FILE_NAME} download failed, Please contact the author! ${CEND}"
          kill -9 $$; exit 1;
        fi
        ;;
      13)
        FILE_NAME=postgresql-${pgsql_ver}.tar.gz
        if [ "${OUTIP_STATE}"x == "China"x ]; then
          DOWN_ADDR_PGSQL=https://mirrors.tuna.tsinghua.edu.cn/postgresql/source/v${pgsql_ver}
          DOWN_ADDR_PGSQL_BK=https://mirrors.ustc.edu.cn/postgresql/source/v${pgsql_ver}
        else
          DOWN_ADDR_PGSQL=https://ftp.postgresql.org/pub/source/v${pgsql_ver}
          DOWN_ADDR_PGSQL_BK=https://ftp.heanet.ie/mirrors/postgresql/source/v${pgsql_ver}
        fi
        src_url=${DOWN_ADDR_PGSQL}/${FILE_NAME} && Download_src
        src_url=${DOWN_ADDR_PGSQL}/${FILE_NAME}.md5 && Download_src
        PGSQL_TAR_MD5=$(awk '{print $1}' ${FILE_NAME}.md5)
        [ -z "${PGSQL_TAR_MD5}" ] && PGSQL_TAR_MD5=$(curl -s ${DOWN_ADDR_PGSQL_BK}/${FILE_NAME}.md5 | grep ${FILE_NAME} | awk '{print $1}')
        tryDlCount=0
        while [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" != "${PGSQL_TAR_MD5}" ]; do
          wget -c --no-check-certificate ${DOWN_ADDR_PGSQL_BK}/${FILE_NAME};sleep 1
          let "tryDlCount++"
          [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" == "${PGSQL_TAR_MD5}" -o "${tryDlCount}" == '6' ] && break || continue
        done
        if [ "${tryDlCount}" == '6' ]; then
          echo "${CFAILURE}${FILE_NAME} download failed, Please contact the author! ${CEND}"
          kill -9 $$; exit 1;
        fi
        ;;
      14)
        # MongoDB
        echo "Download MongoDB binary package..."
        FILE_NAME=mongodb-linux-x86_64-${mongodb_ver}.tgz
        if [ "${OUTIP_STATE}"x == "China"x ]; then
          DOWN_ADDR_MongoDB=${mirror_link}/oneinstack/src
        else
          DOWN_ADDR_MongoDB=https://fastdl.mongodb.org/linux
        fi
        src_url=${DOWN_ADDR_MongoDB}/${FILE_NAME} && Download_src
        src_url=${DOWN_ADDR_MongoDB}/${FILE_NAME}.md5 && Download_src
        MongoDB_TAR_MD5=$(awk '{print $1}' ${FILE_NAME}.md5)
        [ -z "${MongoDB_TAR_MD5}" ] && MongoDB_TAR_MD5=$(curl -s ${DOWN_ADDR_MongoDB}/${FILE_NAME}.md5 | grep ${FILE_NAME} | awk '{print $1}')
        tryDlCount=0
        while [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" != "${MongoDB_TAR_MD5}" ]; do
          wget -c --no-check-certificate ${DOWN_ADDR_MongoDB}/${FILE_NAME};sleep 1
          let "tryDlCount++"
          [ "$(md5sum ${FILE_NAME} | awk '{print $1}')" == "${MongoDB_TAR_MD5}" -o "${tryDlCount}" == '6' ] && break || continue
        done
        if [ "${tryDlCount}" == '6' ]; then
          echo "${CFAILURE}${FILE_NAME} download failed, Please contact the author! ${CEND}"
          kill -9 $$; exit 1;
        fi
        ;;
    esac
  fi


  # Zend Guard Loader
  if [ "${pecl_zendguardloader}" == '1' -a "${armplatform}" != 'y' ]; then
    case "${php_option}" in
      4)
        echo "Download zend loader for php 5.6..."
        src_url=${mirror_link}/oneinstack/src/zend-loader-php5.6-linux-x86_64.tar.gz && Download_src
        ;;
      3)
        echo "Download zend loader for php 5.5..."
        src_url=${mirror_link}/oneinstack/src/zend-loader-php5.5-linux-x86_64.tar.gz && Download_src
        ;;
      2)
        echo "Download zend loader for php 5.4..."
        src_url=${mirror_link}/oneinstack/src/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-x86_64.tar.gz && Download_src
        ;;
      1)
        echo "Download zend loader for php 5.3..."
        src_url=${mirror_link}/oneinstack/src/ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz && Download_src
        ;;
    esac
  fi

  # ioncube
  if [ "${pecl_ioncube}" == '1' ]; then
    echo "Download ioncube..."
    src_url=https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_${SYS_ARCH_i}.tar.gz && Download_src
  fi

  # SourceGuardian
  if [ "${pecl_sourceguardian}" == '1' ]; then
    echo "Download SourceGuardian..."
    src_url=${mirror_link}/oneinstack/src/loaders.linux-${ARCH}.tar.gz && Download_src
  fi

  # imageMagick
  if [ "${pecl_imagick}" == '1' ]; then
    echo "Download ImageMagick..."
    src_url=${mirror_link}/oneinstack/src/ImageMagick-${imagemagick_ver}.tar.gz && Download_src
    echo "Download imagick..."
    if [[ "${php_option}" =~ ^1$ ]]; then
      src_url=https://pecl.php.net/get/imagick-${imagick_oldver}.tgz && Download_src
    else
      src_url=https://pecl.php.net/get/imagick-${imagick_ver}.tgz && Download_src
    fi
  fi

  # graphicsmagick
  if [ "${pecl_gmagick}" == '1' ]; then
    echo "Download graphicsmagick..."
    src_url=https://downloads.sourceforge.net/project/graphicsmagick/graphicsmagick/${graphicsmagick_ver}/GraphicsMagick-${graphicsmagick_ver}.tar.gz && Download_src
    if [[ "${php_option}" =~ ^[1-4]$ ]]; then
      echo "Download gmagick for php..."
      src_url=https://pecl.php.net/get/gmagick-${gmagick_oldver}.tgz && Download_src
    else
      echo "Download gmagick for php 7.x..."
      src_url=https://pecl.php.net/get/gmagick-${gmagick_ver}.tgz && Download_src
    fi
  fi

  # redis-server
  if [ "${redis_flag}" == 'y' ]; then
    echo "Download redis-server..."
    src_url=http://download.redis.io/releases/redis-${redis_ver}.tar.gz && Download_src
  fi

  # pecl_redis
  if [ "${pecl_redis}" == '1' ]; then
    if [[ "${php_option}" =~ ^[1-4]$ ]]; then
      echo "Download pecl_redis for php 5.x..."
      src_url=https://pecl.php.net/get/redis-4.3.0.tgz && Download_src
    elif [[ "${php_option}" =~ ^[5-6]$ ]]; then
      echo "Download pecl_redis for php 7.0~7.1..."
      src_url=https://pecl.php.net/get/redis-5.3.7.tgz && Download_src
    else
      echo "Download pecl_redis for php 7.2+..."
      src_url=https://pecl.php.net/get/redis-${pecl_redis_ver}.tgz && Download_src
    fi
  fi

  # memcached-server
  if [ "${memcached_flag}" == 'y' ]; then
    echo "Download memcached-server..."
    [ "${OUTIP_STATE}"x == "China"x ] && DOWN_ADDR=${mirror_link}/oneinstack/src || DOWN_ADDR=http://www.memcached.org/files
    src_url=${DOWN_ADDR}/memcached-${memcached_ver}.tar.gz && Download_src
  fi

  # pecl_memcached
  if [ "${pecl_memcached}" == '1' ]; then
    echo "Download libmemcached..."
    src_url=${mirror_link}/oneinstack/src/libmemcached-${libmemcached_ver}.tar.gz && Download_src
    if [[ "${php_option}" =~ ^[1-4]$ ]]; then
      echo "Download pecl_memcached for php..."
      src_url=https://pecl.php.net/get/memcached-${pecl_memcached_oldver}.tgz && Download_src
    else
      echo "Download pecl_memcached for php 7.x..."
      src_url=https://pecl.php.net/get/memcached-${pecl_memcached_ver}.tgz && Download_src
    fi
  fi

  # memcached-server pecl_memcached pecl_memcache
  if [ "${pecl_memcache}" == '1' ]; then
    if [[ "${php_option}" =~ ^[1-4]$ ]]; then
      echo "Download pecl_memcache for php 5.x..."
      src_url=https://pecl.php.net/get/memcache-3.0.8.tgz && Download_src
    elif [[ "${php_option}" =~ ^[5-9]$ ]]; then
      echo "Download pecl_memcache for php 7.x..."
      src_url=https://pecl.php.net/get/memcache-${pecl_memcache_oldver}.tgz && Download_src
    else
      echo "Download pecl_memcache for php 8.x..."
      src_url=https://pecl.php.net/get/memcache-${pecl_memcache_ver}.tgz && Download_src
    fi
  fi

  # pecl_mongodb
  if [ "${pecl_mongodb}" == '1' ]; then
    echo "Download pecl mongo for php..."
    src_url=https://pecl.php.net/get/mongo-${pecl_mongo_ver}.tgz && Download_src
    echo "Download pecl mongodb for php..."
    src_url=https://pecl.php.net/get/mongodb-${pecl_mongodb_ver}.tgz && Download_src
  fi

  # nodejs
  if [ "${nodejs_flag}" == 'y' ]; then
    echo "Download Nodejs..."
    [ "${OUTIP_STATE}"x == "China"x ] && DOWN_ADDR_NODE=https://mirrors.tuna.tsinghua.edu.cn/nodejs-release || DOWN_ADDR_NODE=https://nodejs.org/dist
    src_url=${DOWN_ADDR_NODE}/v${nodejs_ver}/node-v${nodejs_ver}-linux-${SYS_ARCH_n}.tar.gz && Download_src
  fi

  # pureftpd
  if [ "${pureftpd_flag}" == 'y' ]; then
    echo "Download pureftpd..."
    src_url=https://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-${pureftpd_ver}.tar.gz && Download_src
  fi

  # phpMyAdmin
  if [ "${phpmyadmin_flag}" == 'y' ]; then
    echo "Download phpMyAdmin..."
    if [[ "${php_option}" =~ ^[1-5]$ ]] || [[ "${mphp_ver}" =~ ^5[3-6]$|^70$ ]]; then
      src_url=https://files.phpmyadmin.net/phpMyAdmin/${phpmyadmin_oldver}/phpMyAdmin-${phpmyadmin_oldver}-all-languages.tar.gz && Download_src
    else
      src_url=https://files.phpmyadmin.net/phpMyAdmin/${phpmyadmin_ver}/phpMyAdmin-${phpmyadmin_ver}-all-languages.tar.gz && Download_src
    fi
  fi

  popd > /dev/null
}
