# 一、消息中间件简介

## 1、jms

全称：Java MessageService 中文：Java 消息服务。 

### （1）jms中的角色

- broker：消息服务器

- provider：生产者

- consumer：消费者

- ConnectionFactory
- Connection
- Destination
  - Queue
  - Topic：默认不会持久化
- Session：JMS Session是生产和消费消息的一个单线程上下文。会话用于创建消息生产者（producer）、消息消费者（consumer）和消息（message）等。会话提供了一个事务性的上下文，在这个上下文中，一组发送和接收被组合到了一个原子操作中。
- 消息模型：
  - p2p：点对点的消息模型
  - pub/sub：订阅/发布的消息模型
  - 区别：

| 1                 | Topic                                                        | Queue                                                        |
| ----------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
|                   | Publish Subscribe messaging 发布 订阅消息                    | Point-to-Point 点对点                                        |
| 有无状态          | topic 数据默认不落地，是无状态的。                           | Queue 数据默认会在 mq 服 务器上以文件形式保存，比如 Active MQ 一 般 保 存 在 $AMQ_HOME\data\kahadb 下 面。也可以配置成 DB 存储。 |
| 完整性保障        | 并不保证 publisher 发布的每条数 据，Subscriber 都能接受到。  | Queue 保证每条数据都能 被 receiver 接收。消息不超时。        |
| 消息是否会丢失    | 一般来说 publisher 发布消息到某 一个 topic 时，只有正在监听该 topic 地址的 sub 能够接收到消息；如果没 有 sub 在监听，该 topic 就丢失了。 | Sender 发 送 消 息 到 目 标 Queue， receiver 可以异步接收这 个 Queue 上的消息。Queue 上的 消息如果暂时没有 receiver 来 取，也不会丢失。前提是消息不 超时。 |
| 消息发布接 收策略 | 一对多的消息发布接收策略，监 听同一个topic地址的多个sub都能收 到 publisher 发送的消息。Sub 接收完 通知 mq 服务器 | 一对一的消息发布接收策 略，一个 sender 发送的消息，只 能有一个 receiver 接收。 receiver 接收完后，通知 mq 服务器已接 收，mq 服务器对 queue 里的消 息采取删除或其他操作。 |

### （2）JMS的消息格式

**JMS消息由以下三部分组成的**：

- 消息头。

  每个消息头字段都有相应的getter和setter方法。

- 消息属性。

  如果需要除消息头字段以外的值，那么可以使用消息属性。

- 消息体。

  JMS定义的消息类型有TextMessage、MapMessage、BytesMessage、StreamMessage和ObjectMessage。

**消息头使用的所有方法**：

```java
public interface Message {

  public Destination getJMSDestination() throws JMSException;

  public void setJMSDestination(Destination destination) throws JMSException;

  public int getJMSDeliveryMode() throws JMSException

  public void setJMSDeliveryMode(int deliveryMode) throws JMSException;

  public String getJMSMessageID() throws JMSException;

  public void setJMSMessageID(String id) throws JMSException;

  public long getJMSTimestamp() throws JMSException'

  public void setJMSTimestamp(long timestamp) throws JMSException;

  public long getJMSExpiration() throws JMSException;

  public void setJMSExpiration(long expiration) throws JMSException;

  public boolean getJMSRedelivered() throws JMSException;

  public void setJMSRedelivered(boolean redelivered) throws JMSException;

  public int getJMSPriority() throws JMSException;

  public void setJMSPriority(int priority) throws JMSException;

  public Destination getJMSReplyTo() throws JMSException;

  public void setJMSReplyTo(Destination replyTo) throws JMSException;

  public String getJMScorrelationID() throws JMSException;

  public void setJMSCorrelationID(String correlationID) throws JMSException;

  public byte[] getJMSCorrelationIDAsBytes() throws JMSException;

  public void setJMSCorrelationIDAsBytes(byte[] correlationID) throws JMSException;

  public String getJMSType() throws JMSException;

  public void setJMSType(String type) throws JMSException;

}
```

### （3）消息类型

- **TextMessage**：文本消息
- **MapMessage**：k/v
- **BytesMessage**：字节流
- **StreamMessage**：java原始的数据流
- **ObjectMessage**：序列化的java对象

### （4）特性

#### 1）消息确认

- 在**事务性会话**中，当一个事务被提交的时候，确认自动发生。

- 在**非事务性会话**中，消息何时被确认取决于创建会话时的应答模式（acknowledgement mode）。该参数有以下三个可选值：
  - **Session.AUTO_ACKNOWLEDGE**。当客户成功的从receive方法返回的时候，或者从MessageListener.onMessage方法成功返回的时候，会话自动确认客户收到的消息。
  - **Session.CLIENT_ACKNOWLEDGE**。客户通过消息的acknowledge方法确认消息。需要注意的是，在这种模式中，确认是在会话层上进行：确认一个被消费的消息将自动确认所有已被会话消费的消息。例如，如果一个消息消费者消费了10个消息，然后确认第5个消息，那么所有10个消息都被确认。
  - **Session.DUPS_ACKNOWLEDGE**。该选择只是会话迟钝的确认消息的提交。如果JMS Provider失败，那么可能会导致一些重复的消息。如果是重复的消息，那么JMS Provider必须把消息头的JMSRedelivered字段设置为true。

#### 2）持久化

JMS 支持以下两种消息提交模式：

- PERSISTENT。指示JMS Provider持久保存消息，以保证消息不会因为JMS Provider的失败而丢失。
- NON_PERSISTENT。不要求JMS Provider持久保存消息。

#### 3）优先级

默认级别4，分10个级别，从0（最低）到9（最高）

#### 4）过期

可以设置消息在一定时间后过期，默认是永不过期。

#### 5）持久订阅

首先消息生产者必须使用PERSISTENT提交消息。客户可以通过会话上的createDurableSubscriber方法来创建一个持久订阅，该方法的第一个参数必须是一个topic，第二个参数是订阅的名称。 JMS Provider会存储发布到持久订阅对应的topic上的消息。如果最初创建持久订阅的客户或者任何其它客户使用相同的连接工厂和连接的客户ID、相同的主题和相同的订阅名再次调用会话上的createDurableSubscriber方法，那么该持久订阅就会被激活。JMS Provider会象客户发送客户处于非激活状态时所发布的消息。 持久订阅在某个时刻只能有一个激活的订阅者。持久订阅在创建之后会一直保留，直到应用程序调用会话上的unsubscribe方法。

#### 6）本地事务

在一个JMS客户端，可以使用本地事务来组合消息的发送和接收。JMS Session接口提供了commit和rollback方法。事务提交意味着生产的所有消息被发送，消费的所有消息被确认；事务回滚意味着生产的所有消息被销毁，消费的所有消息被恢复并重新提交，除非它们已经过期。 事务性的会话总是牵涉到事务处理中，commit或rollback方法一旦被调用，一个事务就结束了，而另一个事务被开始。关闭事务性会话将回滚其中的事务。 需要注意的是，如果使用请求/回复机制，即发送一个消息，同时希望在同一个事务中等待接收该消息的回复，那么程序将被挂起，因为知道事务提交，发送操作才会真正执行。 需要注意的还有一个，消息的生产和消费不能包含在同一个事务中。

## 2、应用场景

- **异步通信**：有些业务不想也不需要立即处理消息
- **缓冲**
- **解耦**
- **冗余**：消息队列会持久化消息，防止丢失。许多消息队列所采用的”插入-获取-删除”范式。
- **扩展性**：分布式扩容
- **可恢复性**：系统一部分组件失效，消息在系统恢复后依旧可以处理。
- **顺序保证**
- **过载保护**：访问量剧增的情况下，保护系统
- **数据流处理**：收集海量数据流，供大数据处理。如：业务日志、监控数据、用户行为等。
- **异构平台**

## 3、常用消息中间件对比

| 特性MQ           | ActiveMQ   | RabbitMQ   | RocketMQ         | Kafka            |
| ---------------- | ---------- | ---------- | ---------------- | ---------------- |
| 生产者消费者模式 | 支持       | 支持       | 支持             | 支持             |
| 发布订阅模式     | 支持       | 支持       | 支持             | 支持             |
| 请求回应模式     | 支持       | 支持       | 不支持           | 不支持           |
| Api完备性        | 高         | 高         | 高               | 高               |
| 多语言支持       | 支持       | 支持       | java             | 支持             |
| 单机吞吐量       | 万级       | 万级       | 万级             | 十万级           |
| 消息延迟         | 无         | 微秒级     | 毫秒级           | 毫秒级           |
| 可用性           | 高（主从） | 高（主从） | 非常高（分布式） | 非常高（分布式） |
| 消息丢失         | 低         | 低         | 理论上不会丢失   | 理论上不会丢失   |
| 文档的完备性     | 高         | 高         | 高               | 高               |
| 提供快速入门     | 有         | 有         | 有               | 有               |
| 社区活跃度       | 高         | 高         | 有               | 高               |
| 商业支持         | 无         | 无         | 商业云           | 商业云           |

# 二、ACtive MQ基础

