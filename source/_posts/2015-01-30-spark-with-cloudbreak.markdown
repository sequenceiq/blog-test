---
layout: post
title: "Install Apache Spark with Cloudbreak"
date: 2015-01-30 13:04:22 +0100
comments: true
categories: [Cloudbreak, Apache Spark]
author: Oliver Szabo
published: true
---

## HDP, Cloudbreak and Apache Spark
In the previous weeks people often asked us how to run our Apache Spark docker container on a multi node cluster or how to install and use it with Cloudbreak.

At the moment Cloudbreak use Ambari blueprints (1.7) to provision multi node HDP cluster (on 4 different cloud providers at the moment: AWS, Google Cloud, Azure, Openstack, you can chose your favorite one). Unfortunately, as far as I know, there is no any Spark component in Ambari (version 1.7). Because of this, you need some manual steps to install it.

With Cloudbreak you can easily set up a cluster on Google Cloud, AWS, Azure or Openstack (look at [here](http://blog.sequenceiq.com/blog/2014/12/23/cloudbreak-on-hdp-2-dot-2/)). After your cluster is ready, you can install Apache Spark with these steps:

Now you have 2 options for installing.
 
### Install from instance

First, you need to enter to one of your instance. Then use the one-liner below:
```
curl -Lo .docker-spark-install j.mp/spark-hdp-docker-install && . .docker-spark-install
```
After the file is downloaded it will be sourced, then you can use the following command:

```
install-spark ambari-agent install
```
Or you can install it without uploading the Spark assembly uberjar with :

```
install-spark ambari-agent install-local
```
After it is done, enter to the ambari-agent container: 
```
docker exec -it ambari-agent bash
```
Apache Spark will be installed at /usr/local/spark in the container. If you want to try it you need to set up some environment variables such as YARN_CONF_DIR or SPARK_JAR.

### Install from container

If you entered one of your instance, enter to the ambari-agent container: (same as you seen above)

```
docker exec -it ambari-agent bash
```
From the container use the following command:
```
curl -Lo .spark-install j.mp/spark-hdp-install && . .spark-install
```
Then you can install spark with "install-spark <install/install-local>" command:
```
install-spark install
```
With this approach you do not need to set up your environment variables. Its already done.

## Run examples

```
spark-submit --class org.apache.spark.examples.SparkPi    --master yarn-cluster  --num-executors 3 --driver-memory 512m  --executor-memory 512m  --executor-cores 1  /usr/local/spark/lib/spark-examples*.jar 10
```

## Issues

* You need to install Spark into every node (you can use it only on 1, but it is not the best approach).
* You do not want to enter docker container or even cloud instances to do things like this.


## Cloudbreak Recipes
