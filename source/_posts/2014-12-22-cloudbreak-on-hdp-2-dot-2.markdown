---
layout: post
title: "New Cloudbreak release - support for HDP 2.2"
date: 2014-12-23 13:59:42 +0100
comments: true
categories: [Cloudbreak]
author: Krisztian Horvath
published: true
---

The last two weeks were pretty busy for us - we have [Dockerized](http://blog.sequenceiq.com/blog/2014/12/04/multinode-ambari-1-7-0/) the new release of Ambari (1.7.0), [integrated](http://blog.sequenceiq.com/blog/2014/12/12/cloudbreak-got-periscope/) Periscope with [Cloudbreak](http://blog.sequenceiq.com/blog/2014/12/12/cloudbreak-got-periscope/) and just now we are announcing a new Cloudbreak [release](https://cloudbreak.sequenceiq.com) which uses Ambari 1.7.0 and has full support for Hortonworks HDP 2.2 and Apache Bigtop stacks. But first - since this has been asked many times - see a `short` movie about Cloudbreak and Periscope in action.

## On-demand Hadoop cluster with autoscaling

<iframe width="640" height="480" src="//www.youtube.com/embed/E6bnEW76H_E" frameborder="0" allowfullscreen></iframe>

<!--more-->

## Ambari 1.7.0

The Ambari community recently released the 1.7.0 version which comes with lots of new features and bug fixes. We've been testing the new version
internally for a while now and finally made it to Cloudbreak. Just to highlight the important ones:

* Ambari Views framework
* Ambari Administration
    * Management of users/groups
    * Management of view instances
    * Management of cluster permissions
* Cancel/Abort background operation requests
* Expose Ambari UI for config versioning, history and rollback
* Ability to manage -env.sh configuration files
* Recommendations and validations (via a "Stack Advisor")
* Export service configurations via Blueprint
* Install + Manage Flume
* HDFS Rebalance
* ResourceManager HA

These are nice features but for us one of the most important thing is that it allows you to install the latest versions of the Hadoop ecosystem.
As usual the Docker image is available for _local_ deployments as well, described [here](http://blog.sequenceiq.com/blog/2014/12/04/multinode-ambari-1-7-0/).

`Note: There were small changes around the API so if you built an application on top of it check your REST calls. The Ambari Shell and the
underlying Groovy rest client have been updated and will go into the Apache repository once it's passed the reviews.`

## Hadoop 2.6

Since with Ambari 1.7.0 we're able to install Hadoop 2.6 let's see what happened in `YARN` in the last couple of months (it's stunning):

* Support for long running services - install _Slider_ with Ambari and scale your Hadoop services!
  * Service Registry for applications
* Support for rolling upgrades - wow!
  * Work-preserving restarts of ResourceManager
  * Container-preserving restart of NodeManager
* Supports node labels during scheduling - label based scaling is on the way with [Periscope](http://blog.sequenceiq.com/blog/2014/12/12/cloudbreak-got-periscope/)
* Support for time-based resource reservations in Capacity Scheduler (beta) - more on this awesome feature soon
* Support running of applications natively in Docker containers (alpha) - [Docker in Docker](http://blog.sequenceiq.com/blog/2014/12/02/hadoop-2-6-0-docker/)

I'm excited about these great innovations (not, because we're involved in a few of them), but because people can leverage them by using Cloudbreak.

## HDP 2.2 blueprint

I have created a blueprint which is not an `official` one, but it contains a few from the new services like: `SLIDER`, `KAFKA`, `FLUME`.
```
{
  "configurations": [
  {
    "nagios-env": {
      "nagios_contact": "admin@localhost"
    }
    },
    {
      "hive-site": {
        "javax.jdo.option.ConnectionUserName": "hive",
        "javax.jdo.option.ConnectionPassword": "hive"
      }
    }
  ],
  "host_groups": [
    {
      "name": "master_1",
      "components": [
        {
          "name": "NAMENODE"
        },
        {
          "name": "ZOOKEEPER_SERVER"
        },
        {
          "name": "HBASE_MASTER"
        },
        {
          "name": "GANGLIA_SERVER"
        },
        {
          "name": "HDFS_CLIENT"
        },
        {
          "name": "YARN_CLIENT"
        },
        {
          "name": "HCAT"
        },
        {
          "name": "GANGLIA_MONITOR"
        },
        {
          "name": "FALCON_SERVER"
        },
        {
          "name": "FLUME_HANDLER"
        },
        {
          "name": "KAFKA_BROKER"
        }
      ],
      "cardinality": "1"
    },
    {
      "name": "master_2",
      "components": [
        {
          "name": "ZOOKEEPER_CLIENT"
        },
        {
          "name": "HISTORYSERVER"
        },
        {
          "name": "HIVE_SERVER"
        },
        {
          "name": "SECONDARY_NAMENODE"
        },
        {
          "name": "HIVE_METASTORE"
        },
        {
          "name": "HDFS_CLIENT"
        },
        {
          "name": "HIVE_CLIENT"
        },
        {
          "name": "YARN_CLIENT"
        },
        {
          "name": "MYSQL_SERVER"
        },
        {
          "name": "GANGLIA_MONITOR"
        },
        {
          "name": "WEBHCAT_SERVER"
        }
      ],
      "cardinality": "1"
    },
    {
      "name": "master_3",
      "components": [
        {
          "name": "RESOURCEMANAGER"
        },
        {
          "name": "APP_TIMELINE_SERVER"
        },
        {
          "name": "SLIDER"
        },
        {
          "name": "ZOOKEEPER_SERVER"
        },
        {
          "name": "GANGLIA_MONITOR"
        }
      ],
      "cardinality": "1"
    },
    {
      "name": "master_4",
      "components": [
        {
          "name": "OOZIE_SERVER"
        },
        {
          "name": "ZOOKEEPER_SERVER"
        },
        {
          "name": "GANGLIA_MONITOR"
        }
      ],
      "cardinality": "1"
    },
    {
      "name": "slave_1",
      "components": [
        {
          "name": "HBASE_REGIONSERVER"
        },
        {
          "name": "NODEMANAGER"
        },
        {
          "name": "DATANODE"
        },
        {
          "name": "GANGLIA_MONITOR"
        },
        {
          "name": "FALCON_CLIENT"
        },
        {
          "name": "OOZIE_CLIENT"
        }
      ],
      "cardinality": "${slavesCount}"
    },
    {
      "name": "gateway",
      "components": [
        {
          "name": "AMBARI_SERVER"
        },
        {
          "name": "NAGIOS_SERVER"
        },
        {
          "name": "ZOOKEEPER_CLIENT"
        },
        {
          "name": "PIG"
        },
        {
          "name": "OOZIE_CLIENT"
        },
        {
          "name": "HBASE_CLIENT"
        },
        {
          "name": "HCAT"
        },
        {
          "name": "SQOOP"
        },
        {
          "name": "HDFS_CLIENT"
        },
        {
          "name": "HIVE_CLIENT"
        },
        {
          "name": "YARN_CLIENT"
        },
        {
          "name": "MAPREDUCE2_CLIENT"
        },
        {
          "name": "GANGLIA_MONITOR"
        },
        {
          "name": "KNOX_GATEWAY"
        }
      ],
      "cardinality": "1"
    }
    ],
    "Blueprints": {
      "blueprint_name": "hdp-multinode-sequenceiq",
      "stack_name": "HDP",
      "stack_version": "2.2"
    }
}
```

## What's next?

{% blockquote %}
Do the difficult things while they are easy and do the great things while they are small. A journey of a thousand miles must begin with a single step.
{% endblockquote %}

We've walked a long journey since we started the company almost a year ago to reach where we are now, but our products are not complete yet. We have big plans
with our product stacks. A couple of things from our roadmap:

### Cloudbreak

* Cloudbreak currently supports homogeneous cluster deployments which we're going to change. The heterogeneous stack structure is more convenient
  from Hadoop's perspective. The ability to define different type of cloud instances is a must, giving the users the option to use much more
  powerful instances for the `ResourceManager` and `NameNodes`.
* Service discovery and decentralization is always a key aspect. At the moment we're using Serf and dnsmasq, but we're already started the
  integration with [Consul](https://consul.io) which generally is a better fit. It provides service registration via DNS, key-value store and
  decentralization across datacenters.
* The deployment of Cloudbreak itself is going to change and use Consul with other side projects like `Consul templates` or `Registrator`. The
  deployment is already based on Docker, but will be much more simplified.
* Custom stack deployments with Ambari will be supported as `"recipes"`.
* Generating reports of cloud instance usages and cost calculation.
* Web hooks to subscribe to different cluster events.
* Shared/company accounts.

### Periscope

* Add more `YARN` and `NameNode` related metrics.
* Node label based scaling.
* Pluggable metric system for custom metrics.
* Application movement in Capacity Scheduler queues enforcing SLAs.
* Time-based resource reservations in Capacity Scheduler for Applications.
* Integration with [ELK](http://blog.sequenceiq.com/blog/2014/10/07/hadoop-monitoring/).

## Happy Holidays

We're taking a short break of writing new blog posts until next year. You can still reach us on the usual social sites, but you can expect
small delays for answering questions. `Happy Holidays everyone.`

[LinkedIn](https://www.linkedin.com/company/sequenceiq/) [Twitter](https://twitter.com/sequenceiq) [Facebook](https://www.facebook)
