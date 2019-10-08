dateStr=`date +%Y%m%d`
loggerFile='install_'${dateStr}'.log'
libDir='lib/'
logDir='log/'
currentPath=$(cd `dirname $0`; pwd)

# 如果日志目录不存在则创建
if [ ! -d "$logDir" ];then
    mkdir $logDir
fi

function logger(){
   echo `date`"..."$1 >>${logDir}$loggerFile
}

function installRpm(){
    rpmPackage=$1
    forceOption=$2
    logger "rpm -ivh $rpmPackage"
    if [ -z $forceOption ];then
        rpm -ivh $rpmPackage >>${logDir}$loggerFile
    else
        rpm -ivh $rpmPackage --force --nodeps >>${logDir}$loggerFile
    fi       
}

# 挂载cgroup目录
function mountCgroup(){
    logger "挂载cgroup目录"
    mount -l|grep cgroup
    if [ $? -ne 0 ];then
        echo "none        /cgroup        cgroup        defaults    0    0" >>/etc/fstab
        mount -a  #使挂载生效
    fi    
}


function checkCgconfig(){
    logger "检查cgconfig服务是否启动"
    re=`/etc/init.d/cgconfig status`
    if [ $? -ne 0 ];then
        logger "/etc/init.d/cgconfig restart"
        /etc/init.d/cgconfig restart
    fi
    logger "chkconfig cgconfig on"
    chkconfig cgconfig on
    logger "restart docker"
    service docker restart
}

logger "====================docker-install=========================="
echo '开始安装...'
echo '安装日志见：'${logDir}${loggerFile}
# 检查docker是否已经安装
logger "检查docker是否已经安装"
type docker
if [ $? -ne 0 ];then
    logger "未检测到docker命令，继续安装"
else
    logger "检测到docker命令，无需另外安装，结束安装程序"
    exit 0
fi
device_mapper_files= `ls ${currentPath}/lib/device-mapper-libs|grep device-mapper`
for device_mapper_file in $device_mapper_files ;do
    installRpm ${currentPath}/lib/device-mapper-libs/${device_mapper_file} force
done
installRpm  ${currentPath}/lib/lxc-libs-1.0.10-2.el6.x86_64.rpm
installRpm  ${currentPath}/lib/lua-alt-getopt-0.7.0-1.el6.noarch.rpm
installRpm  ${currentPath}/lib/lua-filesystem-1.4.2-1.el6.x86_64.rpm
installRpm  ${currentPath}/lib/lua-lxc-1.0.10-2.el6.x86_64.rpm
installRpm  ${currentPath}/lib/lxc-1.0.10-2.el6.x86_64.rpm
installRpm  ${currentPath}/lib/docker-io-1.7.1-2.el6.x86_64.rpm

mountCgroup
checkCgconfig
docker -v
if [ $? -ne 0 ];then
    logger "docker安装失败，请检查日志"
else
    logger "docker安装成功，结束安装程序"
    exit 0
fi

