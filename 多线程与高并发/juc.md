

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

四——4