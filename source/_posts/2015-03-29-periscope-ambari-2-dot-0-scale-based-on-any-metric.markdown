---
layout: post
title: "Periscope - Ambari 2.0 - scale based on any metric"
date: 2015-03-29 11:52:10 +0200
comments: true
categories: [Periscope]
author: Krisztian Horvath
published: true
---

It's been a while since we discussed [Periscope](http://sequenceiq.com/periscope/)'s scaling capabilities, but it's time to revisit again as we're introducing a more generalized way to monitor and scale your cluster. In the first public beta release we relied on 5 different YARN metrics obtained straight from the `ResourceManager` to allow users to experiment with it and plan their capacity needs ahead. The feedbacks were really promising. Some people started extending the portfolio with new metrics and others asked us to add certain types which suits their use cases the best. In the meanwhile the [Ambari](https://ambari.apache.org) community started to work on redesigning the [Alert](https://issues.apache.org/jira/browse/AMBARI-6354) system which the new version of Periscope is going to leverage.

## Ambari 2.0 alerts

The next version of [Ambari](https://ambari.apache.org/) (going to be released soon) will be able to monitor `any` type of metrics that the full Hadoop ecosystem provides. It's really powerful since you'll not only be able to define simple metric alerts but aggregated, service level, host level and script based ones. Let's jump into it and see how it looks like to define an `alert` which triggers if the defined `root queue`'s available memory falls below a certain threshold (basically the available memory in the cluster):
```json
{
  "AlertDefinition": {
    "cluster_name": "cluster-name",
    "component_name": "RESOURCEMANAGER",
    "description": "This alarm triggers if the free memory falls below a certain threshold. The threshold values are in percent.",
    "enabled": true,
    "ignore_host": false,
    "interval": 1,
    "label": "Allocated memory",
    "name": "allocated_memory",
    "scope": "ANY",
    "service_name": "YARN",
    "source": {
      "jmx": {
        "property_list": [
          "Hadoop:service=ResourceManager,name=QueueMetrics,q0=root/AvailableMB",
          "Hadoop:service=ResourceManager,name=QueueMetrics,q0=root/AllocatedMB"
        ],
        "value": "{0}/({0} + {1}) * 100"
      },
      "reporting": {
        "ok": {
          "text": "Memory available: {0} MB, allocated: {1} MB"
        },
        "warning": {
          "text": "Memory available: {0} MB, allocated: {1} MB",
          "value": 50
        },
        "critical": {
          "text": "Memory available: {0} MB, allocated: {1} MB",
          "value": 35
        },
        "units": "%"
      },
      "type": "METRIC",
      "uri": {
        "http": "{{yarn-site/yarn.resourcemanager.webapp.address}}",
        "https": "{{yarn-site/yarn.resourcemanager.webapp.https.address}}",
        "https_property": "{{yarn-site/yarn.http.policy}}",
        "https_property_value": "HTTPS_ONLY",
        "default_port": 0,
        "high_availability": {
          "alias_key": "{{yarn-site/yarn.resourcemanager.ha.rm-ids}}",
          "http_pattern": "{{yarn-site/yarn.resourcemanager.webapp.address.{{alias}}}}",
          "https_pattern": "{{yarn-site/yarn.resourcemanager.webapp.https.address.{{alias}}}}"
        }
      }
    }
  }
}
```
<!--more-->

Most of the Hadoop components expose its metrics via `jmx`, but not all of them (later on this). As you can see we're using the RM's `jmx` as source to obtain the necessary metrics (in this case the `AvailableMB` and the `AllocatedMB` to calculate the overall memory usage: `"value": "{0}/({0} + {1}) * 100"`). So how does [Ambari](https://ambari.apache.org/) knows where to look for these values, like: `"Hadoop:service=ResourceManager,name=QueueMetrics,q0=root/AvailableMB"`? You have to define which property to use in the `uri` section: `yarn-site/yarn.resourcemanager.webapp.address`. It tells Ambari to grab the property from the yarn-site and use the RM's web address and on that use the jmx endpoint. It could be problematic if you're using the RM in HA mode as there are multiple RMs. It can be solved if you provide this information as well in the `high_availability` part. In this way Ambari will always use the active RM and not the ones in `standby` mode. To make sure these metric values are there you can use the following endpoint on your cluster:
```
RM_IP:8088/jmx?qry=Hadoop:service=ResourceManager,name=QueueMetrics,q0=root
```
```
    ...
    "AllocatedMB" : 0,
    "AllocatedVCores" : 0,
    "AllocatedContainers" : 0,
    "AggregateContainersAllocated" : 0,
    "AggregateContainersReleased" : 0,
    "AvailableMB" : 30720,
    "AvailableVCores" : 48,
    "PendingMB" : 0,
    "PendingVCores" : 0,
    "PendingContainers" : 0,
    ...
```
These are the supported source types: `SCRIPT`, `METRIC`, `AGGREGATE`, `PERCENT` and `PORT`. You can cover anything with these types. Simply check if a process is running and listening on a port:
```
{
  "uri": "config/property_with_host_and_port",
  "default_port": 12345
}
```
or a web UI is available:
```
{
  "uri": {
    "http": "hdfs-site/dfs.datanode.http.address",
    "https": "hdfs-site/dfs.datanode.https.address",
    "https_property": "hdfs-site/dfs.http.policy",
    "https_property_value": "HTTPS_ONLY"
  }
}
```
but the most interesting one besides `jmx` is the `SCRIPT` based:
```
{
  "location": "scripts/alert_check.py",
  "arg1": "arg2"
}
```
You can define a script to check a metric value for you and Ambari will execute that script. A good example is to check the [NodeManager's health](https://github.com/apache/ambari/blob/trunk/ambari-server/src/main/resources/common-services/YARN/2.1.0.2.0/package/alerts/alert_nodemanager_health.py).

### Dispatchers

Alerts will produce either `OK`, `WARNING` or `CRITICAL` states. It's possible to send notifications based on these states. For example if an alert reports `CRITICAL` state an e-mail could be sent or an SNMP message to some network devices. It's also planned to be able to provide such dispatcher by placing the implementation to the `classpath`.

### Under the hood

Alerts are fully supported API resources, with sorting, querying and paging:
```bash
curl -X GET -u "admin:admin" http://127.0.0.1:8080/api/v1/clusters/mycluster/alert_definitions
curl -X GET -u "admin:admin" http://127.0.0.1:8080/api/v1/clusters/mycluster/alert_history
curl -X GET -u "admin:admin" http://127.0.0.1:8080/api/v1/clusters/mycluster/alerts
curl -X GET -u "admin:admin" http://127.0.0.1:8080/api/v1/clusters/mycluster/alert_groups
```
If you install a cluster there are many pre-defined alerts by default. In order to create new ones you'll have to send a POST request to the appropriate endpoint, the UI doesn't support it.

How does [Ambari](https://ambari.apache.org/) collect the metrics?

![](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/images/ambari_alrts.png)

Each alert definition provides an `interval` property. This interval defines how often Ambari will check the alert. In the allocated memory example above it's `1` which means every minutes. A python based library will schedule these alerts on the Ambari agents. Due to the distributed nature of the cluster, checking the different alerts will not overwhelm the cluster causing bottlenecks. You can read more on this [here](https://issues.apache.org/jira/secure/attachment/12677952/AlertTechDesignPublic.pdf).

## Periscope alerts

Previously you had to configure such alerts in Periscope and Periscope did the heavy lifting collecting the metric values. The new alert system in Ambari will take care of that and it means in Periscope you'll have to configure which Ambari alert you want to use to scale your cluster. Periscope will make its decisions based on the alert's history preventing to trigger a scaling activity unnecessarily. You'll be able to attach scaling actions to `Ambari defined alerts` the same way you did with Periscope based alerts. For example: enable scaling based on the above defined allocated memory:
```
{
  "alertName": "allocatedmemory",
  "description": "Allocated memory",
  "period": 5,
  "alertDefinition": "allocated_memory",
  "alertState": "CRITICAL"
}
```
This alert will trigger if the `allocated_memory` defined in Ambari reports `CRITICAL` state for 5 minutes.

## Docker

Although Ambari 2.0 is not released yet, a preview [Docker](https://github.com/sequenceiq/docker-ambari/tree/2.0.0) image is available to try the latest build ([same way as wid did with 1.7.0](http://blog.sequenceiq.com/blog/2014/12/04/multinode-ambari-1-7-0/).

`Note`: More and more people getting involved developing and maintaining the Ambari docker images, so we like to thank for all of them. Keep up the good work guys.

## What's next

We're steadily working to make both [Cloudbreak](http://blog.sequenceiq.com/blog/2014/12/23/cloudbreak-on-hdp-2-dot-2/) and [Periscope](http://sequenceiq.com/periscope/) `GA`. If you're interested helping us simply register and start using them - every feedback is welcomed. The key aspect we're focusing on at the moment is the security layer (`kerberos` based security probably worth a blog entry). In the meanwhile follow us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook).
