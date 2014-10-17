---
layout: post
title: "Boot2docker TLS workaround"
date: 2014-10-17 18:46:39 +0200
comments: true
categories: [docker]
author: Lajos Papp
published: true
---

Docker 1.3.0 has been released with the invaluable `docker exec`
[command](https://docs.docker.com/reference/commandline/cli/#exec).

Boot2docker 1.3.0 delivered also some really neat features such
as [Folder sharing](https://github.com/boot2docker/boot2docker#virtualbox-guest-additions)
with virtualbox guest additions. So finally OSX users are able to for example serve local html files in a container:
`docker run -v /Users/lalyos/webapp/:/usr/share/nginx/html:ro nginx`

## Issue

Boot2docker also changed Docker listening from http://0.0.0.0:2375 to https://0.0.0.0:2376.
While switching on TLS is highly recommended, but its not backward compatible.
Some tools or environments are relying to be able to connect to Docker
via simple http. So after upgrading to 1.3.0 something might be broken.

## Workaround

Downgrading is for the weak ;)
One alternative solution is to start a container which uses `socat` to proxy the unix
socket file `/var/run/docker.sock` as a tcp port. It is containerized for you:

```
$(docker run sequenceiq/socat)
```

Now you can reach Docker the *old* way:

```
curl http://192.168.59.103:2375/_ping
OK
```

## tl;dr

The one-liner `$(docker run sequenceiq/socat)` does the following trick under the hood:

- it start the **sequenceiq/socat** container without any volume/port or CMD specification
- so the default `/start` bash script takes command
- the `/start` script ([see source](https://github.com/sequenceiq/docker-socat/blob/master/start)) recognizes that it didn't started the proper way, so it
  **prints the correct docker command** to stdout (see below)
- the `$( ... )` notation executes the correct docker command

So for reference, or you want to start it by hand, here is the full command:

```
docker run -d \
  -p 2375:2375
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  --name=docker-http \
  sequenceiq/socat
```
