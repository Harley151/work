kubectl explain pod.spec.containers
Pod 资源：

      #Defaults to Always if :latest tag is specified, or IfNotPresent otherwise.

      修改镜像中的默认应用：
      command，args
      参数解释：https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/


    标签:；

    
        key=value
            key: 只能使用字母、数字、下滑线、杠、点表示，但只能已字母数字开头，key的总长度不能超过64位
            value: 可以位空，只能字母或数字开头及结尾，中间可使用字母、数字、下滑线、杠、点表示

apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: default
  labels:
    app: myapp
    tier: frontend
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    ports:
    - name: http
      containerPort: 80
    - name: https
      containerPort: 443
  - name: busybox
    image: busybox:latest
    imagePullPolicy: IfNotPresent
    command:
    - "/bin/sh"
    - "-c"
    - "sleep 300"








标签选择器：

    等值关系：=，==，!=

    kubectl delete pod pod-demo
    kubectl create -f pod-demo.yaml
    kubectl get pods --show-labels
    kubectl get pods -L app                                                                      #-L 选项指的是，显示所有pod资源中拥有 app 字段的标签值
    kubectl get pods -l app --show-labels                                                        #-l 选项表示过滤，对应的pod之上拥有标签app就显示这一类
    或者
    kubectl get pods -l app,run --show-labels                                                    #显示app 标签和 run 标签的值
    kubectl label pods pod-demo release=cannry                                                   #给pod在打上一个标签
    kubectl label pods pod-demo release=stable --overwrite                                       #--overwrite强行改变之前已打的标签
    kubectl get pods -l app=myapp,release=canary                                                 #指定两个标签并同时满足，pod才可以被打印
    kubectl get pods -l app!=myapp,release!=canary                                               # != 不等于



    kubectl get pods --show-labels                          #查看所有pod的标签，标签是以键值对的形式存在
    kubectl get pods -L myapp                               #-L 过滤拥有app字段的pod ，显示拥有app字段的标签值
    kubectl get pods -l myapp,run --show-labels             #-l 做标签过滤，可以筛选多个标签
    kubectl label pods pod-demo release=canary              #给pod-demo pod资源打上标签
    kubectl label pods pod-demo release=stable --overwrite  #强行修改之前的标签 选项是 --overwrite

    集合关系:
    KEY in (VALUE1,VALUE2, ....)
    KEY notin (VALUE1,VALUE2, ....)
    KEY (存在此键)
    !KEY (不存在此键)

    kubectl get pods -l "release in (canary,beta,alpha)"   #对应的release 键有canary,beta,alpha都显示
    kubectl get pods -l "release notin (canary,beta,alpha)"#对应的release 键没有canary,beta,alpha就不显示


    许多资源支持内嵌字段定义其使用的标签选择器:
        matchLabels: 直接给定键值
        matchExpressions:基于给定的表达式来定义使用的标签选择器，{key:"KEY",operator:"OPERATOR",values:[VAL1,VAL2,...]}
          操作符：
            In,NotIn: values 字段的值必须为非空列表;
            Exists,NotExists: values字段的值必须为空列表;









kubectl get nodes --show-labels               #也能获取到ondes节点的标签
kubectl label nodes node1 disktype=ssd        #给node1 打上标签
kubectl get nodes -l disktype --show-labels   #通过这条指令获取node1的标签



ndoeSelector <map[string]string>      #节点标签选择器
apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: default
  labels:
    app: myapp
    tier: frontend
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    ports:
    - name: http
      containerPort: 80
    - name: https
      containerPort: 443
  - name: busybox
    image: busybox:latest
    imagePullPolicy: IfNotPresent
    command:
    - "/bin/sh"
    - "-c"
    - "sleep 300"
  nodeSelector:
    disktype:ssd        #因为给node1节点上打过ssd标签，现在通过这个标签指定pod资源在那台服务器创建

然后删除并创建pod，在通过 kubectl describe pods pod-demo ,获取pod在那个节点上创建的。
kubectl delete -f pod-demo.yaml     #通过yaml 文件删除指定pod资源
kubectl create -f pod-demo.yaml
kubectl describe pods pod-demo


nodeName <string> (根据节点名进行选择)

annotations:  (资源注解)
  与label不同的地方在于，它不能用于挑选资源对象，仅仅用于为对象提供"元数据"。



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
  - name: busybox
    image: busybox:latest
    imagePullPolicy: IfNotPresent
    command:
    - "/bin/sh"
    - "-c"
    - "sleep 300"
  nodeSelector:
    disktype: ssd
    
 kubectl create  -f pod-demo.yaml 







创建pod阶段：
请求发送给ApiServer，apiserver将创建的请求的目标状态保存到etcd当中，接下来apiserver还会请求 kube-scheduler（调度器）进行调度，
如果调度成功了，会将调度的结果保存到etcd当中，比如说调度在node1节点上，node1上的kubelet组件通过apiserver当中的变化状态可以知道，
有一个新任务是给自己的，所以此时kubelet会拿到apiserver的请求，拿到之前用户所创建的清单，根据清单在此节点上创建并运行此pod。如果pod
创建成功或者失败了，会呈现一个pod状态，并将这个状态发送给apiserver，由apiserver再次存在etcd当中。
kube-scheduler 必须参与，因为他需要挑选一个合适的节点来运行pod






