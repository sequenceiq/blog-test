---
layout: post
title: "Multinode cluster with Ambari 1.7.0 - in Docker"
date: 2014-12-04 20:07:18 +0200
comments: true
categories: [Ambari]
author: Janos Matyas
published: true
---

Two days ago the latest [version](http://ambari.apache.org/) of Ambari (1.7.0) has been released and now is time for us to release our automated process to deploy Hadoop clusters with Ambari in Docker containers.

The release contains lots of new features (follow [this](http://ambari.apache.org/whats-new.html#) link) - we will highlight a few we consider important for us:

* Ambari Views - a systematic way to plug-in UI capabilities to surface custom visualization, management and monitoring features in Ambari Web.
* Extended/new stack definitions - support for Hortonworks HDP and Apache Bigtop stacks
* Apache Slider integration - ease deployments of existing applications into a YARN cluster

As usual we have `dockerized` the whole Ambari 1.7.0 thus you can take the container and provision your arbitrary size Hadoop cluster.

###Get the Docker container
In case you don’t have Docker browse among our previous posts - we have a few posts about howto’s, examples and best practices in general for Docker and in particular about how to run the full Hadoop stack on Docker.

```
docker pull sequenceiq/ambari:1.7.0
```

<!--more-->


Once you have the container you are almost ready to go - we always automate everything and **over simplify** Hadoop provisioning.

###Get ambari-functions
Get the following `ambari-functions` [file](https://github.com/sequenceiq/docker-ambari/blob/1.7.0/ambari-functions) from our GitHub.

```
curl -Lo .amb j.mp/docker-ambari-170 && . .amb
```

###Create your cluster - manually

```
amb-start-cluster 3
```

This will start a 3 node Ambari cluster where all the containers are preconfigured and the Ambari agants are running.

Now lets get familiar with a [SequenceIQ](http://sequenceiq.com) contribution for Ambari: the [Ambari Shell](https://cwiki.apache.org/confluence/display/AMBARI/Ambari+Shell).

Type the following command

```
amb-shell
```

This will start the Ambari shell. After the welcome screen
Now lets quickly create a cluster. Since two days ago Hortonworks released [HDP 2.2](http://hortonworks.com/blog/available-now-hdp-2-2/) let set up an HDP 2.2 cluster. For that we will use this [blueprint](https://gist.github.com/matyix/aeb8837012b5fa253fa5).

In the shell type the following - note that throughout the process you can use `hint` or `help` for guidance and `tab completion` as well.

```
blueprint add --url https://gist.githubusercontent.com/matyix/aeb8837012b5fa253fa5/raw/3476b538c8ba0c16363dbfd9634f0b9fe88cb36e/multi-node-hdfs-yarn
cluster build --blueprint multi-node-hdfs-yarn
cluster autoAssign
cluster create
```

You can track the progress either from the shell or log into the Ambari UI. If you use `boot2docker` you should add routing from your host into the container:

```
sudo route add -net 172.17.0.0/16 192.168.59.103
```

In order to learn the Ambari UI IP address (IPAddres) use:

{% raw %}
```bash
docker inspect --format='{{.NetworkSettings.IPAddress}}' amb0
```
{% endraw %}

That's it.

##Create your cluster - automated

```
amb-deploy-cluster 3
```

**Whaaat?** No really, that’s it - we have just provisioned you a 3 node Hadoop cluster in less than 2 minutes. Docker, Apache Ambari and Ambari Shell combined is quite powerful, isn't it? You can always start playing with your desired services by changing the [blueprints](https://github.com/sequenceiq/ambari-rest-client/tree/master/src/main/resources/blueprints) - the full Hadoop stack is supported.

If you’d like to play around and understand how this works check our previous blog posts - a good start is this first post about one of our contribution, the [Ambari Shell](http://blog.sequenceiq.com/blog/2014/05/26/ambari-shell/).

You have just seen how easy is to provision a Hadoop cluster on your laptop, if you’d like to see how we provision a Hadoop cluster in the cloud using the very same Docker image you can check our open source, cloud agnostic Hadoop as a Service API - [Cloudbreak](http://blog.sequenceiq.com/blog/2014/07/18/announcing-cloudbreak/). Also we have released a project called [Periscope](http://blog.sequenceiq.com/blog/2014/08/27/announcing-periscope/) - the industry's first open source autoscaling API for Hadoop.


For updates follow us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).
