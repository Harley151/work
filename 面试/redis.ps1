redis是一个可持久化的key-value类型的非关系型缓存数据库，
它支持存储的value类型相对更多，包括string(字符串)、list(列表)、set(集合)（具有唯一性）、zset(sorted set --有序集合)和hashs（哈希类型）。
作用：
Redis的所有数据都是保存在内存中，如果没有配置持久化，redis重启后数据就全丢失了，
于是需要开启redis的持久化功能，将数据保存到磁盘上，当redis重启后，可以从磁盘中恢复数据。
那么不定期的通过异步方式保存到磁盘上（半持久化模式RDB）；也可以把每一次数据变化都写入到
一个append only file里面（全持久化模式AOF）。 如若在服务器中开启了两种持久化的方式，
两种持久化方式可以同时使用，但是在数据恢复时默认用AOF持久化的文件来恢复数据；

实现方式：
RDB持久化：将Reids在内存中的数据库记录定时dump到磁盘上，类似于快照功能。
AOF持久化：append only file--原理是将Reids的操作以追加的方式写入日志文件，近似实时性。
RDB持久化的两种形式
1、自动持久化
2、手动持久化


应用场景：
1). 愿意牺牲一些性能（选择AOF）；
2). 换取更高的缓存一致性（选择AOF）；
3). 写操作频繁的时候，不启用备份来换取更高的性能，待手动运行bgsave的时候，再做备份（RDB）；
4). 为了数据有更高的安全性，选AOF
5). 为了获得更高的性能，选择RDB


Reids6种淘汰策略：
noeviction: 不删除策略, 达到最大内存限制时, 如果需要更多内存, 直接返回错误信息。大多数写命令都会导致占用更多的内存(有极少数会例外。
allkeys-lru:所有key通用; 优先删除最近最少使用(less recently used ,LRU) 的 key。
volatile-lru:只限于设置了 expire 的部分; 优先删除最近最少使用(less recently used ,LRU) 的 key。
allkeys-random:所有key通用; 随机删除一部分 key。
volatile-random: 只限于设置了 expire 的部分; 随机删除一部分 key。
volatile-ttl: 只限于设置了 expire 的部分; 优先删除剩余时间(time to live,TTL) 短的key。




同步类型：全量同步、增量同步、部分同步（差异同步、偏移量同步）
sentinel哨兵会不断监视整个集群的每个redis服务，在一定的时间内如果发现master不做以回应表示master服务宕机，就会重新开始选举，根据配置的参数进行切换
主观下线（Subjectively Down， 简称 SDOWN）
客观下线（Objectively Down， 简称 ODOWN）


如果多个Slave断线了，需要重启的时候，因为只要Slave启动，就会发送sync请求和主机全量同步，当多个同时出现的时候，可能会导致Master IO剧增导致宕机。
建议开启master主服务器的持久化功能，避免出现master重启后，数据无法恢复；
