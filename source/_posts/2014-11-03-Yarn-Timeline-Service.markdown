---
layout: post
title: "YARN Timeline Service"
date: 2014-11-03 20:07:18 +0200
comments: true
categories: [yarn timeline service]
published: false
author: Laszlo Puskas
---


As you may know from our earlier blogposts we are continuously trying to find out what happens inside our YARN clusters, let it be mapreduce jobs, tez DAGs, etc... We've analysed our clusters from various aspects so far; now it came the time to take a look at the information provided by the yarn built-in timeline service.

This post is about how to set up a yarn cluster so that the Timeline Server is available and how to configure applications running in the cluster to report information to it. As an example we've chosen to run a simple TEZ example. (Mapreduce2 also reports to the timeline service)

As a playground we will use a multinode cluster set up on the local machine; alternatively one could do the same on a cluster provisioned with Cloudbreak. Cluster nodes run in docker containers, yarn / tez provisioning and configuration is done with Apache Ambari.

# Building a multinode cluster

To build a multinode cluster we use a set of comodity functions that you can install by running the following in a terminal:

```
curl -Lo .amb j.mp/docker-ambari && . .amb
```

(The commodity functions use our docker-ambari image: sequenceiq/docker-ambari:1.6.0)

With the functions installed, you can start your cluster by running:

```
amb-start-cluster 3
```
After a couple of seconds you'll have a running 3-node ambari cluster.


# Create an ambari blueprint with the Timeline Server configuration entries

To provision and configure hadoop services we use Ambari and ambari blueprints. (You can read about this in our earlier blogposts)

To enable the Timeline Server in the cluster, we've created a blueprint which contains a few overrides of the related configuration properties. (The specific settings for the Timeline Server are described [here](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServer.html) and [here](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1.5/bk_system-admin-guide/content/ch_application-timeline-server.html) )

The blueprint we used can be found here:

https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/timeline-server/blueprints/multi-node-hdfs-yarn-tez-timeline-service.json


Please note here, that the blueprint here only contains those configuration entries that differ from the defaults; the assumption is that the other defaults are similar to thos described in the documentation. It's always possible to override any of the defauls by adding them to the blueprint, or using the Ambari UI.

# Create the yarn cluster with the ambari-shell

Now it's time to provision our cluster with yarn, tez and the Timeline Server enabled. For this let's start the ambari-shell, which, surprisingly runs in a docker container as well.

```
amb-shell
```

Following the instructions displayed as a result of typing the ```hint``` command you can build the cluster:

```
blueprint add --url https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/timeline-server/blueprints/multi-node-hdfs-yarn-tez-timeline-service.json

cluster build --blueprint multi-node-hdfs-yarn-tez-timeline-service

cluster autoAssign

cluster create
```

The initial ambari installation (yarn service) will fail due to an HDFS permission denied operation.
A workaround for this problem is to add the yarn user to the hdfs group:

Enter to the container running ambari:

```docker exec -it <conatainer_id> /bin/bash```

Run the following command from the command line:

```usermod -G hdfs yarn```

From the ambari ui (http://localhost:8080) start yarn.

After services start, you can reach the Timeline Server on the port 8188 of the ambari host.

Please note here, that this is a workaround only; we're still looking for the right solution


# Check the history server information

With the cluster and the Timeline Server set up every tez application starts reporting to the timeline service.
Information is made available at http://<ambari-host:8188>
