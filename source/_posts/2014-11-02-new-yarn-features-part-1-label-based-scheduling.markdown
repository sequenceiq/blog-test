---
layout: post
title: "New YARN features: Label based scheduling"
date: 2014-11-02 13:14:17 +0100
comments: true
categories:
author: Krisztian Horvath
published: false
---

The release of Hadoop 2.6.0 is upon us thus it's time to get to know the upcoming features better. Recently we explained how the
[CapacityScheduler](http://blog.sequenceiq.com/blog/2014/07/22/schedulers-part-1/) and the [FairScheduler](http://blog.sequenceiq.com/blog/2014/09/09/yarn-schedulers-demystified-part-2-fair/)
works and the upcoming release is about to add a few really interesting functionality to them which you should be aware as they might
change the way we think about resource scheduling. The first one which we are going to discuss is the `label based scheduling` although it's
not fully finished, yet. You can track its progress here: [YARN-796](https://issues.apache.org/jira/browse/YARN-796).

## Motivation
Hadoop clusters are usually not fully homogeneous which means that different nodes can have different parameters. For example some nodes
have more memory than the others while others have better cpu's or better network bandwidth. At the moment YARN doesn't have the
ability to segregate nodes in a cluster based on their architectural parameters. Applications which are aware of their resource usages
cannot choose which nodes they want to run their containers on. Labels are about to solve this problem. Administrators will have
the ability to `mark` the nodes with different labels like: cpu, memory, network, rackA, rackB so applications can specify where they'd
like to run.

## Cloud
Things are different in cloud environments as the composition of the Hadoop clusters are more homogeneous. By the nature of cloud it's
easier and more convinient to request nodes with the exact same cababilities. [Cloudbreak](http://blog.sequenceiq.com/blog/2014/07/18/announcing-cloudbreak/)
our Hadoop as a service API will address this problem, by giving the ability to the users to specify their needs. Take one example: on AWS
users can launch `spot price` instances which EC2 can `take away any time`. Labeling them as `spot` we can avoid spinning up the
`ApplicationMasters` on those nodes, thus operate safely and re-launch new containers on different nodes in case it happens.
Furthermore [Periscope](http://blog.sequenceiq.com/blog/2014/08/27/announcing-periscope/) with its autoscaling capabilities will be able
to scale out with nodes that are marked with `cpu`.

<!--more-->

## Terminology
To start with let's declare the different types of labels and expressions:

* node label - describes a node, multiple labels can be specified
* queue label - determines on which nodes the queue can schedule containers
* application label - defines on which nodes the application want to run its containers
* label expression - logical combination of labels (&&, ||, !) e.g: cpu && rackA
* queue label policy - resolve conflicts on different queue and application labels

## Technical details
Labeling nodes itself is not enough. Schedulers cannot rely only on application requirements as administrators can configure the queues
to act differently. As we taught earlier schedulers are defined in a configuration file where you can specify the queues. Initial labeling
can be done in these files:
```xml
<property>
  <name>yarn.scheduler.capacity.root.alpha.label</name>
  <value>cpuheavy||rackA</value>
</property>
```
The value is a `label expression` that means applications which are submitted to this queue can run either on nodes labeled as
cpuheavy or rackA. As I said the configuration files can be used as an initial configuration, but changing dynamically queue labels
and node labels is also not a problem as the `RMAdminCLI` [provides](https://issues.apache.org/jira/browse/YARN-2504) them.
```java
 .put("-addToClusterNodeLabels",
              new UsageInfo("[label1,label2,label3] (label splitted by \",\")",
                  "add to cluster node labels "))
  .put("-removeFromClusterNodeLabels",
              new UsageInfo("[label1,label2,label3] (label splitted by \",\")",
                  "remove from cluster node labels"))
  .put("-replaceLabelsOnNode",
              new UsageInfo("[node1:port,label1,label2 node2:port,label1,label2]",
                  "replace labels on nodes"))
  .put("-directlyAccessNodeLabelStore",
              new UsageInfo("", "Directly access node label store, "
                  + "with this option, all node label related operations"
                  + " will not connect RM. Instead, they will"
                  + " access/modify stored node labels directly."
                  + " By default, it is false (access via RM)."
                  + " AND PLEASE NOTE: if you configured"
                  + " yarn.node-labels.fs-store.root-dir to a local directory"
                  + " (instead of NFS or HDFS), this option will only work"
                  +
                  " when the command run on the machine where RM is running."))
```
Declaring the labels is one thing, but how can the `ResourceManager` enforce that containers run on nodes where the application wants
it to? Let's think the other way around, how can the `ResourceManager` enforce that containers do not run on nodes where the
application doesn't want it to? The answer is already part of the RM. The `ApplicationMaster` can blacklist nodes. The
`AppSchedulingInfo` class can decide based on the `ApplicationLabelExpression` and the `QueueLabelExpression` whether the resource is
blacklisted or not.
```java
  synchronized public void updateBlacklist(
      List<String> blacklistAdditions, List<String> blacklistRemovals) {
    // Add to blacklist
    if (blacklistAdditions != null) {
      blacklist.addAll(blacklistAdditions);
    }

    // Remove from blacklist
    if (blacklistRemovals != null) {
      blacklist.removeAll(blacklistRemovals);
    }
  }
```
Okay, we know how to add labels to queues and nodes, but who is going to handle them? A new service will be introduced as part of
the RM called [LabelManager](https://github.com/sequenceiq/hadoop/blob/trunk/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-server/hadoop-yarn-server-resourcemanager/src/main/java/org/apache/hadoop/yarn/server/resourcemanager/nodelabels/RMNodeLabelsManager.java).
Its responsibilities are:

* load node labels and maintain an internal map of nodes and their labels
* dynamically update the label - node associations (RMAdminCLI, queue configs are reloaded automatically on change)
* evaluate label logical expressions for both queue and application
* evaluate label expressions against nodes

How can applications specify on which nodes they want to run? The [ApplicationSubmissionContext](https://github.com/sequenceiq/hadoop/blob/trunk/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-api/src/main/java/org/apache/hadoop/yarn/api/records/ApplicationSubmissionContext.java#L77)
has been extended with an `appLabelExpression` and `amContainerLabelExpression` thus when submitting the job we can specify them. If
we know that our application consumes too much memory and the labels are properly defined it shouldn't be a problem. Providing
an invalid label obviously our application will be rejected. Fairly complex expressions can be given, e.g: (highmemory && rackA) || master.
Labels can be provided for every [ResourceRequest](https://github.com/sequenceiq/hadoop/blob/trunk/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-api/src/main/java/org/apache/hadoop/yarn/api/records/ResourceRequest.java#L80):
```java
  @Public
  @Stable
  public static ResourceRequest newInstance(Priority priority, String hostName,
      Resource capability, int numContainers, boolean relaxLocality,
      String labelExpression) {
    ResourceRequest request = Records.newRecord(ResourceRequest.class);
    request.setPriority(priority);
    request.setResourceName(hostName);
    request.setCapability(capability);
    request.setNumContainers(numContainers);
    request.setRelaxLocality(relaxLocality);
    request.setNodeLabelExpression(labelExpression);
    return request;
  }
```
It only makes sense when the resource location is `ANY` or `rack` and not `data local`.

## Summary
We're going to revisit this feature once it completely finished with a concrete example labeling multiple `docker` containers
and submit stock examples to see how it works in action. Besides labeling there are other important changes about to come to
the schedulers which will change the way we plan cluster capacities. The `CapacityScheduler` will be fully dynamic to create/remove/resize
queues, move applications on the fly to make room for the `AdmissionControl`.

Keep up with the latest news with us on our [blog](http://blog.sequenceiq.com/) or follow us
on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook).
