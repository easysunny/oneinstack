export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
clear
printf "
#######################################################################
#       OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+      #
#       For more information please visit https://oneinstack.com      #
#######################################################################
"
# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

oneinstack_dir=$(dirname "`readlink -f $0`")
pushd ${oneinstack_dir} > /dev/null
. ./versions.txt
. ./options.conf
. ./include/color.sh
. ./include/check_os.sh
. ./include/check_dir.sh
. ./include/download.sh
. ./include/get_char.sh

dbrootpwd=`< /dev/urandom tr -dc A-Za-z0-9 | head -c8`
dbpostgrespwd=`< /dev/urandom tr -dc A-Za-z0-9 | head -c8`
dbmongopwd=`< /dev/urandom tr -dc A-Za-z0-9 | head -c8`
xcachepwd=`< /dev/urandom tr -dc A-Za-z0-9 | head -c8`
dbinstallmethod=1

version() {
  echo "version: 2.6"
  echo "updated date: 2023-02-04"
}

Show_Help() {
  version
  echo "Usage: $0  command ...[parameters]....
  --help, -h                  Show this help message, More: https://oneinstack.com/auto
  --version, -v               Show version info
  --nginx_option [1-4]        Install Nginx server version

  --nodejs                    Install Nodejs
  --tomcat_option [1-6]       Install Tomcat version
  --jdk_option [1-3]          Install JDK version
  --db_option [1-14]          Install DB version
  --dbinstallmethod [1-2]     DB install method, default: 1 binary install
  --dbrootpwd [password]      DB super password
  --pureftpd                  Install Pure-Ftpd
  --redis                     Install Redis
  --memcached                 Install Memcached
  --docker                    Install Docker
  --ssh_port [No.]            SSH port
  --firewall                  Enable firewall
  --md5sum                    Check md5sum
  --reboot                    Restart the server after installation
  "
}


