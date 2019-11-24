#!/bin/bash

#====================================================
#	System Request:Debian 9+/Ubuntu 18.04+/Centos 7+
#	Author:	wulabing
#	Dscription: V2ray ws+tls onekey 
#	Version: 5.1
#	email:wulabing@admin.com
#	Official document: www.v2ray.com
#====================================================

#fonts color
Green="\033[32m" 
Red="\033[31m" 
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

#notification information
Info="${Green}[信息]${Font}"
OK="${Green}[OK]${Font}"
Error="${Red}[错误]${Font}"

v2ray_conf_dir="/etc/v2ray"

v2ray_conf="${v2ray_conf_dir}/config.json"



source /etc/os-release

#从VERSION中提取发行版系统的英文名称，为了在debian/ubuntu下添加相对应的Nginx apt源
VERSION=`echo ${VERSION} | awk -F "[()]" '{print $2}'`

check_system(){
    if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Centos ${VERSION_ID} ${VERSION} ${Font}"
        INS="yum"
    elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 8 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Debian ${VERSION_ID} ${VERSION} ${Font}"
        INS="apt"
        $INS update
        ## 添加 Nginx apt源
    elif [[ "${ID}" == "ubuntu" && `echo "${VERSION_ID}" | cut -d '.' -f1` -ge 16 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Ubuntu ${VERSION_ID} ${UBUNTU_CODENAME} ${Font}"
        INS="apt"
        $INS update
    else
        echo -e "${Error} ${RedBG} 当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内，安装中断 ${Font}"
        exit 1
    fi

    systemctl stop firewalld && systemctl disable firewalld
    echo -e "${OK} ${GreenBG} firewalld 已关闭 ${Font}"
}

is_root(){
    if [ `id -u` == 0 ]
        then echo -e "${OK} ${GreenBG} 当前用户是root用户，进入安装流程 ${Font}"
        sleep 3
    else
        echo -e "${Error} ${RedBG} 当前用户不是root用户，请切换到root用户后重新执行脚本 ${Font}" 
        exit 1
    fi
}
judge(){
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} $1 完成 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} $1 失败${Font}"
        exit 1
    fi
}


dependency_install(){
    ${INS} install wget git lsof -y

    if [[ "${ID}" == "centos" ]];then
       ${INS} -y install crontabs
    else
       ${INS} -y install cron
    fi
    judge "安装 crontab"

    if [[ "${ID}" == "centos" ]];then
       touch /var/spool/cron/root && chmod 600 /var/spool/cron/root
       systemctl start crond && systemctl enable crond
    else
       touch /var/spool/cron/crontabs/root && chmod 600 /var/spool/cron/crontabs/root
       systemctl start cron && systemctl enable cron

    fi
    judge "crontab 自启动配置 "



    ${INS} -y install bc
    judge "安装 bc"

    ${INS} -y install unzip
    judge "安装 unzip"

    ${INS} -y install qrencode
    judge "安装 qrencode"
    

}
basic_optimization(){
    # 最大文件打开数
    sed -i '/^\*\ *soft\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
    sed -i '/^\*\ *hard\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
    echo '* soft nofile 65536' >> /etc/security/limits.conf
    echo '* hard nofile 65536' >> /etc/security/limits.conf

    # 关闭 Selinux
    if [[ "${ID}" == "centos" ]];then
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
        setenforce 0
    fi

}

modify_port_UUID(){
    let PORT=$RANDOM+10000
    UUID=$(cat /proc/sys/kernel/random/uuid)
	alterID=$(shuf -i1-100 -n1)
    sed -i "/\"port\"/c  \    \"port\":${PORT}," ${v2ray_conf}
    sed -i "/\"id\"/c \\\t  \"id\":\"${UUID}\"," ${v2ray_conf}
    sed -i "/\"alterId\"/c \\\t  \"alterId\":${alterID}" ${v2ray_conf}
    
}


