---
layout: post
title: "Selfhosted ngrok server in Docker"
date: 2014-10-09 10:00:00 +0200
comments: true
categories: [docker]
author: Lajos Papp
published: true
---
[Ngrok](vhttps://ngrok.com/) is used for Introspected tunnels to localhost.
In integration testing situations is really common, that you want to bind some webhooks
to localhost. For example you want AWS SNS deliver messages to your service,
but is not reachable publicly, as it runs only on localhost.

So its really 2 in 1: **local tunnel** and **introspection**. Sometimes you
just want to use its **introspection** feature, to get insight about how a
specific API works. It's like a local [runscope](https://www.runscope.com/).

While you can always use the free hosted version: [ngrok](https://ngrok.com/),
there are reasons to roll you own:

- Sometimes the free hosted version has **availability** issues,when it gets heavy traffic
- Yo don't want your messages/calls go through a public free service, for
  **security** concerns
- You just want to use its **introspection** feature, and want to avoid the
  extra **network** round trip to ngrok.com and back.

There is documentation about [self hosting ngrok](https://github.com/inconshreveable/ngrok/blob/master/docs/SELFHOSTING.md)
But it include steps, like:

- create an SSL certificate
- build server/client binaries using the cert above
- configure, and install it on your server

How about using a **single click** version of this? Easy: we have already containerized
this process and made it available in the official Docker
[repository](https://registry.hub.docker.com/u/sequenceiq/ngrokd/).

<!-- more -->

## Running

To launch the ngrok daemon, you just have to start the `sequenceiq/ngrokd` Docker image:

```
docker run -d --name ngrokd \
  -p 4480:4480 \
  -p 4444:4444 \
  -p 4443:4443 \
  sequenceiq/ngrokd \
    -httpAddr=:4480 \
    -httpsAddr=:4444 \
    -domain=ngrok.mydomain.com
```

It will expose 3 ports:

- **4444**: that is the so called control port, ngrok clients connect there
- **4480/4443**: this to port is used for the tunneled http/https connections
- **domain**: this is the domain name, clients need to use to connect to the
  server, and the ngrok server will assign `<SUBDOMAIN>.ngrok.mydomain.com`
  addresses to each tunnel.

## Install the custom `ngrok` client

You remember we have a custom ngrok daemon inside the Docker image. Based on the
[self hosting documentation](https://gist.github.com/lyoshenka/002b7fbd801d0fd21f2f)

> Since the client and server executables are paired, you won't be able to use
  any other ngrok to connect to this ngrokd, and vice versa.

So we need the *paired* ngrok client

### OSX

If you use brew:
```
brew cask install https://raw.githubusercontent.com/sequenceiq/docker-ngrokd/master/ngrok.rb
```

otherwise:
```
curl -o /usr/local/bin/ngrok https://s3-eu-west-1.amazonaws.com/sequenceiq/ngrok_darwin
chmod +x /usr/local/bin/ngrok
```

### Linux

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

## Client configuration

```
cat > ~/.ngrok <<EOF
server_addr: ngrok.mydomain.com:4443
trust_host_root_certs: false
EOF
```
## Hostname workaround

If you want to run ngrokd internally just use a new entry
in `/etc/hosts`

```
<NGROKD_IP> ngrok.mydomain.com subdomain1.mydomain.com subdomain2.mydomain.com
```

If you want a proper subdomain you need an `A record` suche as:
`*.ngrok.mydomain.com 54.72.21.93`

## Usage

Starting ngrok is business as usual, just use `ngrok <port>`.
Pretty much that’s it, you have a self-hosted ngrok server in Docker.
Then you can introspect the tunnel on http://127.0.0.0:4444

## Sample use case

To fully understand how Docker works, sometimes it's useful to see how the
Docker client communicates with the Docker server. You can just use ngrok
to introspect the Docker API.

```
ngrok -subdomain=docker 127.0.0.1:2375
```

then if you want to record API calls you have to configure

```
alias docker='docker --host=tcp://docker.ngrok.mydomain.com:4480'
```
