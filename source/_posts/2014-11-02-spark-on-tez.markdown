---
layout: post
title: "Spark on Tez execution context - running in Docker"
date: 2014-11-02 20:07:18 +0200
comments: true
categories: [Apache Spark, Apache Tez]
published: true
author: Janos Matyas
---

Last week Hortonworks [announced](http://hortonworks.com/blog/improving-spark-data-pipelines-native-yarn-integration/) improvements for running Apache Spark at scale by introducing a new pluggable `execution context` and has [open sourced](https://github.com/hortonworks/spark-native-yarn-samples) it.

At [SequenceIQ](http://sequenceiq.com/) we are always trying to work and offer the latest technology solutions for our clients and help them to choose their favorite technology/option. We are running a project called [Banzai Pipeline](http://docs.banzai.apiary.io/) - to be open sourced soon - with the goal (among many others) to abstract and allow our customers to use their favorite big data runtime: MR1, Spark or Tez. Along this process we have `dockerized` most of the Hadoop ecosystem - we are running MR2, Spark, Storm, Hive, HBase, Pig, Oozie, Drill etc in Docker containers - on bare metal and in the cloud as well (all of these containers have made **top** downloads on the official Docker repository). For details you can check these older posts/resources:

| Name                  | Description | Documentation | GitHub
|-----------------------|----|--------| ----------
| Apache Hadoop  | Pseudo distributed container | http://blog.sequenceiq.com/blog/2014/08/18/hadoop-2-5-0-docker/ | https://github.com/sequenceiq/hadoop-docker
| Apache Ambari   | Multi node - full Hadoop stack, blueprint based | http://blog.sequenceiq.com/blog/2014/06/19/multinode-hadoop-cluster-on-docker/ | https://github.com/sequenceiq/docker-ambari
| Cloudbreak 	     | Cloud agnostic Hadoop as a Service | http://blog.sequenceiq.com/blog/2014/07/18/announcing-cloudbreak/ | https://github.com/sequenceiq/cloudbreak
| Periscope 	     | SLA policy based autoscaling for Hadoop clusters | http://blog.sequenceiq.com/blog/2014/08/27/announcing-periscope/ | https://github.com/sequenceiq/periscope


We have always been big fans on Apache Spark - due to the simplicity of development and at the same time we are big fans of Apache Tez, for reasons we have [blogged before](http://blog.sequenceiq.com/blog/2014/09/23/topn-on-apache-tez/).

When the [SPARK-3561](https://issues.apache.org/jira/browse/SPARK-3561) has been submitted we were eager to get our hands on the WIP and early implementation - and this time we'd like to help you with a quick ramp-up and easy solution to have a Spark Docker [container](https://github.com/sequenceiq/docker-spark-native-yarn) where the `execution context` has been changed to [Apache Tez](http://tez.apache.org/) and everything is preconfigured. The only thing you will need to do is to follow these easy steps.

###Pull the image from the Docker Repository

We suggest to always pull the container from the official Docker repository - as this is always maintained and supported by us.

```
docker pull sequenceiq/spark-native-yarn
```

Once you have pulled the container you are ready to run the image.

###Run the image

```
docker run -i -t -h sandbox sequenceiq/spark-native-yarn /etc/bootstrap.sh -bash
```
<!-- more -->

You have now a fully configured Apache Spark, where the `execution context` is [Apache Tez](http://tez.apache.org/).

###Test the container

####Calculate PI
Simplest example to test with is the `PI calculation`.

```
cd /usr/local/spark
./bin/spark-submit --class org.apache.spark.examples.SparkPi --master execution-context:org.apache.spark.tez.TezJobExecutionContext --conf update-classpath=true ./lib/spark-examples-1.1.0.2.1.5.0-702-hadoop2.4.0.2.1.5.0-695.jar
```

You should expect something like the following as the result:
```
Pi is roughly 3.14668
```

###Run a KMeans example
We have pushed sample input data sets in the container, you can use those and run these tests as well.
Run the `KMeans` example using the sample dataset.

```
./bin/spark-submit --class sample.KMeans --master execution-context:org.apache.spark.tez.TezJobExecutionContext --conf update-classpath=true ./lib/spark-native-yarn-samples-1.0.jar /sample-data/kmeans_data.txt
```

You should expect something like the following as the result:
```
Finished iteration (delta = 0.0)
Final centers:
DenseVector(0.15000000000000002, 0.15000000000000002, 0.15000000000000002)
DenseVector(9.2, 9.2, 9.2)
DenseVector(0.0, 0.0, 0.0)
DenseVector(9.05, 9.05, 9.05)
```
###Other examples (Join, Partition By, Source count, Word count

Join
```
./bin/spark-submit --class sample.Join --master execution-context:org.apache.spark.tez.TezJobExecutionContext --conf update-classpath=true ./lib/spark-native-yarn-samples-1.0.jar /sample-data/join1.txt /sample-data/join2.txt
```
Partition By
```
./bin/spark-submit --class sample.PartitionBy --master execution-context:org.apache.spark.tez.TezJobExecutionContext --conf update-classpath=true ./lib/spark-native-yarn-samples-1.0.jar /sample-data/partitioning.txt
```
Source count
```
./bin/spark-submit --class sample.SourceCount --master execution-context:org.apache.spark.tez.TezJobExecutionContext --conf update-classpath=true ./lib/spark-native-yarn-samples-1.0.jar /sample-data/wordcount.txt
```
Word count
```
./bin/spark-submit --class sample.WordCount --master execution-context:org.apache.spark.tez.TezJobExecutionContext --conf update-classpath=true ./lib/spark-native-yarn-samples-1.0.jar /sample-data/wordcount.txt 1
```
Note that the last argument (1) is the number of `reducers`.

###Summary

Right after the next day that [SPARK-3561](https://github.com/hortonworks/spark-native-yarn-samples) has been made available we have started to test at scale using [Cloudbreak](http://sequenceiq.com/cloudbreak/) and run performance tests by using the same Spark jobs developed in Banzai (over 50 individual jobs) using the same input sets, cluster size and Scala code - but changing the default `Spark context` to a `Tez context`. Follow up with us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq) as we will release these test results and the lessons we have learned in the coming weeks.
