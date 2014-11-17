---
layout: post
title: "Building the data lake in the cloud - Part2"
date: 2014-11-17 15:56:32 +0200
comments: true
categories: [Cloudbreak]
author: Marton Sereg
published: true
---

Few weeks ago we had a [post](http://blog.sequenceiq.com/blog/2014/10/28/datalake-cloudbreak/) about building a `data lake` in the cloud using a cloud based `object storage` as the primary file system.
In this post we'd like to move forward and show you how to create an `always on` persistent datalake with [Cloudbreak](http://sequenceiq.com/cloudbreak/) and create `ephemeral` clusters which can be scaled up and down based on configured SLA policies using [Periscope](http://sequenceiq.com/periscope/).

Just as a quick reminder - both are open source projects under Apache2 license and the documentation and code is available following these links below.

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

The proposed sample architecture is shown on the diagram below - we have a **permanent** cluster which contains the `metastore database` and a local `metastore service`, an **ephemeral** cluster where the `metastore service` talks to a remote `metastore database` and the Hive `warehouse` with the data being stored in the cloud provider's `object store`.

![](https://raw.githubusercontent.com/sequenceiq/blog-test/source/source/images/hive-metastore/hive-permanent-ephemeral.jpg)

Setting up a an architecture as such can be pretty complicated and involves a few steps - where many things could go wrong.

At [SequenceIQ](http://sequenceiq.com) we try to automate all these steps and build into our product stack - and we did exactly the same with [Cloudbreak](http://sequenceiq.com/cloudbreak/). While a default Hive metastore cluster can be created in a fully automated manner using Cloudbreak `blueprints` in case of different cloud providers (remember we support AWS, Google Cloud and Azure, Open Stack in the pipeline) there are settings which you will need to apply on each nodes, reconfigure services, etc - and on a large cluster this is pretty awkward.
Because of these in the next release of Cloudbreak we introduce a new concept called **recipes**. A recipe will embed a full architectural representation of the Hadoop stack - incorporating all the necessary settings, service configurations - and allows the end user to bring up clusters as the one(s) discussed in this blog - with a push of a button, API call or CLI interface.

##Permanent cluster - on AWS and Google Cloud

Both Amazon EC2 and Google Cloud allows you to set up a permanent cluster and use their `object store` for the Hive warehouse. You can set up these clusters with [Cloudbreak](http://cloudbreak.sequenceiq.com) - overriding the default configurations in the blueprints.

####Using AWS S3 as the Hive warehouse

This setup will use the S3 Block FileSystem - as a quick note you need to remember that this is not interoperable with other S3 tools.

```
    {
      "core-site": {
        "fs.s3.awsAccessKeyId": "YOUR ACCESS KEY",
        "fs.s3.awsSecretAccessKey": "YOUR SECRET KEY"
      }
    },
    {
      "hive-site": {
        "hive.metastore.warehouse.dir": "s3://siq-hadoop/apps/hive/warehouse"
      }
    }
```

You will need to create an S3 `bucket` first - `siq-hadoop` in our example - that will contain the Hive warehouse. After the cluster is up you can start using Hive as usual. When you create a table its metadata will be stored in the MySQL database configured in the blueprint and if you load data in it, it will be moved to the warehouse location on S3. Note that in order to use the `LOAD DATA INPATH` hive command the source and target directories must be located on the same filesystem, so a file in local HDFS cannot be used.

####Using Google Storage as the Hive warehouse

This setup will use the Google Storage - and the GS to HDFS connector.

```
      "global": {
        "fs.gs.impl": "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystem",
        "fs.AbstractFileSystem.gs.impl": "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFS",
        "fs.gs.project.id": "siq-haas",
        "google.cloud.auth.service.account.enable": true,
        "google.cloud.auth.service.account.email": "YOUR_ACCOUNT_ID@developer.gserviceaccount.com",
        "google.cloud.auth.service.account.keyfile": "/mnt/fs1/<PRIVATE_KEY_FILE>.p12"
      }
```

Note that in case of Google being used as an object store you will need to add your account details and the path towards your P12 file. You'll also have to copy the connector JAR to the classpath and the p12 file to every node as mentioned in our previous [post](http://blog.sequenceiq.com/blog/2014/10/28/datalake-cloudbreak/).

##Ephemeral cluster - on AWS and Google Cloud

Ephemeral Hive clusters are using a very similar configuration: they also have to reach the object store as HDFS so the corresponding configurations must be there in the blueprint. The only [additional parameters](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.2.2/bk_installing_manually_book/content/rpm-chap6-3.html) needed are the ones that configure how the metastore service of the ephemeral cluster will reach the Hive `metastore DB` in the permanent cluster. Note: on the permanent cluster you will have to configure the `metastore DB` to allow connections from remote clusters.

```
    {
      "hive-site": {
        "hive.metastore.warehouse.dir": "s3://siq-hadoop/apps/hive/warehouse",
        "javax.jdo.option.ConnectionURL": "jdbc:mysql://$mysql.full.hostname:3306/$database.name?createDatabaseIfNotExist=true",
        "javax.jdo.option.ConnectionDriverName": "com.mysql.jdbc.Driver",
        "javax.jdo.option.ConnectionUserName": "dbusername",
        "javax.jdo.option.ConnectionPassword": "dbpassword"
      }
    }
```

##Conclusion

As highlighted in this example, building a data lake or data warehouse is pretty simple and can be automated with [Cloudbreak](http://cloudbreak.sequenceiq.com) - also with the new `recipe` feature we are standardizing the provisioning of different Hadoop clusters. One of the coming posts will highlight the new architectural changes - and the components we use for service discovery/registry, failure detection, key/value store for dynamic configuration, feature flagging, coordination, leader election and more.

Make sure you check back soon to our [blog](http://blog.sequenceiq.com/) or follow us
on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook).
