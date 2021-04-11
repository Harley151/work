configmap:

1、在创建一个pod时将k8s上标准资源configmap配置关联至pod上，pod从configmap中读取数据传递给pod中内部容器的一个变量，仍然是注入变量的方式给容器传配置信息。
2、将每一个configmap当做存储卷，直接将他挂载到容器的某个目录下，这个目录恰好是应用程序读取配置信息的文件路径，
   并且这种方式可以支持配置文件的动态修改，当所有的pod挂载到一个configmap中，一旦configmap修改了，那么其他pod的配置信息也会随之更改
   通知其他pod加载配置文件，当然有的不能自动重载，还需手动触发一下pod读取配置信息，因此configmap扮演了k8s之上配置中心的角色


secret:
是用于存储加密数据的，新版本的 Kubernetes 已经实现了真正意义上的加解密，所以 Secret 存在是有一定意义的，使用方式跟 ConfigMap 类似，但是命令确不一样。






通过环境变量引用configmap
kubectl explain pods.spec.containers.env.valueFrom

configMapKeyRef:
secretKeyRef:
fieldRef:           引用自身pod的名称空间、元数据、nodeName、labels，传递给某个变量来使用
resourceFieldRef:   资源类，资源限制。调度器用的比较多

configmap 核心作用：配置信息和镜像解耦，镜像可以做成一个骨架，配置信息可以通过configmap进行注入，使得一个镜像文件就可以应付多个不同配置情况下，为应用程序运行不同配置的环境
是为了将配置文件从镜像中解耦，从而增强了应用的可移植性和复用性，简单来讲，一个configmap就是一系列配置数据的集合，而这些数据将来可以注入到pod中的容器使用，而注入的方式有两种
1、直接使用configmap存储卷（整个configmap当中放置的是多个键值数据对）
2、使用env当中valueFrom的方式去引用configmap当中所保存的数据，但确保环境变量传递容器内部可以作为配置信息使用，否则传递过去没什么用




（1）、命令行--from-literal创建configmap:
--from-literal                  #直接在命令行给出键值，如：--from-literal=key=config1
--from-file                     #直接给出键名，而值是来自于文件内，如：--from-file=key1=/path/to/1.txt，而且可以不用给键，文件名可以当做键


kubectl create configmap nginx-config --from-literal=nginx_port=80 --from-literal=server_name=myapp.magedu.com
kubectl get cm                      # 查看configmap是否创建完成
kubectl describe cm                 # 查看configmap的键值信息
这些键值就可以被启动的一个pod所调用了




（2）、命令行--from-file创建configmap:
mkdir /root/mainpod/configmap
cd /root/mainpod/configmap
vim www.conf
server {
    server_name myapp.magedu.com;
    listen 80;
    root /data/web/html;
}

开始创建configmap
kubectl create configmap nginx-www --from-file=./www.conf           # 键名是www.conf，值是文件内容
或者
kubectl create configmap nginx-www --from-file=www=./www.conf       # 键名是www，值是文件内容

kubectl get cm nginx-www -o yaml                                    # 以 yaml 格式输出

vim pod-configmap.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pod-cm-1
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
    env:
    - name: NGINX_SERVER_PORT       # 这个变量要能被容器内部引用（事先存在）
      valueFrom:
        configMapKeyRef:            # 引用configmap
          name: nginx-config        # 引用那个configmap
          key: nginx_port           # 引用configmap的键，意思就是将nginx_port的值注入到了 容器内部的NGINX_SERVER_PORT环境变量当中
    - name: NGINX_SERVER_NAME
      valueFrom:
        configMapKeyRef:
          name: nginx-config
          key: server_name
kubectl apply -f  pod-configmap.yaml

kubectl exec -it pod-cm-1 -- /bin/sh
printenv                # 查看内部有哪些的环境变量

kubectl edit cm nginx-config        # 将 80 改为 8080 发现环境变量的值并没有改变
kubectl describe cm nginx-config

所以在注入环境变量时，只在pod启动时有效，如果通过存储卷的方式获取，是可以动态更新的



