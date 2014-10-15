---
layout: post
title: "Cloudera Manager CLI/shell"
date: 2014-10-16 15:42:11 +0200
comments: true
categories: [Cloudera Manager, Spring Shell, Hadoop, DevOps]
author: Richard Doktorics
published: false
---

Among many others in the past couple of months we have been working on a cloud agnostic, Docker container based Hadoop as a Service API, called [Cloudbreak](http://sequenceiq.com/cloudbreak). The goal of Cloudbreak is to ease the setup of on-demand Hadoop clusters (with support for the whole stack) in any cloud provider - by provisioning the components and services in Docker, and `ship` the containers to your favorite cloud provider. Beside one of the main goals to be `cloud agnostic`, the other important feature for us was to allow customers to select and use their favorite Hadoop distribution, thus providing them freedom and let them avoid distribution lock-in.

We have started the journey by supporting Apache Hadoop and Hortonworks' HDP, and today is time to announce support for Cloudera's distribution (we have Apache Bigtop and MapR in the roadmap, so stay tuned).

Nevertheless, this post will not be about Cloudbreak's integration with Cloudera but the introduction of the 100% open source `Apache 2 licensed` CLI/shell for Cloudera Manager.

At [SequenceIQ](http://sequenceiq.com) we **always** automate everything, and approach all the tasks with a strong DevOps mindset. This was the case when we have announced the [Apache Ambari shell](http://TODO) and [REST client], and this is exacty the case as we are announcing the Cloudera integration. While [Cloudera Manager](TODO) has a nice UI, and an API available we have moved forward and have created a `command line interface` - true DevOps way - which allows to automate and provision a CDH cluster with ease and minutes.

The goal was to support:

* all functionality available through ClouderaManager web-app
* context aware command availability
* tab completion
* required/optional parameter support

##Architecture

* **Spring-shell**: The **write-once-run-everywhere** nature provides support for all OS.[Spring-Shell](http://docs.spring.io/spring-shell/docs/1.0.x/reference/htmlsingle/#preface) seems a natural fit as a base framework.

Spring-Shell is battle tested in various Spring projects including:

* [Spring-Roo](http://projects.spring.io/spring-roo/): lightweight cli tool to aim Rapid Application Development
* [Spring-XD](http://docs.spring.io/spring-xd/docs/1.0.0.BUILD-SNAPSHOT/reference/html) a user-friendly front end for the REST API of Spring XD. Spring XD is a unified, distributed, service for data ingestion, real time analytics, batch processing, and data export.
* [Spring-Rest-Shell](https://github.com/spring-projects/rest-shell) a command-line shell that aims to make writing REST-based applications easier. Spring Rest-Shell itself would be enough to communicate against Ambari REST API, but we wanted a more Donamin Specific Language (DSL) nature of the command structure.

##Installation and usage

CM-Shell is distributed as a single-file executable jar. No ClassNotFound errors should happen. The `uber` jar is generated with the help of spring-boot-gradle-plugin available at: Spring-Boot. Spring-Boot also provides a helper to launch those jars: JarLauncher.

After compiling the project, the shell is ready to use (make sure you use Java 7 or above).

```
java -jar cm-shell/build/libs/cm-shell-0.1.DEV.jar --clouderamanager.host=172.17.0.25 --clouderamanager.port=7180 --clouderamanager.user=admin --clouderamanager.password=admin
```

The `--clouderamanager` options can be omitted if they are the default values otherwise you only need to specify the difference, e.g just the port is different.

```
java -jar cm-shell/build/libs/cm-shell-0.1.DEV.jar --clouderamanager.port=49178
```

After you have launched CM shell you should see something like this:
```
  ___  _ __ ___          ___ | |__    ___ | || |
 / __|| '_ ` _ \  _____ / __|| '_ \  / _ \| || |
| (__ | | | | | ||_____|\__ \| | | ||  __/| || |
 \___||_| |_| |_|       |___/|_| |_| \___||_||_|


Welcome to Cdh Shell. For command and param completion press TAB, for assistance type 'hint'.
```

##Implemented commands
