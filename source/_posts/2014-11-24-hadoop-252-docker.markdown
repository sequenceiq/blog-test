---
layout: post
title: "Apache Hadoop 2.5.2 on Docker"
date: 2014-11-24 20:07:18 +0200
comments: true
categories: [Hadoop]
published: true
author: Janos Matyas
---

Following the release cycle of Hadoop -2.5.2 point release- today we are releasing a new `2.5.2` version of our [Hadoop Docker container](https://registry.hub.docker.com/u/sequenceiq/hadoop-docker/).

##Centos

### Build the image

In case you'd like to try directly from the [Dockerfile](https://github.com/sequenceiq/hadoop-docker/tree/2.5.2) you can build the image as:

```
docker build  -t sequenceiq/hadoop-docker:2.5.2 .
```
<!-- more -->

### Pull the image

As it is also released as an official Docker image from Docker's automated build repository - you can always pull or refer the image when launching containers.

```
docker pull sequenceiq/hadoop-docker:2.5.2
```

### Start a container

In order to use the Docker image you have just build or pulled use:

```
docker run -i -t sequenceiq/hadoop-docker:2.5.2 /etc/bootstrap.sh -bash
```

<!-- more -->

## Testing

You can run one of the stock examples:

```
cd $HADOOP_PREFIX
# run the mapreduce
bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.5.2.jar grep input output 'dfs[a-z.]+'

# check the output
bin/hdfs dfs -cat output/*
```

## Hadoop native libraries, build, Bintray, etc

The Hadoop build process is no easy task - requires lots of libraries and their right version, protobuf, etc and takes some time - we have simplified all these, made the build and released a 64b version of Hadoop nativelibs on our [Bintray repo](https://bintray.com/sequenceiq/sequenceiq-bin/hadoop-native-64bit/2.5.2/view/files). Enjoy.

Should you have any questions let us know through our social channels as [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).
