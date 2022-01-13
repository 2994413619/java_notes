# 一、常识

## 1、内存和硬盘对比

磁盘：

- 寻址：毫秒ms
- 硬盘带宽：G/M

内存：

- 寻址：纳秒ns
- 硬盘带宽：很大

秒>毫秒>微秒>纳秒

磁盘比内存在寻址上慢了10W倍

## 2、I/O buffer的成本问题

磁盘划分：从磁盘到磁道，到扇区，再到每个扇区512byte，划分成一个一个的区域后，索引变大。

格式化的时候，会有个对其选择，一般选4k，选择后，通过操作系统读数据时，无论你读多少数据，一次都是读取4K



**问题**：java读取文件，文件变大，速度变慢，为什么？

硬盘I/O成为瓶颈



## 3、mysql的存储

mysql里也是使用文件存储的，取数据的时候也是按data page（4K）取的。索引就是把“相近”的数据存一起，B+ Tree的树干是存在内存中的。索引目的就是减少IO次数。

**问题**：数据表很大的时候，性能下降？

如果表有索引的话

- 增删改变慢，因为要维护索引；
- 查询速度分情况
  - 1个或少量查询依然很快
  - 并发的的时候会受硬盘带宽影响速度



## 4、为何使用redis

**常识**：数据在内存和磁盘体积不一样

SAP HANA 是内存级别的关系型数据库，收费的。那么买不起内存级别的关系型数据库怎么办，这时候可以用缓存。（memcached、redis）

**memcached、redis的一点区别**：

- memcached的value没有类型的概念
- redis的value有String、hashes、Lists、Sets、sorted sets

**问题**：为什么redis要有数据类型，我直接使用json不就好了？

场景：client要取value中的某个值，如果用json，那么要把value一下全取出来返回client，并且再写代码自己解析。

使用redis的数据类型的好处：redis提供了对应数据结构的方法，我们不需要自己写代码解析，并且不需要把整个value返回给client，减少了网络IO。

用大数据里词汇来说：计算向数据移动



## 5、官网

