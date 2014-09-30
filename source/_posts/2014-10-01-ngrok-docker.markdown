---
layout: post
title: "Running ngrok in Docker"
date: 2014-10-01 18:00:00 +0200
comments: true
categories: [ngrok, REST API, debug]
author: Wilbur Sarnguranaj
published: false
---

At [SequenceIQ](http://sequenceiq.com) we work quite a lot with different cloud providers and receive callbacks, push notifications and messages broadcasted to subscribed topics. While subscribing and receiving these messages to a `public domain/IP address` is not an issue, doing development and testing on internal networks can be challenging. Being able to do these we use **ngrok** - a reverse proxy that creates a secure tunnel between from a public endpoint to a locally running service.

While you can always use hosted and free [ngrok](https://ngrok.com/) solution, many time due to security and availability issues you might want to use your own internally deployed `ngrok server` (with your custom domain name). This post discuss this, and offer a Docker based solution/one-liner for you to start with in less than a minute. As we always `containerize` everything we did the same with ngrok as well, and made it available in the official Docker [repository](https://registry.hub.docker.com/u/sequenceiq/ngrokd/).

##Pull and use the `ngrok` server

To get the container use the following:

```
docker pull sequenceiq/ngrokd
```

Once you have the container you are ready to start and use it.

```
docker run -d --name ngrokd \
  --restart=always \
  -p 4480:4480 \
  -p 4444:4444 \
  -p 4443:4443 \
  sequenceiq/ngrokd \
    -httpAddr=:4480 \
    -httpsAddr=:4444 \
    -domain=ngrok.sequenceiq.com
```
<!-- more -->

##Install the `ngrok` client

Since the `ngrok` client is not distributed *officially*, we have compiled it for Linux and OSX. Based on the [self hosting documentation](https://gist.github.com/lyoshenka/002b7fbd801d0fd21f2f)

> Since the client and server executables are paired, you won't be able to use
  any other ngrok to connect to this ngrokd, and vice versa.

As usual for us - being automation freaks - we have created a `one-liner` for OSX and Linux as well.
####OSX
Run this and everything is done - customize it if you wish.
```
curl -Ls j.mp/ngrok-seq
```

For reference, or if you want to do only the install step:
```
brew cask install https://raw.githubusercontent.com/sequenceiq/docker-ngrokd/master/ngrok.rb
```
####Linux

```
curl -o /usr/local/bin/ngrok https://s3-eu-west-1.amazonaws.com/sequenceiq/ngrok_linux
chmod +x /usr/local/bin/ngrok
```
Please make sure you check the ngrok version:

You should see the `1.7.2` on client side:
```
> ngrok version

1.7.2
```
####Client configuration

In case you have used the `one-liner` above you wont need this.
```
cat > ~/.ngrok <<EOF
server_addr: server.ngrok.sequenceiq.com:4443
trust_host_root_certs: false
EOF
```
Starting ngrok is business as usual, just use `ngrok <port>`. Please note that you will need an an `A record`, something like:

```
*.ngrok.YOURDOMAIN.com xx.xx.xx.xx
```
Pretty much that’s it, you have a self-hosted ngrok server in Docker.

##Sample use case

One of the frequent use cases for us (above the ones mentioned in the introduction) is API debug. SequenceIQ being a technology company, we are creating lots of REST APIs and
would like to have the ability to switch on and off debugging dynamically (without having to modify anything at the application level, logging, etc). Also we’d like to use the same process when we are running over http or https - and do SSL termination when it’s necessary (note that we are talking about dev/test).
We like/use `ngrok` as we can introspect the API and do debugging and call recording/replays in a **non intrusive** way, without modifying the application at all.
Yet another nice feature we are using is to `inspect` Docker commands - over tcp.

If you have any questions or suggestions you can reach us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/),
 [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).
