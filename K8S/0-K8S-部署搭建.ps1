k8s-集群搭建的三种方式和区别：{
    kubeadm:
    是一个工具，用于快速搭建kubernetes集群，目前应该是比较方便和推荐的，简单易用
    kubeadm是Kubernetes 1.4开始新增的特性
    kubeadm init 以及 kubeadm join 这两个命令可以快速创建 kubernetes 集群

    minikube:
    一般用于本地开发、测试和学习，不能用于生产环境
    是一个工具，minikube快速搭建一个运行在本地的单节点的Kubernetes

    二进制包:
    在官网下载相关的组件的二进制包，上面的两个是工具，可以快速搭建集群，也就是相当于用程序脚本帮我们装好了集群，前两者属于自动部署，
    简化部署操作，自动部署屏蔽了很多细节，使得对各个模块感知很少，遇到问题很难排查，如果手动安装，对kubernetes理解也会更全面。
    目前生产环境的主流搭建方式，已在生产环境验证，kubeadm也可以搭建生产环境
}



Kubernetes 1.20的发布，这是2020年发布的第三个也是最终的版本！这个版本包含了42个增强：11个增强已经稳定，15个增强进入beta，16个增强进入alpha。        链接:https://www.mdeditor.tw/pl/g222







kubeadm安装:{
    1、master，nodes：安装kubelet,kubeadm ，docker
    2、master：kubeadm init 主节点初始化
    3、nodes：kubeadm join  加入集群

    #主机名
    hostnamectl set-hostname master
    hostnamectl set-hostname node1
    hostnamectl set-hostname node2
    IP1=172.21.40.161
    IP2=172.21.40.162
    IP3=172.21.40.163
    #创建秘钥：
    ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
    ssh-copy-id root@${IP1}
    ssh-copy-id root@${IP2}
    ssh-copy-id root@${IP3}
    
    cat > server.txt <<-EOF
    ${IP1}
    ${IP2}
    ${IP3}

EOF

    cat server.txt |xargs -i ssh {} "ping -i0.1 -c2 jd.com"

    #同步时间
    cat server.txt |xargs -i ssh {} "yum -y install ntpdate;ntpdate ntp.sjtu.edu.cn"

    #主机映射
    cat server.txt |xargs -i ssh {} "echo '
    '${IP1}' master
    '${IP2}' node1
    '${IP3}' node2' >> /etc/hosts " 

    #关闭防火墙
    cat server.txt |xargs -i ssh {} "systemctl stop firewalld ;systemctl disable firewalld ;setenforce 0"

    #配置yum文件
    cat server.txt |xargs -i ssh {} "yum -y install wget epel-release;wget -P /etc/yum.repos.d/ https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo"
    cat server.txt |xargs -i ssh {} " echo '[kubernetes]
name=Kubernetes Repo
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
enabled=1 ' > /etc/yum.repos.d/kubernetes.repo "

    #检查程序包
    cat server.txt |xargs -i ssh {} "yum repolist"

    #安装docker 和 k8s
    #sed -i '/ExecStart/ i Environment="HTTPS_PROXY=http://www.ik8s.io:10080"' /usr/lib/systemd/system/docker.service 
    #sed -i '/ExecStart/ i Environment="NO_PROXY=127.0.0.0/8,127.20.0.0/16"' /usr/lib/systemd/system/docker.service 
    cat server.txt |xargs -i ssh {} "yum -y install docker-ce kubelet kubeadm kubectl"
    sed -i '/KUBELET/ cKUBELET_EXTRA_ARGS="--fail-swap-on=false"' /etc/sysconfig/kubelet    (每台主机都要执行)
    cat server.txt |xargs -i ssh {} "echo "1" > /proc/sys/net/bridge/bridge-nf-call-iptables"

    # 使用 ipvs 每个节点上都要执行
    cat > /etc/sysconfig/modules/ipvs.modules <<EOF
    #!/bin/bash
    ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_fo ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack_ipv4"
    for kernel_module in \${ipvs_modules}; do
        /sbin/modinfo -F filename \${kernel_module} > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /sbin/modprobe \${kernel_module}
        fi
    done
    EOF
    chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep ip_vs
    
    sed -i '/swap/ s/^/#/g' /etc/fstab
    cat server.txt |xargs -i ssh {} "mkdir /etc/docker/"
    echo '{
     "registry-mirrors": ["https://registry.docker-cn.com"]
}' > /etc/docker/deamon.json
    systemctl daemon-reload
    systemctl start docker
    systemctl enable docker
    systemctl status docker
    systemctl enable kubelet.service

    #k8s初始化
    kubeadm init --kubernetes-version=v1.20.0 --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12 --ignore-preflight-errors=Swap
    sed -i '/--port/ s/^/#/g' /etc/kubernetes/manifests/kube-scheduler.yaml     #注释端口不然组件状态会报错
    sed -i '/--port/ s/^/#/g' /etc/kubernetes/manifests/kube-controller-manager.yaml    #注释端口不然组件状态会报错
    mkdir -p $HOME/.kube                                                        #创建一个用户家目录
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config                         #admin.conf 放的是各个组件的认证信息
    kubectl get componentstatus                                                 #获取各个组件的运行状态
    kubectl get nodes                                                           #获取各个节点信息
    kubectl get ns

    #部署flanal
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    kubectl get pods -n kube-system                                             #获取节点上所有的pod ,而且这些属于kube-system名称空间

    #将节点加入到集群中
    cat > server.txt <<-EOF
    ${IP2}
    ${IP3}
EOF
    cat server.txt |xargs -i ssh {} "sed -i '/KUBELET/ cKUBELET_EXTRA_ARGS='--fail-swap-on=false'' /etc/sysconfig/kubelet"
    cat server.txt |xargs -i ssh {} "systemctl start docker;systemctl enable docker;systemctl enable kubelet"
    cat server.txt |xargs -i ssh {} "kubeadm join 172.21.40.161:6443 --token ombt00.7n5wd7l78l9tny3v \
    --discovery-token-ca-cert-hash sha256:09d0be74564e34512231940acdbc60ee91a0c822d059fe2362d472c0489e9a7c --ignore-preflight-errors=Swap"
    # kubeadm token create --print-join-command 获取 token使节点重新加入节点
    #kubeadm join 172.21.40.161:6443 --token ombt00.7n5wd7l78l9tny3v \
    #--discovery-token-ca-cert-hash sha256:09d0be74564e34512231940acdbc60ee91a0c822d059fe2362d472c0489e9a7c --ignore-preflight-errors=Swap  # k8s 初始化完成获取的内容   
    kubectl get pods -n kube-system -o wide         #获取集群所有组件
    kubectl get nodes                               #获取集群节点
}