vim pod-configmap-2.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pod-cm-2
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
    volumeMounts:
    - name: nginxconf                       # 名称自己定义
      mountPath: /etc/nginx/config.d        # 挂载的目录如果不存在，自动创建
      readOnly: true                        # 不允许容器修改其中的内容
  volumes:
  - name: nginxconf                         # 名称自己定义
    configMap:
      name: nginx-config                  # 挂载的configmap配置文件

kubectl apply -f pod-configmap-2.yaml
kubectl get pods
kubectl exec -it pod-cm-2 -- /bin/sh
ls /etc/nginx/config.d/
nginx_port   server_name        # 发现两个链接文件
cat nginx_port
8080

kubectl edit cm nginx-config         # 将 8080 改为 8088 发现环境变量的值并没有改变

cd ../      # 等待两秒
cd config.d
cat nginx_port
8088
# 发现内容已经同步了




vim pod-configmap-3.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pod-cm-3
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
    volumeMounts:
    - name: nginxconf                       # 名称自己定义
      mountPath: /etc/nginx/conf.d          # 挂载的目录如果不存在，自动创建，这个位置刚好是nginx应用要加载的配置文件路径
      readOnly: true                        # 不允许容器修改其中的内容
  volumes:
  - name: nginxconf                         # 名称自己定义
    configMap:
      name: nginx-www                       # 挂载的configmap配置文件
kubectl apply -f pod-configmap-3.yaml 
kubectl get pods
kubectl exec -it pod-cm-3 -- /bin/sh
cat /etc/nginx/conf.d/www.conf              # www.conf就是 configmap定义的键名，文件内容就是值了
server {
    server_name myapp.magedu.com;
    listen 80;
    root /data/web/html;
}

cat ../nginx.conf                           # 发现内容自动改变了，server下的配置没有了，并且有include /etc/nginx/conf.d/*.conf;这个路径了

nginx -T                     # 显示正常加载的配置
mkdir /data/web/html -pv     
echo "<h1>nginx Server configured by </h1>" > /data/web/html/index.html
exit
kubectl get pods -o wide pod-cm-3            # 获得此pod IP，做成hosts映射
echo "10.244.1.81 myapp.magedu.com" >> /etc/hosts
curl  myapp.magedu.com                       # 访问域名则访问到刚才制作的页面
<h1>nginx Server configured by </h1>

kubectl edit cm nginx-www                       # 将80 改为 8080
cat /etc/nginx/conf.d/www.conf 
server {
    server_name myapp.magedu.com;
    listen 8080;
    root /data/web/html;
}
配置文件是改变了，但是监听的端口是不会变的，只有重载才能生效,如果加载的话可以灰度进行加载，从而写一个脚本最好的
/ # nginx -s reload
2021/03/20 09:48:51 [notice] 31#31: signal process started
/ # netstat -anput
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      1/nginx: master pro
curl myapp.magedu.com:8080
<h1>nginx Server configured by </h1>
# 这就是configmap动态配置








secret:(保存敏感数据内容)
三种格式
generic: 表示通用的，保存一些密码数据之类的，才能用到这个
tls:     类似于秘钥或者域名证书可以使用这种类型
docker-registry: 表示存放向任意私有仓库认证信息

创建secret
kubectl
kubectl create secret generic mysql-root-password --from-literal=password=mysql@123
secret名: mysql-root-password
键: password
值: mysql@123
kubectl describe secret mysql-root-password             # 发现并不会显示 密码 ，只是显示字节数
kubectl get  secret mysql-root-password -o yaml         # 发现密码已被 base64 编码了
apiVersion: v1
data:
  password: bXlzcWxAMTIz
echo bXlzcWxAMTIz | base64 -d                           # 表示解码，得到相应的密码 mysql@123 ，感觉可以给ppvod切片的名称解码

vim pod-secret-1.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-secret-1
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
    env:
    - name: MYSQL_ROOT_PASSWORD         # 这个变量要能被容器内部引用（事先存在）
      valueFrom:
        secretKeyRef:
          name: mysql-root-password
          key: password                 # 引用configmap的键，意思就是将nginx_port的值注入到了 容器内部的NGINX_SERVER_PORT环境变量当中

kubectl exec pod-secret-1 -- printenv | grep MYSQL      # 获取到环境变量对应的值，在变量里，它的值是已经解码过的
这个也可以以存储卷的方式引入一个配置文件