[官网](http://activemq.apache.org/)

## 1、安装启动

- activeMQ不一定要专门启个服务，可以在项目中内嵌：[官网文档](https://activemq.apache.org/vm-transport-reference)

- Windows下：
  - 启动：bin/win64/activemq.bat；
  - web控制台访问路径在启动日志中打印了：http://127.0.0.1:8161/
  - 用户名密码默认为admin admin
- linux下：

在`init.d`下建立软连接

```shell
ln -s /usr/local/activemq/bin/activemq ./
```

设置开启启动

```shell
chkconfig activemq on
```

服务管理

```shell
service activemq start
service activemq status
service activemq stop
```



ActiveMQ 5.0 的二进制发布包中bin目录中包含一个名为activemq的脚本，直接运行这个脚本就可以启动一个broker。 此外也可以通过Broker Configuration URI或Broker XBean URI对broker进行配置，以下是一些命令行参数的例子：

| Example                                                      | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| activemq                                                     | Runs a broker using the default  'xbean:activemq.xml' as the broker configuration file. |
| activemq xbean:myconfig.xml                                  | Runs a broker using the file myconfig.xml as the  broker configuration file that is located in the classpath. |
| activemq xbean:file:./conf/broker1.xml                       | Runs a broker using the file broker1.xml as the  broker configuration file that is located in the relative file path  ./conf/broker1.xml |
| activemq xbean:file:C:/ActiveMQ/conf/broker2.xml             | Runs a broker using the file broker2.xml as the  broker configuration file that is located in the absolute file path  C:/ActiveMQ/conf/broker2.xml |
| activemq broker:(tcp://localhost:61616,  tcp://localhost:5000)?useJmx=true | Runs a broker with two transport connectors and  JMX enabled. |
| activemq broker:(tcp://localhost:61616,  network:tcp://localhost:5000)?persistent=false | Runs a broker with 1 transport connector and 1  network connector with persistence disabled. |



## 2、配置文件

### （1）conf/activemq.xml

memoryUsage：占用jvm百分比

storeUsage：100g，限制最大占用磁盘可用空间（只认启动时的可用空间）

tempUsage：超过memoryUsage，使用磁盘空间存储

```xml
<systemUsage>
	<systemUsage>
		<memoryUsage>
			<memoryUsage percentOfJvmHeap="70" />
		</memoryUsage>
		<storeUsage>
			<storeUsage limit="100 gb"/>
		</storeUsage>
		<tempUsage>
			<tempUsage limit="50 gb"/>
		</tempUsage>
	</systemUsage>
</systemUsage>
```

消息数据默认存放在数据库中的，在data/kahadb文件夹下，配置实在activamq.xml中

```xml
<persistenceAdapter>
                <kahaDB directory="${activemq.data}/kahadb"/>
</persistenceAdapter>
```

db-1.log默认32kb

### （2）conf/jetty.xml

用户名密码在jetty-realm.properties中

## 3、消息存储

学习的时候，可以修改activeMQ的持久化方式为JDBC，把消息等数据放到数据库，方便查看。消费后，数据库中的消息数据就被删除了

如果开了持久化，且持久化到mysql中，会异步把内存中的消息数据写入数据库中。消费数据先消费内存中的，然后删除数据库中的数据。比较浪费性能。可用kahadb、LevelDB这种小型数据库，不用远程连接。

### （1）KahaDB

KahaDB是默认的持久化策略，所有消息顺序添加到一个日志文件中，同时另外有一个索引文件记录指向这些日志的存储地址，还有一个事务日志用于消息回复操作。是一个专门针对消息持久化的解决方案,它对典型的消息使用模式进行了优化。

在data/kahadb这个目录下，会生成四个文件，来完成消息持久化 
1.db.data 它是消息的索引文件，本质上是B-Tree（B树），使用B-Tree作为索引指向db-*.log里面存储的消息 
2.db.redo 用来进行消息恢复 *

3.db-.log 存储消息内容。新的数据以APPEND的方式追加到日志文件末尾。属于顺序写入，因此消息存储是比较 快的。默认是32M，达到阀值会自动递增 
4.lock文件 锁，写入当前获得kahadb读写权限的broker ，用于在集群环境下的竞争处理

```
<persistenceAdapter> <!--directory:保存数据的目录;journalMaxFileLength:保存消息的文件大小 --> <kahaDBdirectory="${activemq.data}/kahadb"journalMaxFileLength="16mb"/> </persistenceAdapter>

```

特性：

1、日志形式存储消息；

2、消息索引以 B-Tree 结构存储，可以快速更新；

3、 完全支持 JMS 事务；

4、支持多种恢复机制kahadb 可以限制每个数据文件的大小。不代表总计数据容量。 

### （2）AMQ

只适用于 5.3 版本之前。 AMQ 也是一个文件型数据库，消息信息最终是存储在文件中。内存中也会有缓存数据。 

```
<persistenceAdapter> <!--directory:保存数据的目录 ;maxFileLength:保存消息的文件大小 --> <amqPersistenceAdapterdirectory="${activemq.data}/amq"maxFileLength="32mb"/> </persistenceAdapter>
```



 性能高于 JDBC，写入消息时，会将消息写入日志文件，由于是顺序追加写，性能很高。

 为了提升性能，创建消息主键索引，并且提供缓存机制，进一步提升性能。

每个日志文件的 大小都是有限制的（默认 32m，可自行配置） 。 

当超过这个大小，系统会重新建立一个文件。

当所有的消息都消费完成，系统会删除这 个文件或者归档。 

主要的缺点是 AMQ Message 会为每一个 Destination 创建一个索引，如果使用了大量的 Queue，索引文件的大小会占用很多磁盘空间。 

而且由于索引巨大，一旦 Broker（ActiveMQ 应用实例）崩溃，重建索引的速度会非常 慢。 

虽然 AMQ 性能略高于 Kaha DB 方式，但是由于其重建索引时间过长，而且索引文件 占用磁盘空间过大，所以已经不推荐使用。

### （3）JDBC

使用JDBC持久化方式，数据库默认会创建3个表，每个表的作用如下： 
activemq_msgs：queue和topic的消息都存在这个表中 
activemq_acks：存储持久订阅的信息和最后一个持久订阅接收的消息ID 
activemq_lock：跟kahadb的lock文件类似，确保数据库在某一时刻只有一个broker在访问



ActiveMQ 将数据持久化到数据库中。 

不指定具体的数据库。 可以使用任意的数据库 中。 

本环节中使用 MySQL 数据库。 下述文件为 activemq.xml 配置文件部分内容。 

 首先定义一个 mysql-ds 的 MySQL 数据源，然后在 persistenceAdapter 节点中配置 jdbcPersistenceAdapter 并且引用刚才定义的数据源。

dataSource 指定持久化数据库的 bean，createTablesOnStartup 是否在启动的时候创建数 据表，默认值是 true，这样每次启动都会去创建数据表了，一般是第一次启动的时候设置为 true，之后改成 false。 

**Beans中添加**

```
<bean id="mysql-ds" class="org.apache.commons.dbcp.BasicDataSource" destroy-method="close"> 

<property name="driverClassName" value="com.mysql.jdbc.Driver"/> 
<property name="url" value="jdbc:mysql://localhost/activemq?relaxAutoCommit=true"/> 
<property name="username" value="activemq"/>
<property name="password" value="activemq"/>
<property name="maxActive" value="200"/>
<property name="poolPreparedStatements" value="true"/> 

</bean>
```

**修改persistenceAdapter**

```
        <persistenceAdapter>
           <!-- <kahaDB directory="${activemq.data}/kahadb"/> -->

		<jdbcPersistenceAdapter dataSource="#mysql-ds" createTablesOnStartup="true" /> 


        </persistenceAdapter>
```

依赖jar包

commons-dbcp commons-pool mysql-connector-java

#### 表字段解释

**activemq_acks**：用于存储订阅关系。如果是持久化Topic，订阅者和服务器的订阅关系在这个表保存。
主要的数据库字段如下：

```
container：消息的destination 
sub_dest：如果是使用static集群，这个字段会有集群其他系统的信息 
client_id：每个订阅者都必须有一个唯一的客户端id用以区分 
sub_name：订阅者名称 
selector：选择器，可以选择只消费满足条件的消息。条件可以用自定义属性实现，可支持多属性and和or操作 
last_acked_id：记录消费过的消息的id。
```

2：**activemq_lock**：在集群环境中才有用，只有一个Broker可以获得消息，称为Master Broker，其他的只能作为备份等待Master Broker不可用，才可能成为下一个Master Broker。这个表用于记录哪个Broker是当前的Master Broker。

3：**activemq_msgs**：用于存储消息，Queue和Topic都存储在这个表中。
主要的数据库字段如下：

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
id：自增的数据库主键 
container：消息的destination 
msgid_prod：消息发送者客户端的主键 
msg_seq：是发送消息的顺序，msgid_prod+msg_seq可以组成jms的messageid 
expiration：消息的过期时间，存储的是从1970-01-01到现在的毫秒数 
msg：消息本体的java序列化对象的二进制数据 
priority：优先级，从0-9，数值越大优先级越高 
xid:用于存储订阅关系。如果是持久化topic，订阅者和服务器的订阅关系在这个表保存。
```



### （4）LevelDB

LevelDB持久化性能高于KahaDB，虽然目前默认的持久化方式仍然是KahaDB。并且，在ActiveMQ 5.9版本提供 了基于LevelDB和Zookeeper的数据复制方式，用于Master-slave方式的首选数据复制方案。 但是在ActiveMQ官网对LevelDB的表述：LevelDB官方建议使用以及不再支持，推荐使用的是KahaDB 

### （5）Memory

顾名思义，基于内存的消息存储，就是消息存储在内存中。persistent=”false”,表示不设置持 久化存储，直接存储到内存中 
在broker标签处设置。

### （6）JDBC Message store with ActiveMQ Journal 

这种方式克服了JDBC Store的不足，JDBC存储每次消息过来，都需要去写库和读库。 ActiveMQ Journal，使用延迟存储数据到数据库，当消息来到时先缓存到文件中，延迟后才写到数据库中。

当消费者的消费速度能够及时跟上生产者消息的生产速度时，journal文件能够大大减少需要写入到DB中的消息。 举个例子，生产者生产了1000条消息，这1000条消息会保存到journal文件，如果消费者的消费速度很快的情况 下，在journal文件还没有同步到DB之前，消费者已经消费了90%的以上的消息，那么这个时候只需要同步剩余的 10%的消息到DB。 如果消费者的消费速度很慢，这个时候journal文件可以使消息以批量方式写到DB。 

## 4、支持协议

[完整支持的协议](http://activemq.apache.org/configuring-version-5-transports.html)

### （1）TCP

Transmission Control Protocol 

1：这是默认的Broker配置，TCP的Client监听端口是61616。
2：在网络传输数据前，必须要序列化数据，消息是通过一个叫wire protocol的来序列化成字节流。默认情况下，ActiveMQ把wire protocol叫做OpenWire，它的目的是促使网络上的效率和数据快速交互。
3：TCP连接的URI形式：tcp://hostname:port?key=value&key=value，加粗部分是必须的
4：TCP传输的优点：
(1)TCP协议传输可靠性高，稳定性强
(2)高效性：字节流方式传递，效率很高
(3)有效性、可用性：应用广泛，支持任何平台

```
<transportConnector name="openwire" uri="tcp://0.0.0.0:61616?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
```

### （2）NIO

New I/O API Protocol

1：NIO协议和TCP协议类似，但NIO更侧重于底层的访问操作。它允许开发人员对同一资源可有更多的client调用和服务端有更多的负载。 
2：适合使用NIO协议的场景：
(1)可能有大量的Client去链接到Broker上一般情况下，大量的Client去链接Broker是被操作系统的线程数所限制的。因此，NIO的实现比TCP需要更少的线程去运行，所以建议使用NIO协议
(2)可能对于Broker有一个很迟钝的网络传输NIO比TCP提供更好的性能
3：NIO连接的URI形式：nio://hostname:port?key=value
4：Transport Connector配置示例： 

```
<transportConnectors>
　　<transportConnector
　　　　name="tcp"
　　　　uri="tcp://localhost:61616?trace=true" />
　　<transportConnector
　　　　name="nio"
　　　　uri="nio://localhost:61618?trace=true" />
</transportConnectors>
```


上面的配置，示范了一个TCP协议监听61616端口，一个NIO协议监听61618端口 

### （3）UDP

User Datagram Protocol

1：UDP和TCP的区别
(1)TCP是一个原始流的传递协议，意味着数据包是有保证的，换句话说，数据包是不会被复制和丢失的。UDP，另一方面，它是不会保证数据包的传递的
(2)TCP也是一个稳定可靠的数据包传递协议，意味着数据在传递的过程中不会被丢失。这样确保了在发送和接收之间能够可靠的传递。相反，UDP仅仅是一个链接协议，所以它没有可靠性之说
2：从上面可以得出：TCP是被用在稳定可靠的场景中使用的；UDP通常用在快速数据传递和不怕数据丢失的场景中，还有ActiveMQ通过防火墙时，只能用UDP
3：UDP连接的URI形式：udp://hostname:port?key=value
4：Transport Connector配置示例： 

```
<transportConnectors>
    <transportConnector
        name="udp"
        uri="udp://localhost:61618?trace=true" />
</transportConnectors>
```

### （4）SSL

Secure Sockets Layer Protocol 

1：连接的URI形式：ssl://hostname:port?key=value
2：Transport Connector配置示例： 

```
<transportConnectors>
    <transportConnector name="ssl" uri="ssl://localhost:61617?trace=true"/>
</transportConnectors>
```

### （5）HTTP/HTTPS

Hypertext Transfer Protocol

1：像web和email等服务需要通过防火墙来访问的，Http可以使用这种场合
2：连接的URI形式：http://hostname:port?key=value或者https://hostname:port?key=value
3：Transport Connector配置示例：

```
<transportConnectors>
    <transportConnector name="http" uri="http://localhost:8080?trace=true" />
</transportConnectors>
```

### （6）VM

1、VM transport允许在VM内部通信，从而避免了网络传输的开销。这时候采用的连 接不是socket连接，而是直接的方法调用。 

2、第一个创建VM连接的客户会启动一个embed VM broker，接下来所有使用相同的 broker name的VM连接都会使用这个broker。当这个broker上所有的连接都关闭 的时候，这个broker也会自动关闭。 

3、连接的URI形式：vm://brokerName?key=value 

4、Java中嵌入的方式： vm:broker:(tcp://localhost:6000)?brokerName=embeddedbroker&persistent=fal se ， 定义了一个嵌入的broker名称为embededbroker以及配置了一个 tcptransprotconnector在监听端口6000上 

5、使用一个加载一个配置文件来启动broker vm://localhost?brokerConfig=xbean:activemq.xml

## 5、简单应用:

### （1）maven

```xml
<!-- https://mvnrepository.com/artifact/org.apache.activemq/activemq-all -->
<dependency>
    <groupId>org.apache.activemq</groupId>
    <artifactId>activemq-all</artifactId>
    <version>5.15.11</version>
</dependency>
```



### （2）sender

```java
import javax.jms.Connection;
import javax.jms.DeliveryMode;
import javax.jms.MessageProducer;
import javax.jms.Queue;
import javax.jms.Session;
import javax.jms.TextMessage;

import org.apache.activemq.ActiveMQConnectionFactory;

public class Sender {

	public static void main(String[] args) throws Exception{

		// 1.获取连接工厂
		

		ActiveMQConnectionFactory connectionFactory = new ActiveMQConnectionFactory(
				"admin",//ActiveMQConnectionFactory.DEFAULT_USER
				"admin",//ActiveMQConnectionFactory.DEFAULT_PASSWORD
				"tcp://localhost:61616"
				);
		// 2.获取一个向ActiveMQ的连接
		Connection connection = connectionFactory.createConnection();
		// 3.获取session	false表示不用事务；
		Session session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
		// 4. 找目的地，获取destination，消费端，也会从这个目的地取消息
		
		Queue queue = session.createQueue("user");
		
		// 51.消息创建者
		
		MessageProducer producer = session.createProducer(queue);
	//	producer.setDeliveryMode(DeliveryMode.NON_PERSISTENT);
		// consumer -> 消费者
		// producer -> 创建者
		// 5.2. 创建消息
		
		for (int i = 0; i < 1000; i++) {
			
			TextMessage textMessage = session.createTextMessage("hi: " + i);
			
			// 5.3 向目的地写入消息
			
			if(i % 4 == 0) {
				// 设置消息的优先级
				// 对producer 整体设置
			//	producer.setPriority(9);
			//	producer.send(textMessage,DeliveryMode.PERSISTENT,9,1000 * 100);关闭持久化
				textMessage.setJMSPriority(9);
			}
			
				producer.send(textMessage);
	//	Thread.sleep(3000);
		}
		
		// 6.关闭连接
		connection.close();
		
		System.out.println("System exit....");
		
	}
	
}

```



### （3）receiver

```java
import javax.jms.Connection;
import javax.jms.Destination;
import javax.jms.Message;
import javax.jms.MessageConsumer;
import javax.jms.MessageProducer;
import javax.jms.Queue;
import javax.jms.Session;
import javax.jms.TextMessage;

import org.apache.activemq.ActiveMQConnectionFactory;

public class Receiver {

	public static void main(String[] args) throws Exception{

		// 1.获取连接工厂
		

		ActiveMQConnectionFactory connectionFactory = new ActiveMQConnectionFactory(
				"admin",
				"admin",
				"tcp://localhost:61616"
				);
		// 2.获取一个向ActiveMQ的连接
		Connection connection = connectionFactory.createConnection();
		
		connection.start();
		// 3.获取session
		Session session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
		// 4. 找目的地，获取destination，消费端，也会从这个目的地取消息
		
		Destination queue = session.createQueue("user");
		
		// 5.获取消息
	
		MessageConsumer consumer = session.createConsumer(queue);
		
		for(int i=0;;i++) {
			
			TextMessage message = (TextMessage)consumer.receive();
			System.out.println("-----");
			System.out.println("message2:" + message.getText());
				
		}
	}
	
}

```

### （4）注意点

- 使用writeBytes后，在写入其他类型，哪个读的时候必须按顺序读，否则报错EOF
- 使用ObjectMessage可能报错，这时候需要把class添加到信任区(接受端)。


```java
list.add(Myclass.class.getPackage().getName())
connectionFactorysetTrustedPackages(list);
```



## 6、安全机制

设置后connection中的用户名密码就不能使用null（默认值）了

### （1）web控制台安全

```
# username: password [,rolename ...]
admin: admin, admin
user: user, user
yiming: 123, user
```

用户名：密码，角色

注意: 配置需重启ActiveMQ才会生效。

### （2）消息安全机制

修改 activemq.xml

在123行     </broker> 节点中添加

```xml
	<plugins>
      <simpleAuthenticationPlugin>
          <users>
              <authenticationUser username="admin" password="admin" groups="admins,publishers,consumers"/>
              <authenticationUser username="publisher" password="publisher"  groups="publishers,consumers"/>
              <authenticationUser username="consumer" password="consumer" groups="consumers"/>
              <authenticationUser username="guest" password="guest"  groups="guests"/>
          </users>
      </simpleAuthenticationPlugin>
 </plugins>

```

## 7、常用API

### （1）事务

```java
session.commit();
session.rollback();
```

- 开启事务后不，不提交，broker中不会有消息
- 批量提交可以提高性能

createSession中，如果开启了事务，第二个参数不生效，默认为CLIENT_ACKNOWLEDGE

开启事务后，可以批量ack；而且broker把消息发送给一个consumer之后，在ack之前，ack期间不会把消息重复发给第二个consumer。

### （2）Purge

清理消息

### （3）消息确认

ActiveMQ支持自动签收与手动签收

- **Session.AUTO_ACKNOWLEDGE**：当客户端从receiver或onMessage成功返回时，Session自动签收客户端的这条消息的收条。
- **Session.CLIENT_ACKNOWLEDGE**：客户端通过调用消息(Message)的acknowledge方法签收消息。在这种情况下，签收发生在Session层面：签收一个已经消费的消息会自动地签收这个Session所有已消费的收条。
- **Session.DUPS_OK_ACKNOWLEDGE**：Session不必确保对传送消息的签收，这个模式可能会引起消息的重复，但是降低了Session的开销，所以只有客户端能容忍重复的消息，才可使用。

### （4）持久化

默认持久化是开启的

```java
producer.setDeliveryMode(DeliveryMode.NON_PERSISTENT)
```

### （5）优先级

可以打乱消费顺序

```
producer.setPriority
```

配置文件需要指定使用优先级的目的地

```xml
<policyEntry queue="queue1" prioritizedMessages="true" />
```

### （6）消息超时/过期

```java
producer.setTimeToLive()
```

设置了消息超时的消息，消费端在超时后无法在消费到此消息。

给消息设置一个超时时间 -> 死信队列 -> 拿出来 -> 重发

### （7）死信队列

**死信**

此类消息会进入到`ActiveMQ.DLQ`队列且不会自动清除，称为死信

此处有消息堆积的风险



死信队列的消息是会被持久化的

```java
//到期后进入死信队列里
producer.setTimeToLive(毫秒)
```

consumer没上线，broker不会检查消息是否过期，上线后才检查，如果过期，则标记为Dequeued，并放入ActiveMQ.DLQ中

**过期的消息不进死信队列**

```xml
<individualDeadLetterStrategy   processExpired="false"  /> 
```

**修改死信队列名称**

```xml
<policyEntry queue="f" prioritizedMessages="true" >
	<deadLetterStrategy> 
		<individualDeadLetterStrategy   queuePrefix="DLxxQ." useQueueForQueueMessages="true" /> 
	</deadLetterStrategy> 
</policyEntry>
```

useQueueForQueueMessages: 设置使用队列保存死信，还可以设置useQueueForTopicMessages，使用Topic来保存死信

**非持久化的消息默认不进死信队列**

让非持久化的消息也进死信队列

```xml
<individualDeadLetterStrategy   queuePrefix="DLxxQ." useQueueForQueueMessages="true"  processNonPersistent="true" /> 
```

### （8）独占消费者

如果有两个consumer都设置了独占消费者，则谁“先来”，谁独占。

```java
Queue queue = session.createQueue("xxoo?consumer.exclusive=true");
```

还可以设置优先级

```
Queue queue = session.createQueue("xxoo?consumer.exclusive=true&consumer.priority=10");
```

### 8、消息类型

### （1）Object

sender：

```java
Girl girl = new Girl("qiqi",25,398.0);		
Message message = session.createObjectMessage(girl);
```

receiver：

```java
if(message instanceof ActiveMQObjectMessage) {
	
	Girl girl = (Girl)((ActiveMQObjectMessage)message).getObject();
	
	System.out.println(girl);
	System.out.println(girl.getName());
}
```

如果遇到此类报错，需要添加信任

```java
Exception in thread "main" javax.jms.JMSException: Failed to build body from content. Serializable class not available to broker. Reason: java.lang.ClassNotFoundException: Forbidden class com.mashibing.mq.Girl! This class is not trusted to be serialized as ObjectMessage payload. Please take a look at http://activemq.apache.org/objectmessage.html for more information on how to configure trusted classes.
	at org.apache.activemq.util.JMSExceptionSupport.create(JMSExceptionSupport.java:36)
	at org.apache.activemq.command.ActiveMQObjectMessage.getObject(ActiveMQObjectMessage.java:213)
	at com.mashibing.mq.Receiver.main(Receiver.java:65)
Caused by: java.lang.ClassNotFoundException: Forbidden class com.mashibing.mq.Girl! This class is not trusted to be serialized as ObjectMessage payload. Please take a look at http://activemq.apache.org/objectmessage.html for more information on how to configure trusted classes.
	at org.apache.activemq.util.ClassLoadingAwareObjectInputStream.checkSecurity(ClassLoadingAwareObjectInputStream.java:112)
	at org.apache.activemq.util.ClassLoadingAwareObjectInputStream.resolveClass(ClassLoadingAwareObjectInputStream.java:57)
	at java.io.ObjectInputStream.readNonProxyDesc(ObjectInputStream.java:1868)
	at java.io.ObjectInputStream.readClassDesc(ObjectInputStream.java:1751)
	at java.io.ObjectInputStream.readOrdinaryObject(ObjectInputStream.java:2042)
	at java.io.ObjectInputStream.readObject0(ObjectInputStream.java:1573)
	at java.io.ObjectInputStream.readObject(ObjectInputStream.java:431)
	at org.apache.activemq.command.ActiveMQObjectMessage.getObject(ActiveMQObjectMessage.java:211)
	... 1 more
```

添加信任

```java
connectionFactory.setTrustedPackages(
	new ArrayList<String>(
			Arrays.asList(
					new String[]{
							Girl.class.getPackage().getName()
							}
					
					)
			)
	
```

### （2）bytesMessage

sender:

```java
BytesMessage bytesMessage = session.createBytesMessage();
bytesMessage.writeBytes("str".getBytes());
bytesMessage.writeUTF("哈哈");
```

receiver：

```java
if(message instanceof BytesMessage) {
	BytesMessage bm = (BytesMessage)message;
	
	 byte[] b = new byte[1024];
	 int len = -1;
	 while ((len = bm.readBytes(b)) != -1) {
		 System.out.println(new String(b, 0, len));
	 }
}
```

还可以使用ActiveMQ给提供的便捷方法,但要注意读取和写入的顺序

```
bm.readBoolean()
bm.readUTF()
```

使用writeBytes后，在写入其他类型，哪个读的时候必须按顺序读，否则报错EOF

**写入文件**

```java
FileOutputStream out = null;
try {
	out = new FileOutputStream("d:/aa.txt");
} catch (FileNotFoundException e2) {
	e2.printStackTrace();
}
byte[] by = new byte[1024];
int len = 0 ;
try {
	while((len = bm.readBytes(by))!= -1){
		out.write(by,0,len);
	}
} catch (Exception e1) {
	e1.printStackTrace();
}
```

### （3）MapMessage

sender:

```java
MapMessage mapMessage = session.createMapMessage();
      	
mapMessage.setString("name","lucy");
mapMessage.setBoolean("yihun",false);
mapMessage.setInt("age", 17);

producer.send(mapMessage);
```

receiver：

```java
Message message = consumer.receive();
MapMessage mes = (MapMessage) message;

System.out.println(mes);

System.out.println(mes.getString("name"));
```

## 9、消息发送原理

### （1）异步与同步

|          | 开启事务 | 关闭事务 |
| -------- | -------- | -------- |
| 持久化   | 异步     | 同步     |
| 非持久化 | 异步     | 异步     |

我们可以通过以下几种方式来设置异步发送：

```java
ActiveMQConnectionFactory connectionFactory = new ActiveMQConnectionFactory(
		"admin",
		"admin",
		"tcp://localhost:61616"
		);
// 2.获取一个向ActiveMQ的连接
connectionFactory.setUseAsyncSend(true);
ActiveMQConnection connection = (ActiveMQConnection)connectionFactory.createConnection();
connection.setUseAsyncSend(true);
```

如果自己没设置，send方法中会自己判断；也就是上表的来源：

```java
if(onComplete==null && sendTimeout <= 0 && !msg.isResponseRequired() && !connection.isAlwaysSyncSend() && (!msg.isPersistent() || connection.isUseAsyncSend() || txid != null)){}
```

### （2）消息堆积

ActiveMQ的send方法实现：其中有个producerWindow，是个简单的限流器，发送消息的大小超过了阈值就发不出去了。阈值大小可以在destination中设置，也可以在连接中设置，设置在：tcp://localhost:61616?jms.producerWindowSize=16。

producer每发送一个消息，统计一下发送的字节数，当字节数达到ProducerWindowSize值时，需要等待broker的确认，才能继续发送。

brokerUrl中设置: `tcp://localhost:61616?jms.producerWindowSize=1048576`

destinationUri中设置: `myQueue?producer.windowSize=1048576`

### （3）延迟消息投递

首先在配置文件中开启延迟和调度

**schedulerSupport="true"**

```xml
<broker xmlns="http://activemq.apache.org/schema/core" brokerName="localhost" dataDirectory="${activemq.data}" schedulerSupport="true">
```

**延迟发送**

```java
message.setLongProperty(ScheduledMessage.AMQ_SCHEDULED_DELAY, 10*1000);
```

### （4）带间隔的重复发送

```java
long delay = 10 * 1000;
long period = 2 * 1000;
int repeat = 9;
message.setLongProperty(ScheduledMessage.AMQ_SCHEDULED_DELAY, delay);
message.setLongProperty(ScheduledMessage.AMQ_SCHEDULED_PERIOD, period);
message.setIntProperty(ScheduledMessage.AMQ_SCHEDULED_REPEAT, repeat);
createProducer.send(message);
```

## 10、监听器

可以使用监听器来处理消息接收

```
consumer.setMessageListener(new MyListener());
```

需要实现接口MessageListener

```
public class MyListener implements MessageListener {

	public void onMessage(Message message) {
		// TODO Auto-generated method stub
		TextMessage textMessage = (TextMessage)message;
		try {
			System.out.println("xxoo" + textMessage.getText());
		} catch (JMSException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

}

```

当收到消息后会调起onMessage方法

## 11、消息过滤

selector选择器

sender：

```java
MapMessage msg1 = session.createMapMessage();
msg1.setString("name", "qiqi");
msg1.setString("age", "18");

msg1.setStringProperty("name", "qiqi");
msg1.setIntProperty("age", 18);
MapMessage msg2 = session.createMapMessage();
msg2.setString("name", "lucy");
msg2.setString("age", "18");
msg2.setStringProperty("name", "lucy");
msg2.setIntProperty("age", 18);
MapMessage msg3 = session.createMapMessage();
msg3.setString("name", "qianqian");
msg3.setString("age", "17");
msg3.setStringProperty("name", "qianqian");
msg3.setIntProperty("age", 17);
```

receiver：

```java
String selector1 = "age > 17";
String selector2 = "name = 'lucy'";
MessageConsumer consumer = session.createConsumer(queue,selector2);
```

## 12、NIO配置

[官方文档](http://activemq.apache.org/configuring-version-5-transports)

nio优化的是服务端，提高broker性能，并发量连接数可以更大了（以前可以连2k，现在可以连接10k）

默认为TCP，使用的是BIO

```xml
<transportConnector name="openwire" uri="tcp://0.0.0.0:61616?maximumConnections=1000&amp;wireFormat.maxFrameSize=104857600"/>
```

Nio是基于TCP的，客户端使用连接时也应使用nio

```java
ActiveMQConnectionFactory connectionFactory = new ActiveMQConnectionFactory(
	"admin",
	"admin",
	"nio://localhost:61617"
	);
```

自动适配协议：Auto + Nio

```xml
<transportConnector name="auto+nio" uri="auto+nio://localhost:5671"/>
```

### （1）OpenWire 可用配置选项

| Option                             | Default    | Description                                                  |
| ---------------------------------- | ---------- | ------------------------------------------------------------ |
| `cacheEnabled`                     | `true`     | Should commonly repeated values be cached so that less marshaling occurs? |
| `cacheSize`                        | `1024`     | When `cacheEnabled=true` then this parameter is used to specify the number of values to be cached. |
| `maxInactivityDuration`            | `30000`    | The maximum [inactivity](http://activemq.apache.org/activemq-inactivitymonitor) duration (before which the socket is considered dead) in milliseconds. On some platforms it can take a long time for a socket to die. Therefore allow the broker to kill connections when they have been inactive for the configured period of time. Used by some transports to enable a keep alive heart beat feature. Inactivity monitoring is disabled when set to a value `<= 0`. |
| `maxInactivityDurationInitalDelay` | `10000`    | The initial delay before starting [inactivity](http://activemq.apache.org/activemq-inactivitymonitor) checks. Yes, the word `'Inital'` is supposed to be misspelled like that. |
| `maxFrameSize`                     | `MAX_LONG` | Maximum allowed frame size. Can help help prevent OOM DOS attacks. |
| `sizePrefixDisabled`               | `false`    | Should the size of the packet be prefixed before each packet is marshaled? |
| `stackTraceEnabled`                | `true`     | Should the stack trace of exception that occur on the broker be sent to the client? |
| `tcpNoDelayEnabled`                | `true`     | Does not affect the wire format, but provides a hint to the peer that `TCP_NODELAY` should be enabled on the communications Socket. |
| `tightEncodingEnabled`             | `true`     | Should wire size be optimized over CPU usage?                |



### （2）Transport 可用配置选项

| Option Name             | Default Value     | Description                                                  |
| ----------------------- | ----------------- | ------------------------------------------------------------ |
| backlog                 | 5000              | Specifies the maximum number of connections waiting to be accepted by the transport server socket. |
| closeAsync              | true              | If **`true`** the socket close call happens asynchronously. This parameter should be set to **`false`** for protocols like STOMP, that are commonly used in situations where a new connection is created for each read or write. Doing so ensures the socket close call happens synchronously. A synchronous close prevents the broker from running out of available sockets owing to the rapid cycling of connections. |
| connectionTimeout       | 30000             | If **`>=1`** the value sets the connection timeout in milliseconds. A value of **`0`** denotes no timeout. Negative values are ignored. |
| daemon                  | false             | If **`true`** the transport thread will run in daemon mode. Set this parameter to **`true`** when embedding the broker in a Spring container or a web container to allow the container to shut down correctly. |
| dynamicManagement       | false             | If **`true`** the **`TransportLogger`** can be managed by JMX. |
| ioBufferSize            | 8 * 1024          | Specifies the size of the buffer to be used between the TCP layer and the OpenWire layer where **`wireFormat`** based marshaling occurs. |
| jmxPort                 | 1099              | (Client Only) Specifies the port that will be used by the JMX server to manage the **`TransportLoggers`**. This should only be set, via URI, by either a client producer or consumer as the broker creates its own JMX server. Specifying an alternate JMX port is useful for developers that test a broker and client on the same machine and need to control both via JMX. |
| keepAlive               | false             | If **`true`,** enables [TCP KeepAlive](http://tldp.org/HOWTO/TCP-Keepalive-HOWTOoverview) on the broker connection to prevent connections from timing out at the TCP level. This should *not* be confused with **`KeepAliveInfo`** messages as used by the **`InactivityMonitor`.** |
| logWriterName           | default           | Sets the name of the **`org.apache.activemq.transport.LogWriter`** implementation to use. Names are mapped to classes in the **`resources/META-INF/services/org/apache/activemq/transport/logwriters`** directory. |
| maximumConnections      | Integer.MAX_VALUE | The maximum number of sockets allowed for this broker.       |
| minmumWireFormatVersion | 0                 | The minimum remote **`wireFormat`** version that will be accepted (note the misspelling). Note: when the remote **`wireFormat`** version is lower than the configured minimum acceptable version an exception will be thrown and the connection attempt will be refused. A value of **`0`** denotes no checking of the remote **`wireFormat`** version. |
| socketBufferSize        | 64 * 1024         | Sets the size, in bytes, for the accepted socket’s read and write buffers. |
| soLinger                | Integer.MIN_VALUE | Sets the socket’s option **`soLinger`** when the value is **`> -1`**. When set to **`-1`** the **`soLinger`** socket option is disabled. |
| soTimeout               | 0                 | Sets the socket’s read timeout in milliseconds. A value of **`0`** denotes no timeout. |
| soWriteTimeout          | 0                 | Sets the socket’s write timeout in milliseconds. If the socket write operation does not complete before the specified timeout, the socket will be closed. A value of **0** denotes no timeout. |
| stackSize               | 0                 | Set the stack size of the transport’s background reading thread. Must be specified in multiples of **`128K`**. A value of **`0`** indicates that this parameter is ignored. |
| startLogging            | true              | If **`true`** the **`TransportLogger`** object of the Transport stack will initially write messages to the log. This parameter is ignored unless **`trace=true`**. |
| tcpNoDelay              | false             | If **`true`** the socket’s option **`TCP_NODELAY`** is set. This disables Nagle’s algorithm for small packet transmission. |
| threadName              | N/A               | When this parameter is specified the name of the thread is modified during the invocation of a transport. The remote address is appended so that a call stuck in a transport method will have the destination information in the thread name. This is extremely useful when using thread dumps for degugging. |
| trace                   | false             | Causes all commands that are sent over the transport to be logged. To view the logged output define the **`Log4j`** logger: **`log4j.logger.org.apache.activemq.transport.TransportLogger=DEBUG`**. |
| trafficClass            | 0                 | The Traffic Class to be set on the socket.                   |
| diffServ                | 0                 | (Client only) The preferred Differentiated Services traffic class to be set on outgoing packets, as described in RFC 2475. Valid integer values: **`[0,64]`**. Valid string values: **`EF`, `AF[1-3][1-4]`** or **`CS[0-7]`**. With JDK 6, only works when the JVM uses the IPv4 stack. To use the IPv4 stack set the system property **`java.net.preferIPv4Stack=true`**. Note: it’s invalid to specify both ‘**diffServ** and **typeOfService**’ at the same time as they share the same position in the TCP/IP packet headers |
| typeOfService           | 0                 | (Client only) The preferred Type of Service value to be set on outgoing packets. Valid integer values: **`[0,256]`**. With JDK 6, only works when the JVM is configured to use the IPv4 stack. To use the IPv4 stack set the system property **`java.net.preferIPv4Stack=true`**. Note: it’s invalid to specify both ‘**diffServ** and **typeOfService**’ at the same time as they share the same position in the TCP/IP packet headers. |
| useInactivityMonitor    | true              | When **`false`** the **`InactivityMonitor`** is disabled and connections will never time out. |
| useKeepAlive            | true              | When **`true` `KeepAliveInfo`** messages are sent on an idle connection to prevent it from timing out. If this parameter is **`false`** connections will still timeout if no data was received on the connection for the specified amount of time. |
| useLocalHost            | false             | When **`true`** local connections will be made using the value **`localhost`** instead of the actual local host name. On some operating systems, such as **`OS X`**, it’s not possible to connect as the local host name so **`localhost`** is better. |
| useQueueForAccept       | true              | When **`true`** accepted sockets are placed onto a queue for asynchronous processing using a separate thread. |
| wireFormat              | default           | The name of the **`wireFormat`** factory to use.             |
| wireFormat.*            | N/A               | Properties with this prefix are used to configure the **`wireFormat`**. |



# 三、整合SpringBoot

springboot中使用activeMQ

- JmsMessagingTemplate(内使用的是JmsTemplate)

- JmsTemplate

## 1、POM

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.2.3.BUILD-SNAPSHOT</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>
	<groupId>com.mashibing.arika</groupId>
	<artifactId>mq</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<name>mq</name>
	<description>Demo project for Spring Boot</description>

	<properties>
		<java.version>1.8</java.version>
	</properties>

	<dependencies>
		

		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
			<exclusions>
				<exclusion>
					<groupId>org.junit.vintage</groupId>
					<artifactId>junit-vintage-engine</artifactId>
				</exclusion>
			</exclusions>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-activemq</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>
		
		
		<dependency>
		    <groupId>org.messaginghub</groupId>
		    <artifactId>pooled-jms</artifactId>
		</dependency>
				
		<dependency>
	            <groupId>org.apache.commons</groupId>
	            <artifactId>commons-pool2</artifactId>
	        </dependency>
		</dependencies>

	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
			</plugin>
		</plugins>
	</build>

	<repositories>
		<repository>
			<id>spring-milestones</id>
			<name>Spring Milestones</name>
			<url>https://repo.spring.io/milestone</url>
		</repository>
		<repository>
			<id>spring-snapshots</id>
			<name>Spring Snapshots</name>
			<url>https://repo.spring.io/snapshot</url>
			<snapshots>
				<enabled>true</enabled>
			</snapshots>
		</repository>
	</repositories>
	<pluginRepositories>
		<pluginRepository>
			<id>spring-milestones</id>
			<name>Spring Milestones</name>
			<url>https://repo.spring.io/milestone</url>
		</pluginRepository>
		<pluginRepository>
			<id>spring-snapshots</id>
			<name>Spring Snapshots</name>
			<url>https://repo.spring.io/snapshot</url>
			<snapshots>
				<enabled>true</enabled>
			</snapshots>
		</pluginRepository>
	</pluginRepositories>

</project>
```

## 2、yml

```yaml
server:
  port: 80
  
spring:
  activemq:
    broker-url: tcp://localhost:61616
    user: admin
    password: admin
    
    pool:
      enabled: true
      #连接池最大连接数
      max-connections: 5
      #空闲的连接过期时间，默认为30秒
      idle-timeout: 0
    packages:
      trust-all: true
  jms:
    pub-sub-domain: true
```

## 3、Config类

用于生产ConnectionFactory

```java
package com.mashibing.arika;

import javax.jms.ConnectionFactory;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jms.annotation.EnableJms;
import org.springframework.jms.config.DefaultJmsListenerContainerFactory;
import org.springframework.jms.config.JmsListenerContainerFactory;

@Configuration
@EnableJms
public class ActiveMqConfig {

	 @Bean
	    public JmsListenerContainerFactory<?> jmsListenerContainerTopic(ConnectionFactory activeMQConnectionFactory) {
	        DefaultJmsListenerContainerFactory bean = new DefaultJmsListenerContainerFactory();
	        bean.setPubSubDomain(true);
	        bean.setConnectionFactory(activeMQConnectionFactory);
	        return bean;
	    }
	    // queue模式的ListenerContainer
	    @Bean
	    public JmsListenerContainerFactory<?> jmsListenerContainerQueue(ConnectionFactory activeMQConnectionFactory) {
	        DefaultJmsListenerContainerFactory bean = new DefaultJmsListenerContainerFactory();
	        bean.setConnectionFactory(activeMQConnectionFactory);
	        return bean;
	    }
}
```

## 4、sender

```java
@JmsListener(destination = "user",containerFactory = "jmsListenerContainerQueue")
public void receiveStringQueue(String msg) {
	System.out.println("接收到消息...." + msg);
}

@JmsListener(destination = "ooo",containerFactory = "jmsListenerContainerTopic")
public void receiveStringTopic(String msg) {
	System.out.println("接收到消息...." + msg);
}
```

## 5、receiver

```java
import java.util.ArrayList;

import javax.jms.Connection;
import javax.jms.ConnectionFactory;
import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.MessageProducer;
import javax.jms.Queue;
import javax.jms.Session;
import javax.jms.TextMessage;

import org.apache.activemq.command.ActiveMQQueue;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jms.core.JmsMessagingTemplate;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.core.MessageCreator;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
public class MqProducerService {

	@Autowired
	private JmsMessagingTemplate jmsMessagingTemplate;
	
	public void sendStringQueue(String destination, String msg) {
		System.out.println("send...");
		ActiveMQQueue queue = new ActiveMQQueue(destination);
		jmsMessagingTemplate.afterPropertiesSet();
		
		ConnectionFactory factory = jmsMessagingTemplate.getConnectionFactory();
		
		try {
			Connection connection = factory.createConnection();
			connection.start();
			
			Session session = connection.createSession(true, Session.AUTO_ACKNOWLEDGE);
			Queue queue2 = session.createQueue(destination);
			
			MessageProducer producer = session.createProducer(queue2);
			
			TextMessage message = session.createTextMessage("hahaha");
			
			
			producer.send(message);
		} catch (JMSException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		jmsMessagingTemplate.convertAndSend(queue, msg);
	}
	public void sendStringQueueList(String destination, String msg) {
		System.out.println("xxooq");
		ArrayList<String> list = new ArrayList<>();
		list.add("1");
		list.add("2");
		jmsMessagingTemplate.convertAndSend(new ActiveMQQueue(destination), list);
	}
}
```



# 四、高级使用

## 1、Hawtio——服务监控

[官网](https://hawt.io/)

启动后，控制台会打印访问地址

### （1）独立jar运行

java -jar

hawtio单程序运行，可以对多个远程ActiveMQ服务器进行监控

连接信息中的路径activeMQ启动的时候会打印

### （2）嵌入ActiveMQ

下载war包

复制到webapps下（activeMQ的目录）

**jetty.xml bean标签下添加**

加到这个节点下面：<bean id="secHandlerCollection"

```
<bean class="org.eclipse.jetty.webapp.WebAppContext">        
	<property name="contextPath" value="/hawtio" />        
	<property name="war" value="${activemq.home}/webapps/hawtio.war" />        
	<property name="logUrlOnStart" value="true" />  
</bean>
```

**ActiveMQ.bat下添加**

```
if "%ACTIVEMQ_OPTS%" == "" set ACTIVEMQ_OPTS=-Xms1G -Xmx1G -Dhawtio.realm=activemq -Dhawtio.role=admins -Dhawtio.rolePrincipalClasses=org.apache.activemq.jaas.GroupPrincipal -Djava.util.logging.config.file=logging.properties -Djava.security.auth.login.config="%ACTIVEMQ_CONF%\login.config" 
```

这时候不能直接双击了。使用命令启动

```shell
activemq start
```

## 2、JMS消息结构

Message主要由三部分组成，分别是Header，Properties，Body， 详细如下：

| Header     | 消息头，所有类型的这部分格式都是一样的                       |
| ---------- | ------------------------------------------------------------ |
| Properties | 属性，按类型可以分为应用设置的属性，标准属性和消息中间件定义的属性 |
| Body       | 消息正文，指我们具体需要消息传输的内容。                     |

### （1）Header

JMS消息头使用的所有方法：

```java
public interface Message {
    public Destination getJMSDestination() throws JMSException;
    public void setJMSDestination(Destination destination) throws JMSException;
    public int getJMSDeliveryMode() throws JMSException
    public void setJMSDeliveryMode(int deliveryMode) throws JMSException;
    public String getJMSMessageID() throws JMSException;
    public void setJMSMessageID(String id) throws JMSException;
    public long getJMSTimestamp() throws JMSException'
    public void setJMSTimestamp(long timestamp) throws JMSException;
    public long getJMSExpiration() throws JMSException;
    public void setJMSExpiration(long expiration) throws JMSException;
    public boolean getJMSRedelivered() throws JMSException;
    public void setJMSRedelivered(boolean redelivered) throws JMSException;
    public int getJMSPriority() throws JMSException;
    public void setJMSPriority(int priority) throws JMSException;
    public Destination getJMSReplyTo() throws JMSException;
    public void setJMSReplyTo(Destination replyTo) throws JMSException;
    public String getJMScorrelationID() throws JMSException;
    public void setJMSCorrelationID(String correlationID) throws JMSException;
    public byte[] getJMSCorrelationIDAsBytes() throws JMSException;
    public void setJMSCorrelationIDAsBytes(byte[] correlationID) throws JMSException;
    public String getJMSType() throws JMSException;
    public void setJMSType(String type) throws JMSException;
}
```



**消息头分为自动设置和手动设置的内容**

### （2）自动头信息

有一部分可以在创建Session和MessageProducer时设置

| 属性名称        | 说明                                                         | 设置者   |
| --------------- | ------------------------------------------------------------ | -------- |
| JMSDeliveryMode | 消息的发送模式，分为**NON_PERSISTENT**和**PERSISTENT**，即非持久性模式的和持久性模式。默认设置为**PERSISTENT（持久性）。**一条**持久性消息**应该被传送一次（就一次），这就意味着如果JMS提供者出现故障，该消息并不会丢失； 它会在服务器恢复正常之后再次传送。一条**非持久性消息**最多只会传送一次，这意味着如果JMS提供者出现故障，该消息可能会永久丢失。在持久性和非持久性这两种传送模式中，消息服务器都不会将一条消息向同一消息者发送一次以上（成功算一次）。 | send     |
| JMSMessageID    | 消息ID，需要以ID:开头，用于唯一地标识了一条消息              | send     |
| JMSTimestamp    | 消息发送时的时间。这条消息头用于确定发送消息和它被消费者实际接收的时间间隔。时间戳是一个以毫秒来计算的Long类型时间值（自1970年1月1日算起）。 | send     |
| JMSExpiration   | 消息的过期时间，以毫秒为单位，用来防止把过期的消息传送给消费者。任何直接通过编程方式来调用setJMSExpiration()方法都会被忽略。 | send     |
| JMSRedelivered  | 消息是否重复发送过，如果该消息之前发送过，那么这个属性的值需要被设置为true, 客户端可以根据这个属性的值来确认这个消息是否重复发送过，以避免重复处理。 | Provider |
| JMSPriority     | 消息的优先级,0-4为普通的优化级，而5-9为高优先级，通常情况下，高优化级的消息需要优先发送。任何直接通过编程方式调用setJMSPriority()方法都将被忽略。 | send     |
| JMSDestination  | 消息发送的目的地，是一个Topic或Queue                         | send     |



**JMSDeliveryMode**

```java
MessageProducer producer = session.createProducer(topic);
producer.setDeliveryMode(DeliveryMode.NON_PERSISTENT);
```

**JMSExpiration**

```java
//将过期时间设置为1小时（1000毫秒 ＊60 ＊60）
producer.setTimeToLive(1000 * 60 * 60);
```

**JMSPriority**

```
producer.setPriority(9);
```



### （3）手动头信息

| 属性名称         | 说明                                                         | 设置者 |
| ---------------- | ------------------------------------------------------------ | ------ |
| JMSCorrelationID | 关联的消息ID，这个通常用在需要回传消息的时候                 | client |
| JMSReplyTo       | 消息回复的目的地，其值为一个Topic或Queue, 这个由发送者设置，但是接收者可以决定是否响应 | client |
| JMSType          | 由消息发送者设置的消息类型，代表消息的结构，有的消息中间件可能会用到这个，但这个并不是是批消息的种类，比如TextMessage之类的 | client |

从上表中我们可以看到，系统提供的标准头信息一共有10个属性，其中有6个是由send方法在调用时设置的，有三个是由客户端（client）设置的，还有一个是由消息中间件（Provider）设置的。

需要注意的是，这里

## 3、JMSCorrelationID

[官方文档](http://activemq.apache.org/how-should-i-implement-request-response-with-jms.html)

用于消息之间的关联，给人一种会话的感觉

sender:

```java
message.setJMSCorrelationID("AAA");
```

## 4、JMSReplyTo

发送方可以接受到消息消费确认的地址



ActiveMQ5.10.x 以上版本必须使用 JDK1.8 才能正常使用。 

ActiveMQ5.9.x 及以下版本使用 JDK1.7 即可正常使用。



这里的queue也可以用临时的queue

```java
session.createTemporaryQueue();
//这个临时的queue是单一节点使用的，也就说有1w个producer调用这个方法，会产生1w个临时的queue，浪费内存和线程（每个destination单独使用一个线程）
```

**sender**:

```java
message.setJMSReplyTo(new ActiveMQQueue("reply"))
```

//然后写一个consumer去监听这个queue.

**receiver**:

```java
//获得replyTo的queue
message.getJMSReplyTo();
//写producer发送信息
```

## 5、queue Browser

可以查看队列中的消息而不消费，没有订阅的功能

```java
QueueBrowser browser = session.createBrowser(new ActiveMQQueue("queueName"));
//创建browser的时候还可以传一个selector进去，进行筛选
browser.getEnumeration();//取出消息的集合
while(enumseration.hasMoreElements()){//遍历查看，只是查看，不会消费
	(TextMessage)enumser.nextElement();
}
```

## 6、QueueRequestor同步消息

可以发送同步消息

本质违背了mq的异步通讯原则

但是mq还是能够提供应用解耦、异构系统的特性

因为使用QueueRequestor发送消息后，会等待接收端的回复，如果收不到回复就会造成死等现象!而且该方法没有设置超时等待的功能 

**使用**

使用临时的queue，producer创建一个tempQueue，consumer消费消息后发一个消息到tempQueue，producer订阅该queue。

**producer**：

```java
//该session是一个QueueSession(activeMq的，不是jms的)，所以要用activeMQ的connection创建
QueueRequestor queueRequestor = new QueueRequestor(session,queue);
//该方法会阻塞，等待响应
Message mes = queueRequestor.request(message);
```

**consumer**：

```java
Destination replyTo = message.getJMSReplyto();
MesssageProducer producer = session.createProducer(replyTo);
producer.send(session.createMessage("xxxx"));
```

可以保证消息顺序，但一般不适用

## 7、影响性能的几个因素

### （1）Out of memory

activemq启动脚本中配置内存

```
%ACTIVEMQ_OPTS%" == "" set ACTIVEMQ_OPTS=-Xms1G -Xmx1G
```

以及配置文件中的百分比

```
<memoryUsage percentOfJvmHeap="70" />
```

SystemUsage配置设置了一些系统内存和硬盘容量，当系统消耗超过这些容量设置时，amq会“slow down producer”，还是很重要的。

### （2）持久化和非持久化

### （3）消息异步发送

建议使用默认，强制开启有可能丢失消息

异步发送丢失消息的场景是：生产者设置UseAsyncSend=true，使用producer.send(msg)持续发送消息。由于消息不阻塞，生产者会认为所有send的消息均被成功发送至MQ。如果服务端突然宕机，此时生产者端内存中尚未被发送至MQ的消息都会丢失。

```java
new ActiveMQConnectionFactory("tcp://locahost:61616?jms.useAsyncSend=true");
```

```java
((ActiveMQConnectionFactory)connectionFactory).setUseAsyncSend(true);
```

```java
((ActiveMQConnection)connection).setUseAsyncSend(true)
```

### （4）批量确认

ActiveMQ缺省支持批量确认消息，批量确认可以提高系统性能

**关闭方法**

```
new ActiveMQConnectionFactory("tcp://locahost:61616?jms.optimizeAcknowledge=false");
```

```
((ActiveMQConnectionFactory)connectionFactory).setOptimizeAcknowledge(fase);
```

```
((ActiveMQConnection)connection).setOptimizeAcknowledge(true);
```

## 8、消费缓冲与消息积压prefetchSize

消费者端，一般来说消费的越快越好，broker的积压越小越好。

但是考虑到事务性和客户端确认的情况，如果一个消费者一次获取到了很多消息却都不确认，这会造成事务上下文变大，broker端这种“半消费状态”的数据变多，所以ActiveMQ有一个prefetchSize参数来控制未确认情况下，最多可以预获取多少条记录。

**Pre-fetch默认值**

| consumer type | default value |
| ------------- | ------------- |
| queue         | 1000          |
| queue browser | 500           |
| topic         | 32766         |
| durable topic | 1000          |

#### （1）可以通过3中方式设置prefetchSize

**创建连接时整体设置**

```
ActiveMQConnectionFactory connectio nFactory = new ActiveMQConnectionFactory(
	"admin",
	"admin",
	"tcp://localhost:5671?jms.prefetchPolicy.all=50"
	);
```

**创建连接时对topic和queue单独设置**

```
ActiveMQConnectionFactory connectionFactory = new ActiveMQConnectionFactory(
	"admin",
	"admin",
	"tcp://localhost:5671?jms.prefetchPolicy.queuePrefetch=1&jms.prefetchPolicy.topicPrefetch=1"
	);
```

**针对destination单独设置**

```
Destination topic = session.createTopic("user?consumer.prefetchSize=10");
```

注意：对destination设置prefetchsize后会覆盖连接时的设置值



**prefetchSize**：

- consumer创建connection的时候会告诉broker，我的prefetchSize是多少
- 在Queue的doActualDispatch()方法中去做处理（位置在6后半段）

- receive() -> sendPullCommand()






## 9、消息是推是拉

发送消息时是推向broker

获取消息时：

- 默认是一条一条的推
- 当customer的prefetchSize满的时候停止推消息
- 当customer的prefetchSize ==0时 拉取消息

### EIP Enterprise Integration Patterns.

EIP系统是以数据为基础，应用为核心，以实现业务及业务流程的自动化为目的多功能企业信息平台。为企业的信息化建设提供一种循序渐进，逐步优化的路径



<img src="./img/EIP.png"></img>

一个围绕消息集成的企业应用集成场景基本在上面的图中描述的比较清楚的，简单说明如下

1)消息发送方和接收方：可以是异构的业务系统，但是都需要提供Endpoint实现集成。
2)消息本身：两个应用系统通过channel连接，实现了消息本身的发送和接收操作
3)消息Channel：即消息传输的通道，消息本身必须要通过channel来实现传输，从源到达目标。
4)消息路由：当有多个目标接收方的时候，如果根据消息的特征来确定究竟发送到哪个接收方？
5)消息转换：消息在传输过程中是否需要进行转换和数据映射，包括报文格式转换和内容转换映射。
6)Pipe and Filter：在执行复杂的消息流处理时，如何维护消息本身的独立性和灵活性。



常用实现Camel

支持ActiveMQ、RabbitMQ、kafka、WebService

**camel实现了客户端与服务端的解耦， 生产者和消费者的解耦。**

## 10、Request/Response模型实现

- **QueueRequestor**：同步阻塞
- **TemporaryQueue**：异步监听，当消息过多时会创建响应的临时queue
- **JMSCorrelationID 消息属性**：异步监听，公用queue

## 11、调优总结

### （1）Topic加强 可追溯消息

避免topic下错过消息：[官方文档](http://activemq.apache.org/retroactive-consumer.html)

**消费者设置**

```
Destination topic = session.createTopic("tpk?consumer.retroactive=true");
```

#### Summary of Available Recovery Policies

| Policy Name                               | Sample Configuration                                         | Description                                                  |
| ----------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| FixedSizedSubscriptionRecoveryPolicy      | <fixedSizedSubscriptionRecoveryPolicy maximumSize="1024"/>   | Keep a fixed amount of memory in RAM for message history which is evicted in time order. |
| FixedCountSubscriptionRecoveryPolicy      | <fixedCountSubscriptionRecoveryPolicy maximumSize="100"/>    | Keep a fixed count of last messages.                         |
| LastImageSubscriptionRecoveryPolicy       | <lastImageSubscriptionRecoveryPolicy/>                       | Keep only the last message.                                  |
| NoSubscriptionRecoveryPolicy              | <noSubscriptionRecoveryPolicy/>                              | Disables message recovery.                                   |
| QueryBasedSubscriptionRecoveryPolicy      | <queryBasedSubscriptionRecoveryPolicy query="JMSType = 'car' AND color = 'blue'"/> | Perform a user specific query mechanism to load any message they may have missed. Details on message selectors are available [here](http://java.sun.com/j2ee/1.4/docs/api/javax/jms/Message.html) |
| TimedSubscriptionRecoveryPolicy           | <timedSubscriptionRecoveryPolicy recoverDuration="60000" />  | Keep a timed buffer of messages around in memory and use that to recover new subscriptions. Recovery time is in milliseconds. |
| RetainedMessageSubscriptionRecoveryPolicy | <retainedMessageSubscriptionRecoveryPolicy/>                 | Keep the last message with ActiveMQ.Retain property set to true |

‘>’表示通配符

#### 1）保留固定字节的消息

指定在内存的大小

```
<policyEntry topic=">">
	<subscriptionRecoveryPolicy>
		<fixedSizedSubscriptionRecoveryPolicy maximumSize="1024"/>
	</subscriptionRecoveryPolicy>
</policyEntry>
```

#### 2）保留固定数量的消息

```
<policyEntry topic=">">
	<subscriptionRecoveryPolicy>
		<fixedCountSubscriptionRecoveryPolicy maximumSize="100"/>
	</subscriptionRecoveryPolicy>
</policyEntry>
```

#### 3）保留时间

```
<subscriptionRecoveryPolicy>
	<timedSubscriptionRecoveryPolicy recoverDuration="60000" /> 
	</subscriptionRecoveryPolicy>
```

#### 4）保留最后一条

```
<subscriptionRecoveryPolicy>
	<lastImageSubscriptionRecoveryPolicy/>
	</subscriptionRecoveryPolicy>
```

### （2）慢速消费

#### 1）SlowConsumerStrategy

对于慢消费者，broker会启动一个后台线程用来检测所有的慢速消费者，并定期的关闭慢消费者。
 **AbortSlowConsumerStrategy abortConnection**：中断慢速消费者，慢速消费将会被关闭。

```xml
<slowConsumerStrategy>    
    <abortSlowConsumerStrategy abortConnection="false"/><!-- 不关闭底层链接 -->    
</slowConsumerStrategy>
```

 **AbortSlowConsumerStrategy maxTimeSinceLastAck**：如果慢速消费者最后一个ACK距离现在的时间间隔超过阀值，则中断慢速消费者。

```xml
<slowConsumerStrategy>    
    <abortSlowConsumerStrategy  maxTimeSinceLastAck="30000"/><!-- 30秒滞后 -->    
</slowConsumerStrategy>
```

#### 2）PendingMessageLimitStrategy：消息限制策略（面向慢消费者）

[官方文档](http://activemq.apache.org/slow-consumer-handling)

  此策略只对Topic有效，只对未持久化订阅者有效，当通道中有大量的消息积压时，broker可以保留的消息量。为了防止Topic中有慢速消费者，导致整个通道消息积压。
**ConstantPendingMessageLimitStrategy**：保留固定条数的消息，如果消息量超过limit，将使用**消息剔除策略**移除消息。

```xml
<policyEntry topic="ORDERS.>">  
    <!-- lets force old messages to be discarded for slow consumers -->  
    <pendingMessageLimitStrategy>  
        <constantPendingMessageLimitStrategy limit="50"/>  
    </pendingMessageLimitStrategy>  
</policyEntry>
```

 **PrefetchRatePendingMessageLimitStrategy**：保留prefetchSize倍数条消息。

```xml
<!-- 若prefetchSize为100，则保留2.5 * 100条消息 -->  
<prefetchRatePendingMessageLimitStrategy multiplier="2.5"/>
```

### （3）消息堆积内存上涨

- 检查消息是否持久化
- 检查消息 消费速度与生产速度
- 调整xms xmx参数

### （4）磁盘满

当非持久化消息堆积到一定程度，ActiveMQ会将非持久化消息写入临时文件，但是在重启的时候不会恢复

当存储持久化数据的磁盘满了的时候

**持久化消息**

生产者阻塞，消费正常，当消费一部分消息后，腾出空间，生产者继续

**非持久化消息**

由于临时文件造成磁盘满了，生产者阻塞，消费异常，无法提供服务

### （5）开启事务

在发送非持久化消息的时候，可以有效防止消息丢失

### （6）prefetchSize影响消费倾斜

慢速消费的时候可以将prefetchSize设为1，每次取一条

### （7）prefetchSize造成消费者内存溢出

### （8）AUTO_ACKNOWLEDGE造成消息丢失/乱序

消息消费失败后，无法复原消息，可以手动ack 避免broker把消息自动确认删除

receive()方法接受到消息后立即确认

listener 的onmessage方法执行完毕才会确认



手动ack的时候要等connection断开 才会重新推送给其他的consumer，所以有可能会导致消费顺序错乱

### （9）exclusive 和selector有可能造成消息堆积



# 五、集群

[官方文档](http://activemq.apache.org/clustering)

## 1、主备集群

[官方文档](http://activemq.apache.org/masterslave.html)



| Master Slave Type                                            | Requirements                       | Pros                                                         | Cons                                                         |
| ------------------------------------------------------------ | ---------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Shared File System Master Slave](http://activemq.apache.org/shared-file-system-master-slave) | A shared file system such as a SAN | Run as many slaves as required. Automatic recovery of old masters | Requires shared file system                                  |
| [JDBC Master Slave](http://activemq.apache.org/jdbc-master-slave) | A Shared database                  | Run as many slaves as required. Automatic recovery of old masters | Requires a shared database. Also relatively slow as it cannot use the high performance journal |
| [Replicated LevelDB Store](http://activemq.apache.org/replicated-Features/PersistenceFeatures/Persistence/Features/Persistence/leveldb-store) | ZooKeeper Server                   | Run as many slaves as required. Automatic recovery of old masters. Very fast. | Requires a ZooKeeper server.                                 |

#### Shared File System Master Slave

基于共享存储的Master-Slave；多个broker共用同一数据源，谁拿到锁谁就是master,其他处于待启动状态，如果master挂掉了，某个抢到文件锁的slave变成master

**启动后**

<img src="img\Startup.png" />

**Master宕机**

<img src="img\MasterFailed.png"/>



**Master重启**

<img src="img\MasterRestart.png" />



**JDBC Master Slave**

基于JDBC的Master-Slave:使用同一个数据库，拿到LOCK表的写锁的broker成为master.

性能较低，不能使用高性能日志

**Replicated LeveDB Store**

基于zookeeper复制LeveDB存储的Master-Slave机制

**配置步骤**

1. 修改broker名称
2. 修改数据源
   1. 如果使用kahadb，配置相同路径
   2. 如果使用mysql 使用同一数据源（同一数据库和表）

**尝试**

<img src="img\1.png"/>

[官方文档](http://activemq.apache.org/failover-transport-reference.html)

#### failover 故障转移协议

断线重连机制是ActiveMQ的高可用性具体体现之一。ActiveMQ提供failover机制去实现断线重连的高可用性，可以使得连接断开之后，不断的重试连接到一个或多个brokerURL。

默认情况下，如果client与broker直接的connection断开，则client会新起一个线程，不断的从url参数中获取一个url来重试连接。

配置语法

```java
		ActiveMQConnectionFactory connectionFactory = new ActiveMQConnectionFactory(
				"admin",
				"admin",
				"failover:(nio://localhost:5671,nio://localhost:5672)"
				);
```

**可配置选项**

#### Transport Options

| Option Name                   | Default Value | Description                                                  |
| ----------------------------- | ------------- | ------------------------------------------------------------ |
| `backup`                      | `false`       | Initialize and hold a second transport connection - to enable fast failover. |
| `initialReconnectDelay`       | `10`          | The delay (in ms) before the *first* reconnect attempt.      |
| `maxCacheSize`                | `131072`      | Size in bytes for the cache of tracked messages. Applicable only if `trackMessages` is `true`. |
| `maxReconnectAttempts`        | `-1 | 0`      | **From ActiveMQ 5.6**: default is `-1`, retry forever. `0` means disables re-connection, e.g: just try to connect once. **Before ActiveMQ 5.6**: default is `0`, retry forever. **All ActiveMQ versions**: a value `>0` denotes the maximum number of reconnect attempts before an error is sent back to the client. |
| `maxReconnectDelay`           | `30000`       | The maximum delay (in ms) between the *second and subsequent* reconnect attempts. |
| `nested.*`                    | `null`        | **From ActiveMQ 5.9:** common URI options that will be applied to each URI in the list**.** |
| `randomize`                   | `true`        | If `true`, choose a URI at random from the list to use for reconnect. |
| `reconnectDelayExponent`      | `2.0`         | The exponent used during exponential back-off attempts.      |
| `reconnectSupported`          | `true`        | Determines whether the client should respond to broker `ConnectionControl` events with a reconnect (see: `rebalanceClusterClients`). |
| `startupMaxReconnectAttempts` | `-1`          | A value of `-1` denotes that the number of connection attempts at startup should be unlimited. A value of `>=0` denotes the number of reconnect attempts at startup that will be made after which an error is sent back to the client when the client makes a subsequent reconnect attempt. **Note**: once successfully connected the `maxReconnectAttempts` option prevails. |
| `timeout`                     | `-1`          | **From ActiveMQ 5.3**: set the timeout on send operations (in ms) without interruption of re-connection process. |
| `trackMessages`               | `false`       | Keep a cache of in-flight messages that will flushed to a broker on reconnect. |
| `updateURIsSupported`         | `true`        | **From** **ActiveMQ 5.4:** determines whether the client should accept updates from the broker to its list of known URIs. |
| `updateURIsURL`               | `null`        | **From ActiveMQ 5.4:** a URL (or path to a local file) to a text file containing a comma separated list of URIs to use for reconnect in the case of failure. |
| `useExponentialBackOff`       | `true`        | If `true` an exponential back-off is used between reconnect attempts. |
| `warnAfterReconnectAttempts`  | `10`          | **From ActiveMQ 5.10:** a value `>0` specifies the number of reconnect attempts before a warning is logged. A logged warning indicates that there is no current connection but re-connection is being attempted. A value of `<=0` disables the logging of warnings about reconnect attempts. |

**backup**

初始化的时候创建第二个连接，快速故障转移

**initialReconnectDelay**

第一次重试延迟

**trackMessages**

设置是否缓存（故障发生时）尚未传送完成的消息，当broker一旦重新连接成功，便将这些缓存中的消息刷新到新连接的代理中，使得消息可以在broker切换前后顺利传送。默认false

**maxCacheSize**

当trackMessage启动时，缓存的最大子字节数

**maxReconnectAttempts**

默认1|0，自5.6版本开始，-1为默认值，代表不限重试次数，0标识从不重试（只尝试连接一次，并不重连），5.6以前的版本，0为默认值，代表不重试，如果设置大于0的数，则代表最大重试次数。

**maxReconnectDelay**

最长重试间隔

**randomize**

使用随机连接，以达到负载均衡的目的，默认true

只配主备的情况下最好关闭

**startupMaxReconnectAttempts**

初始化时的最大重试次

“-1”表示在启动时连接尝试的次数是无限的。

' >=0 '的值表示在启动时重新连接尝试的次数

一旦成功连接后续将使用“maxReconnectAttempts”选项

**timeout**

连接超时

**updateURIsSupported**

是否可以动态修改broker uri

**updateURIsURL**

指定动态修改地址的路径

**useExponentialBackOff**

重连时间间隔是否以指数形式增长

**reconnectDelayExponent**

指数增长时的指数

**warnAfterReconnectAttempts**

重连日志记录

## 2、负载均衡

[官方文档](http://activemq.apache.org/networks-of-brokers.html)

静态网络配置

<img src="img\2.png"/>

在broker节点下配置networkConnectors

- networkConnectors（网络连接器）主要用来配置ActiveMQ服务端与服务端之间的通信
- TransportConnector（传输连接器）主要用于配置ActiveMQ服务端和客户端之间的通信方式

```
<networkConnectors>
  <networkConnector duplex="true" name="amq-cluster" uri="static:failover://(nio://localhost:5671,nio://localhost:5672)"  />
</networkConnectors>
```

参与的节点都需要修改

注意如果单机启动多个节点，记得修改端口避免冲突

启动成功后`Connections`中会有其他节点

<img src="img\3.png"/>

`Network`中也会显示桥接连接

<img src="img\4.png"/>

负载均衡的环境下，broker上的消息优先给在本地连接的consumer

当networkerConnector与remote Broker建立链接之后，那么remote Broker将会向local Broker交付订阅信息，包括remote broker持有的destinations、Consumers、持久订阅者列表等；那么此后local Broker将把remote Broker做一个消息“订阅者”



**Advisory**

ActiveMQ提供了“Advisory”机制，通常ActiveMQ内部将某些事件作为“advisory”在全局广播，比如destination的创建、consumer的加入、DLQ的产生等，这将额外的消耗极小的性能；我们可以在ActiveMQ的监控页面上看到影响的消息，开发者也可以View这些消息(通道名称以“ActiveMQ.Advisory.”开头)。对于分布式网络中的broker，将严重依赖“Advisory”，特别是“dynamic network”，默认已开启

在一个broker上发生事件，都会以“通知”的方式发送给配置文件中指定的所有networkConnector

**Dynamic networks**

“动态网络”表明当remote Broker持有通道的消费者时，local Broker才会转发相应的消息；此时我们需要开启advisorySupport。当remote broker上有Consumer创建时，Advisory中将会广播消息，消息为ConsumerInfo类型，它将包括consumer所在的broker path，如果local broker与此path建立了networkConnector，那么此后local Broker将会启动响应的消息转发。

**Static networks**

  相对于“动态网络”而言，“静态网络”将不依赖Advisory，在任何时候，即使remote Broker中没有相应的consumer，消息也将转发给remote Broker

将brokers作为简单代理并转发消息到远端而不管是否有消费者

#### 可配置属性

##### URI的几个属性

| property              | default | description                                                  |
| --------------------- | ------- | ------------------------------------------------------------ |
| initialReconnectDelay | 1000    | time(ms) to wait before attempting a reconnect (if useExponentialBackOff is false) |
| maxReconnectDelay     | 30000   | time(ms) to wait before attempting to re-connect             |
| useExponentialBackOff | true    | increases time between reconnect for every failure in a reconnect sequence |
| backOffMultiplier     | 2       | multipler used to increase the wait time if using exponential back off |

##### NetworkConnector Properties

| property                            | default | description                                                  |
| ----------------------------------- | ------- | ------------------------------------------------------------ |
| name                                | bridge  | name of the network - for more than one network connector between the same two brokers - use different names |
| dynamicOnly                         | false   | if true, only activate a networked durable subscription when a corresponding durable subscription reactivates, by default they are activated on startup. |
| decreaseNetworkConsumerPriority     | false   | if true, starting at priority -5, decrease the priority for dispatching to a network Queue consumer the further away it is (in network hops) from the producer. When false all network consumers use same default priority(0) as local consumers |
| networkTTL                          | 1       | the number of brokers in the network that messages and subscriptions can pass through (sets both message&consumer -TTL) |
| messageTTL                          | 1       | (version 5.9) the number of brokers in the network that messages can pass through |
| consumerTTL                         | 1       | (version 5.9) the number of brokers in the network that subscriptions can pass through (keep to 1 in a mesh) |
| conduitSubscriptions                | true    | multiple consumers subscribing to the same destination are treated as one consumer by the network |
| excludedDestinations                | empty   | destinations matching this list won’t be forwarded across the network (this only applies to dynamicallyIncludedDestinations) |
| dynamicallyIncludedDestinations     | empty   | destinations that match this list **will** be forwarded across the network **n.b.** an empty list means all destinations not in the exluded list will be forwarded |
| useVirtualDestSubs                  | false   | if true, the network connection will listen to advisory messages for virtual destination consumers |
| staticallyIncludedDestinations      | empty   | destinations that match will always be passed across the network - even if no consumers have ever registered an interest |
| duplex                              | false   | if true, a network connection will be used to both produce ***AND\*** Consume messages. This is useful for hub and spoke scenarios when the hub is behind a firewall etc. |
| prefetchSize                        | 1000    | Sets the [prefetch size](http://activemq.apache.org/what-is-the-prefetch-limit-for) on the network connector’s consumer. It must be > 0 because network consumers do not poll for messages |
| suppressDuplicateQueueSubscriptions | false   | (from 5.3) if true, duplicate subscriptions in the network that arise from network intermediaries will be suppressed. For example, given brokers A,B and C, networked via multicast discovery. A consumer on A will give rise to a networked consumer on B and C. In addition, C will network to B (based on the network consumer from A) and B will network to C. When true, the network bridges between C and B (being duplicates of their existing network subscriptions to A) will be suppressed. Reducing the routing choices in this way provides determinism when producers or consumers migrate across the network as the potential for dead routes (stuck messages) are eliminated. networkTTL needs to match or exceed the broker count to require this intervention. |
| bridgeTempDestinations              | true    | Whether to broadcast advisory messages for created temp destinations in the network of brokers or not. Temp destinations are typically created for request-reply messages. Broadcasting the information about temp destinations is turned on by default so that consumers of a request-reply message can be connected to another broker in the network and still send back the reply on the temporary destination specified in the JMSReplyTo header. In an application scenario where most/all messages use request-reply pattern, this will generate additional traffic on the broker network as every message typically sets a unique JMSReplyTo address (which causes a new temp destination to be created and broadcasted via an advisory message in the network of brokers). When disabling this feature such network traffic can be reduced but then producer and consumers of a request-reply message need to be connected to the same broker. Remote consumers (i.e. connected via another broker in your network) won’t be able to send the reply message but instead raise a “temp destination does not exist” exception. |
| alwaysSyncSend                      | false   | (version 5.6) When true, non persistent messages are sent to the remote broker using request/reply in place of a oneway. This setting treats both persistent and non-persistent messages the same. |
| staticBridge                        | false   | (version 5.6) If set to true, broker will not dynamically respond to new consumers. It will only use `staticallyIncludedDestinations` to create demand subscriptions |
| userName                            | null    | The username to authenticate against the remote broker       |
| password                            | null    | The password for the username to authenticate against the remote broker |

**name**

相同的名称会被添加到同一集群中

**dynamicOnly**

是否直接转发，设置成true的话 broker会在没有消费者的时候不去转发消息

**decreaseNetworkConsumerPriority**

如果为true，网络的消费者优先级降低为-5。如果为false，则默认跟本地消费者一样为0.

**networkTTL** **messageTTL** **consumerTTL**

消息和订阅在网络中被broker转发（穿过）的最大次数，消息在网络中每转发一次，都会将TTL-1



**conduitSubscriptions**

多个消费者消费消息被当作一个消费者

**excludedDestinations**

在这个名单中的Destination不会在网络中被转发

```
<excludedDestinaitons>
        <queue physicalName="include.test.foo"/>
        <topic physicalName="include.test.bar"/>
　</excludedDestinaitons>
```



**dynamicallyIncludedDestinations**

通过网络转发的destinations，注意空列表代表所有的都转发。

```
　<dynamicallyIncludeDestinaitons>
        <queue physicalName="include.test.foo"/>
        <topic physicalName="include.test.bar"/>
　</dynamicallyIncludeDestinaitons>
```



**useVirtualDestSubs**

开启此选项会在转发消息时

**staticallyIncludedDestinations**

匹配的目的地将始终通过网络传递——即使没有消费者对此感兴趣 对应静态networks

```
 <staticallyIncludeDestinaitons>
        <queue physicalName="aways.include.queue"/>
　</staticallyIncludeDestinaitons>
```



**duplex**

是否允许双向连接**如果该属性为true，当这个节点使用Network Bridge连接到其它目标节点后，将强制目标也建立Network Bridge进行反向连接**

**prefetchSize**

缓冲消息大小，必须大于0，不会主动拉取消息

**suppressDuplicateQueueSubscriptions**

如果为true, 重复的订阅关系一产生即被阻止。

**bridgeTempDestinations**

是否转发临时destination，禁用后再使用request/reply模型的时候客户端需要连接到同一broker，不然会找不到destination

**alwaysSyncSend**

开启后转发非持久化消息会使用request/reply模型

**staticBridge**

如果设置为true，则代理将不会动态响应新的consumer，只能使用staticallyIncludedDestinations中的destination

**userName** **password**

连接broker时的用户名和密码



#### 动态网络配置

[官方文档](http://activemq.apache.org/multicast-transport-reference)



使用multicast协议，可以指定组播地址或使用`multicast://default`（239.255.2.3）

配置`networkConnectors`;`networkConnectors`配置在broker下

```
<networkConnectors>
 <networkConnector uri="multicast://239.0.0.5" duplex="false"/>
</networkConnectors>
```

broker启动后会使用udp协议向组播地址发送数据报文以便让其他在这个组播地址的节点感知到自己的存在

每个UDP数据报中，包含的主要信息包括本节点ActiveMQ的版本信息，以及连接到自己所需要使用的host名字、协议名和端口信息。

配置`transportConnector`指明将哪一个连接通过UDP数据报向其他ActiveMQ节点进行公布，就需要在transportConnector标签上使用discoveryUri属性进行标识

```
	<transportConnector name="auto+nio" uri="auto+nio://localhost:5672" discoveryUri="multicast://239.0.0.5"/>
```



### 消息回流

在消息转发的时候，remote broker转发Local broker的消息会消费掉LocalBroker的消息

那么在转发的过程中，消息在被拉取后和发送给consumer的过程中重启的话会造成消息丢失

`replayWhenNoConsumers` 选项可以使remote broke上有需要转发的消息但是没有被消费时，把消息回流到它原始的broker.同时把enableAudit设置为false,为了防止消息回流后被当作重复消息而不被分发

```
　　　　 <destinationPolicy>
            <policyMap>
              <policyEntries>
                <policyEntry queue=">" enableAudit="false">
                    <networkBridgeFilterFactory>
                        <conditionalNetworkBridgeFilterFactory replayWhenNoConsumers="true"/>
                    </networkBridgeFilterFactory>
                </policyEntry>
              </policyEntries>
            </policyMap>
        </destinationPolicy>
```



### [消息副本](http://activemq.apache.org/replicated-message-store)









**未整理**：

负载均衡

1、使用jdbc：修改brokerName，端口

2、使用kahadb，两个mq指向同一数据源



**destination分享**

destination分享，service2相当于service1的消费者（其实更适合topic，在这种情况下性能提升更明显）

在<broker></broker>节点下配置

duplex="true"：是不是双向的通道

name="amq-cluster"：互联的name相同











Journal ：文件缓存，消费后就不写入数据库，减少写入数据库的数据量，文件比数据库快。





**异步发送消息防丢失**：producer发送消息后，提供一个回调给broker,

ActiveMQMessageProducer中的send方法提供回调

send(message,new AsyncCallback(){});





Timestamp：消息产生的时间

```java
message.getJMSTimestamp();
```

brokerInTime：进broker的时间

brokerOutTime：出broker的时间

# 六、面试题

**1、ActiveMQ如何防止消息丢失？会不会丢消息？**

做高可用

死信队列

持久化

ack

消息重投

记录日志

接收（消费）确认 reply to

broker负载/限流

检查独占消费者

**2、如何防止重复消费？**

消息幂等处理

map *ConcurrentHashMap* -> putIfAbsent   guava cache

map -> putifABsent()，有则返回值，并put不覆盖；无则put成功，返回null；不能用static的，一直put不重启，可能溢出

guava cache有过期机制，防止溢出

**3、如何保证消费顺序？**

queue 优先级别设置

多消费端 -> 

**4、问题**

如果一个消费者获得消息，还未ack，另一个消费者会重复获得消息消费。这时候要做消费逻辑的幂等处理。