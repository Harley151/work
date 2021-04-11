pause：叫做 pod 的基础架构容器，他不启动，他是靠一个独特的镜像来创建的，他是pod的根，包括网络名称空间的分配都是分配给他的。
所以同一个pod 的多个容器，共享pause的网络名称空间，共享同一个IP地址，同一个TCP/IP 协议栈，IPC，NAT和UTS名称空间
以往docker 存储卷 是存放在 docker当前节点上提供数据持久存储，容器只能存放在当前节点上运行，才能找到存储的数据
而 k8s 调度的 pod 是随机分配到不同节点上的，所以 pod 的位置就不固定，这是一定的区别 ，它们同样可以使用 NFS 共享

存储卷类型：
pod 中的 pause拥有了存储卷，那么pod内的容器就会共享这个存储卷，而容器存储卷会与宿主机的目录产生关联关系，所有随着主机目录的终结那么pod也就终结了（宿主机目录是挂载到外部的网络存储上）


emptyDir（当做临时目录，或者缓存）
hostPath (主机路径)


kubectl explain pods.spec.volumes           # 查看支持的存储类型

网络存储：
SNA: iscsi,...
NAS: nfs.cifs

分布式存储:
gluster,rbd.cephfs

云存储:
EBS(亚马逊),Azure Disk(微软),


pvc 要和 pv建立关联关系，而 pv要与 存储系统 建立关联关系


mkdir volumes
cd volumes

vim pod-volumes-demo.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: default
  labels:
    app: myapp
    tier: frontend
  annotations:
    magedu.com/create-by: "cluster admin"
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    ports:
    - name: http
      containerPort: 80
    - name: https
      containerPort: 443
    volumeMounts:
    - name: html
      mountPath: /data/web/html    
  - name: busybox
    image: busybox:latest
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: html
      mountPath: /data/  
    command:
    - "/bin/sh"
    - "-c"
    - "sleep 300"
  volumes:
  - name: html
    emptyDir: {}
    # emptyDir 的属性是 medium（空字符串使用的是磁盘，memory就是使用内存）和sizeLimit（限制磁盘或者内存使用的大小），{} 表示没有键值，使用映射数据，表示使用磁盘，没有限制，并不是不定义

kubectl apply -f pod-volumes-demo.yaml
kubectl exec -it pod-demo -c busybox -- /bin/sh

/ # echo $(date) >> /data/index.html 
/ # echo $(date) >> /data/index.html 
/ # cat /data/index.html 
Thu Mar 18 14:11:55 UTC 2021
Thu Mar 18 14:11:58 UTC 2021

kubectl exec -it pod-demo -c myapp -- /bin/sh
cat data/web/html/index.html 
Thu Mar 18 14:11:55 UTC 2021
Thu Mar 18 14:11:58 UTC 2021

发现他们共享的是一个存储卷







# 定义主容器与辅助容器 
vim pod-volumes-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: default
  labels:
    app: myapp
    tier: frontend
  annotations:
    magedu.com/create-by: "cluster admin"
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 80
    - name: https
      containerPort: 443
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html/
  - name: busybox
    image: busybox:latest
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: html
      mountPath: /data/  
    command: ["/bin/sh"]
    args: ["-c","while true;do echo $(date) >> /data/index.html;sleep 2;done"]
  volumes:
  - name: html
    emptyDir: {}

kubectl delete -f pod-volumes-demo.yaml
kubectl apply -f pod-volumes-demo.yaml
kubectl get pods -o wide
curl  10.244.1.71

目的：一个pod内创建主容器和辅助容器，通过辅助容器将网页文件上传到共享的存储，而后主容器根据上传的内容进行加载，并响应信息








gitRepo

在pod创建时，它会自动连接到（GitHub或者gitlab）之上，但是要依赖与宿主机上有git命令，通过宿主机将git文件克隆到本地来，
并将它作为存储卷挂载值至pod之上,不过要注意的是，pod创建的那一刻，他才会把数据克隆到存储卷上来，之后Git文件在修改都不会同步到存储卷内。
要想实现数据同步，可以增加一个辅助容器，其实gitRepo和emptyDir类似








hostPath
pod 所在宿主机之上的脱离pod名称空间之外，宿主机的文件系统的某一目录，与pod建立关联关系，这里能保证的是pod被删除了，还能调度到同一节点上，那么数据是继续存在的

