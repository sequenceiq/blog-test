---
layout: post
title: "Using UAA as an identity server"
date: 2014-10-16 16:23:59 +0200
comments: true
categories: [OAuth2, CloudFoundry, UAA, Docker]
author: Marton Sereg
published: false
---

When we first released [Cloudbreak](https://cloudbreak.sequenceiq.com/) it contained its own authentication and user management layer.
We were using basic authentication for the API calls so every request had to contain a username and a password *Base64* encoded in the authorization header.
Cloudbreak also had its own user representation and we were binding the resources - like clusters - to these users.

This approach had multiple flaws. As we were starting to develop multiple [projects](http://sequenceiq.com/periscope/) for our future Platform as a Service solution it became obvious that we will have to refactor our whole user management layer out from Cloudbreak and **share it across our projects**.
Base64 encoding of usernames and passwords is not the best solution either even if transport layer security is working.

What comes into play almost instantly when dealing with these kind of problems is **OAuth2** but it's not as trivial as it first sounds.

##OAuth2

The main "problem" with OAuth2 is that its [specification](http://tools.ietf.org/html/rfc6749) leaves a lot of decisions up to the implementations.
First of all it does not speak at all about authentication, only authorization. It also leaves out details such as how to manage users, how scopes and tokens look like or how these tokens should be checked by a resource server.

Because of all these reasons implementing a full OAuth2 solution from scratch means a *lot* of work and reinventing the wheel and of course we didn't want to do that.
Luckily there are a few specifications that complement the original standard and there are also some solutions that implement not only the basic specification but these complementary specifications too.

**[UAA](https://github.com/cloudfoundry/uaa) is CloudFoundry's fully open source identity management service.**
According to the documentation its primary role is as an OAuth2 provider that can issue tokens for client applications, but it can also authenticate users and can manage user accounts and OAuth2 clients through an HTTP API.
To achieve these things it uses these specifications:

- [OpenID Connect](http://openid.net/connect/) for authentication

- [SCIM](http://www.simplecloud.info/) for user management

- [JWT](http://self-issued.info/docs/draft-ietf-oauth-json-web-token.html) for token representation

UAA adds a few more things on top of these like client management endpoints which makes it a complete solution as an identity server.
And the best thing is that it is **fully configurable through environment variables and a YAML file**.

<!-- more --> 

##Deploying the UAA server

UAA is a Spring-based Java web application that runs on Tomcat. The first thing we did was to create a [Docker image](https://registry.hub.docker.com/u/sequenceiq/uaa/) that deploys a UAA server so it became this easy:
```
docker run -d --link uaa-db:db -e UAA_CONFIG_URL=https://raw.githubusercontent.com/sequenceiq/docker-uaa/master/uaa.yml sequenceiq/uaa:1.8.1
```
There are two ways to provide an UAA configuration file: you can specify an URL like above, or via volume sharing. You can simply put your configuration in the shared directory (`/tmp/uaa` in the example):
```
docker run -d --name uaa --link uaa-db:db -v /tmp/uaa:/uaa sequenceiq/uaa:1.8.1
```
Linking a database container is only necessary if you're using a configuration like we did [in this example](https://github.com/sequenceiq/docker-uaa/blob/master/uaa.yml).
If you'd like to create a postgresql database to try out the sample configuration on your local environment run the following command first that creates a default postgresql database:
```
docker run -d --name uaa-db postgres
```

##UAA Configuration

The UAA [documentation](https://github.com/cloudfoundry/uaa/blob/master/docs/Sysadmin-Guide.rst#configuration) covers the configuration part pretty well, but I'll share my own experiences through some examples.

###Database

The first part of the configuration file describes where the data will be stored. Environment variables can be used inside the YAML file, they will be expanded when UAA processes the file.
When linking Docker containers the address and the exposed ports of the linked container show up as environment variables in the other container so we can make use of it and provide the postgresql address like this:
```
database:
  driverClassName: org.postgresql.Driver
  url: jdbc:postgresql://${DB_PORT_5432_TCP_ADDR}:${DB_PORT_5432_TCP_PORT}/${DB_ENV_DB:postgres}
  username: ${DB_ENV_USER:postgres}
  password: ${DB_ENV_PASS:}
```

###Default clients

Default clients and users can also be described in the configuration, but they can be added or modified later through the [User Management API](https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#user-account-management-apis) and the [Client Administration API](https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#client-registration-administration-apis).

```
oauth:
  clients:
    mywebapp:
      id: mywebapp
      secret: changeme
      authorized-grant-types: authorization_code
      scope: myresourceserver.scope1,myresourceserver.scope2,openid,password.write
      authorities: uaa.none
      redirect-uri: http://localhost:3000/authorize
```
Every client should have an `authorized-grant-types` attribute that tells which OAuth2 flow the client can use to obtain a token. The most common is the *authorization code flow* that is typically used by web applications. The other possible values are `implicit`, `password` and `client_credentials`.

A `secret` is not needed for a client with an implicit grant type (implicit flow is typically used from client-side web apps where a secret cannot be used), and of course a `redirect-uri` is not needed for a client with a `client_credentials` grant type.

The client can request the `scopes` described here from the user. These scopes are arbitrary strings that mean something only to the resource server, but UAA uses the base name (anything before the first dot) of the scopes as the [audience field](http://tools.ietf.org/html/draft-ietf-oauth-json-web-token-25#section-4.1.3) in the JWT token, so it's recommended to use this kind of naming convention.

`authorities` are basically scopes but only used when the token represents the client itself. It can be useful for example when a client wants to use the SCIM endpoints of the UAA server - there are built-in scopes for that: `scim.read` and `scim.write`.

There are some clients where the user should not be asked to approve a token grant explicitly (e.g.: a command line shell). To surpass the confirmation and accept the permission request automatically, add the following to the `oauth` section:
```
client:
    override: true
    autoapprove:
      - mycommandlineshell
```

###Default users

The users defined in this section are populated in the database after startup.

```
scim:
  username_pattern: '[a-z0-9+\-_.@]+'
  users:
    - paul|wombat|paul@test.org|Paul|Smith|openid,myresourceserver.scope1,myresourceserver.scope2
```

This one is quite straightforward. The users are added in the specified format:
```
username|password|email|given name|last name|groups
```
The SCIM specification does not speak about roles, scopes or accounts, it only knows *[groups](http://www.simplecloud.info/specs/draft-scim-core-schema-01.html#group-resource)* besides *users* where users can be *members* of a group.
UAA handles scopes as groups, but groups can also be used for other things like adding users to a company account.

##Resources
If you'd like to learn more about UAA, check out its [documentation](https://github.com/cloudfoundry/uaa/tree/master/docs) or its [sample applications](https://github.com/cloudfoundry/uaa/tree/master/samples).
We'll also have another blog post soon where I'll show some code examples of the OAuth2 flows we're using with UAA as an identity server so check back in a few days if you're interested.

For updates follow us on [LinkedIn](https://www.linkedin.com/company/sequenceiq), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).

