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