vim pod-hostpath-vol.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-vol-hostpath
  namespace: default
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
  volumes:
  - name: html
    hostPath: 
      path: /data/pod/volume1
      type: DirectoryOrCreate
      # hostpath类型分为好几种,如下：
      # DirectoryOrCreate	如果给定路径上不存在任何内容，则将根据需要在该目录中创建一个空目录，并将权限设置为0755，该目录与Kubelet具有相同的组和所有权。
      # Directory	目录必须存在于给定的路径中
      # FileOrCreate	如果给定路径上不存在任何内容，则将根据需要在其中创建一个空文件，并将权限设置为0644，该文件具有与Kubelet相同的组和所有权。
      # File	文件必须存在于给定的路径
      # 参考网址：https://kubernetes.io/docs/concepts/storage/volumes/#hostpath

因为不知道pod会调度到那个节点，则选择一下方式：

node1:
mkdir /data/pod/volume1 -pv
echo "node01" >> /data/pod/volume1/index.html

node2:
mkdir /data/pod/volume1 -pv
echo "node02" >> /data/pod/volume1/index.html

kubectl apply -f pod-hostpath-vol.yaml
kubectl get pods -o wide
curl 10.244.1.72
kubectl delete -f pod-hostpath-vol.yaml 
kubectl apply -f pod-hostpath-vol.yaml

在某种程度上他已经实现了，存储持久性，但是这种持久只是节点级的持久，一旦某个节点宕机了那么数据也就没了。


下面利用共享存储：
1、找到一个新的节点来作为 NFS 服务节点
yum -y install nfs-utils
mkdir -pv /data/volumes
vim /etc/exports
/data/volumes 172.21.0.0/16(rw,no_root_squash)
读写共享，即使对root 用户来说也不压缩它的权限
systemctl start nfs
netstat -anput | grep 2049


2、node 挂载
yum -y install nfs-utils
mount -t nfs 172.21.40.242:/data/volumes /mnt
df -hT
umount /mnt





3、定义配置清单
vim pod-vol-nfs.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-vol-nfs
  namespace: default
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
  volumes:
  - name: html
    nfs: 
      path: /data/volumes
      server: 172.21.40.242
      # readOnly , 默认是读写挂载
kubectl apply -f pod-vol-nfs.yaml 
kubectl get pods -o wide              # 获取IP


验证：
到达新的节点
cd /data/volumes
echo "<h1>NFS stort</h1>" >> index.html

回到master节点
curl 10.244.1.74
<h1>NFS stort</h1>


发现数据目录是共享的，并挂载到了pod之上，接下来删除掉pod
kubectl delete -f pod-vol-nfs.yaml
cat /data/volumes/index.html    # 发现数据已然存在
现在我们的pod可以说是具有真正意义上的持久能力，但是NFS挂掉了，数据也依然丢失






pod、pv、pvc的关联关系图:
参考地址: https://img-blog.csdnimg.cn/20200113144255555.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3pob25nbGluemhhbmc=,size_16,color_FFFFFF,t_70

pvc的数据是放在pv上的，pvc 需要绑定的 pv 的情况下，究竟要绑定那个 pv ，是取决于 pod 创建时在它的用户空间内定义请求使用多大的磁盘空间，
比如请求需要5G的空间，那么pv需要给定指定的5G空间，2G的就不匹配，也可以定义使用指定pv只允许一个pvc 挂载和读写使用，可以定义它的访问模型，一人读，一人写，多人读，多人写



PVC是k8s中一种标准的资源,他是存贮在etc当中的
kubectl explain pvc

pvc:spec:{
  accessModes:  可支持多个人同时访问
  resources:    期望对应的pv存储空间至少拥有多少GB空间
  selector:     标签选择器，表示pvc必须要与那个pv进行建立关联关系，也可以不加标签，他可以在所有pv中找到最佳匹配
  storageClassName:   存储类名称，
  volumeMode:   是指后端存储卷的模式，做类型限制
  volumeName:   卷名称，必须要绑定某个pv就需要volumeName指定的pv名，如果不指他会在一大堆pv中选择
}

pvc 和 pv 是一一对应的，一旦哪个 pv 被 pvc 占用了，就不能被其他 pvc 使用，如果被绑定了，
会显示binding（已被绑定），但是一个 pvc 可以被多个pod所访问，这个支不支持多个访问可以定义 pvc 的访问模式accessModes