ARG_NUM=$#
TEMP=`getopt -o hvV --long help,version,nginx_option:,apache,apache_mode_option:,apache_mpm_option:,php_option:,mphp_ver:,mphp_addons,phpcache_option:,php_extensions:,nodejs,tomcat_option:,jdk_option:,db_option:,dbrootpwd:,dbinstallmethod:,pureftpd,redis,memcached,docker,phpmyadmin,ssh_port:,firewall,md5sum,reboot -- "$@" 2>/dev/null`
[ $? != 0 ] && echo "${CWARNING}ERROR: unknown argument! ${CEND}" && Show_Help && exit 1
eval set -- "${TEMP}"
while :; do
  [ -z "$1" ] && break;
  case "$1" in
  -h | --help)
    Show_Help
    exit 0
    ;;
  -v | -V | --version)
    version
    exit 0
    ;;
  --nginx_option)
    nginx_option=$2
    shift 2
    [[ ! ${nginx_option} =~ ^[1-4]$ ]] && {
      echo "${CWARNING}nginx_option input error! Please only input number 1~5${CEND}"
      exit 1
    }
    [ -e "${nginx_install_dir}/sbin/nginx" ] && {
      echo "${CWARNING}Nginx already installed! ${CEND}"
      unset nginx_option
    }
    [ -e "${tengine_install_dir}/sbin/nginx" ] && {
      echo "${CWARNING}Tengine already installed! ${CEND}"
      unset nginx_option
    }
    [ -e "${openresty_install_dir}/nginx/sbin/nginx" ] && {
      echo "${CWARNING}OpenResty already installed! ${CEND}"
      unset nginx_option
    }
    [ -e "${caddy_install_dir}/bin/caddy" ] && {
      echo "${CWARNING}Caddy already installed! ${CEND}"
      unset nginx_option
    }
    ;;
  --nodejs)
    nodejs_flag=y
    shift 1
    [ -e "${nodejs_install_dir}/bin/node" ] && {
      echo "${CWARNING}Nodejs already installed! ${CEND}"
      unset nodejs_flag
    }
    ;;
  --tomcat_option)
    tomcat_option=$2
    shift 2
    [[ ! ${tomcat_option} =~ ^[1-6]$ ]] && {
      echo "${CWARNING}tomcat_option input error! Please only input number 1~6${CEND}"
      exit 1
    }
    [ -e "$tomcat_install_dir/conf/server.xml" ] && {
      echo "${CWARNING}Tomcat already installed! ${CEND}"
      unset tomcat_option
    }
    ;;
  --jdk_option)
    jdk_option=$2
    shift 2
    [[ ! ${jdk_option} =~ ^[1-4]$ ]] && {
      echo "${CWARNING}jdk_option input error! Please only input number 1~4${CEND}"
      exit 1
    }
    ;;
  --db_option)
    db_option=$2
    shift 2
    if [[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]]; then
      [ -d "${db_install_dir}/support-files" ] && {
        echo "${CWARNING}MySQL already installed! ${CEND}"
        unset db_option
      }
    elif [ "${db_option}" == '13' ]; then
      [ -e "${pgsql_install_dir}/bin/psql" ] && {
        echo "${CWARNING}PostgreSQL already installed! ${CEND}"
        unset db_option
      }
    elif [ "${db_option}" == '14' ]; then
      [ -e "${mongo_install_dir}/bin/mongo" ] && {
        echo "${CWARNING}MongoDB already installed! ${CEND}"
        unset db_option
      }
    else
      echo "${CWARNING}db_option input error! Please only input number 1~14${CEND}"
      exit 1
    fi
    ;;
  --dbrootpwd)
    dbrootpwd=$2
    shift 2
    dbpostgrespwd="${dbrootpwd}"
    dbmongopwd="${dbrootpwd}"
    ;;
  --dbinstallmethod)
    dbinstallmethod=$2
    shift 2
    [[ ! ${dbinstallmethod} =~ ^[1-2]$ ]] && {
      echo "${CWARNING}dbinstallmethod input error! Please only input number 1~2${CEND}"
      exit 1
    }
    ;;
  --pureftpd)
    pureftpd_flag=y
    shift 1
    [ -e "${pureftpd_install_dir}/sbin/pure-ftpwho" ] && {
      echo "${CWARNING}Pure-FTPd already installed! ${CEND}"
      unset pureftpd_flag
    }
    ;;
  --redis)
    redis_flag=y
    shift 1
    [ -e "${redis_install_dir}/bin/redis-server" ] && {
      echo "${CWARNING}redis-server already installed! ${CEND}"
      unset redis_flag
    }
    ;;
  --memcached)
    memcached_flag=y
    shift 1
    [ -e "${memcached_install_dir}/bin/memcached" ] && {
      echo "${CWARNING}memcached-server already installed! ${CEND}"
      unset memcached_flag
    }
    ;;
  --docker)
    docker_flag=y
    shift 1
    command -v docker >/dev/null 2>&1 && {
      echo "${CWARNING}Docker already installed! ${CEND}"
      unset docker_flag
    }
    ;;
  --ssh_port)
    ssh_port=$2
    shift 2
    ;;
  --firewall)
    firewall_flag=y
    shift 1
    ;;
    --md5sum)
      md5sum_flag=y; shift 1
	;;
  --reboot)
    reboot_flag=y
    shift 1
    ;;
  --)
    shift
    ;;
  *)
    echo "${CWARNING}ERROR: unknown argument! ${CEND}" && Show_Help && exit 1
    ;;
  esac
done











# Use default SSH port 22. If you use another SSH port on your server
if [ -e "/etc/ssh/sshd_config" ]; then
  [ -z "`grep ^Port /etc/ssh/sshd_config`" ] && now_ssh_port=22 || now_ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}' | head -1`
  while :; do echo
    [ ${ARG_NUM} == 0 ] && read -e -p "Please input SSH port(Default: ${now_ssh_port}): " ssh_port
    ssh_port=${ssh_port:-${now_ssh_port}}
    if [ ${ssh_port} -eq 22 >/dev/null 2>&1 -o ${ssh_port} -gt 1024 >/dev/null 2>&1 -a ${ssh_port} -lt 65535 >/dev/null 2>&1 ]; then
      break
    else
      echo "${CWARNING}input error! Input range: 22,1025~65534${CEND}"
      exit 1
    fi
  done

  if [ -z "`grep ^Port /etc/ssh/sshd_config`" -a "${ssh_port}" != '22' ]; then
    sed -i "s@^#Port.*@&\nPort ${ssh_port}@" /etc/ssh/sshd_config
  elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ]; then
    sed -i "s@^Port.*@Port ${ssh_port}@" /etc/ssh/sshd_config
  fi
