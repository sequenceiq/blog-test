---
layout: post
title: "Install Apache Spark with Cloudbreak"
date: 2015-01-30 13:04:22 +0100
comments: true
categories: [Cloudbreak, Apache Spark]
author: Oliver Szabo
published: true
---

In the previous weeks many of you often asked us how to run our Apache Spark Docker [container](https://github.com/sequenceiq/docker-spark) on a multi node cluster or how to install Spark and use it with [Cloudbreak](http://sequenceiq.com/cloudbreak/).
Cloudbreak uses Ambari (1.7) blueprints to provision multi node HDP clusters (on different cloud providers: AWS, Google Cloud, Azure, Openstack - with Rackspace and HP Helion coming soon).

In this post we'd like to help you with installing Spark on [Cloudbreak](http://sequenceiq.com/cloudbreak/) in a quick and easy way.

First of all you will have to create a cluster using Cloudbreak on your favorite cloud provider - Google Cloud, AWS, Azure or Openstack (check this [post](http://blog.sequenceiq.com/blog/2014/12/23/cloudbreak-on-hdp-2-dot-2/)) using a simple `multi-node-hdfs-yarn` blueprint. After your cluster is ready, you can install Apache Spark with the following steps:

### Install from the cloud instance

First, you need to enter to one of your cloud instances. Then use the one-liner below:

```
curl -Lo .docker-spark-install j.mp/spark-hdp-docker-install && . .docker-spark-install
```

After the file is downloaded it will be sourced, then you can use the following command:

```
install-spark ambari-agent install
```
<!--more-->

Alternatively you can install it without uploading the Spark assembly `uberjar` using :

```
install-spark ambari-agent install-local
```

After it is done, enter into the ambari-agent container:

```
docker exec -it ambari-agent bash
```

Apache Spark will be installed at /usr/local/spark in the container. If you want to try it you need to configure a few environment variables such as YARN_CONF_DIR or SPARK_JAR (see the Install from container option)

### Install from container

If you entered in one of your cloud instances, enter into the ambari-agent container: (same as you seen above):

```
docker exec -it ambari-agent bash
```

Inside the container use the following command:

```
curl -Lo .spark-install j.mp/spark-hdp-install && . .spark-install
```

Then you can install spark with "install-spark <install/install-local>" command:

```
install-spark install
```

With this approach you do not need to set up your environment variables. The script will do it for you.

## Run examples

```
spark-submit --class org.apache.spark.examples.SparkPi    --master yarn-cluster  --num-executors 3 --driver-memory 512m  --executor-memory 512m  --executor-cores 1  /usr/local/spark/lib/spark-examples*.jar 10
```

## Issues

* You need to install Spark into every node (you can use it only on 1, but it is not the best approach).
* You do not want to enter docker container or even cloud instances to do things like this.

As you see until Ambari will not fully support Spark installation with Blueprints this is not an ideal situation.

Nevertheless we understood this and with the introduction of **recipes** in the latest Cloudbreak release we are going to publish a new Cloudbreal Spark recipe next week. In the meanwhile stay tuned as we are publishing a post early next week about the concept and architecture of `recipes`, how to use it and will publish a few custom ones (by request).

Make sure you check back soon to our [blog](http://blog.sequenceiq.com/) or follow us
on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook).
