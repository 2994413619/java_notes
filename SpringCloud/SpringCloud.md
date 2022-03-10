# Eureka

[配置单个、两个、多个eureka](https://docs.spring.io/spring-cloud-netflix/docs/current/reference/html/#spring-cloud-eureka-server-standalone-mode)

[github](https://github.com/Netflix/eureka)

## 1、问题

（1）为什么导入eureka-server的jar,加一个@EnableEurekaServer注解就可以成为eureka注册中心？

@EnableEurekaServer注解主要作用是创建了一个maker对象。

位置：@EnableEurekaServer注解上导入了类@Import({EurekaServerMarkerConfiguration.class})，进入这个类，就看到new Maker()。

在eureka-server的EurekaServerAutoConfiguration类上有个注解@ConditionalOnBean({Marker.class})，表示有Marker这个对象就加载配置。Marker对象相当于是一个开关

EurekaServerAutoConfiguration位置：eureka-server.jar的META-INF下的spring.factories

```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
  org.springframework.cloud.netflix.eureka.server.EurekaServerAutoConfiguration
```

EurekaServerAutoConfiguration：

```java
@Import({EurekaServerInitializerConfiguration.class})
@ConditionalOnBean({Marker.class})
@EnableConfigurationProperties({EurekaDashboardProperties.class, InstanceRegistryProperties.class})
@PropertySource({"classpath:/eureka/server.properties"})
public class EurekaServerAutoConfiguration implements WebMvcConfigurer {
    ...
}
```

<img src="img\eureka-server-marker.png" />





（2）在CAP定律中，eureka 为什么是AP。

- 三级缓存，读的并不是实时的，读的是缓存注册表
- 从其他peer拉取注册表。peer。int registryCount = this.registry.syncUp()



## 2、源码

### （1）剔除服务源码

涉及到优化

**EurekaServerInitializerConfiguration.start() 主要做的事情**：

- 从peer拉去注册表
- 启动定时剔除任务
- 自我保护

**剔除逻辑，源码跟踪**：

```java
//进入EurekaServerAutoConfiguration上import注解的类
EurekaServerInitializerConfiguration.start();
//进入以下方法
this.eurekaServerBootstrap.contextInitialized(this.servletContext);
//进入以下方法
this.initEurekaServerContext();
//进入
this.registry.openForTraffic(this.applicationInfoManager, registryCount);
//进入
super.postInit();

//这里加入了个剔除任务，进去查看
this.evictionTaskRef.set(new AbstractInstanceRegistry.EvictionTask());
//进入run()的这一行,该方法就是具体的剔除逻辑
AbstractInstanceRegistry.this.evict(compensationTimeMs);
```

**自我保护机制优化**：

- 服务多，开自我保护
- 服务少，不开

**原因**：

当注册的服务到达自我保护的阈值（比如，一共注册10个服务，阈值是80%，这时候挂了3个，接下来触发自我保护，接下来一个服务真的挂了， 但是由于自我保护没有剔除，则其他服务调用改服务就会出错）。

**例子**：

阈值80%

一共10个服务，挂3个，开启自我保护，这时候有一个服务真的挂了，但是没有剔除，其他服务就调用到挂了的服务了。

一共100个服务，挂3个，这时候没有打到阈值，没开启自我保护，真挂一个，那么就剔除了，没有问题。其他服务也请求屠刀这里来



map<服务名，map<实例id，实例信息>>

```
ConcurrentHashMap<String, Map<String, Lease<InstanceInfo>>>
```

<img src="img\eureka-server-self-preservation.png" />

### （2）三级缓存源码

跑一个eureka-server和一个client

访问eureka-server：http://localhost:7900/eureka/apps/1

debug eureka-server

```java
//进入
com.netflix.eureka.resources.ApplicationResource#getApplication
//进入
String payLoad = this.responseCache.get(cacheKey);

// 从缓存中取instance的源码
try {
    if (useReadOnlyCache) {
        ResponseCacheImpl.Value currentPayload = (ResponseCacheImpl.Value)this.readOnlyCacheMap.get(key);
        if (currentPayload != null) {
            payload = currentPayload;
        } else {
            payload = (ResponseCacheImpl.Value)this.readWriteCacheMap.get(key);
            this.readOnlyCacheMap.put(key, payload);
        }
    } else {
        payload = (ResponseCacheImpl.Value)this.readWriteCacheMap.get(key);
    }
} catch (Throwable var5) {
    logger.error("Cannot get value for key : {}", key, var5);
}
```

readWriteCacheMap和readOnlyCacheMap 30秒同步一次的代码：com.netflix.eureka.registry.ResponseCacheImpl#ResponseCacheImpl

### （3）集群同步源码

动作：新启动项目，注册的时候

```java
//入口
com.netflix.eureka.resources.ApplicationResource#addInstance
//进入
registry.register(info, "true".equals(isReplication));
//集群同步
replicateToPeers(Action.Register, info.getAppName(), info.getId(), info, null, isReplication);
```

### （4）client下线、续约

源码：com.netflix.eureka.resources.InstanceResource

### （5）服务拉取

访问：http://localhost:7900/eureka/apps，可进入：com.netflix.eureka.resources.ApplicationsResource#getContainers

com.netflix.eureka.resources.ApplicationsResource#getContainerDifferential

### （6）client不需要加注解开启

该类上默认开启了

```java
@ConditionalOnProperty(value = "eureka.client.enabled", matchIfMissing = true)
...
public class EurekaClientAutoConfiguration {
    ...
    public EurekaClient eurekaClient...
}


@ImplementedBy(DiscoveryClient.class)
public interface EurekaClient extends LookupService {
    ...
}
```

无论是eureka还是consul只要实现了DiscoveryClient接口就可以当注册中心的client端。

**client启动**：

- 封装和server交互的配置
- 初始化定时任务
  - 发送心跳
  - 缓存刷新
  - 状态改变监听（按需注册，client的实例信息和server上的不一样；reflesh，动态刷新）
- 发起注册，等40秒后

<img src="img\eureka-client-1.png" />



## 3、eureka-server配置优化

```yaml
spring:
  application:
    name: eureka
server:
  port: 7900

eureka:
  instance:
    hostname: localhost
  client:
    registerWithEureka: false
    fetchRegistry: false
    serviceUrl:
	    # 写了多个地址，第一个注册成功，就不会想后面的地址注册了；同样，也只从第一个server拉去注册表
	    # 如果写了4个server地址，向前三个注册失败，不会向第四个注册。（retry默认3）
	    # 源码 com.netflix.discovery.shared.transport.decorator.RetryableEurekaHttpClient#execute
	    # 优化点：所以，不同的client使用不同的顺序，不然所有client的请求都打到第一个eureka上了
      defaultZone: http://${eureka.instance.hostname}:${server.port}/eureka/
  server:
    # 自我保护
    enable-self-preservation: false
    # 自我保护阈值，默认0.85
    renewal-percent-threshold: 0.85
    # 快速下线 eureka-server检查服务，并提出；检查间隔
    eviction-interval-timer-in-ms: 1000
    # 三级缓存 com.netflix.eureka.resources.ApplicationResource.addInstance
    # register readWriteCacheMap readOnlyCacheMap 默认true，getAppli的时候会先从readOnlyCacheMap中取，为null在readWriteCacheMap中取。
    # register和readWriteCacheMap是一致的；readWriteCacheMap和readOnlyCacheMap 30秒同步一次
    use-read-only-response-cache: false
    # readWrite 和 readOnly 同步时间间隔 默认：30秒同步一次
    response-cache-update-interval-ms: 1000
```

## 4、总结

<img src="img\eureka-end.png" />



























# 	**Springcloud Hoxton**	

1、业务网关：zuul；流量网关：nginx；

2、TPS：Transactions Per Second 意思是每秒事务数 

 QPS：Queries Per Second，意思是每秒查询率，是一台服务器每秒能够响应的查询次数

cdn

httpdns防止域名劫持

二级域名系统

OpenFeign是在feign上加了一层包装，配了一些springmvc的一些东西，省的我们在配置了

eureka有一些元数据信息，有eureka本身的，也可以自定义。比如，我们在调用某个服务的时候，从元数据中取自定义权重值，来做负载均衡

服务可不可用不取决于Eureka客户端发不发心跳包。当eureka客户端依旧定时发心跳包的时候也可以自己手动down掉服务，就是告诉eureka服务器，我“休假”了，虽然我没挂掉。

 

Ribbo是客户端的负载均衡，

 

SpringData Rest

 

Rest协议优点:异构平台、可插拔

Dubbo长链接





熟悉项目：架构图、流程图、关键业务实现、核心业务实现

# spring cloud alibaba

[github地址](https://github.com/alibaba/spring-cloud-alibaba)

spring cloud alibaba是实现spring cloud标准的微服务框架

spring cloud alibaba脚手架：https://start.aliyun.com/

## 一、Nacos

- 注册中心
- 配置中心
- 服务管理

### 1、注册中心

- nacos：CP + AP		默认使用的AP，如何切换？
- eureka：AP
- zookeeper：CP

下载安装nacos server：

默认为集群模式，启动前修改bin/startup.cmd：

```shell
# MODE="cluster" 改为
MODE="standlone"
```

配置文件：

可以配置数据源，默认是使用的内存，没有持久化



保护阈值：设置值0-1之间

[Nacos Discovery配置](https://github.com/alibaba/spring-cloud-alibaba/wiki/Nacos-discovery)

基础配置：

```yaml
spring:
  application:
    name: nacos-start
  cloud:
    nacos:
      discovery:
        username: nacos
        password: nacos
        # namespace: public
        server-addr: 127.0.0.1:8848
        ephemeral: true # false-永久实例（哪怕宕机了，也不会删除实例） ,true-临时实例； 默认true
server:
  port: 8080
```

### 2、配置中心

[官方文档](https://github.com/alibaba/spring-cloud-alibaba/wiki/Nacos-config)

**config和nacos的区别**

- spring cloud config大部分场景结合git使用，动态变更还需要依赖spring cloud bus消息总线来通过所有的客户端变化。
- spring cloud cofig不提供可视化界面
- nacos config使用长连接，1s以内获得变化的配置

使用权限需要开启配置conf/application.properties：

```properties
nacos.core.auth.enabled=true
```

注意：

- 一般namespace-开发环境；group-项目；dataId-服务
- 配置文件优先级：profile > 默认 > extension-configs > shared-configs（下标越大，优先级越大）
- nacos discovery会每隔10ms去nacos server判断配置文件有没有修改，使用MD5判断（namespace为public的时候，也有可能是server和discovery版本不一致）
- 使用@RefreshScope动态更新@Value获得的值
- spring.application.name和nacos config上的dataId一样才可以读到内容
- nacos默认读取properties的配置，如果是其他格式的，需要在配置文件中指定

```properties
# 只针对默认的配置文件（dateId为项目名）和profile
spring.cloud.nacos.config.file-extension=yaml
```

## 二、Ribbon

- nacos默认使用ribbon
- 所有负载均衡策略顶级接口都是IRule接口，AbstractLoadBalanceRule实现了IRule接口，其他负载均衡策略都继承了该抽象类
  - IRule核心方法choose，用来选择一个服务实例
- nacos-discovery依赖了ribbon，可以不用再引入ribbon

### 1、使用

```java
@Configuration
public class RestConfig{
    @Bean
    @LoadBalanced
    public RestTemplate restTemplate(){
        return new RestTemplate();
    }
}
```

### 2、修改负载均衡策略

#### （1）使用配置文件配置

给单个服务配置：

```yaml
# 被调用的服务名
mall-order:
  ribbon:
    # 指定使用nacos提供的负载均衡策略（优先调用同一集群的实例，基于随机&权重）
    NFLoadbalancerRuleClassName: com.alibaba.cloud.nacos.ribbon.NacosRule
```

#### （2）使用RibbonClient配置

1、

注意：该类放到ComponentScan扫描到的地方就会全局有效

```java
@Configuration
public class RibbonConfig{
    //方法名必须叫iRule
    @Bean
    public IRule iRule(){
        return new NacosRule();
    }
}
```

2、

```java
@SpringBootApplication
@RibbonClient(value = {
        //name:服务名
        @RibbonClient(name = "mall-order", configuration = RibbonConfig.class),
        @RibbonClient(name = "mall-account", configuration = RibbonConfig.class)
})
public class NacosStartApplication {

    public static void main(String[] args) {
        SpringApplication.run(NacosStartApplication.class, args);
    }

}
```

#### （3）自定义负载均衡策略

AbstractLoadBalanceRule里面主要定义了一个ILoadBalancer，主要要来**辅助负责负载均衡策略选取合适的服务端实例**

1、继承AbstractLoadBalancerRule抽象类

```java
public class CoustomRule extends AbstractLoadBalancerRule {
    @Override
    public Server choose(Object key) {
        ILoadBalancer loadBalancer = this.getLoadBalancer();

        //获得当前请求的实例集合
        List<Server> reachableServers = loadBalancer.getReachableServers();

        int i = ThreadLocalRandom.current().nextInt(reachableServers.size());

        return reachableServers.get(i);
    }

    @Override
    public void initWithNiwsConfig(IClientConfig iClientConfig) {

    }
}
```

2、配置到配置文件中，或者使用注解配置，方式：二、2、（1）（2）

### 3、使用饥饿加载

问题：默认第一次调用服务的时候加载，所以第一次访问可能比较慢

解决方式：使用饥饿加载

```yaml
ribbon:
  eager-load:
    # 调用mall-order服务时，使用饥饿加载，多个用逗号隔开
    clients: mall-order
    # 开启饥饿加载
    enabled: true
```

## 三、LoadBalancer

- spring cloud 官方提供的负载均衡器，用来替代Ribbon
- 不仅支持TestTemplate，还支持WebClient
- spring cloud 2021版后，就没有使用ribbon作为默认了

nacos默认使用ribbon，替换为LoadBalancer，两种方式：

1、nacos-discovery中引入了ribbon，移除ribbon的包，并添加loadbalancer的依赖

```xml
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
    <exclusions>
        <exclusion>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-netflix-ribbon</artifactId>
        </exclusion>
    </exclusions>
</dependency>

<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-loadbalancer</artifactId>
</dependency>
```

2、yml中配置不使用ribbon

```yaml
spring:
  application:
    name: nacos-start
  cloud:
    loadbalancer:
      ribbon:
        # 不使用ribbon
        enabled: false
```

## 四、openFeign

open-feign使用的是springmvc的注解，使用feign还得单独学习注解

### 1、契约配置

目的：保留原生feign的注解；

使用场景：spring cloud 1.x项目升级到高版本，不用修改代码

### 2、超时设置

```yaml
feign:
  client:
    config:
      product-service:
        loggerLevel: BASIC
        # 契约配置
        contract: feign.Contract.Default
        # 连接超时间 默认2s
        connectTimeout: 5000
        # 请求超时 默认5s
        readTimeout: 3000
        # 配置拦截器
        requestInterceptors[0]:
          com.example.test.intercepter.fegin.CustomFeginIntercepter
```

### 3、自定义拦截器

- 实现RequestInterceptor接口
- 配置文件配置

场景：请求时，header加内容；打印日志；

```java
public class CustomFeginIntercepter implements RequestInterceptor {
    @Override
    public void apply(RequestTemplate requestTemplate) {
        requestTemplate.header("xxx", "xxx");
        requestTemplate.query("id","123");
        requestTemplate.uri("/9");
    }
}
```

## 五、sentinel

[官网](https://github.com/alibaba/Sentinel/wiki/%E4%BB%8B%E7%BB%8D)

**服务挂掉可能的原因**：

- 流量激增 打垮
- 被其他服务器拖垮（如：第三方服务挂机，导致服务堆积）
- 异常没处理



**问题**：

服务雪崩（服务提供者挂掉，导致调用者挂掉，问题逐渐扩大）



**解决方案**：

- 超时机制——超时后，直接给用户返回提示信息
- 服务限流——比如提前压测QPS，超过则直接返回提示信息、或直接决绝等等
- 隔离——比如控制线程数，超过则直接返回提示信息、或直接决绝等等
- 服务熔断——多次访问服务提供者没有相应，则短时间内不再访问，过一段时间再访问
- 服务降级——在弱依赖中进行

强依赖、若依赖：比如秒杀下单中，买完商品后会给你加积分。这时候积分服务就是弱依赖，订单、库存则是强依赖。积分服务不可用，那么可以记录一条日志，后来在去给用户加，但是没有订单、库存，则下单这个过程完成不了。



**特点**：

- 信号量隔离（没有基于线程池的隔离，因为取决于web容器，所以sentinel干脆没有实现这个）
- 熔断降级策略：基于响应时间和失败比率
- 流量整形：支持慢启动、匀速器模式
- 有控制台，开箱即用，可配置规则，查看秒级监控、机器发现等
- 持久化，用于报错控制台设置的信息；也可以持久化到注册中心



[代码植入的方式进行QPS限流、服务降级](https://github.com/alibaba/Sentinel/wiki/%E6%96%B0%E6%89%8B%E6%8C%87%E5%8D%97)：

- QPS限流：
  - 一般设置在服务提供端
  - 到达qps限制则执行限流方法
- 服务降级：
  - 一般设置在服务消费端
  - 到达服务降级要求，就执行降级方法，降级时间过去后，恢复接口请求调用（半开状态），如果第一次又抛异常，则直接服务降级；

引入依赖：pom文件可以不继承spring cloud alibaba，可以单独引入依赖使用



41