fi




if [ ${ARG_NUM} == 0 ]; then
  if [ ! -e ~/.oneinstack ]; then
    # check firewall
    while :; do echo
      read -e -p "Do you want to enable firewall? [y/n]: " firewall_flag
      if [[ ! ${firewall_flag} =~ ^[y,n]$ ]]; then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
      else
        break
      fi
    done
  fi

  # check Web server
  while :; do echo
    read -e -p "Do you want to install Web server? [y/n]: " web_flag
    if [[ ! ${web_flag} =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      if [ "${web_flag}" == 'y' ]; then
        # Nginx/Tegine/OpenResty
        while :; do
          echo
          echo 'Please select Web server type:'
          echo -e "\t${CMSG}1${CEND}. Install Nginx"
          echo -e "\t${CMSG}2${CEND}. Install Tengine"
          echo -e "\t${CMSG}3${CEND}. Install OpenResty"
          echo -e "\t${CMSG}4${CEND}. Install Caddy"
          echo -e "\t${CMSG}5${CEND}. Do not install"
          read -e -p "Please input a number:(Default 1 press Enter) " nginx_option
          nginx_option=${nginx_option:-1}
          if [[ ! ${nginx_option} =~ ^[1-5]$ ]]; then
            echo "${CWARNING}input error! Please only input number 1~5${CEND}"
          else
            [ "${nginx_option}" != '5' -a -e "${nginx_install_dir}/sbin/nginx" ] && {
              echo "${CWARNING}Nginx already installed! ${CEND}"
              unset nginx_option
            }
            [ "${nginx_option}" != '5' -a -e "${tengine_install_dir}/sbin/nginx" ] && {
              echo "${CWARNING}Tengine already installed! ${CEND}"
              unset nginx_option
            }
            [ "${nginx_option}" != '5' -a -e "${openresty_install_dir}/nginx/sbin/nginx" ] && {
              echo "${CWARNING}OpenResty already installed! ${CEND}"
              unset nginx_option
            }
            [ "${nginx_option}" != '5' -a -e "${caddy_install_dir}/bin/caddy" ] && {
              echo "${CWARNING}Caddy already installed! ${CEND}"
              unset nginx_option
            }
            break
          fi
        done
        if [[ ${nginx_option} =~ ^[1-3]$ ]]; then
          # Apache
          while :; do
            echo
            read -e -p "Do you want to install Apache? [y/n]: " apache_flag
            if [[ ! ${apache_flag} =~ ^[y,n]$ ]]; then
              echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
            else
              [ "${apache_flag}" == 'y' -a -e "${apache_install_dir}/bin/httpd" ] && {
                echo "${CWARNING}Aapche already installed! ${CEND}"
                unset apache_flag
              }
              break
            fi
          done
        
          # Tomcat
          while :; do
            echo
            echo 'Please select tomcat server:'
            echo -e "\t${CMSG}1${CEND}. Install Tomcat-11"
            echo -e "\t${CMSG}2${CEND}. Install Tomcat-10"
            echo -e "\t${CMSG}3${CEND}. Install Tomcat-9"
            echo -e "\t${CMSG}4${CEND}. Install Tomcat-8"
            echo -e "\t${CMSG}5${CEND}. Install Tomcat-7"
            echo -e "\t${CMSG}6${CEND}. Install Tomcat-6"
            echo -e "\t${CMSG}7${CEND}. Do not install"
            read -e -p "Please input a number:(Default 7 press Enter) " tomcat_option
            tomcat_option=${tomcat_option:-7}
            if [[ ! ${tomcat_option} =~ ^[1-7]$ ]]; then
              echo "${CWARNING}input error! Please only input number 1~7${CEND}"
            else
              [ "${tomcat_option}" != '7' -a -e "$tomcat_install_dir/conf/server.xml" ] && {
                echo "${CWARNING}Tomcat already installed! ${CEND}"
                unset tomcat_option
              }
              if [[ "${tomcat_option}" =~ ^1$ ]]; then
                while :; do
                  echo
                  echo 'Please select JDK version:'
                  echo -e "\t${CMSG}1${CEND}. Install openjdk-8-jdk"
                  echo -e "\t${CMSG}2${CEND}. Install openjdk-11-jdk"
                  echo -e "\t${CMSG}3${CEND}. Install openjdk-17-jdk"
                  echo -e "\t${CMSG}4${CEND}. Install openjdk-18-jdk"
                  read -e -p "Please input a number:(Default 1 press Enter) " jdk_option
                  jdk_option=${jdk_option:-1}
                  if [[ ! ${jdk_option} =~ ^[1-4]$ ]]; then
                    echo "${CWARNING}input error! Please only input number 1~4${CEND}"
                  else
                    break
                  fi
                done
              elif [[ "${tomcat_option}" =~ ^[2-3]$ ]]; then
                while :; do
                  echo
                  echo 'Please select JDK version:'
                  echo -e "\t${CMSG}1${CEND}. Install openjdk-8-jdk"
                  echo -e "\t${CMSG}2${CEND}. Install openjdk-11-jdk"
                  echo -e "\t${CMSG}3${CEND}. Install openjdk-17-jdk"
                  read -e -p "Please input a number:(Default 1 press Enter) " jdk_option
                  jdk_option=${jdk_option:-1}
                  if [[ ! ${jdk_option} =~ ^[1-3]$ ]]; then
                    echo "${CWARNING}input error! Please only input number 1~3${CEND}"
                  else
                    break
                  fi
                done
              elif [ "${tomcat_option}" == '4' ]; then
                while :; do
                  echo
                  echo 'Please select JDK version:'
                  echo -e "\t${CMSG}1${CEND}. Install openjdk-8-jdk"
                  read -e -p "Please input a number:(Default 1 press Enter) " jdk_option
                  jdk_option=${jdk_option:-1}
                  if [[ ! ${jdk_option} =~ ^1$ ]]; then
                    echo "${CWARNING}input error! Please only input number 1${CEND}"
                  else
                    break
                  fi
                done
              fi
              break
            fi
          done
        elif [ "${nginx_option}" == '4' ]; then
          # Caddy
          while :; do
            echo
            read -e -p "Do you want to install Caddy? [y/n]: " caddy_flag
            if [[ ! ${caddy_flag} =~ ^[y,n]$ ]]; then
              echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
            else
              [ "${caddy_flag}" == 'y' -a -e "${caddy_install_dir}/bin/caddy" ] && {
                echo "${CWARNING}Caddy already installed! ${CEND}"
                unset caddy_flag
              }
              break
            fi
          done
        fi
      fi
      break
    fi
  done

  # choice database
  while :; do
    echo
    read -e -p "Do you want to install Database? [y/n]: " db_flag
    if [[ ! ${db_flag} =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      if [ "${db_flag}" == 'y' ]; then
        while :; do
          echo
          echo 'Please select a version of the Database:'
          echo -e "\t${CMSG} 0${CEND}. Install MySQL-8.2"
          echo -e "\t${CMSG} 1${CEND}. Install MySQL-8.0"
          echo -e "\t${CMSG} 2${CEND}. Install MySQL-5.7"
          echo -e "\t${CMSG} 3${CEND}. Install MySQL-5.6"
          echo -e "\t${CMSG} 4${CEND}. Install MySQL-5.5"
          echo -e "\t${CMSG} 5${CEND}. Install MariaDB-10.11"
          echo -e "\t${CMSG} 6${CEND}. Install MariaDB-10.5"
          echo -e "\t${CMSG} 7${CEND}. Install MariaDB-10.4"
          echo -e "\t${CMSG} 8${CEND}. Install MariaDB-5.5"
          echo -e "\t${CMSG} 9${CEND}. Install Percona-8.0"
          echo -e "\t${CMSG}10${CEND}. Install Percona-5.7"
          echo -e "\t${CMSG}11${CEND}. Install Percona-5.6"
          echo -e "\t${CMSG}12${CEND}. Install Percona-5.5"
          echo -e "\t${CMSG}13${CEND}. Install PostgreSQL"
          echo -e "\t${CMSG}14${CEND}. Install MongoDB"
          read -e -p "Please input a number:(Default 2 press Enter) " db_option
          db_option=${db_option:-2}
          if [[ "${db_option}" =~ ^[0-9]$|^1[0-4]$ ]]; then
            if [ "${db_option}" == '13' ]; then
              [ -e "${pgsql_install_dir}/bin/psql" ] && { echo "${CWARNING}PostgreSQL already installed! ${CEND}"; unset db_option; break; }
            elif [ "${db_option}" == '14' ]; then
              [ -e "${mongo_install_dir}/bin/mongo" ] && { echo "${CWARNING}MongoDB already installed! ${CEND}"; unset db_option; break; }
            else
              [ -d "${db_install_dir}/support-files" ] && { echo "${CWARNING}MySQL already installed! ${CEND}"; unset db_option; break; }
            fi
            while :; do
              if [ "${db_option}" == '13' ]; then
                read -e -p "Please input the postgres password of PostgreSQL(default: ${dbpostgrespwd}): " dbpwd
                dbpwd=${dbpwd:-${dbpostgrespwd}}
              elif [ "${db_option}" == '14' ]; then
                read -e -p "Please input the root password of MongoDB(default: ${dbmongopwd}): " dbpwd
                dbpwd=${dbpwd:-${dbmongopwd}}
              else
                read -e -p "Please input the root password of MySQL(default: ${dbrootpwd}): " dbpwd
                dbpwd=${dbpwd:-${dbrootpwd}}
              fi
              [ -n "`echo ${dbpwd} | grep '[+|&]'`" ] && { echo "${CWARNING}input error,not contain a plus sign (+) and & ${CEND}"; continue; }
              if (( ${#dbpwd} >= 5 )); then
                if [ "${db_option}" == '13' ]; then
                  dbpostgrespwd=${dbpwd}
                elif [ "${db_option}" == '14' ]; then
                  dbmongopwd=${dbpwd}
                else
                  dbrootpwd=${dbpwd}
                fi
                break
              else
                echo "${CWARNING}password least 5 characters! ${CEND}"
              fi
            done
            # choose install methods
            if [[ "${db_option}" =~ ^[0-9]$|^1[0-4]$ ]]; then
              while :; do echo
                echo "Please choose installation of the database:"
                echo -e "\t${CMSG}1${CEND}. Install database from binary package."
                echo -e "\t${CMSG}2${CEND}. Install database from source package."
                read -e -p "Please input a number:(Default 1 press Enter) " dbinstallmethod
                dbinstallmethod=${dbinstallmethod:-1}
                if [[ ! ${dbinstallmethod} =~ ^[1-2]$ ]]; then
                  echo "${CWARNING}input error! Please only input number 1~2${CEND}"
                else
                  break
                fi
              done
            fi
            break
          else
            echo "${CWARNING}input error! Please only input number 1~14${CEND}"
          fi
        done
      fi
      break
    fi
  done

 

  # check Nodejs
  while :; do echo
    read -e -p "Do you want to install Nodejs? [y/n]: " nodejs_flag
    if [[ ! ${nodejs_flag} =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      [ "${nodejs_flag}" == 'y' -a -e "${nodejs_install_dir}/bin/node" ] && { echo "${CWARNING}Nodejs already installed! ${CEND}"; unset nodejs_flag; }
      break
    fi
  done

  # check Pureftpd
  while :; do echo
    read -e -p "Do you want to install Pure-FTPd? [y/n]: " pureftpd_flag
    if [[ ! ${pureftpd_flag} =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      [ "${pureftpd_flag}" == 'y' -a -e "${pureftpd_install_dir}/sbin/pure-ftpwho" ] && { echo "${CWARNING}Pure-FTPd already installed! ${CEND}"; unset pureftpd_flag; }
      break
    fi
  done


  # check redis
  while :; do echo
    read -e -p "Do you want to install redis-server? [y/n]: " redis_flag
    if [[ ! ${redis_flag} =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      [ "${redis_flag}" == 'y' -a -e "${redis_install_dir}/bin/redis-server" ] && { echo "${CWARNING}redis-server already installed! ${CEND}"; unset redis_flag; }
      break
    fi
  done

  # check memcached
  while :; do echo
    read -e -p "Do you want to install memcached-server? [y/n]: " memcached_flag
    if [[ ! ${memcached_flag} =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      [ "${memcached_flag}" == 'y' -a -e "${memcached_install_dir}/bin/memcached" ] && { echo "${CWARNING}memcached-server already installed! ${CEND}"; unset memcached_flag; }
      break
    fi
  done

  # check Docker
  while :; do echo
    read -e -p "Do you want to install Docker? [y/n]: " docker_flag
    if [[ ! ${docker_flag} =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      [ "${docker_flag}" == 'y' ] && command -v docker >/dev/null 2>&1 && { echo "${CWARNING}Docker already installed! ${CEND}"; unset docker_flag; }
      break
    fi
  done
fi





if [[ ${nginx_option} =~ ^[1-4]$ ]] || [ "${apache_flag}" == 'y' ] || [ "${caddy_flag}" == 'y' ] || [[ ${tomcat_option} =~ ^[1-6]$ ]]; then
  [ ! -d ${wwwroot_dir}/default ] && mkdir -p ${wwwroot_dir}/default
  [ ! -d ${wwwlogs_dir} ] && mkdir -p ${wwwlogs_dir}
fi
[ -d /data ] && chmod 755 /data


# install wget gcc curl
if [ ! -e ~/.oneinstack ]; then
  downloadDepsSrc=1
  [ "${PM}" == 'apt-get' ] && apt-get -y update > /dev/null
  [ "${PM}" == 'yum' ] && yum clean all > /dev/null
  ${PM} -y install wget gcc curl > /dev/null
fi

. ./include/get_internal_ip.sh
# get the IP information
IPADDR=$(get_ip)
OUTIP_STATE=$(get_country)


# openSSL
. ./include/openssl.sh

# Check download source packages
. ./include/check_download.sh


[ "${armplatform}" == "y" ] && dbinstallmethod=2
checkDownload 2>&1 | tee -a ${oneinstack_dir}/install.log

# get OS Memory
. ./include/memory.sh




if [ ! -e ~/.oneinstack ]; then
  # Check binary dependencies packages
  . ./include/check_sw.sh
  case "${Family}" in
    "rhel")
      installDepsRHEL 2>&1 | tee ${oneinstack_dir}/install.log
      . include/init_RHEL.sh 2>&1 | tee -a ${oneinstack_dir}/install.log
      ;;
    "debian")
      installDepsDebian 2>&1 | tee ${oneinstack_dir}/install.log
      . include/init_Debian.sh 2>&1 | tee -a ${oneinstack_dir}/install.log
      ;;
    "ubuntu")
      installDepsUbuntu 2>&1 | tee ${oneinstack_dir}/install.log
      . include/init_Ubuntu.sh 2>&1 | tee -a ${oneinstack_dir}/install.log
      ;;
  esac
  # Install dependencies from source package
  installDepsBySrc 2>&1 | tee -a ${oneinstack_dir}/install.log
fi



# start Time
startTime=`date +%s`

# openSSL
Install_openSSL | tee -a ${oneinstack_dir}/install.log

# Jemalloc
if [[ ${nginx_option} =~ ^[1-3]$ ]] || [[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]]; then
  . include/jemalloc.sh
  Install_Jemalloc | tee -a ${oneinstack_dir}/install.log
fi


# Database
case "${db_option}" in
  0)
    . include/mysql-8.2.sh
    Install_MySQL82 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  1)
    . include/mysql-8.0.sh
    Install_MySQL80 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  2)
    . include/mysql-5.7.sh
    Install_MySQL57 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  3)
    . include/mysql-5.6.sh
    Install_MySQL56 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  4)
    . include/mysql-5.5.sh
    Install_MySQL55 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  5)
    . include/mariadb-10.11.sh
    Install_MariaDB1011 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  6)
    . include/mariadb-10.5.sh
    Install_MariaDB105 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  7)
    . include/mariadb-10.4.sh
    Install_MariaDB104 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  8)
    . include/mariadb-5.5.sh
    Install_MariaDB55 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  9)
    [ "${Family}" == 'rhel' ] && [ "${RHEL_ver}" == '8' ] && dbinstallmethod=2 && checkDownload
    . include/percona-8.0.sh
    Install_Percona80 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  10)
    . include/percona-5.7.sh
    Install_Percona57 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  11)
    . include/percona-5.6.sh
    Install_Percona56 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  12)
    . include/percona-5.5.sh
    Install_Percona55 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  13)
    . include/postgresql.sh
    Install_PostgreSQL 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  14)
    . include/mongodb.sh
    Install_MongoDB 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