v2ray_install(){
    if [[ -d /root/v2ray ]];then
        rm -rf /root/v2ray
    fi
    if [[ -d /etc/v2ray ]];then
        rm -rf /etc/v2ray
    fi
    mkdir -p /root/v2ray && cd /root/v2ray
    wget  --no-check-certificate https://install.direct/go.sh

    ## wget http://install.direct/go.sh
    
    if [[ -f go.sh ]];then
        bash go.sh --force
        judge "安装 V2ray"
    else
        echo -e "${Error} ${RedBG} V2ray 安装文件下载失败，请检查下载地址是否可用 ${Font}"
        exit 4
    fi
    # 清除临时文件
    rm -rf /root/v2ray
}




v2ray_conf_add(){
    cd /etc/v2ray
    wget https://raw.githubusercontent.com/mikewubox/tvonekey/master/mkcp/config.json -O config.json
modify_port_UUID
judge "V2ray 配置修改"
}


start_process_systemd(){
    

    systemctl restart v2ray
    judge "V2ray 启动"

    systemctl enable v2ray
    judge "设置 v2ray 开机自启"
}

#debian 系 9 10 适配
#rc_local_initialization(){
#    if [[ -f /etc/rc.local ]];then
#        chmod +x /etc/rc.local
#    else
#        touch /etc/rc.local && chmod +x /etc/rc.local
#        echo "#!/bin/bash" >> /etc/rc.local
#        systemctl start rc-local
#    fi
#
#    judge "rc.local 配置"
#}


vmess_qr_config(){
    cat >/etc/v2ray/vmess_qr.json <<-EOF
    {
        "v": "2",
        "ps": "wulabing_${domain}",
        "add": "${domain}",
        "port": "${port}",
        "id": "${UUID}",
        "aid": "${alterID}",
        "net": "ws",
        "type": "none",
        "host": "${domain}",
        "path": "/${camouflage}/",
        "tls": "tls"
    }
EOF

    vmess_link="vmess://$(cat /etc/v2ray/vmess_qr.json | base64 -w 0)"
    echo -e "${Red} URL导入链接:${vmess_link} ${Font}" >>./v2ray_info.txt
    echo -e "${Red} 二维码: ${Font}" >>./v2ray_info.txt
    echo "${vmess_link}"| qrencode -o - -t utf8 >>./v2ray_info.txt
}

show_information(){
    clear
    cd ~

    echo -e "${OK} ${Green} V2ray+ws+tls 安装成功" >./v2ray_info.txt
    echo -e "${Red} V2ray 配置信息 ${Font}" >>./v2ray_info.txt
    echo -e "${Red} 地址（address）:${Font} ${domain} " >>./v2ray_info.txt
    echo -e "${Red} 端口（port）：${Font} ${port} " >>./v2ray_info.txt
    echo -e "${Red} 用户id（UUID）：${Font} ${UUID}" >>./v2ray_info.txt
    echo -e "${Red} 额外id（alterId）：${Font} ${alterID}" >>./v2ray_info.txt
    echo -e "${Red} 加密方式（security）：${Font} 自适应 " >>./v2ray_info.txt
    echo -e "${Red} 传输协议（network）：${Font} ws " >>./v2ray_info.txt
    echo -e "${Red} 伪装类型（type）：${Font} none " >>./v2ray_info.txt
    echo -e "${Red} 路径（不要落下/）：${Font} /${camouflage}/ " >>./v2ray_info.txt
    echo -e "${Red} 底层传输安全：${Font} tls " >>./v2ray_info.txt
    vmess_qr_config
    cat ./v2ray_info.txt

}


main(){
    is_root
    check_system
    
    dependency_install
    basic_optimization
       
    v2ray_install
        
    v2ray_conf_add
   
    #将证书生成放在最后，尽量避免多次尝试脚本从而造成的多次证书申请
    
    show_information
    start_process_systemd
   
}

main

