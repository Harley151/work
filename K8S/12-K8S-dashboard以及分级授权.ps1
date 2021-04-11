
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml
kubectl patch svc kubernetes-dashboard -p '{"spec":{"type":"NodePort"}}' -n kubernetes-dashboard            # 通过service的NodePort端口，使外部集群被访问到

浏览器访问：
https://172.21.40.162:32048/#/login         # 如果是私密链接，输入thisisunsafe 打开

两种认证方式：
1、kubeconfig:  对于访问 dashboard 时候的使用 kubeconfig 文件如brand.kubeconfig 必须追到 token 字段，否则认证不会通过

2、token:   

集群空间admin_token认证方式:

# 创建 serviceaccount 用户
kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard

# 将集群角色绑定在kubernetes-dashboard名称空间下的dashboard-admin用户
kubectl create clusterrolebinding dashboard-cluster-admin --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:dashboard-admin
目前dashboard-admin用户能够访问到整个集群内部的资源

kubectl get secret -n kubernetes-dashboard
dashboard-admin-token-cchp6                     # 这个是dashboard-admin用户绑定之后自动生产的token信息

# 获取认证令牌
kubectl  describe secret dashboard-admin-token-cchp6 -n kubernetes-dashboard            # 发现当前集群的serviceaccount 用户的认证令牌

# 输入token信息访问dashbord


名称空间admin_token认证方式：

#  创建默认名称空间的 serviceaccount 用户
kubectl create serviceaccount def-ns-admin -n default           # default 不指认也可以

# 绑定在 clusterrole 名称成空间的admin角色上，只对default空间的用户有效
kubectl create rolebinding def-ns-admin --clusterrole=admin --serviceaccount=default:def-ns-admin
kubectl get secret
kubectl describe secret def-ns-admin-token-cf2lv                # 获取到的token







# 基于用户认证

kubectl config set-cluster kubernetes --kubeconfig=/root/def-ns-admin.conf --server="https://172.21.40.161:6443" \
--certificate-authority=/etc/kubernetes/pki/ca.crt  --embed-certs=true

kubectl config view --kubeconfig=/root/def-ns-admin.conf
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://172.21.40.161:6443
  name: kubernetes
contexts: null
current-context: ""
kind: Config
preferences: {}
users: null


# 获取token
kubectl  get secret
DEF_NS_ADMIN_TOKEN=$(kubectl  get secret def-ns-admin-token-cf2lv -o jsonpath={.data.token} | base64 -d)       # 获取token进行解码

# 创建一个用户并将token加入认证文件
kubectl config set-credentials def-ns-admin --token=$DEF_NS_ADMIN_TOKEN --kubeconfig=/root/def-ns-admin.conf  
kubectl config set-context def-ns-admin@kubernetes --cluster=kubernetes --user=def-ns-admin --kubeconfig=/root/def-ns-admin.conf

kubeconfig : 把serviceAccount 的token封装为kubeconfig文件

生成kubeconfig 文件
kubectl config  set-cluster
kubectl config  set-credentials NAME(用户名) --token=$KUBE_TOKEN
kubectl config  set-context
kubectl config  use-context

