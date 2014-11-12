---
layout: post
title: "Extreme OLAP Engine running on Docker"
date: 2014-11-13 16:14:17 +0100
comments: true
categories: OLAP
author: Krisztian Horvath
published: false
---

_[Kylin](https://github.com/KylinOLAP/Kylin) is an open source Distributed Analytics Engine from eBay Inc. that provides SQL interface and multi-dimensional analysis (OLAP) on Hadoop supporting extremely large datasets._

At [SequenceIQ](http://sequenceiq.com/) we are always interested in the latest emerging technologies, and try to offer those to our customers and the open source community. A few weeks ago [eBay Inc.](http://www.ebayinc.com/) released [Kylin](https://github.com/KylinOLAP/Kylin) as an open source product and made available for the community under an Apache 2 license. Since we share the approach towards `open source` software we have partnered with them to `Dockerize` Kylin - and made it extremely easy for people to deploy a Kylin locally or in the cloud, using our Hadoop as a Service API - [Cloudbreak](http://sequenceiq.com/cloudbreak/).


While there is a pretty good [documentation](http://www.kylin.io/document.html) available for Kylin we'd like to give you a really short introduction and overview.

##Architecture

For an overview and the used components and architecture please check this diagram.

![](https://raw.githubusercontent.com/sequenceiq/docker-kylin/master/img/kylin_diagram.png)

For your reference you can also check the Ambari blueprint to learn the components used by Kylin. Both [singlenode](https://raw.githubusercontent.com/sequenceiq/docker-kylin/master/kylin-singlenode.json) and [multinode](https://raw.githubusercontent.com/sequenceiq/docker-kylin/master/kylin-multinode.json) blueprint templates are available.

##Kylin cluster running on Docker

We have put together and fully `automated` the steps of creating a Kylin cluster. The only thing you will need to do is to pull the container from the `official` Docker repository by ussuing the following command.

```
docker pull sequenceiq/kylin
```

Once the container is pulled you are ready to start playing with Kylin. Get the following helper functions from our Kylin GitHub [repository](https://github.com/sequenceiq/docker-kylin/blob/master/ambari-functions) - _(make sure you source it)._

```
 kylin-deploy-cluster 3
```

You can specify the number of nodes you'd like to have in your cluster (3 in this case). Once we installed all the necessary Hadoop
services we'll build Kylin on top of it and then you can reach the UI on: 
```
http://<container_ip>:9080
```
The default credentials to login are: `admin:KADMIN`. The cluster is pre-populated with sample data and is ready to build cubes as shown [here](https://github.com/KylinOLAP/Kylin/wiki/Kylin-Cube-Creation-Tutorial).

Keep up with the latest news with us on our [blog](http://blog.sequenceiq.com/) or follow us
on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook).
