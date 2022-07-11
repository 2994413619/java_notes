[例子汇总](https://github.com/2994413619/some_demo/tree/main/src/com/ityc/se/juc)

# 一、线程基础知识

## 1、线程的历史

​	——一部对CPU性能压榨的历史

- 单进程人工切换：纸带机
- 多进程批处理：多个任务批量执行
- 多进程并行处理：把程序写在不同的内存位置上来回切换
- 多线程：selector - epoll
- 线程/协程：绿色线程，用户管理的（而不是OS管理的）线程

## 2、进程、线程

<img src="img\计算机的组成.png" />

**进程**：双击“QQ.exe”，会把程序放入到内存中，这就是一个进程，再双击一次，又加载到内存中，又是另一个进程。是操作系统进行资源分配和调度的基本单位。（QQ.exe就是程序）

**线程**：线程共享进程所分配到的“资源”。以线程为单位执行，会找到“QQ.exe”的主线程（main）开始执行

**线程切换**：执行T1：指令加载到PC，registers存数据，ALU计算。切换线程把信息放到缓存中，再执行T2

<img src="img\线程切换.png" />

## 3、思考题

（1）单核CPU设定多线程是否有意义？

有意义：虽然一个核同一时刻只能执行一个线程，但是一个线程不是所有时间都在使用cpu，比如在等待网络输入。

线程类型：

- CPU密集型：线程大量时间在做计算

- IO密集型：线程大量时间在做IO操作（比如拷贝文件）


（2）工作线程数是不是设置的越大越好？

不是：线程切换也需要消耗资源，会花大量时间在切换线程上。

（3）工作线程数（线程中线程数量）设多少合适

可以设置不同的线程数，进行压测，找到最合适的值（小例子：写一个循环加1亿个数的程序，分别给一个线程，2个线程，10000个线程看程序使用了多长时间）

可以根据CPU核数来设置：有多少个核就设置几个线程；但是机器上除了我们的程序，还有其他程序在运行，比如tomcat、操作系统自己的程序。我们可以设置80%，预留20%，当然具体得模拟实际情况进行压测

**公式**(来自《java并发编程实践》)：

N<sub>threads</sub> = N<sub>CPU</sub> * U<sub>CPU</sub> * (1 + W/C)

其中：

- N<sub>CPU</sub>是处理器的核的数目，可以通过Runtime.getRuntime().availableProcessors()得到
- U<sub>CPU</sub>是期望CPU的利用率（该值应该介于0和1之间）
- W/C是等待时间和计算时间的比例（W:wait；C:computer）

（4）你怎么知道线程的等待时间和使用CPU的时间比例呢？

通过工具来进行测算，profiler（统称，是性能统计工具）；工具有好多，常用的有JProfiler（收费）。压测环境和真实环境不一样，咋办，用：Arthas（阿里的）

## 4、创建线程的5种方法

本质上是一种（new Thread().start()）。

（1）继承Thread类

（2）实现Runnable接口（比Thread跟灵活，因为一个类只能继承一个类）

（3）实现Callable接口（Future、FutureTask）

（4）线程池

（5）lamada表达式

```java
public class T01_HowToCreateThread {
    
    public static void main(String[] args) throws Exception{
        FutureTask<String> task = new FutureTask<String>(new MyCall());
        //FutureTask实现了Runnable接口
        Thread t = new Thread(task);
        t.start();
        System.out.println(task.get());

        ExecutorService service = Executors.newCachedThreadPool();
        service.execute(()->{
            System.out.println("hello ThreadPool");
        });
        Future<String> f = service.submit(new MyCall());
        String s = f.get();
        System.out.println(s);
        service.shutdown();

    }
}

class MyCall implements Callable<String> {
    @Override
    public String call(){
        System.out.println("Hello MyCall");
        return "success";
    }
}
```

FutureTask定义：

```java
public class FutureTask<V> implements RunnableFuture<V>
public interface RunnableFuture<V> extends Runnable, Future<V>
```



## 5、零散记录

- 同步和非同步方法可以同时调用。
- atomic lock都是自旋锁
- sleep()：指定时间不使用cpu
- yield()：让出一个cpu时间片
- join()：如果有两个线程t1、t2；t1执行了t2.join()，则暂停t1执行，等待t2执行完再继续执行t1。（经常用来等待另一个线程的介绍，自己调用自己的join方法没什么用）
- stop()：不建议使用，容易产生状态不一致。
- wait()——notify()、notifyAll()
- interrupter()
- lockSupport.park()——LockSupport.unpark()
- getState()：获得线程状态
- 同步异步
  - 同步（synchronized）：同步的概念就是共享，如果不是共享的资源，也就没有必要同步。
  - 异步（asynchronized）：异步的概念就是独立，相互之间不受制约。
    - 同步的目的就是为了线程安全，其实对于线程安全来说，需要满足两个特性：
      - 原子性（同步）
      - 可见性

## 6、synchronized

- synchronized即保证了可见性，也保证了原子性。

- synchronized——Hotspot实现：对象头拿出2位来标志
- synchronized(this)和synchronized方法是等价的，synchronized static方法相当于synchronized(T.class)；T.class也是一个对象（特殊的对象）。
- 写加锁，读不加锁。有可能出现脏读的问题。
- synchronized的可重入性：一个同步方法可以调用另外一个同步方法，一个线程已经拥有某个对象的锁，再次申请的时候仍然会得到该对象的锁。（子类重写父类synchronizd方法，子类调用super...如果不是可重入就会产生死锁）
- 程序中出现异常，锁会被释放。
- synchronized不能用String常量（不同地方使用相同字符串是同一个对象）、Integer（变一下值会变成新的对象）、Long等基础类型
- 锁对象改变：锁定某对象o，如果o的属性发生改变，不影响锁的使用；但是如果o变成另外一个对象，则锁定的对象发生改变；应该避免将锁定对象的引用变成另外的对象。（习惯给锁对象加 final修饰）

## 7、synchronized的底层实现

JDK早期：重量级 - OS

之后改进：

### （1）锁升级

（1）偏向锁（markword 记录这个线程ID）

（2）如果有其他线程争用，升级为自旋锁

（3）默认争抢10次以后，重量级锁 - OS

自旋锁占CPU，但是不访问操作系统，在用户态解决所得问题，不经过内核态，所以效率更高。



**问题**：什么时候用自旋？什么时候用系统锁？

- 执行时间短（加锁代码），线程数少，用自旋
- 执行时间长，线程数多，用系统锁

### （2）synchronized优化

- 锁粒度细化
- 某些情况下也可以进行锁粒度粗化（细锁多，减少锁竞争）

## 8、volatile

volatile关键字只具有可见性，没有原子性。要实现原子性建议使用atomic类的系列对象，支持原子性操作（注意atomic类只保证本身方法原子性，并不保证多次操作的原子性）。netty的底层代码就大量使用了volatile

- 保证线程可见性
  - MESI 缓存一致性协议
- 不保证原子性
- 禁止指令重排（volatile禁止的是语言级别的，不能禁止CPU）
  - 指令
    - loadfence指令
    - storefence指令
  - DCL单例（double check lock）
  - new对象三步（指令重排可能导致第二第三步顺序颠倒）
    - 分配内存
    - 赋初值
    - 变量指向内存地址

问：**到底是强制读主线程的，还是写入时间不定**

## 9、CAS

- 也叫：无锁优化、自旋、乐观锁

- Compare And Swap

- CPU源语支持

- Atomic开头的类都是CAS的

- cas(V, Expected, NewValue)：中间不能被打断，CPU源语支持

  if V == E

  V = New

  otherwise try again or fail

**ABA问题**：原来值是1，一个线程get后，在进行cas操作前，这个1变成了2，又变成了1。

解决方法：利用版本号解决。

atomic中的类：AtomicStampedReference

**Unsafe**

单例；Compare And Set操作都是在Unsafe类中完成。

- 直接操作内存：allocateMemory 
- 直接生成实例
- 直接操作类或实例变量



# 二、线程状态

1、Java中6种线程状态

（1）NEW：					线程刚刚创建，还没有启动

（2）RUNNABLE:			可运行状态，由线程调度器可以安排执行（READY、RUNNING）

（3）WAITING：				等待被唤醒

（4）TIMED WAITING：	隔一段时间后自动唤醒

（5）BLOCKED：			被阻塞

（6）TERMINATED：		线程结束

<img src="img\线程状态切换.png" />

图中的Waiting是忙等待，自旋。除了Synchronized的等锁为blocked，其他的等锁都是WAITING

# 三、线程的“打断”（interrupt）

1、interrupt相关的三个方法

```java
//Thread.java
public void interrupt()				//t.interupt()打断t线程（设置t线程某给标志位f=true，并不是打断线程的运行）
public boolean isInterrupted()		//t.isInterrupted() 查询打断标志位是否被设置（是不是曾经被打断过）
public static boolean interrupted()	//Thread.interrupted() 查看“当前”线程是否被打断，如果被打断，恢复标志位
```

2、sleep、wait、join的时候，调用interrupted，线程会抛出InterruptedException，catch异常后，标志位会复位。

3、interrupt不会打断正在争抢锁、竞争锁的线程，包括synchronized和lock。如果要打断可以使用lock.lockInterruptibly()。

# 四、线程的“结束”

如何优雅的结束一个线程？

eg：上传一个大文件，正在处理费时的计算，如何优雅的结束这个线程？

1、自然结束（能自然结束尽量自然结束）

2、stop()、suspend()、resume()

3、volatile标志

- 不适合某些场景（比如还没有同步的时候，线程做了阻塞操作，没有办法循环回去）
- 打断时间不是特别精准，比如一个阻塞容器，容量为5的时候结束生产者，但是，由于volatile同步线程标志位的时间控制不是很精准，有可能生产者还继续生产一段时间。

4、interrupt、 isInterrupted（比较优雅）

# 五、并发编程三大特性

## 1、可见性（visibility）

### （1）volatile

- volatile可使基本类型线程间可见
- 某些语句会触发内存缓存同步刷新（比如System.out.println，该方法里面使用了synchronized）
- volatile修饰引用类型，对象里面的变量不可见

### （2）多级缓存

<img src="img\三级缓存.png" />

<img src="img\多CPU三级缓存.png" />

registers读数据，是一级一级读先L1、然后L2，线程间可见指的是main memory可见。

### （3）缓存行

：一次读一整块的数据（64 byte）

空间局部性原理：当我用到一个值的时候，一般会用到该值接下来内存的值。

时间局部性原理：当我读了一个指令的时候，很可能会用到下个指令。

<img src="img\cache_line.png" />

### （4）缓存一致性

（和volatile无关）：两个核中如果读入了同一数据，一个核中修改了数据，缓存一致性协议会通知另一个核，另一个核重新同步数据。

```java
public class T16_Cache_line_padding {

    public static long COUNT = 100_0000_0000L;

    private static class T{
        //private long p1,p2,p3,p4,p5,p6,p7;
        @Contended //只有jdk1.8起作用  使用时加上参数：-XX:-RestrictContended
        public volatile long x = 0L;
        //private long p8,p9,p10,p11,p12,p13,p14,p15;
    }

    public static T[] arr = new T[2];

    static {
        arr[0] = new T();
        arr[1] = new T();
    }

    public static void main(String[] args) throws InterruptedException {
        CountDownLatch latch = new CountDownLatch(2);
        Thread t1 = new Thread(() -> {
            for (long i = 0; i < COUNT; i++) {
                arr[0].x = i;
            }
            latch.countDown();
        });

        Thread t2 = new Thread(() -> {
            for (long i = 0; i < COUNT; i++) {
                arr[1].x = i;
            }
            latch.countDown();
        });

        final long startTime = System.nanoTime();
        t1.start();
        t2.start();
        latch.await();
        System.out.println((System.nanoTime() - startTime) / 100_0000);

    }

}
```

- JDK 1.7就是使用了这种填充的写法（LinkedBlockingQueue）
- disruptor开源框架也用来这种写法（单机最强的MQ）RingBuffer类中

**硬件层面的缓存一致性**：不同CPU使用的缓存一致性协议是不同的，MESI Cache一致性协议只是其中一种，是intel设计的。

<img src="img\MESI_Cache.png" />

为什么缓存一行是64字节？

缓存行越大，局部性空间效率高，但读取时间慢

缓存行越小，局部性空间效率越低，但读取时间快

去一个折中值，目前多用：64字节

## 2、有序性（ordering）

### （1）乱序证明

```java
public class T17_Disorder {

    private static int a = 0, b = 0;
    private static int x = 0, y = 0;

    public static void main(String[] args) throws InterruptedException {
        for(long i = 0; i < Long.MAX_VALUE; i++) {
            a = 0;
            b = 0;
            x = 0;
            y = 0;

            CountDownLatch latch = new CountDownLatch(2);

            Thread t1 = new Thread(() -> {
                a = 1;
                x = b;
                latch.countDown();
            });

            Thread t2 = new Thread(()->{
                b = 1;
                y = a;
                latch.countDown();
            });

            t1.start();
            t2.start();
            latch.await();

            if(x == 0 && y ==0) {
                System.out.println("第" + i + "次：x=" + x + ", y=" + y);
                break;
            }

        }
    }

}
```

### （2）为何会有乱序？

答：为了提高效率；比如，一个指令去内存中读数据（但是寄存器的效率是内存的100倍），在这个等待过程中，可以先执行第二个指令（++操作）。

### （3）乱序存在的条件

- as - if - serial
- 不影响单线程的最终一致性

前后两条语句没有依赖关系。

### （4）乱序带来的问题

#### 1）例子

```java
public class T18_NoVisibility {

    private static volatile boolean ready = false;
    private static int number = 0;

    public static void main(String[] args) {
        Thread t1 = new Thread(() -> {
            while (!ready) {
                Thread.yield();
            }
            System.out.println(number);
        });

        t1.start();

        //这两句没有依赖关系，可能乱序执行，导致number输出0
        number = 42;
        ready = true;

    }

}
```

#### 2）对象的半初始化转态

this对象溢出：原因——指令重排，成员变量为中间状态，还没赋初始值，就被另一个线程取出来了

```java
public class T19_This_escape {

    private int num = 8;

    public T19_This_escape(){
        new Thread(()->{
            System.out.println(this.num);//有可能输出0
        }).start();
    }

    public static void main(String[] args) throws IOException {
        new T19_This_escape();
        System.in.read();//保证主线程结束前，上面那个线程执行玩
    }

}
```

所以，最好不要再构造方法里启动线程（可以new线程）

## 3、原子性（atomicity）



# 六、JUC同步工具

## 1、atomic

AtomicLong：CAS锁

LongAdder：分段锁 + CAS；专门用来做多个线程对一个数进行递增。

问题：多个线程对一个数进行递增，那种效率更高？synchronized、AtomicLong、LongAdder

## 2、ReentrantLock

- 可以替代synchronized，使用lock()、unlock()。
- 使用syn锁定的话如果遇到异常，jvm会自动释放锁，但是lock必须手动释放锁，因此经常在finally中进行锁的释放；
- lock.tryLock(5, TimeUnit.SECONDS)尝试5秒内获得锁，获得不了就结束阻塞
- lock.lockInterruptibly()使用该方法表示可以被打断
- new ReentrantLock(true)创建公平锁
- 公平的实现是使用一个队列来实现的，这个队列在AbstractQueuedSynchronizer类中
- 多个condition本质就是多个等待队列，可以notifyAll()指定的线程组


## 3、CountDownLatch门闩

用于某个线程在其他线程之后执行

例子：100个线程执行完后，主线程继续执行

```java
private static void usingCountDownLatch() {
    Thread[] threads = new Thread[100];
    CountDownLatch latch = new CountDownLatch(threads.length);

    for(int i=0; i<threads.length; i++) {
        threads[i] = new Thread(()->{
            int result = 0;
            for(int j=0; j<10000; j++) result += j;
            latch.countDown();
        });
    }

    for (int i = 0; i < threads.length; i++) {
        threads[i].start();
    }

    try {
        latch.await();
    } catch (InterruptedException e) {
        e.printStackTrace();
    }

    System.out.println("end latch");
}
```

## 4、CyclicBarrier线程栅栏

20个线程阻塞，然后一起执行。

```java
public static void main(String[] args) {

    //CyclicBarrier barrier = new CyclicBarrier(20);

    /*CyclicBarrier barrier = new CyclicBarrier(20, new Runnable() {
            @Override
            public void run() {
                System.out.println("满人，发车");
            }
        });*/

    CyclicBarrier barrier = new CyclicBarrier(20, () -> {
        System.out.println("满人，发车");
    });

    for(int i = 0; i < 100; i++) {
        new Thread(()->{
            try {
                System.out.println("等待");
                barrier.await();
                System.out.println("执行");
            } catch (InterruptedException e) {
                e.printStackTrace();
            } catch (BrokenBarrierException e) {
                e.printStackTrace();
            }
        }).start();
    }


}
```

限流工具：Guava RateLimiter

## 5、Phaser

有可能用到的场景：遗传算法

## 6、ReadWriteLock

- 共享锁
- 排他锁（互斥锁）

```java
ReadWriteLock readWriteLock = new ReentrantReadWriteLock();
Lock readLock = readWriteLock.readLock();
Lock writeLock = readWriteLock.writeLock();
```

## 7、Semaphore信号量

同时执行线程的数量，限流

```java
Semaphore s = new Semaphore(2, true);//可以设置为公平
s.acquire();//获得许可，信号减一;没获取到，则阻塞在这,等待其他线程release
s.release();//释放许可
```

## 8、Exchanger

两个线程间交换对象，交换方法是阻塞的

ReadWriteLock——stampedLock

## 9、LockSupport

unpark可以先park执行

```java
LockSupport.park();//当前线程阻塞
LockSupport.unpark(t);//t线程开始运行，停止阻塞
```

# 七、源码：

**读源码原则**：

- 跑步起来不读

- 解决问题就好——目的性

- 一条线索到底

- 无关细节略过

## 1、AQS：

- Template method

- Callback Function

- 父类默认实现

- 子类具体实现


### （1）ReentrantLock源码：

**jdk 11如下**

类继承关系图：NonfairSync ——> Sync ——> AQS（class名:AbstractQueuedSynchronizer）

<img src="img\ReetrantLock_2.png" />

方法调用图：Template method：AQS.acquiree(1)调用了tryAcquire(1)，AQS自己有改方法，但是实际运行中调用的是子类的tryAcquire(1)，子类重写该方法

<img src="img\ReentrantLock_1.png" />





### （2）AQS源码（CLH）

核心：state（volatile int）；该值的意义取决于子类；在ReentrantLock表示0表示未加锁，1表示加了锁，2表示重入了两次。在CountDownLatch中表示。。。

AQS里面维护了一个队列(元素就是node)，有一个内部类Node，node有一个属性是Thread，有前一个节点引用，和后一个节点引用，双向链表（需要看前一个节点的状态）。

<img src="img\AQS_1.png" />



VarHandle  1.9之后才有，通过varhandle可以做cas的原子操作。没有varhandle之前，只能用反射，varhandle效率更高。

- 普通属性原子操作
- 比反射快，直接操作二进制码

## 2、ThreadLocal源码

Thread对象中维护了一个Map，key就是ThreadLocal。

Spring中的声明式事务用了ThreadLocal

ThreadLocal的set()方法：

```java
public void set(T value) {
    Thread t = Thread.currentThread();
    //获得的是Thread中的map;map(ThreadLocal, value)
    ThreadLocalMap map = getMap(t);
    if (map != null) {
        map.set(this, value);
    } else {
        createMap(t, value);
    }
}
```



## 3、强软弱虚引用

- 强：new出来的对象
- 软：堆内存不够，会回收软引用指向的对象
  - 大对象的缓存
  - 常用对象的缓存
- 弱：遭到gc就会回收
  - 缓存，没有容器引用指向的时候就需要清除的缓存
  - ThreadLocal（不使用一定要remove(),不然会内存泄露；弱引用只能解决key,不能解决value）
  - WeakHashMap
- 虚（给写JVM的人用的，或自己写netty）
  - 管理堆外内存
  - JVM回收不到对外堆存，可以用虚引用检测DirectByteBuffer，它被回收的时候，我们通过Queue检测，然后回收堆外内存（java回收堆外内存，Unsafe）

弱引用：

<img src="img\weeakReference.png" />

虚引用：

<img src="img\phantomReference.png" />

# 八、同步容器

## 1、容器Tree

- Collection
  - List
    - CopyOnWriteList
    - Vector      Stack
    - ArrayList
    - LinkedList
  - Set
    - HashSet      LinkedHashMap
    - SortedSet     TreeSet
    - EnumSet
    - CopyOnWriteArraySet
    - ConcurrentSkipListSet
  - Queue
    - Deque
      - ArrayDeque
      - BlokingDeque      LinkedBlockingDeque
    - BlockingQueue
      - ArrayBlockingQueue
      - PriorityBlockingQueue
      - LinkedBlockingQueue
      - TransferQueue         LinkedTransferQueue
      - SynchronousQueue
    - PriorityQueue
    - ConcurrentLinkedQueue
    - DelayQueue
- Map
  - HashMap	LinkedHashMap
  - TreeMap
  - WeakHashMap
  - IdentityHashMap
  - ConcurrentHashMap
  - ConcurrentSkipListMap

## 2、历史

Queue与List主要区别，它是为高并发设计的

Queue的子接口——Deque（双端队列，两端都可以取和放）

1.0的时候只有两个集合：Vector，HashTable；自带锁，基本不用。

```java
//可以把hashMap变成线程安全的；里面new Object()，然后synchronized这个对象
Collections.synchronizedMap(new HashMap<UUID, UUID>());
```

ConcurrentHashMap主要是读的效率更高，写的效率比HashTable低。





> 同步容器类
>
> 1：Vector Hashtable ：早期使用synchronized实现 
>
> 2：ArrayList HashSet ：未考虑多线程安全（未实现同步）
>
> 3：HashSet vs Hashtable StringBuilder vs StringBuffer
>
> 4：Collections.synchronized***工厂方法使用的也是synchronized
>
> 使用早期的同步容器以及Collections.synchronized***方法的不足之处，请阅读：
> http://blog.csdn.net/itm_hadf/article/details/7506529
>
> 使用新的并发容器
> http://xuganggogo.iteye.com/blog/321630



## 3、Map

非同步容器：

- LinkedHashMap遍历效率比HashMap高
- TreeMap：红黑树，排好序的
- HashMap：无序



高并发集合：

- ConcurrentHashMap：无序
- ConcurrentSkipListMap：有序；跳表结构；CAS实现在Tree的节点上太复杂了，所有没有CurrentTreeMap，但是有时候又需要排好序的Map，所有有了这个集合。

[跳表和ConcurrentSkipListMap源码](http://blog.csdn.net/sunxianghuang/article/details/52221913)

## 4、List

CopyOnWriteSet

CopyOnWriteList：写时复制；读不加锁，写的时候，synchronized加锁，并把原来的数组复制一份，操作复制的新数组，然后再替换掉原来的数组。使用情况：读特别多，写比较少。

add源码：

```java
public boolean add(E e) {
    synchronized (lock) {
        Object[] es = getArray();
        int len = es.length;
        es = Arrays.copyOf(es, len + 1);
        es[len] = e;
        setArray(es);
        return true;
    }
}
```

synchronizedList：

```java
List<String> strs = new ArrayList<>();
List<String> strsSync = Collections.synchronizedList(strs);
```



## 5、Queue

Queue方法：

```java
strs.offer(obj);//添加元素
strs.poll();//取出并remove
strs.peek();//取出不remove
```

非BlockingQueue：ConcurrentLinkedQueue

### （1）BlockingQueue

BlockingQueue添加的方法：

```java
//阻塞的存取方法
strs.take();//当队列为null，阻塞
strs.put(obj); //满了就会等待，程序阻塞

//各种添加对比
strs.add(obj);//满了add会抛异常
strs.offer(obj);//满了，会返回false表示添加失败
strs.offer(obj, 1, TimeUnit.SECONDS);//阻塞一秒后失败

```



- LinkedBlockingQueue：无界队列（最大Integer.MAXVALUE）
- ArrayBlockingQueue：有界队列
- DelayQueue：按时间（可自己实现compareTo()）进行任务调度，里面的任务必须实现Delayed接口；本质是PriorityQueque
- PriorityQueque：实现是一个二叉树（小顶堆）
- SynchronousQueue：线程间传单个任务；容量为0；一个线程put()，另一个线程take()。两个均为阻塞方法，也就是说如果没有线程take()，那么put()会一致阻塞，反之亦然。自己实现线程池常用。
- TransferQueue：线程间传过个任务；加入队列后，阻塞，等到被取出后才继续往下执行；自己实现线程池常用



PipedStream：效率低



# 九、线程池

## 1、基础知识

<img src="img\threadPool_1.png" />

Executor：线程定义

ExecutorService：线程的执行





常用类：

- Callable：又返回结果的线程接口
- Future：存储执行的将来产生的结果
- FutureTask：实现了Runnable、Future接口，成员变量还有Callable



CompletableFuture：可管理多个Future返回的结果，底层使用的ForkJoinPool。



JDK提供两种类型的线程池

- ThreadPoolExecutor
- ForkJoinPool
  - 分解汇总的任务
  - 用很少的线程可以执行很多的任务（子任务）TPE做不到先执行任务
  - CPU密集型

线程池里面维和了两个集合，一个是线程集合，一个是任务集合

<img src="img\threadPool_2.png" />



## 2、自定义线程池参数

new ThreadPoolExecutor的七个参数

```java
public ThreadPoolExecutor(int corePoolSize,
                          int maximumPoolSize,
                          long keepAliveTime,
                          TimeUnit unit,
                          BlockingQueue<Runnable> workQueue,
                          ThreadFactory threadFactory,
                          RejectedExecutionHandler handler) {
    ...
}
```

**参数解释**：

keepAliveTime：线程多长时间没活干，超过这个时间归还线程资源给OS

threadFactory：ThreadFactory接口只有一个newThread()方法。传参可以为Executors.defaultThreadFactory()，默认的Factory。该类的newThread方法



线程池开始没线程，任务来了创建线程，到达核心线程数后（核心线程不会回收），放入队列中，队列满了，再创建线程，直到最大线程数，最后执行拒绝策略

**注意点**：

- 创建线程或线程池时要指定有意义的线程名，方便错误回溯；优先级不要设置，默认的就好，设置也没什么用；守护线程设置成false（t.sestDaemon(fasle)——t是线程对象）
- 最好不要用JDK自带的几个线程池，因为它的Queue可能满，造成OOM



### （1）拒绝策略

JDK提供了4种拒绝策略

- Abort：抛异常
- Discard：扔掉，不抛异常
- DiscardOldest：扔掉排队时间最久的
- CallerRuns：调用者处理任务（哪个线程execute()了，就哪个线程执行任务）



自定义拒绝策略：实现RejectedExecutionHandler接口

## 3、Executors

可以理解为线程池的工厂

### （1）SingleThreadPool

可以保证线程执行的顺序

**问题**：为什么要有单线程的线程池？

- 有任务队列（不用自己维护）
- 生命周期管理

```java
//JDK源码
public static ExecutorService newSingleThreadExecutor() {
    return new FinalizableDelegatedExecutorService
        (new ThreadPoolExecutor(1, 1,
                                0L, TimeUnit.MILLISECONDS,
                                new LinkedBlockingQueue<Runnable>()));
}
```



### （2）CachedPool

```java
//JDK源码
public static ExecutorService newCachedThreadPool() {
    return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                                  60L, TimeUnit.SECONDS,
                                  new SynchronousQueue<Runnable>());
}
```



### （3）FixedThreadPool

```java
//JDK源码
public static ExecutorService newFixedThreadPool(int nThreads) {
    return new ThreadPoolExecutor(nThreads, nThreads,
                                  0L, TimeUnit.MILLISECONDS,
                                  new LinkedBlockingQueue<Runnable>());
}
```



**问题**：什么时候用CachedPool vs FixedThreadPool？（阿里建议自定义）

CachedPool：来的线程忽高忽低

FixedThreadPool：来的线程比较稳



### （4）ScheduledPool

```java
//JDK源码
public ScheduledThreadPoolExecutor(int corePoolSize) {
    super(corePoolSize, Integer.MAX_VALUE,
          DEFAULT_KEEPALIVE_MILLIS, MILLISECONDS,
          new DelayedWorkQueue());
}
```

很少用，一般用quartz之类的框架



**问题**：假如提供一个闹钟服务，订阅这个服务的人特别多，10亿人，怎么优化？

**常识**：并发（concurrent）和并行（parallel）的却别

- 并发指任务提交，并行指任务执行
- 并行是并发的子集
- 并发一个CPU交替执行线程，并行多个CPU同时执行多个线程

## 4、ThreadPoolExecutor源码

### （1）常用变量的解释

```java
// 1. `ctl`，可以看做一个int类型的数字，高3位表示线程池状态，低29位表示worker数量
private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
// 2. `COUNT_BITS`，`Integer.SIZE`为32，所以`COUNT_BITS`为29
private static final int COUNT_BITS = Integer.SIZE - 3;
// 3. `CAPACITY`，线程池允许的最大线程数。1左移29位，然后减1，即为 2^29 - 1
private static final int CAPACITY   = (1 << COUNT_BITS) - 1;

// runState is stored in the high-order bits
// 4. 线程池有5种状态，按大小排序如下：RUNNING < SHUTDOWN < STOP < TIDYING < TERMINATED
private static final int RUNNING    = -1 << COUNT_BITS;
private static final int SHUTDOWN   =  0 << COUNT_BITS;
private static final int STOP       =  1 << COUNT_BITS;
private static final int TIDYING    =  2 << COUNT_BITS;
private static final int TERMINATED =  3 << COUNT_BITS;

// Packing and unpacking ctl
// 5. `runStateOf()`，获取线程池状态，通过按位与操作，低29位将全部变成0
private static int runStateOf(int c)     { return c & ~CAPACITY; }
// 6. `workerCountOf()`，获取线程池worker数量，通过按位与操作，高3位将全部变成0
private static int workerCountOf(int c)  { return c & CAPACITY; }
// 7. `ctlOf()`，根据线程池状态和线程池worker数量，生成ctl值
private static int ctlOf(int rs, int wc) { return rs | wc; }

/*
 * Bit field accessors that don't require unpacking ctl.
 * These depend on the bit layout and on workerCount being never negative.
 */
// 8. `runStateLessThan()`，线程池状态小于xx
private static boolean runStateLessThan(int c, int s) {
    return c < s;
}
// 9. `runStateAtLeast()`，线程池状态大于等于xx
private static boolean runStateAtLeast(int c, int s) {
    return c >= s;
}
```

### （2）构造方法

```java
public ThreadPoolExecutor(int corePoolSize,
                          int maximumPoolSize,
                          long keepAliveTime,
                          TimeUnit unit,
                          BlockingQueue<Runnable> workQueue,
                          ThreadFactory threadFactory,
                          RejectedExecutionHandler handler) {
    // 基本类型参数校验
    if (corePoolSize < 0 ||
        maximumPoolSize <= 0 ||
        maximumPoolSize < corePoolSize ||
        keepAliveTime < 0)
        throw new IllegalArgumentException();
    // 空指针校验
    if (workQueue == null || threadFactory == null || handler == null)
        throw new NullPointerException();
    this.corePoolSize = corePoolSize;
    this.maximumPoolSize = maximumPoolSize;
    this.workQueue = workQueue;
    // 根据传入参数`unit`和`keepAliveTime`，将存活时间转换为纳秒存到变量`keepAliveTime `中
    this.keepAliveTime = unit.toNanos(keepAliveTime);
    this.threadFactory = threadFactory;
    this.handler = handler;
}
```

### （3）提交执行task的过程

```java
public void execute(Runnable command) {
    if (command == null)
        throw new NullPointerException();
    /*
     * Proceed in 3 steps:
     *
     * 1. If fewer than corePoolSize threads are running, try to
     * start a new thread with the given command as its first
     * task.  The call to addWorker atomically checks runState and
     * workerCount, and so prevents false alarms that would add
     * threads when it shouldn't, by returning false.
     *
     * 2. If a task can be successfully queued, then we still need
     * to double-check whether we should have added a thread
     * (because existing ones died since last checking) or that
     * the pool shut down since entry into this method. So we
     * recheck state and if necessary roll back the enqueuing if
     * stopped, or start a new thread if there are none.
     *
     * 3. If we cannot queue task, then we try to add a new
     * thread.  If it fails, we know we are shut down or saturated
     * and so reject the task.
     */
    int c = ctl.get();
    // worker数量比核心线程数小，直接创建worker执行任务
    if (workerCountOf(c) < corePoolSize) {
        if (addWorker(command, true))
            return;
        c = ctl.get();
    }
    // worker数量超过核心线程数，任务直接进入队列
    if (isRunning(c) && workQueue.offer(command)) {
        int recheck = ctl.get();
        // 线程池状态不是RUNNING状态，说明执行过shutdown命令，需要对新加入的任务执行reject()操作。
        // 这儿为什么需要recheck，是因为任务入队列前后，线程池的状态可能会发生变化。
        if (! isRunning(recheck) && remove(command))
            reject(command);
        // 这儿为什么需要判断0值，主要是在线程池构造方法中，核心线程数允许为0
        else if (workerCountOf(recheck) == 0)
            addWorker(null, false);
    }
    // 如果线程池不是运行状态，或者任务进入队列失败，则尝试创建worker执行任务。
    // 这儿有3点需要注意：
    // 1. 线程池不是运行状态时，addWorker内部会判断线程池状态
    // 2. addWorker第2个参数表示是否创建核心线程
    // 3. addWorker返回false，则说明任务执行失败，需要执行reject操作
    else if (!addWorker(command, false))
        reject(command);
}
```

### （4）addworker源码解析

```java
private boolean addWorker(Runnable firstTask, boolean core) {
    retry:
    // 外层自旋
    for (;;) {
        int c = ctl.get();
        int rs = runStateOf(c);

        // 这个条件写得比较难懂，我对其进行了调整，和下面的条件等价
        // (rs > SHUTDOWN) || 
        // (rs == SHUTDOWN && firstTask != null) || 
        // (rs == SHUTDOWN && workQueue.isEmpty())
        // 1. 线程池状态大于SHUTDOWN时，直接返回false
        // 2. 线程池状态等于SHUTDOWN，且firstTask不为null，直接返回false
        // 3. 线程池状态等于SHUTDOWN，且队列为空，直接返回false
        // Check if queue empty only if necessary.
        if (rs >= SHUTDOWN &&
            ! (rs == SHUTDOWN &&
               firstTask == null &&
               ! workQueue.isEmpty()))
            return false;

        // 内层自旋
        for (;;) {
            int wc = workerCountOf(c);
            // worker数量超过容量，直接返回false
            if (wc >= CAPACITY ||
                wc >= (core ? corePoolSize : maximumPoolSize))
                return false;
            // 使用CAS的方式增加worker数量。
            // 若增加成功，则直接跳出外层循环进入到第二部分
            if (compareAndIncrementWorkerCount(c))
                break retry;
            c = ctl.get();  // Re-read ctl
            // 线程池状态发生变化，对外层循环进行自旋
            if (runStateOf(c) != rs)
                continue retry;
            // 其他情况，直接内层循环进行自旋即可
            // else CAS failed due to workerCount change; retry inner loop
        } 
    }
    boolean workerStarted = false;
    boolean workerAdded = false;
    Worker w = null;
    try {
        w = new Worker(firstTask);
        final Thread t = w.thread;
        if (t != null) {
            final ReentrantLock mainLock = this.mainLock;
            // worker的添加必须是串行的，因此需要加锁
            mainLock.lock();
            try {
                // Recheck while holding lock.
                // Back out on ThreadFactory failure or if
                // shut down before lock acquired.
                // 这儿需要重新检查线程池状态
                int rs = runStateOf(ctl.get());

                if (rs < SHUTDOWN ||
                    (rs == SHUTDOWN && firstTask == null)) {
                    // worker已经调用过了start()方法，则不再创建worker
                    if (t.isAlive()) // precheck that t is startable
                        throw new IllegalThreadStateException();
                    // worker创建并添加到workers成功
                    workers.add(w);
                    // 更新`largestPoolSize`变量
                    int s = workers.size();
                    if (s > largestPoolSize)
                        largestPoolSize = s;
                    workerAdded = true;
                }
            } finally {
                mainLock.unlock();
            }
            // 启动worker线程
            if (workerAdded) {
                t.start();
                workerStarted = true;
            }
        }
    } finally {
        // worker线程启动失败，说明线程池状态发生了变化（关闭操作被执行），需要进行shutdown相关操作
        if (! workerStarted)
            addWorkerFailed(w);
    }
    return workerStarted;
}
```

### （5）线程池worker任务单元

本身就是一个线程，可以用来执行；也是一个锁，可以自己worker.lock()

```java
private final class Worker
    extends AbstractQueuedSynchronizer
    implements Runnable
{
    /**
     * This class will never be serialized, but we provide a
     * serialVersionUID to suppress a javac warning.
     */
    private static final long serialVersionUID = 6138294804551838833L;

    /** Thread this worker is running in.  Null if factory fails. */
    final Thread thread;
    /** Initial task to run.  Possibly null. */
    Runnable firstTask;
    /** Per-thread task counter */
    volatile long completedTasks;

    /**
     * Creates with given first task and thread from ThreadFactory.
     * @param firstTask the first task (null if none)
     */
    Worker(Runnable firstTask) {
        setState(-1); // inhibit interrupts until runWorker
        this.firstTask = firstTask;
        // 这儿是Worker的关键所在，使用了线程工厂创建了一个线程。传入的参数为当前worker
        this.thread = getThreadFactory().newThread(this);
    }

    /** Delegates main run loop to outer runWorker  */
    public void run() {
        runWorker(this);
    }

    // 省略代码...
}
```

### （6）核心线程执行逻辑-runworker

```java
final void runWorker(Worker w) {
    Thread wt = Thread.currentThread();
    Runnable task = w.firstTask;
    w.firstTask = null;
    // 调用unlock()是为了让外部可以中断
    w.unlock(); // allow interrupts
    // 这个变量用于判断是否进入过自旋（while循环）
    boolean completedAbruptly = true;
    try {
        // 这儿是自旋
        // 1. 如果firstTask不为null，则执行firstTask；
        // 2. 如果firstTask为null，则调用getTask()从队列获取任务。
        // 3. 阻塞队列的特性就是：当队列为空时，当前线程会被阻塞等待
        while (task != null || (task = getTask()) != null) {
            // 这儿对worker进行加锁，是为了达到下面的目的
            // 1. 降低锁范围，提升性能
            // 2. 保证每个worker执行的任务是串行的
            w.lock();
            // If pool is stopping, ensure thread is interrupted;
            // if not, ensure thread is not interrupted.  This
            // requires a recheck in second case to deal with
            // shutdownNow race while clearing interrupt
            // 如果线程池正在停止，则对当前线程进行中断操作
            if ((runStateAtLeast(ctl.get(), STOP) ||
                 (Thread.interrupted() &&
                  runStateAtLeast(ctl.get(), STOP))) &&
                !wt.isInterrupted())
                wt.interrupt();
            // 执行任务，且在执行前后通过`beforeExecute()`和`afterExecute()`来扩展其功能。
            // 这两个方法在当前类里面为空实现。
            try {
                beforeExecute(wt, task);
                Throwable thrown = null;
                try {
                    task.run();
                } catch (RuntimeException x) {
                    thrown = x; throw x;
                } catch (Error x) {
                    thrown = x; throw x;
                } catch (Throwable x) {
                    thrown = x; throw new Error(x);
                } finally {
                    afterExecute(task, thrown);
                }
            } finally {
                // 帮助gc
                task = null;
                // 已完成任务数加一 
                w.completedTasks++;
                w.unlock();
            }
        }
        completedAbruptly = false;
    } finally {
        // 自旋操作被退出，说明线程池正在结束
        processWorkerExit(w, completedAbruptly);
    }
}
```

## 5、WorkStealingPool

每个线程都有自己的队列，当线程自己的队列空了后，会拿别人别的线程队列里的任务。底层调用的ForkJoinPool，相当于封装了一下ForkJoinPool，用起来更方便；不是TreadPoolExecutor。

**原理**：

- 多个work queue
- 采用work stealing算法

<img src= "img\WorkStealingPool.png" />

## 6、ForkJoinPool

- 一个任务太大，可以切成一个一个小任务，然后再把每个任务的结果汇总
- 比如：10亿个数，相加
- fork:分解任务；join：汇总任务结果
- 线程池里的任务必须是可以拆分的任务，可以继承RecursiveAction类，无返回值；继承RecursiveTask类，无返回值



## 7、ParallelStreamAPI 

并行流：里面用的也是forkJoinPool

例子：对比流式处理和并行流的执行时间

# 十、JMH

Java MicrobenChmark Harness

[官网]( http://openjdk.java.net/projects/code-tools/jmh/ ) 

[进一步学习，官方样例](http://hg.openjdk.java.net/code-tools/jmh/file/tip/jmh-samples/src/main/java/org/openjdk/jmh/samples/)

- 2013年首发
- 由JIT的开发人员开发
- 归于OpenJDK

## 1、创建JMH测试

1. 创建Maven项目，添加依赖

   ```java
   <?xml version="1.0" encoding="UTF-8"?>
   <project xmlns="http://maven.apache.org/POM/4.0.0"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
       <modelVersion>4.0.0</modelVersion>
   
       <properties>
           <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
           <encoding>UTF-8</encoding>
           <java.version>1.8</java.version>
           <maven.compiler.source>1.8</maven.compiler.source>
           <maven.compiler.target>1.8</maven.compiler.target>
       </properties>
   
       <groupId>mashibing.com</groupId>
       <artifactId>HelloJMH2</artifactId>
       <version>1.0-SNAPSHOT</version>
   
   
       <dependencies>
           <!-- https://mvnrepository.com/artifact/org.openjdk.jmh/jmh-core -->
           <dependency>
               <groupId>org.openjdk.jmh</groupId>
               <artifactId>jmh-core</artifactId>
               <version>1.21</version>
           </dependency>
   
           <!-- https://mvnrepository.com/artifact/org.openjdk.jmh/jmh-generator-annprocess -->
           <dependency>
               <groupId>org.openjdk.jmh</groupId>
               <artifactId>jmh-generator-annprocess</artifactId>
               <version>1.21</version>
               <scope>test</scope>
           </dependency>
       </dependencies>
   
   
   </project>
   ```

2. idea安装JMH插件 JMH plugin v1.0.3

3. 由于用到了注解，打开运行程序注解配置

   > compiler -> Annotation Processors -> Enable Annotation Processing

4. 定义需要测试类PS (ParallelStream)

   ```java
   package com.mashibing.jmh;
   
   import java.util.ArrayList;
   import java.util.List;
   import java.util.Random;
   
   public class PS {
   
   	static List<Integer> nums = new ArrayList<>();
   	static {
   		Random r = new Random();
   		for (int i = 0; i < 10000; i++) nums.add(1000000 + r.nextInt(1000000));
   	}
   
   	static void foreach() {
   		nums.forEach(v->isPrime(v));
   	}
   
   	static void parallel() {
   		nums.parallelStream().forEach(PS::isPrime);
   	}
   	
   	static boolean isPrime(int num) {
   		for(int i=2; i<=num/2; i++) {
   			if(num % i == 0) return false;
   		}
   		return true;
   	}
   }
   ```

5. 写单元测试

   > 这个测试类一定要在test package下面
   >
   > ```java
   > package com.mashibing.jmh;
   > 
   > import org.openjdk.jmh.annotations.Benchmark;
   > 
   > import static org.junit.jupiter.api.Assertions.*;
   > 
   > public class PSTest {
   > @Benchmark	//JDK的注解，不过自由定义
   > /*@Warmup(iterations = 1, time = 3)//每次调用前，预热，两次预热间隔3秒
   > @Fork(5) //启5个线程执行
   > @BenchmarkMode(Mode.Throughput) //Mode.Throughput:吞吐量	次/秒  ops/time
   > @Measurement(iterations = 1, time = 3) //方法调用1次*/
   > public void testForEach() {
   >   PS.foreach();
   > }
   > }
   > ```

6. 运行测试类，如果遇到下面的错误：

   ```java
   ERROR: org.openjdk.jmh.runner.RunnerException: ERROR: Exception while trying to acquire the JMH lock (C:\WINDOWS\/jmh.lock): C:\WINDOWS\jmh.lock (拒绝访问。), exiting. Use -Djmh.ignoreLock=true to forcefully continue.
   	at org.openjdk.jmh.runner.Runner.run(Runner.java:216)
   	at org.openjdk.jmh.Main.main(Main.java:71)
   ```

   这个错误是因为JMH运行需要访问系统的TMP目录，解决办法是：

   打开RunConfiguration -> Environment Variables -> include system environment viables

7. 阅读测试报告

## 2、JMH中的基本概念

1. Warmup
   预热，由于JVM中对于特定代码会存在优化（本地化, JIT），预热对于测试结果很重要
2. Mesurement
   总共执行多少次测试
3. Timeout
4. Threads
   线程数，由fork指定
5. Benchmark mode
   基准测试的模式
6. Benchmark
   测试哪一段代码

# 十一、Disruptor

单机性能最好的消息队列

[代码](https://github.com/bjmashibing/MaShiBingDisrutpor)

## 1、介绍

主页：http://lmax-exchange.github.io/disruptor/

源码：https://github.com/LMAX-Exchange/disruptor

GettingStarted: https://github.com/LMAX-Exchange/disruptor/wiki/Getting-Started

api: http://lmax-exchange.github.io/disruptor/docs/index.html

maven: https://mvnrepository.com/artifact/com.lmax/disruptor

## 2、Disruptor的特点

对比ConcurrentLinkedQueue : 链表实现

JDK中没有ConcurrentArrayQueue

Disruptor是数组实现的

无锁，高并发，使用环形Buffer，直接覆盖（不用清除）旧的数据，降低GC频率

实现了基于事件的生产者消费者模式（观察者模式）

## 3、RingBuffer

<img src="img\disruptor_1.png" />

环形队列

RingBuffer的序号，指向下一个可用的元素

采用数组实现，没有首尾指针

对比ConcurrentLinkedQueue，用数组实现的速度更快

> 假如长度为8，当添加到第12个元素的时候在哪个序号上呢？用12%8决定
>
> 当Buffer被填满的时候到底是覆盖还是等待，由Producer决定
>
> 长度设为2的n次幂，利于二进制计算，例如：12%8 = 12 & (8 - 1)  pos = num & (size -1)

## 4、Disruptor开发步骤

1. 定义Event - 队列中需要处理的元素

2. 定义Event工厂，用于填充队列

   > 这里牵扯到效率问题：disruptor初始化的时候，会调用Event工厂，对ringBuffer进行内存的提前分配
   >
   > GC产频率会降低

3. 定义EventHandler（消费者），处理容器中的元素

## 5、事件发布模板

```java
long sequence = ringBuffer.next();  // Grab the next sequence
try {
    LongEvent event = ringBuffer.get(sequence); // Get the entry in the Disruptor
    // for the sequence
    event.set(8888L);  // Fill with data
} finally {
    ringBuffer.publish(sequence);
}
```

## 6、使用EventTranslator发布事件

```java
//===============================================================
        EventTranslator<LongEvent> translator1 = new EventTranslator<LongEvent>() {
            @Override
            public void translateTo(LongEvent event, long sequence) {
                event.set(8888L);
            }
        };

        ringBuffer.publishEvent(translator1);

        //===============================================================
        EventTranslatorOneArg<LongEvent, Long> translator2 = new EventTranslatorOneArg<LongEvent, Long>() {
            @Override
            public void translateTo(LongEvent event, long sequence, Long l) {
                event.set(l);
            }
        };

        ringBuffer.publishEvent(translator2, 7777L);

        //===============================================================
        EventTranslatorTwoArg<LongEvent, Long, Long> translator3 = new EventTranslatorTwoArg<LongEvent, Long, Long>() {
            @Override
            public void translateTo(LongEvent event, long sequence, Long l1, Long l2) {
                event.set(l1 + l2);
            }
        };

        ringBuffer.publishEvent(translator3, 10000L, 10000L);

        //===============================================================
        EventTranslatorThreeArg<LongEvent, Long, Long, Long> translator4 = new EventTranslatorThreeArg<LongEvent, Long, Long, Long>() {
            @Override
            public void translateTo(LongEvent event, long sequence, Long l1, Long l2, Long l3) {
                event.set(l1 + l2 + l3);
            }
        };

        ringBuffer.publishEvent(translator4, 10000L, 10000L, 1000L);

        //===============================================================
        EventTranslatorVararg<LongEvent> translator5 = new EventTranslatorVararg<LongEvent>() {

            @Override
            public void translateTo(LongEvent event, long sequence, Object... objects) {
                long result = 0;
                for(Object o : objects) {
                    long l = (Long)o;
                    result += l;
                }
                event.set(result);
            }
        };

        ringBuffer.publishEvent(translator5, 10000L, 10000L, 10000L, 10000L);
```

## 7、使用Lamda表达式

```java
package com.mashibing.disruptor;

import com.lmax.disruptor.RingBuffer;
import com.lmax.disruptor.dsl.Disruptor;
import com.lmax.disruptor.util.DaemonThreadFactory;

public class Main03
{
    public static void main(String[] args) throws Exception
    {
        // Specify the size of the ring buffer, must be power of 2.
        int bufferSize = 1024;

        // Construct the Disruptor
        Disruptor<LongEvent> disruptor = new Disruptor<>(LongEvent::new, bufferSize, DaemonThreadFactory.INSTANCE);

        // Connect the handler
        disruptor.handleEventsWith((event, sequence, endOfBatch) -> System.out.println("Event: " + event));

        // Start the Disruptor, starts all threads running
        disruptor.start();

        // Get the ring buffer from the Disruptor to be used for publishing.
        RingBuffer<LongEvent> ringBuffer = disruptor.getRingBuffer();


        ringBuffer.publishEvent((event, sequence) -> event.set(10000L));

        System.in.read();
    }
}
```

## 8、ProducerType生产者线程模式

> ProducerType有两种模式 Producer.MULTI和Producer.SINGLE
>
> 默认是MULTI，表示在多线程模式下产生sequence
>
> 如果确认是单线程生产者，那么可以指定SINGLE，效率会提升
>
> 如果是多个生产者（多线程），但模式指定为SINGLE，会出什么问题呢？

## 9、等待策略

（1）(常用）BlockingWaitStrategy：通过线程阻塞的方式，等待生产者唤醒，被唤醒后，再循环检查依赖的sequence是否已经消费。

（2）BusySpinWaitStrategy：线程一直自旋等待，可能比较耗cpu

（3）LiteBlockingWaitStrategy：线程阻塞等待生产者唤醒，与BlockingWaitStrategy相比，区别在signalNeeded.getAndSet,如果两个线程同时访问一个访问waitfor,一个访问signalAll时，可以减少lock加锁次数.

（4）LiteTimeoutBlockingWaitStrategy：与LiteBlockingWaitStrategy相比，设置了阻塞时间，超过时间后抛异常。

（5）PhasedBackoffWaitStrategy：根据时间参数和传入的等待策略来决定使用哪种等待策略

（6）TimeoutBlockingWaitStrategy：相对于BlockingWaitStrategy来说，设置了等待时间，超过后抛异常

（7）（常用）YieldingWaitStrategy：尝试100次，然后Thread.yield()让出cpu

（8）（常用）SleepingWaitStrategy : sleep

## 10、消费者异常处理

默认：disruptor.setDefaultExceptionHandler()

覆盖：disruptor.handleExceptionFor().with()

## 11、依赖处理



# 十二、ThreadPoolExecutor源码









# 十三、面试题

**1、如何保证几个线程顺序执行**

法一：主线程中顺序执行start、join方法

```java
Thread thread1 = new Thread(new A());
thread1.start();
thread1.join();
Thread thread2 = new Thread(new B());
thread2.start();
thread2.join();
Thread thread3 = new Thread(new C());
thread3.start();
```

法二：创建一个只有一根线程的线程池，保证所有任务按照指定顺序执行

```java
ExecutorService executorService = Executors.newSingleThreadExecutor();
executorService.submit(new A());
executorService.submit(new B());
executorService.submit(new C());
executorService.shutdown();
```

**2、实现一个容器，提供两个方法，add，size；写两个线程，线程1添加10个元素到容器中，线程2实现监控元素的个数，当个数到5个时，线程2给出提示并结束。**

**3、写一个固定容量同步容器，拥有put和get方法，以及getCount方法，能够支持2个生产者线程以及10个消费者线程的阻塞调用**

**4、两个线程交替打印A-Z、1-26**





