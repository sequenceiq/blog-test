---
layout: post
title: "Building the data lake in the cloud - Part1"
date: 2014-10-28 15:56:32 +0200
comments: true
categories: [Cloudbreak]
author: Tamas Bihari
published: true 
---

A while ago we have released our cloud agnostic and Docker container based Hadoop as a Service API - [Cloudbreak](http://sequenceiq.com/cloudbreak/). Though the purpose of [Cloudbreak](https://cloudbreak.sequenceiq.com) is to quickly provision arbitrary sized Hadoop clusters in the cloud, the project emerged from bare metal Hadoop provisioning in Docker containers. We were (still doing it) [provisioning](http://blog.sequenceiq.com/blog/2014/06/19/multinode-hadoop-cluster-on-docker/) Hadoop on bare metal using Docker - and because of this legacy the data was always stored in HDFS. Recently we have been asked to run a proof-of-concept project and build an `always on` data lake using a cloud `object storage`. 

This post is the first in this series and will cover the connectivity, interoperability and access of data from an `object storage` and work with that in Hadoop. For this post we choose to create a `data lake` on Google Cloud Compute and guide you through the steps, run performance tests and understand the benefits/drawbacks of such a setup.

_
Next post will be about sharing the `data lake` among multiple clusters, using [Apache HCatalog](http://hortonworks.com/hadoop/hcatalog/)._

##Object storage

An object storage usually is an `internet service` to store data in the cloud and comes with a programming interface which allows to retrieve data in a secure, durable and highly-scalable way. The most well know object storage is **Amazon S3** - with a pretty well covered literature, thus in this example we will use the **Google Cloud Storage**. Google Cloud Storage enables application developers to store their data on Google’s infrastructure with very high reliability, performance and availability, and can be used to distribute large data objects - like HDFS. In many occasions companies stores their data in objects storages - but for analytics they would like to access it from their Hadoop cluster. There are several options available: 
* replicate the full dataset in HDFS
* read and write from `object storage` at start/stop of the flow and use HDFS for intermediary data
* use a connector such as Google Cloud Storage Connector for Hadoop

##Google Cloud Storage Connector for Hadoop

Using [this](https://cloud.google.com/hadoop/google-cloud-storage-connector) connector developed by Google allows you to choose `Google Cloud Storage` as the default file system for Hadoop, and run all your jobs on top (we will come up with MR2 and Spark examples). Using the connector can have several benefits, to name a few:
* Direct data access - data is stored in GCS, no need to transfer it into HDFS 
* HDFS compatibility - data stored in HDFS can be accessed through the connector
* Data accessibility - data is always accessible, even when the Hadoop cluster is shut down
* High data availability - data is highly available and globally replicated 

<!-- more -->

##DIY - build your data lake

Follow these steps in order to create your own `data lake`. 

1. Create your [Cloudbreak account](https://cloudbreak.sequenceiq.com/)
2. Configure your Google Cloud account following these [steps](http://sequenceiq.com/cloudbreak/#accounts)
3. Copy the appropriate version of the [connector jar](https://cloud.google.com/hadoop/google-cloud-storage-connector) to the Hadoop classpath and the key file for auth on every node of the cluster - use this [script](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/data-lake/copyscripts.sh) to automate the process
4. Use this Ambari [blueprint](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/data-lake/gcs-con-multi-node-hdfs-yarn.blueprint) to configure the connector
5. Restart the following services: HDFS, YARN and MapReduce2

That's it - you are done, you can work on your data stored in Google Storage. The next release of [Cloudbreak](https://github.com/sequenceiq/cloudbreak) will incorporate and automate these steps for you - and will use HCatalog to allow you to configure an `always on` data store using object storages. 

## Performance results

We configured two identical clusters with [Cloudbreak](http://sequenceiq.com/cloudbreak/) on Google Cloud with the following parameters 

* Number of nodes: 1 master node + 10 slave nodes 
* 2 * 200 GB rotating HDD (where appropriate)
* 2 Virtual CPU
* 7.5 GB of memory

First of all we run all the Hadoop and the certification tests in order to validate the correctness of the setups. For the tests we have provisioned an **Hortonwork's HDP 2.1** cluster.

After these steps we have switched to the `standard` performance test - **TeraGen, TeraSort and TeraValidate**. Please see the results below.


| File System           | TeraGen | TeraSort | TeraValidate
|-----------------------|---------|----------|-------------  
| HDFS                  |58mins, 58sec|4hrs, 59mins, 6sec|35mins, 58sec
| Google Cloud Storage  || 4hrs, 34mins, 52sec|


## Summary

There is a pretty good literature about HDFS and object storages and lots of debates around. At [SequenceIQ](http://sequenceiq.com) we support both - and we also believe that each and every company or use case has his own rationale behind choosing one of them. When we came up with the mission statement of simplifying how people work with Hadoop and stated that we'd like to give the broadest available options to developers we were pretty serious about. 

[Cloudbreak](http://sequenceiq.com/cloudbreak/) was designed around being cloud agnostic - running on Docker and being able to ship those containers to bare metal or any cloud provider with a very easy integration process: currently we support **Amazon AWS, Microsoft Azure and Google Cloud** in public beta and **OpenStack, Digital Ocean** integration in progress/private beta. 
As for the supported Hadoop distribution we provision **Apache Hadoop and Hortonworks HDP** in public and **Cloudera CDH** in private beta.

All the private betas will emerge into public programs and will be in GA - and open sourced under an Apache2 license during Q4.

[Banzai Pipeline](http://docs.banzai.apiary.io/) will be released quite soon - stay tuned - will support one API/representation of your big data pipeline and running on multiple runtimes: **MR2, Spark and Tez**.

For updates follow us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or
[Facebook](https://www.facebook.com/sequenceiq). 
