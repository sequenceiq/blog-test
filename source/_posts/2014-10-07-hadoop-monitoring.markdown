---
layout: post
title: "Real-time monitoring of Hadoop clusters"
date: 2014-10-07 20:00:00 +0200
comments: true
categories: [Docker, Elasticsearch, Kibana, Hadoop, Yarn, metrics]
author: Attila Kanto
published: true
---

At [SequenceIQ](http://sequenceiq.com) we are running Hadoop clusters on different environments using [Cloudbreak](http://sequenceiq.com/cloudbreak/) and apply [SLA autoscaling](http://sequenceiq.com/periscope/) policies on the fly, thus monitoring the cluster is a key operation.

Although various solutions have been created in the software industry for monitoring of activities taking place in a cluster, but it turned out that only a very few of them satisfies most of our needs. When we made the decision about which monitoring libraries and components to integrate in our stack we kept in mind that it needs to be:

 * **scalable** to be able to efficiently monitor small Hadoop clusters which are consisting of only a few nodes and also clusters which containing thousands of nodes

 * **flexible** to be able to provide overview about the health of the whole cluster or about the health of individual nodes or even dive deeper into the internals of Hadoop, e.g. shall be able to visualize how our autoscaling solution for Hadoop YARN called  [Periscope](http://blog.sequenceiq.com/blog/2014/08/27/announcing-periscope) moves running applications between [queues](http://blog.sequenceiq.com/blog/2014/07/02/move-applications-between-queues)

 * **extensible** to be able to use the gathered and stored data by extensions written by 3rd parties, e.g. a module which processes the stored (metrics) data and does real-time anomaly detection

 * **zero-configuration** to be able to plug into any existing Hadoop cluster without additional configuration, component installation

Based on the requirements above our choice were the followings:

 * [Logstash](http://logstash.net) for log/metrics enrichment, parsing and transformation
 * [Elasticsearch](http://www.elasticsearch.org) for data storage, indexing
 * [Kibana](http://www.elasticsearch.org/overview/kibana) for data visualization


##High Level Architecture

In our monitoring solution one of the design goal was to provide a **generic, pluggable and isolated monitoring component** to existing Hadoop deployments. We also wanted to make it non-invasive and avoid adding any monitoring related dependency to our Ambari, Hadoop or other Docker images. For that reason we have packaged the monitoring client component into its own Docker image which can be launched alongside with a Hadoop running in another container or even alongside a Hadoop which is not even containerized.

-> {% img https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/hadoop-monitoring/hadoop-monitoring-arch.png %} <-

In a nutshell the monitoring solution consist of client and server containers. The `server` contains the Elasticsearch and the Kibana module. The server container is horizontally scalable and it can be clustered trough the clustering capabilities of Elasticsearch.

The `client` container - which is deployed on the machine what is needed to be monitored - contains the Logstash and the collectd module. The Logstash connects to Elasticsearch cluster as client and stores the processed and transformed metrics data there.

<!-- more -->

##Hadoop metrics
The metrics data what we are collecting and visualizing are provided by [Hadoop metrics](http://blog.cloudera.com/blog/2012/10/what-is-hadoop-metrics2), which is a collection of runtime information that are exposed by all Hadoop daemons. We have configured the Metrics subsystem in that way that it writes the valuable metrics information into the filesystem.

In order to be able to access the metrics data from the monitoring client component - which is running inside a different Docker container - we used the capability of [Docker Volumes](https://docs.docker.com/userguide/dockervolumes) which basically let's you access a directory within one container form other container or even access directories from host systems.

For example if you would like mount the ```/var/log``` from the container named ```ambari-singlenode``` under the ```/amb/log``` in the monitoring client container then the following sequence of commands needs to be executed:

{% raw %}
```bash
EXPOSED_LOG_DIR=$(docker inspect --format='{{index .Volumes "/var/log"}}' ambari-singlenode)
docker run -i -t -v $EXPOSED_LOG_DIR:/amb/log  sequenceiq/baywatch-client /etc/bootstrap.sh -bash
```
{% endraw %}

Hundreds of different metrics are gathered form Hadoop metrics subsystem and all data is transformed by Logstash to JSON and stored in ElasticSearch to make it ready for querying or displaying it with Kibana.

The screenshot below has been created from one of our sample dashboard which is displaying Hadoop metrics for a small cluster which was started on my notebook. In this cluster the Yarn's Capacity Scheduler is used and for demonstration purposes I have created a queue called `highprio` alongside the `default` queue. I have reduced the capacity of the `default` queue to 30 and defined the `highprio` queue with a capacity of 70.
The red line in the screenshot belongs to the `highprio` queue, the yellow line belongs to the `default` queue and the green line is the `root` queue which is the common ancestor both of them.
In the benchmark, the jobs were submitted to the `default` queue and a bit later (somewhere around 17:48) the same jobs were submitted to the `highprio` queue. As it is clearly observable for `highprio` queue the allocated Containers, Memory and VCores were higher and jobs were finished much more faster than those that were submitted to the default queue.

Such kind of dashboard is extremely useful when we are visualizing decisions made by [Periscope](http://blog.sequenceiq.com/blog/2014/08/27/announcing-periscope) and check e.g. how the applications are moved across [queues](http://blog.sequenceiq.com/blog/2014/07/02/move-applications-between-queues), or additional nodes are added or removed dynamically from the cluster.

-> {% img https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/hadoop-monitoring/hadoop_metrics.png %} <-

To see it in large, please [click here](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/hadoop-monitoring/hadoop_metrics.png).

Since all of the Hadoop metrics are stored in the Elasticsearch, therefore there are a lot of possibilities to create different dashboards using that particular parameter of the cluster which is interesting for the operator. The dashboards can be configured on the fly and the metrics are displayed in real-time.

##System resources

Beside Hadoop metrics, "traditional" system resource data (cpu, memory, io, network) are gathered with the aid of [collectd](https://collectd.org). This can also run inside the monitoring client container since due to the [resource management](https://goldmann.pl/blog/2014/09/11/resource-management-in-docker/#_example_managing_the_cpu_shares_of_a_container) in Docker the containers can access and gather information about the whole system and a container can even "steal" the network of other container if you start with: ```--net=container:id-of-other-container``` which is very useful if cases when network traffic is monitored.

-> {% img https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/hadoop-monitoring/system_resource_metrics.png %} <-

##Summary

So far the Hadoop metrics and system resource metrics have been processed, but it is planned to use the information written into the history file (or fetch from History server) and make it also `queryable` trough Elasticsearch to be able to provide information about what is happening inside the jobs.

The development preview of the monitoring server and client is already available on our GitHub [here](https://github.com/sequenceiq/docker-elk) and [here](https://github.com/sequenceiq/docker-elk-client). In the next release this will be part of **Periscope** and **Cloudbreak**.

For updates follow us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).
