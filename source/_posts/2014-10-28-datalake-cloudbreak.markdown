---
layout: post
title: "Building the data lake in the cloud - Part1"
date: 2014-10-28 15:56:32 +0200
comments: true
categories: [Cloudbreak]
author: Janos Matyas
published: false 
---

A while ago we have released our cloud agnostic and Docker container based Hadoop as a Service API - [Cloudbreak](http://sequenceiq.com/cloudbreak/). Though the purpose of [Cloudbreak](https://cloudbreak.sequenceiq.com) is to quickly provision arbitrary sized Hadoop clusters in the cloud, the project emerged from bare metal Hadoop provisioning in Docker containers. We were (still doing it) [provisioning](http://blog.sequenceiq.com/blog/2014/06/19/multinode-hadoop-cluster-on-docker/) Hadoop on bare metal using Docker - and because of this legacy the data was always stored in HDFS. Recently we have been asked to run a proof-of-concept project and build an `always on` data lake using a cloud `object storage`. 

This post is the first in this series and will cover the connectivity, interoperability and access of data from an `object storage` and work with that in Hadoop. For this post we choose to create a `data lake` on Google Cloud Compute and guide you through the steps, run performance tests and understand the benefits/drawbacks of such a setup.

##Object storage

An object storage usually is an `internet service` to store data in the cloud and comes with a programming interface which allows to retrieve data in a secure, durable and highly-scalable way. The most well know object storage is **Amazon S3** - with a pretty well covered literature, thus in this example we will use the **Google Cloud Storage**. Google Cloud Storage enables application developers to store their data on Google’s infrastructure with very high reliability, performance and availability, and can be used to distribute large data objects - like HDFS. In many occasions companies stores their data in objects storages - but for analytics they would like to access it from their Hadoop cluster. There are several options available: 
* replicate the full dataset in HDFS
* read and write from `object storage` at start/stop of the flow and use HDFS for intermediary data
* use a connector such as Google Cloud Storage Connector for Hadoop

##Google Cloud Storage Connector for Hadoop

Using this connector developed by Google allows you to choose `Google Cloud Storage` as the default file system for Hadoop, and run all your jobs on top (we will come up with MR2 and Spark examples). Using the connector can have several benefits, to name a few:
* Direct data access - data is stored in GCS, no need to transfer it into HDFS 
* HDFS compatibility - data stored in HDFS can be accessed through the connector
* Data accessibility - data is always accessible, even when the Hadoop cluster is shut down
* High data availability - data is highly available and globally replicated 

##DIY - build your data lake

## Performance results


For updates follow us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or
[Facebook](https://www.facebook.com/sequenceiq).
