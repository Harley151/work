K8S的访问控制：

API server作为kubernetes集群系统的网关，是访问及管理资源对象的唯一入口，而其他所有的组件及kubectl命令都要经由此网关进行集群的访问和管理。
而各组件及客户端每一次的访问请求都要有api server进行合法性校验，包括身份鉴别、操作权限验证等。所有的检查通过之后才能访问或存入数据于后端的etcd中。


（1）用户账号和用户组

 客户端访问API服务的途径通常有三种分别是kubectl、客户端库、REST接口，而执行此类请求的主体通常有两类分别是常规用户（User Account）和服务账号（Service Account）。

①User Account：
一般是独立于kubernetes之外的其他服务管理的用户账号，如管理员分发的秘钥、keystone一类的用户  存储等。
Kubernetes中不存在标识此类用户账户的对象，因此，不能被直接添加进kubernetes系统中。该账号通常用于复杂的业务逻辑管控，它作用于系统全局，故其名称必须全局唯一。

②Service Account：
是由kubernetes API管理的账号，用于为Pod中的服务进程在访问Kubernetes API时提供身份标识。
该账户需要绑定于特定的名称空间，他们由API server创建或，附带着一组存储为secret的用于访问api的凭证。Service Account隶属于名称空间，仅用于实现某些特定的操作任务。
用户组是用户账号的逻辑集合，本身并无操作权限，但附加于组上的权限可由其内部的所有用户继承，以实现高效的授权管理机制。Kubernetes中附带着一些内建的用于特殊目的的组。




（2）认证、授权与准入控制

认证：
Kubernetes使用身份认证插件对API请求进行身份认证时支持的认证方式包括客户端认证、承载令牌认证（bearer tokens）、身份验证代理（authingenticating proxy）及http base认证等。
API Server同时支持多种认证机制，但至少分别为Service Accoun和User Account各自启用一个认证插件。
API server支持的具体认证方式有：
①X509客户端证书认证
②静态令牌文件（Static Token File）：由kube-apiserver的命令行工具—token-auth-file加载
③引导令牌（Bootstrap Tokens）：动态管理承载令牌进行身份认证的方式，常用于简化新建kubernetes集群的节点认证过程
④静态密码文件
⑤服务账户令牌
⑥OpenID连接令牌
⑦Webhook令牌
⑧认证代理
⑨Keystone密码
⑩匿名请求

授权:
身份认证后具体的操作请求还需要转交给授权插件进行许可权限检查。
API server主要支持使用四类内建的授权插件来定义用户的操作权限：
①Node：基于pod资源的目标调度节点来实现对kubelet的访问控制
②ABAC（attribute-based access control）：基于属性的访问控制
③RBAC（role-based access control）：基于角色的访问控制
④Webhook：基于HTTP回调机制通过外部REST服务检查确认用户授权的访问控制
  
准入控制:
准入控制器用于在客户端请求经过身份验证和授权检查之后但在对象持久化存储etcd之前拦截请求，用于实现在资源的创建、更新和删除操作期间强制执行对象的语义验证等功能，API Server内置的常用准入控制器有：
①AlwaysAdmit：允许所有的请求
②AlwaysDeny：拒绝所有的请求，仅用于测试
③AlwaysPullImages：总是下载镜像，常用于多租户环境中
④NamespaceLifecycle：拒绝与不存在的名称空间中创建资源
⑤LimitRange：可用资源的范围界定
⑥ServiceAccount：用于实现Service Account管控机制的自动化




任何用户想要对k8s请求资源内容都需要经历一下步骤：
用户想要操作k8s中某一资源，首先通过apiserver接受请求，然后得到认证（用户要有访问k8s正确的账号，
用户认证通过只能代表是当前的合法用户），第二步就是授权检查（检查是否拥有删除对应资源的权限），
第三步是准入控制（要关联不同资源的操作手段）
因此它的认证、授权、准入控制各自都通过插件的方式，可以由用户选择经由什么插件来完成何种控制裸机

1、以认证为例：k8s支持两种常用的认证方式
k8s提供的是resetful风格的接口，它所有的服务都是以HTTP 协议提供的，因此认证信息只能通过HTTP的认证守护
（1）、token令牌（服务端需要创建用户的token令牌，这种token是与用户共享的秘钥，而用户拿到这个令牌就能得到认证）
（2）、ssl私钥、秘钥（双方都需要做双向证书认证，认证完之后就可以实现ssl回话加密通信）

2、常见的授权检查方式:
node
RBAC(目前的主流使用方案)
webhook...


3、准入控制: 用来定义对应授权检查完成以后的后续的其他安全检查操作，了解即可


用户账号包含的信息：

客户端-->API server
user: username , id
group:
extra:

Request path:
用户会拿着某个账号请求特定的资源（获取所有的pod资源）是通过某个特定的API 资源获取的，也就是通过URL访问某个资源
比如通过账号访问一个控制器：
    http://172.21.40.161:6443/apis(访问入口)/apps(API组)/v1(版本)/namespaces/default(名称空间的名字)/deployments/myapp-deploy
    这就可以对这个URL进行增删改查操作,apiserver 工作在6443端口上

