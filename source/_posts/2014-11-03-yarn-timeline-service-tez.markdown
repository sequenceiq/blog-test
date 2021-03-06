---
layout: post
title: "YARN Timeline Service"
date: 2014-11-04 20:07:18 +0200
comments: true
categories: [Timeline service]
published: true
author: Laszlo Puskas
---


As you may know from our earlier [blogposts](http://blog.sequenceiq.com/blog/2014/10/07/hadoop-monitoring/) we are continuously monitoring and trying to find out what happens inside our YARN clusters, let it be MapReduce jobs, TEZ DAGs, etc... We've analyzed our clusters from various aspects so far; now it's the time to take a look at the information provided by the built YARN `timeline` service.

This post is about how to set up a YARN cluster so that the Timeline Server is available and how to configure applications running in the cluster to report information to it. As an example we've chosen to run a simple TEZ example. (MapReduce2 also reports to the `timeline` service)

As a playground we will use a multinode cluster set up on the local machine; alternatively one could do the same on a cluster provisioned with [Cloudbreak](http://sequenceiq.com/cloudbreak). Cluster nodes run in Docker containers, YARN / TEZ provisioning and configuration is done with [Apache Ambari](http://ambari.apache.org/).

## Building a multinode cluster

To build a multinode cluster we use a set of commodity functions that you can install by running the following in a terminal:

```
curl -Lo .amb j.mp/docker-ambari && . .amb
```

(The commodity functions use our docker-ambari image: sequenceiq/ambari:1.6.0)

<!-- more -->

With the functions installed, you can start your cluster by running:

```
amb-start-cluster 3
```

After a couple of seconds you'll have a running 3-node Ambari cluster.

## Create an Ambari blueprint with the Timeline Server configuration entries

To provision and configure Hadoop services we use Ambari and Ambari blueprints. Check this [blogpost](http://blog.sequenceiq.com/blog/2014/06/19/multinode-hadoop-cluster-on-docker/) about how to setup an multi-node Hadoop cluster.

To enable the Timeline Server in the cluster, we've created a blueprint which contains a few overrides of the related configuration properties. A detailed description of the configuration settings for the Timeline Server are described [here](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServer.html) and [here](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1.5/bk_system-admin-guide/content/ch_application-timeline-server.html).

We used [this](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/timeline-server/blueprints/multi-node-hdfs-yarn-tez-timeline-service.json) blueprint for the experiment.

Please note, that the blueprint here only contains those configuration entries that differ from the defaults; the assumption is that the other defaults are similar to those described in the documentation. It's always possible to override any of the defaults by adding them to the blueprint, or using the Ambari UI.

# Create the YARN cluster with ambari-shell

Now it's time to provision our cluster with YARN, TEZ and the Timeline Server enabled. For this let's start the `ambari-shell`, which, surprisingly runs in a docker container as well.

```
amb-shell
```

Following the instructions below you can provision the Timeline Server enabled cluster:

```
#add the blueprint
blueprint add --url https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/timeline-server/blueprints/multi-node-hdfs-yarn-tez-timeline-service.json
#build the cluster
cluster build --blueprint multi-node-hdfs-yarn-tez-timeline-service
#auto assign nodes
cluster autoAssign
#create the cluster
cluster create
```

After services start, you can reach the Timeline Server on the port 8188 of the ambari host.


There is some more configuration needed for the Timeline Server to work properly, we have to set the following entries to the address where the timeline service is running. You can get the proper value from Ambari -  the Timeline Server runs where the resource manager is.

```
yarn.timeline-service.webapp.address
yarn.timeline-service.webapp.https.address
yarn.timeline-service.address
```

This can be done from the Ambari web UI; a restart of the YARN services is needed after the values are saved.

# Check the information in the Timeline Server

With the cluster and the Timeline Server set up every MR2 and TEZ application starts reporting to the `timeline` service. Information is made available at `http://<ambari-host:8188>`. You can also inspect application related information using the command line, as described in the aforementioned documentation.

As we mentioned at the beginning of this post, we choose TEZ to show you how to use the Timeline Server. After running the Tez application in the Timeline Server web UI you will have fine grained generic information about the application, application attempt, containers used by the application, etc.

You can find a few screenshots of the web ui  [here](https://github.com/sequenceiq/sequenceiq-samples/tree/master/timeline-server/ts-screenshots/gen-app-logs).

If you'd like to have a vizualized view of the application   you can use the _swimlanes_ tez tool. Based on the information provided by the Timeline Server this generates images similar to [this](https://github.com/sequenceiq/sequenceiq-samples/blob/master/timeline-server/ts-screenshots/swimlanes/topk_topk_stark_application_1415093602516_0016.svg)

If you are curious what framework related information have been logged, you can access the Timeline Server RESTful interface.
You can get very deep details similar to the ones in [these](https://github.com/sequenceiq/sequenceiq-samples/tree/master/timeline-server/ts-screenshots/framework-logs) screenshots


For further details follow up with us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).