PV制作:
在新节点上创建5个目录
mkdir /data/volumes/v{1..5}
vim /etc/exports
/data/volumes/v1 172.21.0.0/16(rw,no_root_squash)
/data/volumes/v2 172.21.0.0/16(rw,no_root_squash)
/data/volumes/v3 172.21.0.0/16(rw,no_root_squash)
/data/volumes/v4 172.21.0.0/16(rw,no_root_squash)
/data/volumes/v5 172.21.0.0/16(rw,no_root_squash)

exportfs -arv       # 使用配置重新生效
showmount -e        # 查看是否生效






// PV是k8s中一种标准的资源

kubectl explain pv.spec.nfs         # 定义 nfs 格式的 pv

spec:accessModes
  RWO-ReadWriteOnce     # 单路读写
  ROX-ReadOnlyMany      # 多路只读
  RWX-ReadWriteMany     # 多路读写

spec:capacity           # 指定空间大小
  storage: 2Gi          # 指定空间大小为2Gi     Gi（1024） 和 G（1000） 的区别

spec:nfs
  path:
  readOnly:
  server: 


// PV 是属于整个集群，不属于某个名称空间，但是PVC 是属于名称空间的
vim pv-damo.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv001
  labels:
    name: pv001
spec:
  nfs:
    path: /data/volumes/v1
    server: 172.21.40.242
  accessModes: ["ReadWriteMany","ReadWriteOnce"]
  capacity:
    storage: 2Gi
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv002
  labels:
    name: pv002
spec:
  nfs:
    path: /data/volumes/v2
    server: 172.21.40.242
  accessModes: ["ReadWriteMany","ReadWriteOnce"]
  capacity:
    storage: 5Gi
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv003
  labels:
    name: pv003
spec:
  nfs:
    path: /data/volumes/v3
    server: 172.21.40.242
  accessModes: ["ReadWriteMany","ReadWriteOnce"]
  capacity:
    storage: 20Gi
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv004
  labels:
    name: pv004
spec:
  nfs:
    path: /data/volumes/v4
    server: 172.21.40.242
  accessModes: ["ReadWriteMany","ReadWriteOnce"]
  capacity:
    storage: 10Gi
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv005
  labels:
    name: pv005
spec:
  nfs:
    path: /data/volumes/v5
    server: 172.21.40.242
  accessModes: ["ReadWriteMany","ReadWriteOnce"]
  capacity:
    storage: 10Gi

// 注意:在这里遇到了一次坑，就是我的accessModes设置的是 ["ReadOnlyMany","ReadWriteOnce"],创建出来的pod 和 pvc 一直处于pending状态，换上下面内容则创建成功 ["ReadWriteMany","ReadWriteOnce"] 

kubectl apply -f pv-damo.yaml
kubectl get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY(回收策略)   STATUS      CLAIM   STORAGECLASS   REASON   AGE
pv001   2Gi        RWO,ROX        Retain（保留）           Available                                   16s
pv002   5Gi        RWO            Retain                  Available                                   16s
pv003   20Gi       RWO,ROX        Retain                  Available                                   16s
pv004   10Gi       RWO,ROX        Retain                  Available                                   16s
pv005   10Gi       RWO,ROX        Retain                  Available                                   16s

// 回收策略：
// 如果某个PVC绑定了PV，并且在里面存入数据了，但后来这个PVC释放了，把PVC 删除掉，那么绑定就不存在了，一旦绑定不存在了PV 可以进行保留，也可以进行回收，能够让下一个PVC进行绑定


vim pod-vol-pvc.yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mypvc
  namespace: default
spec:
  accessModes: ["ReadWriteMany"]
  resources:
    requests:
      storage: 6Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: pod-vol-pvc
  namespace: default
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
  volumes:
  - name: html
    persistentVolumeClaim:
      claimName: mypvc

kubectl apply -f pod-vol-pvc.yaml
kubectl get pvc
kubectl get pods
kubectl describe pods pod-vol-pvc


PVC是k8s中一种标准的资源,他是存贮在etc当中的，就算pod 被删除，他也不会删除，1.9之前k8s中pvc正在使用但是pv可以被删除，之后版本中要删除PV是会报错的
参考：PV-PVC创建：https://blog.csdn.net/weixin_36171533/article/details/82627920








// 创建PVC动态分配PV

StorageClass
借助StorageClass中间层来完成资源的分配
resetful 风格的接口ceph存储完成PV的创建，NFS不支持