esac


# Nginx server
case "${nginx_option}" in
1)
  . include/nginx.sh
  Install_Nginx 2>&1 | tee -a ${oneinstack_dir}/install.log
  ;;
2)
  . include/tengine.sh
  Install_Tengine 2>&1 | tee -a ${oneinstack_dir}/install.log
  ;;
3)
  . include/openresty.sh
  Install_OpenResty 2>&1 | tee -a ${oneinstack_dir}/install.log
  ;;
4)
  . include/caddy.sh
  Install_Caddy 2>&1 | tee -a ${oneinstack_dir}/install.log
  caddy_flag='y'
  ;;
esac



# JDK
case "${jdk_option}" in
  1)
    . include/openjdk-8.sh
    Install_OpenJDK8 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  2)
    . include/openjdk-11.sh
    Install_OpenJDK11 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  3)
    . include/openjdk-17.sh
    Install_OpenJDK17 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  4)
    . include/openjdk-18.sh
    Install_OpenJDK18 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
esac

case "${tomcat_option}" in
  1)
    . include/tomcat-11.sh
    Install_Tomcat11 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  2)
    . include/tomcat-10.sh
    Install_Tomcat10 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  3)
    . include/tomcat-9.sh
    Install_Tomcat9 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  4)
    . include/tomcat-8.sh
    Install_Tomcat8 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  5)
    . include/tomcat-7.sh
    Install_Tomcat7 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
  6)
    . include/tomcat-6.sh
    Install_Tomcat6 2>&1 | tee -a ${oneinstack_dir}/install.log
    ;;
