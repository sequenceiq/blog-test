---
layout: post
title: "Cloudbreak on HDP 2.2"
date: 2014-12-22 13:59:42 +0100
comments: true
categories: [Cloudbreak]
author: Krisztian Horvath
published: true
---

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

but the most important thing is that it allows you to install the latest versions of the Hadoop ecosystem.

## Hadoop 2.6

Since with Ambari 1.7.0 we're able to install Hadoop 2.6 let's see what happend in `YARN` in the last couple of months (it's stunning):

* Support for long running services - install _Slider_ with Ambari and scale your Hadoop services!
  * Service Registry for applications
* Support for rolling upgrades - wow!
  * Work-preserving restarts of ResourceManager
  * Container-preserving restart of NodeManager
* Support node labels during scheduling - label based scaling is on the way with [Periscope](http://blog.sequenceiq.com/blog/2014/12/12/cloudbreak-got-periscope/)
* Support for time-based resource reservations in Capacity Scheduler (beta) - more on this awesome feature soon
* Support running of applications natively in Docker containers (alpha) - [Docker in Docker](http://blog.sequenceiq.com/blog/2014/12/02/hadoop-2-6-0-docker/)

I'm excited about these great innovations (not, because we're involved in a few of them), but because people can leverage from them using Cloudbreak.

## HDP 2.2 blueprint

I created a blueprint which is not an official one, but it contains a few from the new services like: `SLIDER`, `KAFKA`, `FLUME`.
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

### Local environment

As usual the Docker image is available for _local_ deployments as well, described [here](http://blog.sequenceiq.com/blog/2014/12/04/multinode-ambari-1-7-0/).
