#!/usr/bin/env python3
from re import I
from telnetlib import IP
from tkinter.messagebox import NO
import paramiko
import time
import ast
import sys


# ==========================
# - FileName:      # remote
# - Created:       #2022/09/21
# - CreateTime:    #ZhangHaile
# - Email:         #15156744727@126.com
# - Region:        #China HangZhou
# - Description:   #远程主机执行shell命令
# ==========================


class SSH_Executive():
    '''获取linux服务器ip'''

    def __init__(self, hostname, port, username, password, cmds, nums):
        '''

        :param hostname: linux主机的ip
        :param port: linux主机的端口
        :param username: linux主机登录用户名
        :param password: linux主机登录密码
        :param cmds: 需要执行的linux命令
        :param nums: 传循环的值
        '''
        self.ip = hostname
        self.port = port
        self.user = username
        self.password = password
        self.cmds = cmds
        self.nums = nums
        try:
            # 实例化客户端
            self.client = paramiko.SSHClient()
            # 保存服务器的主机名和密钥信息
            self.client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            # 连接服务端，进行身份验证
            self.client.connect(self.ip, self.port, self.user, self.password, timeout=10,allow_agent=False)

            # 获取当前时间
            times = time.strftime('%H:%M:%S', time.localtime(time.time()))
            print("[{}] {} \33[0;32m[SUCCEED]\33[0m \33[0;35m{}\33[0m".format(self.nums, times, self.ip))
        except Exception as e:
            # raise e
            print("连接失败，错误是{}".format(e))
            raise e

    def excute_command(self):
        '''执行命令'''
        # todo stdin是标准输入文件，stdout是标准输出文件，stderr标准出错文件，应用在输出的重新定位上。
        self.stdin, self.stdout, self.stderr = self.client.exec_command(self.cmds, get_pty=True)
        print(self.stdout.read().decode('utf-8'), end='')

    def __del__(self):
        '''关闭连接'''
        self.client.close()
        # print("连接关闭...")


if __name__ == '__main__':
    # 获取要远程的IP
    strs = sys.argv  # sys.argv 接受脚本外的参数
    if len(strs) == 1:
        print("请在 remote 后面添加要执行的命令!")
        sys.exit()
    elif strs[1] == "-i":
        files = strs[2]
    else:
        files = "/etc/remote/hosts.conf"

    Host = None
    for i in strs:
        if i == "-h":
            Host = strs[-2]
        
    # k = 主机 ，v = 密码
    try:
        with open(files, 'r', encoding='utf-8') as file:
            Iplist = []
            lines = file.readlines()
            if Host is None:
                for line in lines:
                    a = line.strip()
                    Iplist.append(a)
            else:
                for line in lines:
                    a = line.strip()
                    if a.find(Host) == 0:
                        # 与文件内的IP精准对比
                        Newip = a.split(' ')
                        if Host == Newip[0]:
                            Iplist.append(a)
                if Iplist == []:
                    print("\33[0;31mError {} does is not in file\33[0m".format(Host))
    except FileNotFoundError:
        print('\33[0;32m1. 通过配置 "/etc/remote/hosts.conf" 文件执行命令如下:\33[0m')
        print('--> remote "ls"')
        print()
        print('\33[0;32m2. 通过 -i 选项指定自定义文件,执行命令如下:\33[0m')
        print('--> remote -i "/root/iplist.txt" "ls"')
        print()
        print('\33[0;32m3. 通过 -h 指定IP执行(前提是文件内已经有此IP),执行命令如下:\33[0m')
        print('--> remote -h "Your IP" "ls"')
        sys.exit()


    def Linux(command):
        num = 1
        for i in range(len(Iplist)):
            sas = Iplist[i].split(' ')
            Host = sas[0]
            Port = sas[1]
            User = sas[2]
            Pass = sas[3]
            linux = SSH_Executive(Host, int(Port), User, Pass, command, num)
            linux.excute_command()
            num += 1


    # 执行 shell命令
    # Linux('cat /etc/redhat-release')

    # 调用函数接受外部参数执行命令
    Linux(strs[-1])
    print('')