[数据库引擎排名、介绍](https://db-engines.com/en/)

[中文官网](http://www.redis.cn/)             

[官网](http://redis.io)



# 二、下载安装

可以使用wget来下载

```shell
yum install wget

wget https://download.redis.io/releases/redis-6.2.6.tar.gz

# 进入目录执行make,make会找本目录下的MakeFile文件，成功后src下会生成可执行文件
make

# 执行make后报错 缺少cc（c语言环境）
# g是单词“全局”的缩写
yum install gcc

# 清理之前make报错的后的垃圾文件, 然后再make
make distclean

# 启动
./redis-server

# 安装到指定目录 执行完后到该目录下，可以看到只有执行文件，就没有和源码混在一起
make install PREFIX=/opt/yuchao/redis6

#添加redis的环境变量
vi /etc/profile
# 添加一行
export REDIS_HOME=/opt/yuchao/redis6
export PATH=$PATH:$REDIS_HOME/bin

#更新配置
source /etc/profile

#查看path
echo $PATH

# 把它变成一个服务 utils下有个脚本，执行即可
cd utils
./install_server.sh
# 执行完后看输出的信息，写了在/etc/init.d/下创建了redis_6379的脚本。并启动了服务
#查看服务状态
service redis_6379 status
```

下载下来解压后是c语言源码，需要安装，安装方式其实在README.MD中有。以上操作README.MD中都有

一个机器上可以跑多个redis，用port区分，并且执行utils/install server.sh是可以配置



# 三、原理

## 1、epoll

windows有AIO，linux没有AIO，epoll也是NIO

```shell
#查看文件描述符
ps -ef | grep reids
cd /proc/进程id/fd
ll
```

BIO -> NIO（同步非阻塞） -> 多路复用NIO（减少用户态和内核态切换） -> AIO

**IO演化**:



<img src="img\IO.png" />



## 2、零拷贝



<img src="img\zero_copy.png" />

## 3、redis原理

redis操作数据是单进程、单线程、单实例（他可能还有其他的线程）；那么并发，请求很多的时候，是如何变得很快的？

使用了epoll。



Nginx也使用了epoll

JVM：一个线程的成本：1MB（栈），可以调低

（1）线程多了调度成本CPU良妃

（2）内存消耗大

# 四、redis使用

- redis默认有16个库，从0-15
- redis的方法是和value的类型绑定的，当客户端调一个方法的时候，Redis会使用type命令查看value的类型，发现类型不一致，会直接返回错误。这也是Redis的一个优化点
- 使用的命令是哪个分组的，value的类型就是哪个
- key是一个object，包含
  - value的type
  - encoding
  - value的长度
- redis对cpu亲和性的支持



## 1、通用命令

### （1）redis-cli

```shell
# 连接redis
redis-cli
# 如果linux上启了多个redis，可以通过端口号连接不同的
redis-cli -p 端口号
#直接连接redis的8号库
redis-cli -p 端口号 -n 8
#查看redis-cli具体参数
redis-cli -h
#在这种状态下，会把get获取的16进制xshell的编码显示；比如显示“中”，而不是16进制
redis-cli --raw
```

### （2）help

```shell
#连接redis后，通过help命令来查学习
help
#输入 help 和字母，然后按tab键，redis会给你补全命令
help SE 
#查看命令分组@开头；查看generic命令
help @generic
help @string
help @hash
```

### （3）object

命令object encoding k1结果：

- int
- embstr
- raw

类型改变：

- append后会变成raw
- incr后会变成int

```shell
#查看object命令
object help
#object后面可以接一个子命令 如果k1为99，则返回int,
object encoding k1
```

### （4）select

```shell
#连接redis后，也可以通过select 命令来切换库
select 8
```

### （5）keys

```shell
# 查询 匹配符合的key  keys pattern
keys *
```

### （6）flush

```shell
# 清库 运维一般会把这个命令重命名
FLUSHDB
FLUSHALL
```

### （7）type

```shell
#查看value的方法
type k1
```

## 2、概念

### （1）二进制安全

二进制安全（只有字节流，没有字符流；把内容变成字节存入redis中）

- 执行incr时，先取出转换成int，再加一，然后把encoding改为int；下一次就可以直接加。
- set k1 中（strlen k1  显示的是3；原因是xshell的编码设置的是UTF-8；改成GBK的话，长度就是2个字节）

```shell
#取出的k1长度，取决于xshell的编码；在UTF-8中“中”是3个字符，在GBK中是2个字符
set k1 中
setlen k1
#显示的是16进制（超过了ASCII码）
get k1
```

### （2）字符集

字符集说的是ascii，用一个字节表示一个字符，八位： 0xxxxxxx（开头以为一定是0 ）；其他一般叫扩展字符集，复用ASCII有的编码，扩展其他字符

**例子**：

读出一个字节，是0开头可以直接转为ascii对应的字符；如果是三个1，表示还需要读出两个字节，然后去掉开头的三个1，去找对应字符集的字符。

## 3、String(byte)

### （1）字符串

命令：

- set
- get
- append
- setrange
- getrange
- strlen
- mset
- mget
- msetnx
- getset

```shell
#设置值 
#nx参数，表示key不存在的时候才能设置（分布式锁的时候用）
#xx参数，key存在的时候才可以设置
set key value [nx | xx]
#取值
get key

#批量设置
mset k1 a k2 b
#批量获取
mget k1 k2

#原子操作,有一个失败，全失败
msetnx k1 a k2 b
#追加
appen k1 " world"
#截取string
setrange k1 6 10
#正负索引
setrange k1 6 -1
#重下标6开始覆盖
setrange k1 6 'yuchao'
#获取长度
strlen k1

#set新值，get老值
getset k1 yyy
```

### （2）数值

- incr（抢购，秒杀，详情页，点赞，评论；规避并发下，对数据库的事务操作完全由redis内存代替操作）

```shell
#加一
incr k1
#加一个数
incrby k1 20

#减一
decr k1
#减一个数
decrby k1 20

#加小数
INCRBYFLOAT k1 0.5
```

### （3）bitmap

命令：

- setbit key offset value（offset是二进制位偏移量，不是二进制数组）
- bitcount key bit [start] [end]
- bitpos key bit [start] [end]（这里的start、end是字节的偏移量） 查询start到end中bit出现的第一个位置，具体看以下命令
- bitop operation destkey key [key ...]

数据结构：每一个字节有一套下标；每一位也有一套下标

<img src="img\bitmap_1.png" />

```shell
#--------------------------------------------- setbit操作
# 0100 0000
127.0.0.1:6379> setbit k1 1 1
0
127.0.0.1:6379> get k1
@
# 0100 0001
127.0.0.1:6379> setbit k1 7 1
0
127.0.0.1:6379> get k1
A
127.0.0.1:6379> strlen k1
1

# 0100 0001 0100 0000
127.0.0.1:6379> setbit k1 9 1
0
127.0.0.1:6379> strlen k1
2
127.0.0.1:6379> get k1
A@


#linux查看ascii
man ascii


#--------------------------------------------- bitpos查询
127.0.0.1:6379> bitpos k1 1 0 0
1
127.0.0.1:6379> bitpos k1 1 1 1
9

#--------------------------------------------- BITCOUNT统计
127.0.0.1:6379> BITCOUNT k1 0 1
3
127.0.0.1:6379> BITCOUNT k1 0 0
2
127.0.0.1:6379> BITCOUNT k1 1 1
1


#--------------------------------------------- bitop位运算
# k1:0100 0010			A
# k2:0100 0100			B
# andkey:0100 0000		@
# orkey:0100 0110		C
127.0.0.1:6379> setbit k1 1 1
0
127.0.0.1:6379> setbit k1 7 1
0
127.0.0.1:6379> get k1
A
127.0.0.1:6379> setbit k2 1 1
0
127.0.0.1:6379> setbit k2 6 1
0
127.0.0.1:6379> get k2
B
127.0.0.1:6379> bitop and andkey k1 k2
1
127.0.0.1:6379> get andkey
@
127.0.0.1:6379> bitop or orkey k1 k2
1
127.0.0.1:6379> get orkey
C

```

bitma使用场景：

（1）有用户系统，统计用户登录天数，且窗口随机（一位表示一天）

（2）登录送礼，用户有2亿，大库要备多少货（计算活跃用户，日期为key，用户id对应位；如果要计算3天内登录的，只要bitop or 最近三天的key，然后统计即可）

## 4、List

数据结构：



<img src="img\list_1.png" />

同向命令实现栈

反向命令实现队列

使用index操作，数组

阻塞，单薄队列（FIFO）

```shell
127.0.0.1:6379> lpush k1 a b c d e f
(integer) 6
127.0.0.1:6379> lpop k1
"f"
127.0.0.1:6379> lpop k1
"e"
127.0.0.1:6379> LRANGE k1 0 -1
1) "d"
2) "c"
3) "b"
4) "a"

#通过下标操作
127.0.0.1:6379> LINDEX k1 0
"d"
127.0.0.1:6379> LSET k1 0 dd
OK
127.0.0.1:6379> LINDEX k1 0
"dd"


# 从左删除两个a
127.0.0.1:6379> lpush k2 1 a 2 b 3 a 4 c 5 a 6 d
(integer) 12
127.0.0.1:6379> LRANGE k2 0 -1
 1) "d"
 2) "6"
 3) "a"
 4) "5"
 5) "c"
 6) "4"
 7) "a"
 8) "3"
 9) "b"
10) "2"
11) "a"
12) "1"
127.0.0.1:6379> LREM k2 2 a
(integer) 2
127.0.0.1:6379> LRANGE k2 0 -1
 1) "d"
 2) "6"
 3) "5"
 4) "c"
 5) "4"
 6) "3"
 7) "b"
 8) "2"
 9) "a"
10) "1"

# 在6的后面插入一个a
127.0.0.1:6379> LINSERT k2 after 6 a
(integer) 11
127.0.0.1:6379> LRANGE k2 0 -1
 1) "d"
 2) "6"
 3) "a"
 4) "5"
 5) "c"
 6) "4"
 7) "3"
 8) "b"
 9) "2"
10) "a"
11) "1"
# 在3的前面插入一个a
127.0.0.1:6379> LINSERT k2 before 3 a
(integer) 12
127.0.0.1:6379> LRANGE k2 0 -1
 1) "d"
 2) "6"
 3) "a"
 4) "5"
 5) "c"
 6) "4"
 7) "a"
 8) "3"
 9) "b"
10) "2"
11) "a"
12) "1"
#查询元素个数
127.0.0.1:6379> llen k2
(integer) 12

# 阻塞弹出 0-表示一致阻塞（阻塞时间）；list中无数据，会阻塞，知道有值push到list中
blpop k2 0

#去除开头和结尾的元素
127.0.0.1:6379> lpush k3 a b c d e f
(integer) 6
127.0.0.1:6379> lrange k3 0 -1
1) "f"
2) "e"
3) "d"
4) "c"
5) "b"
6) "a"
127.0.0.1:6379> ltrim k3 0 -1
OK
127.0.0.1:6379> lrange k3 0 -1
1) "f"
2) "e"
3) "d"
4) "c"
5) "b"
6) "a"
127.0.0.1:6379> lrange k3 2 -2
1) "d"
2) "c"
3) "b"
127.0.0.1:6379> lrange k3 0 -1
1) "f"
2) "e"
3) "d"
4) "c"
5) "b"
6) "a"
```

## 5、Hash

```shell
#存取
127.0.0.1:6379> hset sean name yc
(integer) 1
127.0.0.1:6379> hset sean age 18 address sz
(integer) 2
127.0.0.1:6379> hget sean name
"yc"
127.0.0.1:6379> hmget sean name age
1) "yc"
2) "18"
127.0.0.1:6379> hkeys sean
1) "name"
2) "age"
3) "address"
127.0.0.1:6379> hvals sean
1) "yc"
2) "18"
3) "sz"
127.0.0.1:6379> hgetall sean
1) "name"
2) "yc"
3) "age"
4) "18"
5) "address"
6) "sz"

#计算
127.0.0.1:6379> HINCRBYFLOAT sean age 0.5
"18.5"
127.0.0.1:6379> hget sean age
"18.5"
127.0.0.1:6379> HINCRBYFLOAT sean age -1
"17.5"
127.0.0.1:6379> hget sean age
"17.5"

```

使用场景：

- 商品详情
- 微博关注数、点赞数

## 6、Set

去重、无序

```shell
127.0.0.1:6379> sadd k1 tom jack peter tom xxoo
(integer) 4
127.0.0.1:6379> SMEMBERS k1
1) "xxoo"
2) "peter"
3) "jack"
4) "tom"
127.0.0.1:6379> srem k1 xxoo peter
(integer) 2
127.0.0.1:6379> SMEMBERS k1
1) "jack"
2) "tom"

#交集 并集 差集
#交集
127.0.0.1:6379> sadd k2 1 2 3 4 5
(integer) 5
127.0.0.1:6379> sadd k3 4 5 6 7 8
(integer) 5
#直接输出交集
127.0.0.1:6379> SINTER k2 k3
1) "4"
2) "5"
#把交集存到dest中
127.0.0.1:6379> SINTERSTORE dest k2 k3
(integer) 2
127.0.0.1:6379> SMEMBERS dest
1) "4"
2) "5"
#并集
127.0.0.1:6379> sunion k2 k3
1) "1"
2) "2"
3) "3"
4) "4"
5) "5"
6) "6"
7) "7"
8) "8"
#差集
127.0.0.1:6379> SDIFF k2 k3
1) "1"
2) "2"
3) "3"
127.0.0.1:6379> SDIFF k3 k2
1) "6"
2) "7"
3) "8"
#随机事件 
127.0.0.1:6379> sadd k4 tom peter tony jack xx oo ox xo
(integer) 8
127.0.0.1:6379> SRANDMEMBER k4 5 -5 10 -10 0 
```

**SRANDMEMBER**

正数：取出一个去重的结果集（不超过已有集合）

负数：取出一个带重复的结果集，一定满足你要的数量

0：不返回

**SPOP**：随机弹出一个元素



**使用场景**：

抽奖：

10个奖品

用户：<10  >10

中奖：是否重复

## 7、sorted_set

默认字典序排序，物理内存左小右大（按score）

具备集合操作（交、并、差）

```shell
127.0.0.1:6379> zadd k1 8 apple 2 banana 3 orange
(integer) 3
127.0.0.1:6379> ZRANGE k1 0 -1
1) "banana"
2) "orange"
3) "apple"
127.0.0.1:6379> ZRANGE k1 0 -1 withscores
1) "banana"
2) "2"
3) "orange"
4) "3"
5) "apple"
6) "8"
127.0.0.1:6379> ZRANGEBYSCORE k1  3 8
1) "orange"
2) "apple"
#倒序取出
127.0.0.1:6379> ZREVRANGE k1 0 -1 withscores
1) "apple"
2) "8"
3) "banana"
4) "4.5"
5) "orange"
6) "3"
#查score
127.0.0.1:6379> ZSCORE k1 apple
"8"
#查下标
127.0.0.1:6379> ZRANk k1 apple
(integer) 2
#计算——添加score
127.0.0.1:6379> ZINCRBY k1 2.5 banana
"4.5"
127.0.0.1:6379> ZRANGE k1 0 -1 withscores
1) "orange"
2) "3"
3) "banana"
4) "4.5"
5) "apple"
6) "8"
```

做结合操作的时候（交、并、差），有一个问题，就是当两个集合都有的元素取那个的score，这时候可以取min、max、sum（默认sum）

```shell
#默认
127.0.0.1:6379> zadd k2 80 tom 60 sean 70 baby
(integer) 3
127.0.0.1:6379> zadd k3 60 tom 100 sean 40 jack
(integer) 3
127.0.0.1:6379> ZUNIONSTORE unkey 2 k2 k3
(integer) 4
127.0.0.1:6379> ZRANGE unkey 0 -1 withscores
1) "jack"
2) "40"
3) "baby"
4) "70"
5) "tom"
6) "140"
7) "sean"
8) "160"

#设置权重 最后score等于 sum(原来的score * 权重)
127.0.0.1:6379> ZUNIONSTORE unkey1 2 k2 k3 weights 1 0.5
(integer) 4
127.0.0.1:6379> ZRANGE unkey1 0 -1 withscores
1) "jack"
2) "20"
3) "baby"
4) "70"
5) "sean"
6) "110"
7) "tom"
8) "110"

#取最大值
127.0.0.1:6379> ZUNIONSTORE unkey2 2 k2 k3 aggregate max
(integer) 4
127.0.0.1:6379> ZRANGE unkey2 0 -1 withscores
1) "jack"
2) "40"
3) "baby"
4) "70"
5) "tom"
6) "80"
7) "sean"
8) "100"

```

sorted_set底层实现：skip list（类平衡树）

**问题**：排序是怎么实现的？增删查改的速度？

在压测下，和其他数据结构比，使用调表的增删查改的平均效率是最高的

插入后，随机造层

# 五、redis进阶

## 1、管道（Pipelining）

如果机器上没有redis客户端，可以用nc命令连接redis进行操作。因为redis支持这种socket的连接

```shell
[root@iZwz91n56f8y4m7ta0i7xoZ ~]# nc localhost 6379
keys *
*6
$2
k2
$2
k1
$2
k3
$5
unkey
$6
unkey2
$6
unkey1
```

[管道](http://www.redis.cn/topics/pipelining.html)，可以把多个 命令一次性发给service，降低了我们的通信成本

使用：

```shell
[root@iZwz91n56f8y4m7ta0i7xoZ ~]# echo -e "set key2 99\n incr key2\n get key2" | nc localhost 6379
+OK
:100
$3
100
```

管道使用：[Redis从文件中批量插入数据](http://www.redis.cn/topics/batch-insert.html)

这里有个换行符（linux中和windows的换行符不一样，一个是\n，一个是\r\n）转码的问题

redis冷启动

## 2、发布订阅

查看命令：

```shell
127.0.0.1:6379> help @pubsub
```

发布订阅测试：

```shell
#开两个连接测试，一个用来发布，一个用来订阅
#发布
127.0.0.1:6379> publish ooxx hello
(integer) 0
127.0.0.1:6379> publish ooxx hello
(integer) 1
127.0.0.1:6379>


#订阅（可以有多个）	第一次并没有接受到消息（因为必须先有订阅，再发布才能收到）；
127.0.0.1:6379> SUBSCRIBE ooxx
Reading messages... (press Ctrl-C to quit)
1) "subscribe"
2) "ooxx"
3) (integer) 1
1) "message"
2) "ooxx"
3) "hello"
```

查看历史消息，思考比如微信要看历史消息，这个消息咋存，消息分类：

<img src="img\pubsub.png" />



图中的sorted set：以时间排序消息，设立3天的窗口，删除之前的

以上redis可以拆分为两个：

<img src="img\pubsub_2.png" />





## 3、事务

redis的使用，主要是它快。

redis的事务没有回滚：[为什么Redis不支持rollback](http://www.redis.cn/topics/transactions.html)

```shell
#开启事务，开启后，下面的命令会通过cli发送到service，但不会执行，调用exec后才执行
multi
#执行
exec
#取消
discard
#乐观锁	配合multi/exec执行	使用顺序：watch、multi、exec
watch
```

以下：谁的exec先到达，先执行谁的，另一个后执行，可能执行失败（先delete，后get不到）

<img src="img\transaction_1.png" />



乐观锁：以下情况，当client执行exec会失败，因为这个过程中监控的k1变了，失败的处理需要client自己考虑

<img src="img\transaction_2.png" />

## 4、modules布隆过滤器

modules：redis支持添加扩展库来实现一些功能

















redis作为数据库/缓存的区别

