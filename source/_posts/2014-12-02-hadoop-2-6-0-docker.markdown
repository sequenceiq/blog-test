---
layout: post
title: "Running Hadoop 2.6.0 in Docker containers"
date: 2014-12-02 20:07:18 +0200
comments: true
categories: [Hadoop]
author: Janos Matyas
published: true
---

Yesterday the Hadoop community has released the `2.6.0` version of Hadoop - the 4th major release of this year - and one which contains quite a few new and interesting features:

* Rolling upgrades - the holly grail for enterprises to switch Hadoop versions
* Long running services in YARN
* Heterogeneous storage in HDFS

These were the most popular features, though beside these there were quite a few extremely important ones -at least for us and our our [Periscope](http://sequenceiq.com/periscope/) project. As you might be aware we are working on an SLA policy based autoscaling API for Apache YARN, and we were closely following/been involved and contributed to these JIRA's below:

* [YARN-2248](https://issues.apache.org/jira/browse/YARN-2248) - CS changes for moving apps between queues
* [YARN-1051](https://issues.apache.org/jira/browse/YARN-1051) - YARN Admission Control/Planner

These tasks/subtasks (beside a few others) are all coming with the new major release and opening up brand new opportunities to make Hadoop YARN a more dynamic environment. Combining this with [Apache Slider](http://slider.incubator.apache.org/index.html) it's pretty clear to see that exciting times are coming.

We have combined all these above with [Docker](http://slider.incubator.apache.org/index.html) and both our open source projects - [Cloudbreak](http://sequenceiq.com/cloudbreak) and [Periscope](http://sequenceiq.com/periscope/) - leverages these new innovations, so stay tuned and get these containers.

In the meanwhile (as usuall) we have [released](https://registry.hub.docker.com/u/sequenceiq/hadoop-docker/) our Hadoop 2.6.0 container to ease your quickstart with Hadoop.


### DIY - Build the image

In case you'd like to try directly from the [Dockerfile](https://github.com/sequenceiq/hadoop-docker/tree/2.6.0) you can build the image as:

```
docker build  -t sequenceiq/hadoop-docker:2.6.0 .
```
<!-- more -->

### Pull the image

As it is also released as an official Docker image from Docker's automated build repository - you can always pull or refer the image when launching containers.

```
docker pull sequenceiq/hadoop-docker:2.6.0
```

### Start a container

In order to use the Docker image you have just build or pulled use:

```
docker run -i -t sequenceiq/hadoop-docker:2.6.0 /etc/bootstrap.sh -bash
```

<!-- more -->

## Testing

You can run one of the stock examples:

```
cd $HADOOP_PREFIX
# run the mapreduce
bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.6.0.jar grep input output 'dfs[a-z.]+'

# check the output
bin/hdfs dfs -cat output/*
```

## Hadoop native libraries, build, Bintray, etc

The Hadoop build process is no easy task - requires lots of libraries and their right version, protobuf, etc and takes some time - we have simplified all these, made the build and released a 64b version of Hadoop nativelibs on our [Bintray repo](https://bintray.com/sequenceiq/sequenceiq-bin/hadoop-native-64bit/2.6.0/view/files). Enjoy.

Should you have any questions let us know through our social channels as [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).