esac

# Nodejs
if [ "${nodejs_flag}" == 'y' ]; then
  . include/nodejs.sh
  Install_Nodejs 2>&1 | tee -a ${oneinstack_dir}/install.log
fi

# Pure-FTPd
if [ "${pureftpd_flag}" == 'y' ]; then
  . include/pureftpd.sh
  Install_PureFTPd 2>&1 | tee -a ${oneinstack_dir}/install.log
fi



# redis
if [ "${redis_flag}" == 'y' ]; then
  . include/redis.sh
  Install_redis_server 2>&1 | tee -a ${oneinstack_dir}/install.log
fi

# memcached
if [ "${memcached_flag}" == 'y' ]; then
  . include/memcached.sh
  Install_memcached_server 2>&1 | tee -a ${oneinstack_dir}/install.log
fi

# Docker
if [ "${docker_flag}" == 'y' ]; then
  . include/docker.sh
  Install_Docker 2>&1 | tee -a ${oneinstack_dir}/install.log
fi


# get web_install_dir and db_install_dir
. include/check_dir.sh



# Starting DB
[ -d "/etc/mysql" ] && /bin/mv /etc/mysql{,_bk}
[ -d "${db_install_dir}/support-files" ] && [ -z "`ps -ef | grep mysqld_safe | grep -v grep`" ] && service mysqld start



