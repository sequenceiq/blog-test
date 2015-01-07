---
layout: post
title: "Docker containers as Apache YARN containers"
date: 2015-01-07 11:00:00 +0200
comments: true
categories: [YARN]
author: Attila Kanto
published: true
---

The Hadoop 2.6 release contains a new [feature](https://issues.apache.org/jira/browse/YARN-1964) that allows to launch Docker containers directly as YARN containers. Basically this solution let the developers package their applications and all of the dependencies into a Docker container in order to provide a consistent environment for execution and also provides isolation from other applications or softwares installed on host.

##Configuration
To launch YARN containers as Docker containers the  [DockerContainerExecutor](http://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/DockerContainerExecutor.html) and the Docker client needs to be set up in the `yarn-site.xml` configuration file:
```xml
<property>
  <name>yarn.nodemanager.container-executor.class</name>
  <value>org.apache.hadoop.yarn.server.nodemanager.DockerContainerExecutor</value>
</property>

<property>
  <name>yarn.nodemanager.docker-container-executor.exec-name</name>
  <value>/usr/local/bin/docker</value>
</property>
```

As the documentations states the DockerContainerExecutor requires the Docker daemon to be running on the NodeManagers and the Docker client must be also available, but at [SequenceIQ](http://sequenceiq.com) we have already packaged and running the whole Hadoop ecosystem into Docker containers and therefore we already have a Docker daemon and Docker client, the only problem is that they are outside of our Hadoop container and therefore the NodeManager or any other process running inside the container does not have access to them. In one of our [earlier post](http://blog.sequenceiq.com/blog/2014/11/20/yarn-containers-and-docker/) we have considered  to run Docker daemon inside Docker, but instead of running Docker in Docker it is much more simpler just to reuse the Docker daemon and Docker client what was used for launching the [SequenceIQ](http://sequenceiq.com) containers.


##Reuse of Docker daemon and client
The problem what needs to be solved is to connect to Docker daemon (running on host) from a process running inside the container. It is possible to make the Docker daemon to listen on a specific TCP port, but it is not recommended due to security reasons since exposing the port might allow other clients to connect it and accidentally start/stop containers or even gain root access to the host where the daemon is running. Luckily the Docker daemon can listen on Unix domain socket on `unix:///var/run/docker.sock` to allow local connections and this can be mounted as Docker volume from the container.

For setting up the Docker client we also have multiple options, e.g. we can install it into the container or we can just mount the Docker client as a volume since it is just a single binary executable file.

These configuration has already been set up in the [dce branch of hadoop-docker repository](https://github.com/sequenceiq/hadoop-docker/tree/dce) and also made available in the Docker Registry under the name sequenceiq/hadoop-docker:2.6.0-dce, therefore the command to try out the DockerContainerExecutor would look like this:

```
docker run -i -t -v /usr/local/bin/docker:/usr/local/bin/docker -v /var/run/docker.sock:/var/run/docker.sock --net=host sequenceiq/hadoop-docker:2.6.0-dce /etc/bootstrap.sh -bash

# To verify it just launch the following command inside the container
docker ps
CONTAINER ID        IMAGE                                COMMAND ...
c07914786e78        sequenceiq/hadoop-docker:2.6.0-dce   "/etc/bootstrap.sh ...
```

From the first look this seems sufficient, but if you try to execute any Hadoop example it will fail, because the DockerContainerExecutor passes launch configuration and shares log files with YARN containers trough Docker volumes and in our configuration the Docker daemon is running outside of the sequenceiq/hadoop-docker container in other words it is not running on the same place where the NodeManager, therefore directories that are intended to be mounted as Docker volumes for YARN containers will not be there since the NodeManager is running inside a container and the directories are mounted from host. The workaround for this is to create the directories directly on host machine and mount them to sequenceiq/hadoop-docker container and the same directories will be mounted to YARN containers by DockerContainerExecutor.

```
# On host machine where the Docker daemon is running (if you are using OS X then on boot2docker)
mkdir -p /tmp/hadoop-root/nm-local-dir
mkdir -p /usr/local/hadoop/logs/userlogs/

docker run -i -t -v /usr/local/bin/docker:/usr/local/bin/docker -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/hadoop-root/nm-local-dir:/tmp/hadoop-root/nm-local-dir -v /usr/local/hadoop/logs/userlogs:/usr/local/hadoop/logs/userlogs --net=host sequenceiq/hadoop-docker:2.6.0-dce /etc/bootstrap.sh -bash

```

This is clearly a workaround and we are considering to create a patch for DockerContainerExecutor to make the volume sharing seamless by using Data Volume Container.

##Starting a MapReduce Job
Starting a stock example also requires a few extra parameters like `mapreduce.map.env`, `mapreduce.reduce.env` and `yarn.app.mapreduce.am.env`, since the DockerContainerExecutor needs to know which Docker container shall be executed as YARN container.

```
# run the grep with 2.6.0
cd $HADOOP_PREFIX

bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.6.0.jar grep -Dmapreduce.map.env="yarn.nodemanager.docker-container-executor.image-name=sequenceiq/hadoop-docker:2.6.0-dce" -Dmapreduce.reduce.env="yarn.nodemanager.docker-container-executor.image-name=sequenceiq/hadoop-docker:2.6.0-dce" -Dyarn.app.mapreduce.am.env="yarn.nodemanager.docker-container-executor.image-name=sequenceiq/hadoop-docker:2.6.0-dce" input output 'dfs[a-z.]+'

# check the output of grep
bin/hdfs dfs -cat output/*
```

As you can see the sequenceiq/hadoop-docker:2.6.0-dce image has been specified as parameters and not the sequenceiq/hadoop-docker:2.6.0, but basically there is no difference in this case, since when it is launched as YARN container then only the libraries are are used from the image and the bootstrap.sh or configuration files like yarn-site.xml are ignored.


In order to make it easier to understand you can take a look at the diagram which shows the relationship between containers, processes and volumes.

 * green box: shows the container started by `docker run` command which is defined above
 * blue boxes: represent the containers started by DockerContainerExecutor
 * red boxes: processes started inside the individual containers or directly on host in case of Docker daemon
 * yellow boxes: mounted Docker volumes

 ![](https://raw.githubusercontent.com/sequenceiq/blog-test/source/source/images/yarn-container/process_map.png)

##Summary
We hope that the above example provides you a good start to play with DockerContainerExecutor, but it is important to know that this new feature has been put to Hadoop 2.6 release only in the last minute and it is still in alpha state, therefore using it in production is not recommended.

Make sure you check back soon to our [blog](http://blog.sequenceiq.com/) or follow us
on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook).
