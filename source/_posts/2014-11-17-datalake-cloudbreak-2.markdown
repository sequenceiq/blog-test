---
layout: post
title: "Building the data lake in the cloud - Part2"
date: 2014-11-27 15:56:32 +0200
comments: true
categories: [Cloudbreak]
author: Marton Sereg
published: false
---

Few weeks ago we had a [post](http://blog.sequenceiq.com/blog/2014/10/28/datalake-cloudbreak/) about building a `data lake` in the cloud using the `object storage` as the primary file system.
In this post we'd like to move forward and show you how to create an `always on` persistent datalake with [Cloudbreak](http://sequenceiq.com/cloudbreak/) and create `ephemeral` clusters which can be scalled up and down based on configured SLA policies using [Periscope](http://sequenceiq.com/periscope/).

Just as a quick reminder - both are open source projects under Apache2 license and the documentation and code is available following these links.

| Name                  | Description | Documentation | GitHub
|-----------------------|----|--------| ----------
| Cloudbreak 	     | Cloud agnostic Hadoop as a Service | http://blog.sequenceiq.com/blog/2014/07/18/announcing-cloudbreak/ | https://github.com/sequenceiq/cloudbreak
| Periscope 	     | SLA policy based autoscaling for Hadoop clusters | http://blog.sequenceiq.com/blog/2014/08/27/announcing-periscope/ | https://github.com/sequenceiq/periscope

##Sample architecture

For the sample use case we will create a `datalake` on **AWS** and **Google Cloud** as well - and use the most popular data warehouse software with an SQL interface - [Apache Hive](https://hive.apache.org/).

<!--more-->

From Hive perspective (simplified) while building the `datalake` there are tree main components:

* Hive warehouse - the location where the raw data is stored. Usually it's HDFS, in our case it's the `object store` - **Amazon S3** or **Google Cloud Storage**
* Hive metastore service - the Hive metastore service stores the metadata for Hive tables and partitions in a relational database - aka: **metastore DB**, and provides clients (including Hive) access to this information
* Metastore database - a database implementation where the metastore information is stored and the local/remote metastore services talk to, over a JDBC interface

The proposed sample architecture looks like on this diagram before - we have a **permanent** cluster which contains the `metastore database` and a local `metastore service`, an **ephemeral** cluster where the `metastore service` talks to a remote `metastore database` and the Hive `warehouse` with the data being stored in the cloud provider's `object store`.

![](https://raw.githubusercontent.com/sequenceiq/blog-test/source/source/images/hive-metastore/hive-permanent-ephemeral.jpg)

Setting up a an architecture as such can be pretty complicated and involves a few steps - where many things could go wrong.

At [SequenceIQ](http://sequenceiq.com) we try to automate all these steps and build into our product stack - and we did exactly the same with [Cloudbreak](http://sequenceiq.com/cloudbreak/). While a default Hive metastore cluster can be created in a fully automated manner using Cloudbreak `blueprints` in case of different cloud providers (remember we support AWS, Google Cloud and Azure, Open Stack in the pipeline) there are settings which you will need to apply on each hosts, reconfigure services, etc - and on a large cluster this is pretty awkward.
For this in the next release of Cloudbreak we introduce a new concept called **recipes**. A recipe will incorporate full architectural representations of Hadoop stacks - incorporating all the necessary settings, service configurations - and allows the end user to bring up clusters as the one(s) discussed in this blog - with a push of a button. More over, the recipes being be part of the **subscription based support** we offer once Cloudbreak is in GA, will assure customers that the solution is fully tested on the preferred cloud provider and supported by us and our Hadoop [partner](http://hortonworks.com/partner/sequenceiq/).
