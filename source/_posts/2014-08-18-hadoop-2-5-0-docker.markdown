---
layout: post
title: "Apache Hadoop 2.5.0 on Docker"
date: 2014-08-18 20:07:18 +0200
comments: true
categories: [Apache, Hadoop, Docker, Registry]
published: true
author: Janos Matyas
---
A few weeks ago we have released an Apache Hadoop 2.3 Docker image - in a very short time this become the most [popular](https://registry.hub.docker.com/search?q=hadoop) Hadoop image in the Docker [registry](https://registry.hub.docker.com/).


Following on the success of our Hadoop 2.3.0, 2.4.0 and 2.4.1 Docker [image](https://registry.hub.docker.com/u/sequenceiq/hadoop-docker/), the feedbacks and requests we have received and aligning with the Hadoop release cycle, we have released an Apache Hadoop 2.5.0 Docker image - same as the previous version this is available as a trusted and automated build on the official Docker [registry](https://registry.hub.docker.com/).

Please note that beside this Hadoop image, we have released and maintain a [pseudo-distributed](http://blog.sequenceiq.com/blog/2014/06/17/ambari-cluster-on-docker/) and [fully distributed](http://blog.sequenceiq.com/blog/2014/06/19/multinode-hadoop-cluster-on-docker/) Hadoop Docker image provisioned with Apache Ambari. As they are provisioned with Ambari you have the option to change, add and remove Hadoop components using cluster blueprints. 

Also we are happy to let you know that this release of Apache Hadoop contains a few of SequenceIQ's open source **contributions** and [fixes](https://issues.apache.org/jira/browse/YARN-2250) around YARN schedulers. 
We are working on an SLA enforcer for Hadoop - very soon to be open sourced - and part of that work we are contributing back to the community. Also there is a major contribution of ours coming in the next release of Hadoop - 2.6.0. 
Stay tuned and follow us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).

## Build the image

In case you'd like to try directly from the [Dockerfile](https://github.com/sequenceiq/hadoop-docker) you can build the image as:

```
docker build  -t sequenceiq/hadoop-docker .
```
<!-- more -->

## Pull the image

As it is also released as an official Docker image from Docker's automated build repository - you can always pull or refer the image when launching containers.

```
docker pull sequenceiq/hadoop-docker:2.5.0
```

## Start a container

In order to use the Docker image you have just build or pulled use:

```
docker run -i -t sequenceiq/hadoop-docker:2.5.0 /etc/bootstrap.sh -bash
```

## Testing

You can run one of the stock examples:

```
cd $HADOOP_PREFIX
# run the mapreduce
bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.5.0.jar grep input output 'dfs[a-z.]+'

# check the output
bin/hdfs dfs -cat output/*
```

## Hadoop native libraries, build, Bintray, etc

The Hadoop build process is no easy task - requires lots of libraries and their right version, protobuf, etc and takes some time - we have simplified all these, made the build and released a 64b version of Hadoop nativelibs on our [Bintray repo](https://bintray.com/sequenceiq/sequenceiq-bin/hadoop-native-64bit/2.4.1/view/files). Enjoy. 

Should you have any questions let us know through our social channels as [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).