endTime=`date +%s`
((installTime=($endTime-$startTime)/60))
echo "####################Congratulations########################"
echo "Total OneinStack Install Time: ${CQUESTION}${installTime}${CEND} minutes"
[[ "${nginx_option}" =~ ^[1-3]$ ]] && echo -e "\n$(printf "%-32s" "Nginx install dir":)${CMSG}${web_install_dir}${CEND}"
[ "${caddy_flag}" == 'y' ] && echo -e "\n$(printf "%-32s" "Caddy install dir":)${CMSG}${caddy_install_dir}${CEND}"
[[ "${tomcat_option}" =~ ^[1-6]$ ]] && echo -e "\n$(printf "%-32s" "Tomcat install dir":)${CMSG}${tomcat_install_dir}${CEND}"
[[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]] && echo -e "\n$(printf "%-32s" "Database install dir:")${CMSG}${db_install_dir}${CEND}"
[[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]] && echo "$(printf "%-32s" "Database data dir:")${CMSG}${db_data_dir}${CEND}"
[[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]] && echo "$(printf "%-32s" "Database user:")${CMSG}root${CEND}"
[[ "${db_option}" =~ ^[1-9]$|^1[0-2]$ ]] && echo "$(printf "%-32s" "Database password:")${CMSG}${dbrootpwd}${CEND}"
[ "${db_option}" == '13' ] && echo -e "\n$(printf "%-32s" "PostgreSQL install dir:")${CMSG}${pgsql_install_dir}${CEND}"
[ "${db_option}" == '13' ] && echo "$(printf "%-32s" "PostgreSQL data dir:")${CMSG}${pgsql_data_dir}${CEND}"
[ "${db_option}" == '13' ] && echo "$(printf "%-32s" "PostgreSQL user:")${CMSG}postgres${CEND}"
[ "${db_option}" == '13' ] && echo "$(printf "%-32s" "postgres password:")${CMSG}${dbpostgrespwd}${CEND}"
[ "${db_option}" == '14' ] && echo -e "\n$(printf "%-32s" "MongoDB install dir:")${CMSG}${mongo_install_dir}${CEND}"
[ "${db_option}" == '14' ] && echo "$(printf "%-32s" "MongoDB data dir:")${CMSG}${mongo_data_dir}${CEND}"
[ "${db_option}" == '14' ] && echo "$(printf "%-32s" "MongoDB user:")${CMSG}root${CEND}"
[ "${db_option}" == '14' ] && echo "$(printf "%-32s" "MongoDB password:")${CMSG}${dbmongopwd}${CEND}"
[ "${pureftpd_flag}" == 'y' ] && echo -e "\n$(printf "%-32s" "Pure-FTPd install dir:")${CMSG}${pureftpd_install_dir}${CEND}"
[ "${pureftpd_flag}" == 'y' ] && echo "$(printf "%-32s" "Create FTP virtual script:")${CMSG}./pureftpd_vhost.sh${CEND}"
[ "${redis_flag}" == 'y' ] && echo -e "\n$(printf "%-32s" "redis install dir:")${CMSG}${redis_install_dir}${CEND}"
[ "${memcached_flag}" == 'y' ] && echo -e "\n$(printf "%-32s" "memcached install dir:")${CMSG}${memcached_install_dir}${CEND}"
[ "${docker_flag}" == 'y' ] && echo -e "\n$(printf "%-32s" "Docker version:")${CMSG}$(docker --version 2>/dev/null | awk '{print $3}' | sed 's/,//')${CEND}"
if [[ ${nginx_option} =~ ^[1-4]$ ]] || [ "${apache_flag}" == 'y' ] || [[ ${tomcat_option} =~ ^[1-6]$ ]]; then
  echo -e "\n$(printf "%-32s" "Index URL:")${CMSG}http://${IPADDR}/${CEND}"
fi
if [ ${ARG_NUM} == 0 ]; then
  while :; do echo
    echo "${CMSG}Please restart the server and see if the services start up fine.${CEND}"
    read -e -p "Do you want to restart OS ? [y/n]: " reboot_flag
    if [[ ! "${reboot_flag}" =~ ^[y,n]$ ]]; then
      echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
      break
    fi
  done
fi
[ "${reboot_flag}" == 'y' ] && reboot
