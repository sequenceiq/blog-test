---
layout: post
title: "Cloudbreak welcomes Periscope"
date: 2014-12-12 15:13:33 +0100
comments: true
categories: [Cloudbreak]
author: Richard Doktorics
published: true
---

Today we have pushed out a new release of [Cloudbreak](---
layout: post
title: "Cloudbreak welcomes Periscope"
date: 2014-12-12 15:13:33 +0100
comments: true
categories: [Cloudbreak]
author: Richard Doktorics
published: true
---

Today we have pushed out a new release of [Cloudbreak](http://sequenceiq.com/cloudbreak/) - our Docker container based and cloud agnostic Hadoop as a Service solution - containing a few major changes. While there are many significant changes (both functional and architectural) in this blog post we'd like to describe one of most expected one - the `autoscaling` of Hadoop clusters.

Just to quickly recap, Cloudbreak allows you to provision clusters - `full stacks` - in all major cloud providers using a unified API, UI or CLI/shell. Currently we support provisioning of clusters in `AWS`, `Google Cloud` and `Azure` and `OpenStack` (in private beta) - new cloud providers can be added quite easily (as everything runs in Docker) using our SDK.

[Periscope](http://sequenceiq.com/periscope/) allows you to configure SLA policies for your Hadoop cluster and scale up or down on demand. You are able to set alarms and notifications for different metrics like `pending containers`, `lost nodes` or `memory usage`, etc and set SLA scaling policies based on these alarms.

Today's [release](http://cloudbreak.sequenceiq.com/) made available the integration between the two projects (they work independently as well) and allows subscribers to enable autoscaling for their already deployed or newly created Hadoop cluster.

We would like to guide you through the UI and help you to set up an autoscaling Hadoop cluster.

<!--more-->

##Using Periscope

Once you have created your Hadoop clusters with Cloudbreak you will now how the option to configure autoscaling policies.

![](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/images/select.png)

In order to configure autoscaling for your cluster you should go to `autoscaling SLA policies` tab and hit the `enable` button.

###Alarms

Periscope allows you to configure two types of `alarms`.

**Metric based** alarms are alarms based on different `YARN` metrics. A plugin mechanism will be available in case you'd like to plug your own metrics. As a quick note, we have another project called [Baywatch](http://blog.sequenceiq.com/blog/2014/10/07/hadoop-monitoring/) where we collect around 400 Hadoop metrics - and those will be all pluggable in Periscope.

![](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/images/alarm-metric.png)

* alarm name - name of the alarm
* description - description of the alarm
* metrics - currently the default YARN metrics we support are: `pending containers`, `pending applications`, `lost nodes`, `unhealthy nodes` and `global resources`
* period -  the time that the metric has to be sustained in order for an alarm to be triggered
* notification email (optional) - address where Periscope sends an email in case the alarm is triggered


**Time based** alarms allow autoscaling of clusters based on the configured time. We have [blogged](http://blog.sequenceiq.com/blog/2014/11/25/periscope-scale-your-cluster-on-time/) about this new feature recently - with this new release of [Cloudbreak](http://cloudbreak.sequenceiq.com/) this feature is available through UI as well.

![](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/images/alarm-time.png)

* alarm name - name of the alarm
* description - description of the alarm
* time zone - the timezone for the `cron` expression
* cron expression - the cron expression
* notification email (optional) - address where Periscope sends an email in case the alarm is triggered

##Scaling policies

Once you have an alarm you can configure scaling policies based on it. Scaling policies defines the actions you'd like Periscope to take in case of a triggered alarm.

![](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/images/scaling.png)

* policy name - the name of the SLA scaling policy
* scaling adjustment - the adjustment counted in `nodes`, `percentage` or `exact` numbers of cluster nodes
* host group - the `autoscaled` Ambari hostgroup
* alarm - the configured alarm

##Cluster scaling configurations

A cluster has a default configuration which Periscope scaling policies can't override. This is due to avoid over or under scaling a Hadoop cluster with policies and also to definde a cooldown time period between two scaling actions.

![](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/images/cluster-config.png)

* cooldown time - the time spent between two scaling actions
* cluster size min. - the minimun size (in nodes) of a cluster
* cluster size max. - the maximum size (in nodes) of a cluster

It's that simple. Happy autoscaling.

In case you'd like to test autoscaling and generate some load on your cluster you can use these `stock` Hadoop examples and the scripts below:


```test.sh
#!/bin/bash

export HADOOP_LIBS=/usr/lib/hadoop-mapreduce
export JAR_JOBCLIENT=$HADOOP_LIBS/hadoop-mapreduce-client-jobclient-2.4.0.2.1.2.0-402-tests.jar

smalljobs(){
  echo "############################################"
  echo Running smalljobs tests..
  echo "############################################"

  CMD="hadoop jar $JAR_JOBCLIENT mrbench -baseDir /user/hrt_qa/smallJobsBenchmark -numRuns 2 -maps 10 -reduces 5 -inputLines 10 -inputType ascending"
  echo TEST 1: $CMD
  su hdfs -c "$CMD" 1> smalljobs-time.log 2> smalljobs.log
}

smalljobs
```

To test it you can run it with the following script:

```
#!/bin/bash

for i in {1..10}
do
nohup /test.sh &
done
```

Make sure you check back soon to our [blog](http://blog.sequenceiq.com/) or follow us
on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook).
) - our Docker container based and cloud agnostic Hadoop as a Service solution - containing a few major changes. While there are many significant changes (both functiona and architectural) in this blog post we'd like to describe one of most expected one - the `autoscaling` of Hadoop clusters.

Just to quickly recap, Cloudbreak allows you to provision clusters - `full stacks` - in all major cloud providers using a unified API, UI or CLI/shell. Currently we support provisioning of clusters in `AWS`, `Google Cloud` and `Azure` and `OpenStack` (in private beta) - new cloud providers can be added quite easily (as everything runs in Docker) using our SDK.

[Periscope](http://blog.sequenceiq.com/blog/2014/08/27/announcing-periscope/) allows you to configure SLA policies for your Hadoop cluster and scale up or down on demand. You are able to set alarms and notifications for different metrics like `pending containers`, `lost nodes` or `memory usage`, etc and set SLA scaling policies based on these alarms.

Today's [release](http://cloudbreak.sequenceiq.com/) made available the integration between the two projects (they work independently as well) and allows subscibers to enable autoscaling for their already deployed or newly created Hadoop cluster.

We would like to guide you through the UI and help you to set up an autoscaling Hadoop cluster.

<!--more-->

##Using Periscope

Once you have created your Hadoop clusters with Cloudbreak you will now how the option to configure autoscaling policies.

![](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/images/select.png)

In order to configure autoscaling for your cluster you should go to `autoscaling SLA policies` tab and hit the `enable` button.

###Alarms

Periscope allows you to configure two types of `alarms`.

**Metric based** alarms are alarms based on different `YARN` metrics. A plugin mechanism will be available in case you'd like to plug your own metrics. As a quick note, we have another project called [Baywatch](http://blog.sequenceiq.com/blog/2014/10/07/hadoop-monitoring/) where we collect around 400 Hadoop metrics - and those will be all pluggable in Periscope.

![](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/images/alarm-metric.png)

* alarm name - name of the alarm
* description - description of the alarm
* metrics - currently the default YARN metrics we support are: `pending containers`, `pending applications`, `lost nodes`, `unhealthy nodes` and `global resources`
* period -  the time that the metric has to be sustained in order for an alarm to be triggered
* notification email (optional) - address where Periscope sends an email in case the alarm is triggered


**Time based** alarms allow autoscaling of clusters based on thge configured time. We have [bloged](http://blog.sequenceiq.com/blog/2014/11/25/periscope-scale-your-cluster-on-time/) about this new feature recently - with this new release of [Cloudbreak](http://cloudbreak.sequenceiq.com/) this feature is available through UI as well.

![](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/images/alarm-time.png)

* alarm name - name of the alarm
* description - description of the alarm
* time zone - the timezone for the `cron` expression
* cron expression - the cron expression
* notification email (optional) - address where Periscope sends an email in case the alarm is triggered

##Scaling policies

Once you have an alarm you can configure scaling policies based on it. Sclaing policies defines the actions you'd like Periscope to take in case of a triggered alarm.

![](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/images/scaling.png)

* policy name - the name of the SLA scaling policy
* scaling adjustment - the adjustment counted in `nodes`, `percentage` or `exact` numbers of cluster nodes
* host group - the `autoscaled` Ambari hostgroup
* alarm - the configured alarm

##Cluster scaling configurations

A cluster has a default configuration which Periscope scaling policies can't override. This is due to avoid over or underscaling a Hadoop cluster with policies and also to definde a cooldown time period between two scaling actions.

![](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/images/cluster-config.png)

* cooldown time - the time spent between two scaling actions
* cluster size min. - the minimun size (in nodes) of a cluster
* cluster size max. - the maximum size (in nodes) of a cluster

It's that simple. Happy autoscaling.

In case you'd like to test autoscaling and generate some load on your cluster you can use these `stock` Hadoop examples and the scripts below:


```
#!/bin/bash

export HADOOP_LIBS=/usr/lib/hadoop-mapreduce
export JAR_JOBCLIENT=$HADOOP_LIBS/hadoop-mapreduce-client-jobclient-2.4.0.2.1.2.0-402-tests.jar

smalljobs(){
  echo "############################################"
  echo Running smalljobs tests..
  echo "############################################"

  CMD="hadoop jar $JAR_JOBCLIENT mrbench -baseDir /user/hrt_qa/smallJobsBenchmark -numRuns 2 -maps 10 -reduces 5 -inputLines 10 -inputType ascending"
  echo TEST 1: $CMD
  su hdfs -c "$CMD" 1> smalljobs-time.log 2> smalljobs.log
}

smalljobs
```

To test it you can run it with the following script:

```
#!/bin/bash

for i in {1..10}
do
nohup /test.sh &
done
```

Make sure you check back soon to our [blog](http://blog.sequenceiq.com/) or follow us
on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook).
