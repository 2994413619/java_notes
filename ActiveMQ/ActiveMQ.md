# 一、简介和安装

启动：bin/win64/activemq.bat；web控制台访问路径在启动日志中打印了：http://127.0.0.1:8161/

用户名密码默认为admin admin

配置文件

1、conf/activemq.xml

2、conf/jetty.xml；用户名密码在jetty-realm.properties中

3、消息数据默认存放在数据库中的，在data/kahadb文件夹下，配置实在activamq.xml中

```xml
<persistenceAdapter>
                <kahaDB directory="${activemq.data}/kahadb"/>
</persistenceAdapter>
```



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



4——00:17:47