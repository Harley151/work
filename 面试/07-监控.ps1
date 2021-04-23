Zabbix：
Zabbix是一个基于WEB界面企业级开源分布式监控解决方案
被监控端：主机通过安装agent方式采集数据，网络设备通过SNMP方式采集数据
Server端：通过收集SNMP和agent发送的数据，写入MySQL数据库，再通过php+nginx在web前端展示

客户端守护进程：
zabbix的工具，zabbix_get获取客户端的内容的方式来做故障排查。


这里agentd收集数据分为主动和被动两种模式：
    主动：agent请求server获取主动的监控项列表，并主动将监控项内需要检测的数据提交给server/proxy
    被动：server向agent请求获取监控项的数据，agent返回数据。
Server=             #被动模式所接受的服务器Ip，此处是为了启用监听10050端口，从而监测到zabbix主机的zbx状态。
StartAgents=1       #默认启动的zabbix_agentd pre-fork进程，如果为0的话表示停用被动模式
ServerActive=       #主动模式的服务器IP