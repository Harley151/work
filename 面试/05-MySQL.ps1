存储引擎：
1.innoDB：
    innoDB他的特点就是支持事务，具有事务提交、回滚、崩溃恢复等机制
优点：
    1、支持主键外键，具有安全的约束性，主键是唯一的聚集索引，和数据存放在一起，效率高，可以有非聚集索引，非聚集索引单独存放
    2、对于死锁情况，innoDB会将持有最少的事务回滚，支持分区、表空间、类似于Oracle；
缺点：
    1、占用磁盘较多，占用内存较多（缓存），读效率慢于MyISAM，不存储总行数
生产场景：
业务需要事务的支持；
行级锁定对高并发有很好的适应能力；
业务数据更新较为频繁的场景，如微博，论坛等；
业务数据一致性要求较高，比如银行业务；
MySQL占用硬件设备内存较大，利用InnoDB较好的缓存能力来提高内存利用率；



2.MyISAM：MyISAM管理非事务表。它提供高速存储和检索，以及全文搜索能力，在mysql 5.5版本之前的默认的存储引擎
优点：
    1、查询访问较快它可以支持多种存储方式：如静态表，动态表，压缩表以及存储总行数等；
    2、通过key_buffer_size参数来设置设置缓存索引，提高访问的性能，减少磁盘I/O的压力；
缺点：
    1、写入效率慢，没有事务的概念，数据恢复起来比较困难；
    2、数据在读取或写入过程中会阻塞用户对数据的读取和写入；
生产场景：
    1、公司业务不需要事务的支持；
    2、对单方面的读取数据的需求较大，或者单方面写入数据的需求较多，不适合双方面；




Sql语句分类：
DDL：数据定义语言，对数据库中的对象database，table进行管理，而create、alter、drop是用来创建数据库中的各种对象，例如：库、表、视图、 索引
DML：数据操纵语言，对数据库中的数据进行一些简单操作，用来查询、插入、删除、修改数据库中的数据，如select（查询输出）、insert（插值）、update（更新）、delete（删除数据内容）；
DCL：数据控制语言用来授予或回收访问数据库的某种特权，并控制数据库操纵事务发生的时间及效果，对数据库实行监视等如commit、rollback、revoke；
DQL (Data Query Language)数据查询语言：
数据查询语言DQL基本结构是由select子句，from子句，where子句组成的查询块





select 语句用法：
输出最大薪资：max
输出最小薪资：min
输出平均薪资：avg
输出大于等于平均指的数：“>=” 或者 “！”（取非）
按照小到大排序：order by 列名 asc       order by默认是生序进行排列，第一列最小值，最后一列最大值
按照大到小排序：order by 列名 desc
求和值：sum
别名：（输出）



条件查询：
找出工资不等于3000的？
select ename,sal from emp where sal <> 3000；
select ename,sal from emp where sal != 3000；
找出工资在1100和3000之间的员工，包括1100和3000？
select ename,sal from emp where sal >= 1100 and sal <=3000;
select ename,sal from emp where sal between 1100 and 3000;   // between. . . and...  是闭区

找出工作岗位是MANAGER和SALESMAN的员工？
select ename,job from emp where job = 'MANAGER' or job = 'SALESMAN';            # where 定位中的 or

模糊查询：
找出名字当中含有0的？
（在模糊查询当中，必须掌握两个特殊的符号，一个是%，一个是 _  ）
%代表任意多个字符，_代表任意1个字符。
select ename from emp where ename like '%0%' ；	


group by : 按 照某个字段或者某些字段进行分组。
having : 	having是对 分组之后的数据进行再次过滤。
having是group by 的搭档，只有group by 出现的时候才能进行having过滤，having的作用只是分完组之后的数据进行过滤


update 库.表set 要修改的新列=新值 where 定位主键原列名=原值;		改列值
alter table 库.表 add （新列名 新类型）;				加列
alter table 库.表 drop 	原列名;						删列
alter table 库.表 change 原列名 新列名 新类型;		改列改类型
alter table 库.表 modify  原列名 新类型;				直接该类型
alter database 库 default charset utf8;				更改库信息
delete from 库.表 where 列名=”数值”;					删列值


begin;			##开始事务
commit;			##提交事务
rollback;		##事务回滚




MySQL主服务所更新的数据操作都会记录在binary log 二进制日志内，主从之间有一个实时信号，只要主库更新了，slave从库会自动激活I/O线程实时同步，
如果没有检测到数据更新，它会自动睡眠等待master产生新的日志操作，主库的数据一旦更新，那么我们的从库会生成两个线程，一个是I/O线程，一个是SQL线程，
那么I/O线程会去请求主库 的binlog日志，并将得到的binlog日志写入到relay log（中继日志） 文件中，而主库会生成一个 log dump 线程，用来给从库 i/o线程
传binlog，相当于是两个日志进行同步，其中中继日志文件是存放在OS（操作）缓存中的，开销比较小，写入到中继日志之后，SQL 线程会读取relay log文件中的日志，
并解析成具体操作，来实现主从的操作一致，而最终数据一致复制过程中，Slave从库中的数据复制是串行化的，并行操作无法在Slave上实现，也就是说master上的并行更新操作不能在slave上并行操作


复制类型：
1、基于语句的复制：主库上执行的sql语句，与从库执行的语句一样，mysql默认选用语句的复制方式效率比较高，这种复制方式也叫逻辑复制（logical replication）
2、基于行的复制：把改变的内容复制过去，而不是把命令重新执行一遍；
3、混合类型的复制：也是采用基于语句的方式复制，一旦发现基于语句无法精确复制时，就会采用行复制；

主从复制方式：
基于二进制文件：二进制日志文件；
基于GTID方式：5.6版本开启的新型复制方式，被称之为全局事务标示符




通过MHA这款高可用软件可以实现MySQL可用性环境下的故障切换以及主从切换最终保证业务的高可用。MySQL故障切换过程中能做到0~30秒之内自动完成数据库的故障切换操作，
而故障切换的时间我们是可以设置的，比如两秒钟，在切换的过程中，MHA会找到同步效率最高slave从库去代理主库，能够在一定程度上保证数据的一致性，从而达到真正意义上的高可用。
MHA是由两部分构成，一个是 MHA Manager（管理节点）和MHA Node（数据检测节点）


MHA工作流程：
首先MHA会去保存宕机崩溃的master二进制日志事件（binlog events），能够最大程度的保证数据不丢失，那么MHA Node会识别一个slave主机中的中继日志最新，
并让所有的slave从库的日志与最新的中继日志进行同步，然后同步master主机中保存的二进制日志事件，完成同步之后就指认中继日志最新的从库成为新主master，
使其他的slave重新指认此台新master主机进行复制