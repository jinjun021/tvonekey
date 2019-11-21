
## Debian10常用软件包
   root用户下安装

#apt-get -y update && apt-get -y install unzip zip wget curl mc nano sudo ufw socat ntp ntpdate gcc git

## CentOS8常用软件包
   root用户下安装

#yum -y update && yum -y install unzip zip wget nano sudo curl firewalld redhat-lsb epel-release socat gcc git

## 加速優化（效果咋樣，見仁見智）
原版BBR加速

修改系统变量

#echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf

#echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

保存生效

#sysctl -p

查看内核是否已开启BBR

#lsmod | grep bbr

返回值有 tcp_bbr 模块即说明 bbr 已启动

TLS开启OSCP

#openssl s_client -connect yourzzz.ml:443 -status -tlsextdebug < /dev/null 2>&1 | grep -i "OCSP response"

TCP fastopen

#echo 3 > /proc/sys/net/ipv4/tcp_fastopen


# 收集一键脚本，所有权利归原作者所有。
除了官网一键代码，各路大神的大多数原版一键脚本已删贴走人隐居甚至失效。

## 独立版官方克隆脚本
#bash <(curl -Ls https://raw.githubusercontent.com/mikewubox/tvonekey/master/go.sh)

# 手动本地安装

先上传go.sh+安装包到VPS

安装bash go.sh --local ./v2ray-linux-64.zip

删除bash go.sh --remove

时间校正、配置、启动与其他方式一样


#  基于Nginx 的 vmess+ws+tls 一键安装脚本
#bash <(curl -L -s https://raw.githubusercontent.com/mikewubox/V2Ray_ws-tls_bash_onekey/master/install.sh) | tee v2ray_ins.log
