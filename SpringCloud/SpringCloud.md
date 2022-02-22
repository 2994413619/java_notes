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