pod生命周期重要行为:
  初始化容器: 启动过程会有多个初始化容器，这些容器是串行化启动。
  容器探测  :
      liveness probe:  是用来判定主容器是否还活着
      readiness probe: 是用来判定主容器当中的主进程，是否已经准备就绪，并对外提供服务
      两种行为每个30秒检测一次，要想提供检测状态容器内部必须要有探针
      探针类型有三种:
      ExecAction:
      TCPSockettAction:
      HTTTPGetAction:
      




启动过程状态：
pending             #挂起，我们在启动pod时发现条件不能满足，调度没有完成，没有任何一个节点能满足pod的调度条件
running             #正在运行
Failed              #启动失败
Successed           #创建成功，显示时间很短
Unknown             #未知错误

pod 内部可以运行多个容器，但是一般来说我们只运行一个容器，并且一个容器只运行一个主程序。
在pod内部共有两种容器，一个是初始化容器（init container），另一个是主容器(main container)，初始化容器有多个，并且都是串行启动
初始化容器一旦初始化完成那么，就会启动主容器，主容器启动时会有启动后钩子，主容器结束时会有结束前钩子，容器在运行当中，分别有两个重要
的容器运行状态检测行为，一个是liveness probe是做存活性状态检测，是用来判定主容器是否还活着，另一个是 readiness probe 就绪性检测，
是用来判定主容器当中的主进程，是否已经准备就绪，并对外提供服务。
主容器一退出，那么pod就退出（死掉），


容器探测：


#根据exec 进行探测

vim liveness-exec.yaml

apiVersion: v1
kind: Pod
metadata:
   name: liveness-exec-pod
   namespace: default
spec:
  containers:
  - name: liveness-exec-container
    image: busybox:latest
    imagePullPolicy: IfNotPresent
    command: ["/bin/sh","-c","touch /tmp/healthy;sleep 30;rm -rf /tmp/healthy;sleep 3600"]
    livenessProbe:
      exec:
        command: ["test","-e","/tmp/healthy" ]
      initialDelaySeconds: 1
      periodSeconds: 3

这个清单的含义是对指点命令的操作进行探测，判定一个文件是否存在
kubectl create -f liveness-exec.yaml
kubectl get pods
kubectl describe pods liveness-exec-pod           #查看pod整个运行状态，知道重启次数达到一定限制，则不会重启





#根据httpGet进行探测
cp liveness-exec.yaml  liveness-httpget.yaml
vim liveness-httpget.yaml

apiVersion: v1
kind: Pod
metadata:
   name: liveness-httpget-pod
   namespace: default
spec:
  containers:
  - name: liveness-httpget-container
    image: ikubernetes/myapp:v1
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 80
    livenessProbe:
      httpGet:
        port: http
        path: /index.html
      initialDelaySeconds: 1
      periodSeconds: 3

kubectl create -f liveness-httpget.yaml
kubectl get pods
kubectl describe pods liveness-httpget-pod        #查看详细信息

#模拟故障，使之探针起到作用
kubectl exec -it liveness-httpget-pod -- /bin/sh
rm -rf /usr/share/nginx/html/index.html           #删除index.html 文件pod就会重启，因为探针会判定index.html是否存在，如果不存在，则会重新启动pod，那么index.html文件还会继续生成
kubectl describe pods liveness-httpget-pod        #可以看到pod的整体运行状态






以后创建pod配置清单必须要做 livenessProbe 和 readinessProbe
解释：
在创建新pod之前已然有两个pod正在运行，并且导出的端点servic通过pod标签被关联着，如果新创建一个pod则会立刻被service关联，pod创建之后默认是立刻进行探测，
这时主容器内的服务很可能没有初始化完成，探针发现没有服务，就会将pod资源重启，而导致不能正常提供服务，所以每次创建一个新的pod我们都要做就绪性探测




#根据 readiness-httpGet 进行探测

cp  liveness-httpget.yaml  readiness-httpget.yaml
vim readiness-httpget.yaml

apiVersion: v1
kind: Pod
metadata:
   name: readiness-httpget-pod
   namespace: default
spec:
  containers:
  - name: readiness-httpget-container
    image: ikubernetes/myapp:v1
    imagePullPolicy: IfNotPresent
    ports:
    - name: http
      containerPort: 80
    readinessProbe:
      httpGet:
        port: http
        path: /index.html
      initialDelaySeconds: 1
      periodSeconds: 3

kubectl create -f readiness-httpget.yaml
kubectl get pods
kubectl exec -it readiness-httpget-pod -- /bin/sh
rm -rf /usr/share/nginx/html/index.html

kubectl get pods                                        #此时发现pod已处于就绪状态，并没有提供服务，因为配置清单判定的文件不存在了，所有手动创建一个文件
readiness-httpget-pod         0/1     Running   0          3m2s
echo "hi" >> /usr/share/nginx/html/index.html 
kubectl get pods                                        #发现指定文件存在立马提供服务
kubectl describe pods readiness







#生命周期的另外一种行为（启动后钩子和终止前钩子）


vim poststart-pod.yaml
apiVersion: v1
kind: Pod
metadata:
    name: poststart-pod
    namespace: default
spec:
  containers:
  - name: busybox-http
    image: busybox:latest
    imagePullPolicy: IfNotPresent
    lifecycle:
      postStart:
        exec:
          command: ["/bin/sh","-c","touch /tmp/index.html;echo hi >> /tmp/index.html"]
    #command: ["/bin/httpd","-f","-h /tmp"]

