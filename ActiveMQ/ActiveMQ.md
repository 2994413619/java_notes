# 一、消息中间件简介

## 1、jms

全称：Java MessageService 中文：Java 消息服务。 

### jms中的角色：

broker：消息服务器

provider：生产者

consumer：消费者





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

 

















# 二、简介和安装

[官网](http://activemq.apache.org/)

Windows下：

启动：bin/win64/activemq.bat；web控制台访问路径在启动日志中打印了：http://127.0.0.1:8161/

用户名密码默认为admin admin

linux下：



配置文件

1、conf/activemq.xml

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

2、conf/jetty.xml；用户名密码在jetty-realm.properties中

3、消息数据默认存放在数据库中的，在data/kahadb文件夹下，配置实在activamq.xml中

```xml
<persistenceAdapter>
                <kahaDB directory="${activemq.data}/kahadb"/>
</persistenceAdapter>
```

db-1.log默认32kb





简单应用:

sender:

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



receiver:

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



安全机制：设置后connection中的用户名密码就不能使用null（默认值）了





学习的时候，可以修改activeMQ的持久化方式为JDBC，把消息等数据放到数据库，方便查看。消费后，数据库中的消息数据就被删除了

如果开了持久化，且持久化到mysql中，会异步把内存中的消息数据写入数据库中。消费数据先消费内存中的，然后删除数据库中的数据。比较浪费性能。可用kahadb、LevelDB这种小型数据库，不用远程连接。



事务：开启后不session.commit()，broker中不会有消息；批量提交可以提高性能。

session.rollback();



问题：如果一个消费者获得消息，还未ack，另一个消费者会重复获得消息消费。这时候要做消费逻辑的幂等处理。

 

createSession中，如果开启了事务，第二个参数不生效，默认为CLIENT_ACKNOWLEDGE

开启事务后，可以批量ack；而且broker把消息发送给一个consumer之后，在ack之前，ack期间不会把消息重复发给第二个consumer。



topic默认不会持久化



使用ObjectMessage可能报错，这时候需要把class添加到信任区(接受端)。

list.add(Myclass.class.getPackage().getName())

connectionFactorysetTrustedPackages(list);



使用writeBytes后，在写入其他类型，哪个读的时候必须按顺序读，否则报错EOF

# 死信队列

//到期后进入死信队列里

producer.setTimeToLive(毫秒)

consumer没上线，broker不会检查消息是否过期，上线后才检查，如果过期，则标记为Dequeued，并放入ActiveMQ.DLQ中

非持久化的消息默认不进死信队列

死信队列的消息是会被持久化的



独占消费者，如果有两个consumer都设置了，则谁“先来”，谁独占。



sender消息分组：

message.setStringProperty("key","value");

receiver:

session.createConsumer(queue,"key=value")



设置同步异步发送消息

connectionFactory.setSendAcksAsync(true);//异步

或者：connection.setUseAsyncSend(true);

如果自己没设置，send方法中会自己判断。

```java
if(onComplete==null && sendTimeout <= 0 && !msg.isResponseRequired() && !connection.isAlwaysSyncSend() && (!msg.isPersistent() || connection.isUseAsyncSend() || txid != null)){}
```





消息堆积

ActiveMQ的send方法实现：其中有个producerWindow，是个简单的限流器，发送消息的大小超过了阈值就发不出去了。阈值大小可以在destination中设置，也可以在连接中设置，设置在：tcp://localhost:61616?jms.producerWindowSize=16	



消息延迟发送



间隔重复发送



selector选择器



Journal ：文件缓存，消费后就不写入数据库，减少写入数据库的数据量，文件比数据库快。



springboot中使用activeMQ

JmsMessagingTemplate(内使用的是JmsTemplate)

JmsTemplate



activeMQ不一定要专门启个服务，可以在项目中内嵌：[官网文档](https://activemq.apache.org/vm-transport-reference)



**reply to**

//这里的queue也可以用临时的queue

//session.createTemporaryQueue();这个临时的queue是单一节点使用的，也就说有1w个producer调用这个方法，会产生1w个临时的queue，浪费内存和线程（每个destination单独使用一个线程）

sender:message.setJMSReplyTo(new ActiveMQQueue("reply"))

//然后写一个consumer去监听这个queue.

receiver:

//获得replyTo的queue

message.getJMSReplyTo();

//写producer发送信息



防止消息丢失：

做高可用

死信队列

持久化

ack

消息重投

记录日志

接收（消费）确认 reply to

broker负载/限流

检查独占消费者



消息重复消费

map -> putifABsent()，有则返回值，并put不覆盖；无则put成功，返回null；不能用static的，一直put不重启，可能溢出

 guava cache有过期机制，防止溢出



nio优化的是服务端，提高broker性能，并发量连接数可以更大了（以前可以连2k，现在可以连接10k）



使用auto+nio后，就不用配其他协议了，都可以用

```xml
<transportConnector name="auto+nio" uri="auto+nio://localhost:5671"/>
```

# 高级使用

## **queue browser**

```java
QueueBrowser browser = session.createBrowser(new ActiveMQQueue("queueName"));

创建browser的时候还可以传一个selector进去，进行筛选

browser.getEnumeration();//取出消息的集合

while(enumseration.hasMoreElements()){//遍历查看，只是查看，不会消费

(TextMessage)enumser.nextElement();

}
```



## **Hawtio**

服务监控

启动后，控制台会打印访问地址

以war包的形式启动：复制war包到webapps目录下（activeMQ的目录），然后修改jetty.xml配置文件，然后再修改activemq.bat;然后控制台启动，这时候不能直接双击了。activemq start

jetty.xml：

加到这个节点下面：<bean id="secHandlerCollection"



使用java -jar启动，连接信息中的路径activeMQ启动的时候会打印

## JMSCorrelationID

reply To后消息id会变

sender:

message.setJMSCorrelationID("AAA");



## QueueRequestor同步消息

使用临时的queue，producer创建一个tempQueue，consumer消费消息后发一个消息到tempQueue，producer订阅该queue。

producer：

```java
//该session是一个QueueSession(activeMq的，不是jms的)，所以要用activeMQ的connection创建
QueueRequestor queueRequestor = new QueueRequestor(session,queue);
//该方法会阻塞，等待响应
Message mes = queueRequestor.request(message);
```

consumer：

```java
Destination replyTo = message.getJMSReplyto();
MesssageProducer producer = session.createProducer(replyTo);
producer.send(session.createMessage("xxxx"));
```

可以保证消息顺序，但一般不适用

## 影响性能的几个因素

**prefetchSize**

consumer创建connection的时候会告诉broker，我的prefetchSize是多少

在Queue的doActualDispatch()方法中去做处理（位置在6后半段）

receive() -> sendPullCommand()

**消息是推是拉**



**异步发送消息防丢失**：producer发送消息后，提供一个回调给broker,

ActiveMQMessageProducer中的send方法提供回调

send(message,new AsyncCallback(){});





Timestamp：消息产生的时间

```java
message.getJMSTimestamp();
```

brokerInTime：进broker的时间

brokerOutTime：出broker的时间





## topic加强

保留固定字节的消息：指定在内存的大小

‘>’表示通配符



生产的小问题：消费倾斜

## 集群

**主备集群**

1、使用jdbc：修改brokerName，端口

2、使用kahadb，两个mq指向同一数据源



**destination分享**

destination分享，service2相当于service1的消费者（其实更适合topic，在这种情况下性能提升更明显）

在<broker></broker>节点下配置

duplex="true"：是不是双向的通道

name="amq-cluster"：互联的name相同

8-00：54:21