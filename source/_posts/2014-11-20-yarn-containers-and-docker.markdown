---
layout: post
title: "YARN containers as Docker containers in Docker"
date: 2014-11-20 15:56:32 +0200
comments: true
categories: [YARN]
author: Janos Matyas
published: true
---

The new Hadoop 2.6 [release](https://issues.apache.org/jira/secure/ReleaseNote.jspa?projectId=12310240&version=12327179) is almost here with an impressive set of new features and collaboration from the community - including [SequenceIQ](http://sequenceiq.com) as well. It's not a new information that we use Docker quite a lot - and have `containerized` the full Hadoop ecosystem, and the **2.6** release will contain a new feature: [YARN-1964](https://issues.apache.org/jira/browse/YARN-1964).

##YARN containers as .. Docker containers

[Introduction](https://issues.apache.org/jira/browse/MAPREDUCE-279) of YARN has revolutionized Hadoop - extending it with a new resource management, opening up Hadoop to different workloads, etc. - it's all history and we know it. With the emergence and wide adoption of Docker these days we are part of another `interesting` times again. Hadoop 2.6 will introduce (though in `alpha`) an analogy of YARN containers as Docker containers.

Just to remember, a container is the resource allocation which is the successful result of the ResourceManager granting a specific ResourceRequest. A Container grants rights to an application to use a specific amount of resources (memory, cpu etc.) on a specific host, and isolates it from other containers. Sounds familiar - well, among few others this is what exactly Docker does - with the additional benefit of `packaging` and `shipping` applications the easy way.

Though there is still a long way to go in order to make this support the same features as YARN containers does today the future is very promising. All the networking, accessing external data, etc are already well-trodden paths. As an example [SequenceIQ containers](https://registry.hub.docker.com/repos/sequenceiq/?&s=downloads) available and open sourced on the official Docker registry all using some of these needed features.

##Wait, but you run Hadoop in Docker already

OK, got it. YARN containers are Docker containers. But wait, all the Hadoop ecosystem at [SequenceIQ](http://sequenceiq.com) is running inside a cluster of Docker containers, right?
Actually that's true - we run everything in Docker, and we will use these new feature to package some applications as Docker containers and run them inside YARN containers as Docker containers (err, how many times am I going to write down Docker in one sentence). Basically we will run **Docker in Docker**. How's that possible? Pretty easy and simple, Docker already does support this - the only requirement is that your Docker version should support the `--privileged` flag (0.6+).

We have put together a Docker container for you to give it a quick try - it's available on our [GitHub page](https://github.com/sequenceiq/docker-dind).

Built the container

```
docker build -t sequenceiq/dind .
```

Run the container

```
docker run -it --rm --privileged -e LOG=file sequenceiq/dind
```

It will start a Docker daemon in the background (unix:///var/run/docker.sock) and provide a bash session where you can play with a vanilla Docker environment. Once you are inside the container you will be able to pull or start any other Docker container - this is basically will work the same way as the how a YARN Docker container will run inside a Dokcer container.

Once the new **2.6** release will be out we will release it as a Hadoop [container](https://registry.hub.docker.com/u/sequenceiq/hadoop-docker/) (as usuall) as well - to give you an easy way to try this new feature. Also we are putting together some examples in order to start experimenting this new cool feature - now that you understand how **Docker in Docker** works and you can start containers inside containers (inside containers, ...) check back soon for some more serious stuff. In the meanwhile make sure you follow us through our [blog](http://blog.sequenceiq.com/), [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook).