通过curl 访问k8s资源：
kubectl proxy --port=8080           # 首先启动一个代理，如果是远程要确保kubectl和需要远程的master做认证，在本机的话就不用了


curl http://localhost:8080/api/v1/namespaces        # 打开另外一个终端，访问的是某一种对象的集合
curl http://localhost:8080/apis/apps/v1/namespaces/kube-system/deployments

HTTP request verb(请求动作):
    get,post,put,delete
API request verb:
    通过上面HTTP request verb，转化为 API 请求
    get,list,create,update,patch,watch,proxy,delete(这就是经常使用的命令)




service Account：

kubectl describe pods myapp-deploy-5b6987f576-5sts6| grep Volumes -A 3
Volumes:
  default-token-xj5f7:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-xj5f7
每个pod资源都有一个默认的存储卷，存储卷下放的也是默认的存储卷名称 default-token-xj5f7,
这个就是 pod service Account认证时需要的认证信息，也是通过secret类型去定义的，通过secret来连接apiserver ，并完成认证。
所有pod都可以连入apiserver是通过默认的secret，token认证信息

kubectl get secret -n ingress-nginx| grep default
default-token-2gwpf                   kubernetes.io/service-account-token   3      5d4h




# 创建一个服务账号
kubectl create serviceaccount mysa -o yaml --dry-run            # -o yaml 显示yaml 格式的文件，--dry-run 不真正执行

kubectl create serviceaccount admin         # 创建admin账号
kubectl get sa                              # 查看已有账号
kubectl describe sa admin                   # 发现创建账号是也自动生成了一个token
kubectl get secret                          # 发现创建了一个admin-token，用来连入apiserver的认证信息
NAME                    TYPE                                  DATA   AGE
admin-token-ddbjm       kubernetes.io/service-account-token   3      3m45s


vim pod-sa-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-sa-demo
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
  serviceAccount: admin       # 表明使用自定义的sa账号
kubectl apply -f pod-sa-demo.yaml 
kubectl describe pods pod-sa-demo | grep Volumes -A 3       # 发现认证信息的名称改变账号的名称
Volumes:
  admin-token-ddbjm:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  admin-token-ddbjm


kubectl config view| grep " context" -A 4
- context:
    cluster: kubernetes       # 这个集群
    user: kubernetes-admin    # 被这个账号访问
  name: kubernetes-admin@kubernetes   # 当前用的context
current-context: kubernetes-admin@kubernetes

context：以列表的形式展现，表示用哪个账号访问哪个集群都有对应关系，并且当前节点有多个context，必须选择一个正在使用的




kubectl config --help
  current-context 显示 current_context
  delete-cluster  删除 kubeconfig 文件中指定的集群
  delete-context  删除 kubeconfig 文件中指定的 context
  delete-user     Delete the specified user from the kubeconfig
  get-clusters    显示 kubeconfig 文件中定义的集群
  get-contexts    描述一个或多个 contexts
  get-users       Display users defined in the kubeconfig
  rename-context  Renames a context from the kubeconfig file.
  set             设置 kubeconfig 文件中的一个单个值
  set-cluster     设置 kubeconfig 文件中的一个集群条目
  set-context     设置 kubeconfig 文件中的一个 context 条目
  set-credentials 设置 kubeconfig 文件中的一个用户条目
  unset           取消设置 kubeconfig 文件中的一个单个值
  use-context     设置 kubeconfig 文件中的当前上下文
  view            显示合并的 kubeconfig 配置或一个指定的 kubeconfig 文件



生成证书私钥：
cd /etc/kubernetes/pki
(umask 077;openssl  genrsa -out magedu.key 2048)
openssl  req -new -key magedu.key -out magedu.csr -subj "/CN=magedu"        # 证书签署请求
openssl x509 -req -in magedu.csr -CA ./ca.crt  -CAkey ./ca.key  -CAcreateserial -out magedu.crt -days 365     # 证书签署
openssl  x509 -in  magedu.crt -text -noout          # 文本输出认证信息


# 创建了一个user
kubectl config set-credentials magedu --client-certificate=./magedu.crt --client-key=./magedu.key --embed-certs=true  
# 设置上下文，让magedu用户也能访问集群
kubectl config set-context magedu@kubernetes --cluster=kubernetes --user=magedu

kubectl config view| grep " context" -A 4
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
- context:
    cluster: kubernetes
    user: magedu
  name: magedu@kubernetes
current-context: kubernetes-admin@kubernetes

# 切换到magedu账号
kubectl config use-context magedu@kubernetes

kubectl get pods      # 获取内容，下面表示没有权限获取资源
Error from server (Forbidden): pods is forbidden: User "magedu" cannot list resource "pods" in API group "" in the namespace "default"
kubectl config use-context  kubernetes-admin@kubernetes     # 切换为管理员

kubectl config set-cluster mycluster --kubeconfig=/tmp/test.conf --server="https://172.21.40.161:6443" --certificate-authority=/etc/kubernetes/pki/ca.crt  --embed-certs=true
kubectl config view --kubeconfig=/tmp/test.conf 
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://172.21.40.161:6443
  name: mycluster
contexts: null
current-context: ""
kind: Config
preferences: {}
users: null
这就是如何定义当前API server 签署的客户端证书，并且创建新的用户账号



