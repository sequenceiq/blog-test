---
layout: post
title: "Securing Cloudbreak with OAuth2 - part 2"
date: 2014-11-03 18:00:08 +0100
comments: true
categories: OAuth2 UAA
author: Marton Sereg
published: true
---

A few weeks ago we've published a [blog post](http://blog.sequenceiq.com/blog/2014/10/16/using-uaa-as-an-identity-server/) about securing our [Cloudbreak](https://cloudbreak.sequenceiq.com/) infrastructure with OAuth2.
We've discussed how we were setting up and configuring a new UAA OAuth2 identity server with Docker but we haven't detailed how to use this identity server in client applications.
And that's exactly what we'll do now: we'll show some code examples about how to obtain tokens from different clients and how to check these tokens in resource servers.

We're using almost every type of the OAuth2 flows in our infrastructure: Cloudbreak and [Periscope](http://sequenceiq.com/periscope/) act as resource servers while [Uluwatu](https://github.com/sequenceiq/uluwatu) and [Cloudbreak shell](https://github.com/sequenceiq/cloudbreak-shell) for example are clients for these APIs.

## Obtaining an access token

The main goal of an OAuth2 flow is to obtain an access token for the resource owner that can be used to access a resource server later.
There are multiple common flows depending on the client type, we'll have examples for three of them now: *implicit*, *authorization code* and *client credentials*.
If you're not familiar with the roles and expressions that take part in the OAuth2 flows I suggest to check out some ["Getting started" resources](http://aaronparecki.com/articles/2012/07/29/1/oauth2-simplified) first before going forward with this post.

### Implicit flow

This is not the most common flow with OAuth2 but it is the most simple one because only one request should be made to the identity server and the token will arrive directly in the response.
Two different types of this flow is supported by UAA. One for browser-based applications and one for those scenarios when there is no browser interaction (e.g.: CLIs).
The common part of these scenarios is that it would be useless to have a client secret because it couldn't be kept as a secret.

We are using the *implicit flow with credentials* in the [Cloudbreak Shell](https://github.com/sequenceiq/cloudbreak-shell).
When using the shell you must provide your SequenceIQ credentials as environment variables and the shell uses those to obtain an access token.
Cloudbreak shell is written in Java but let's see a basic `curl` example instead - it does exactly the same as the Java code. (If you're still eager you can check out the code [here](https://github.com/sequenceiq/cloudbreak-shell/blob/master/src/main/java/com/sequenceiq/cloudbreak/shell/configuration/ShellConfiguration.java#L122))

```
curl -iX POST -H "accept: application/x-www-form-urlencoded"  \
 -d 'credentials={"username":"admin","password":"periscope"}' \
 "http://localhost:8080/oauth/authorize?response_type=token&client_id=cli&scope.0=openid&redirect_uri=http://cli"
```

<!-- more -->

*notes:*

- the `response_type=token` part tells the identity server to return a token *implicitly*

- UAA must be running on `localhost:8080`

- there is a registered client in UAA with `implicit` as *authorized_grant_type*, `cli` as *client ID*, and `http://cli` as *redirect URI* (it doesn't need to be a valid URL but has to match the one in the request)

- the `cli` client is configured in UAA as *autoapproved*

- a user with `admin` as username and `periscope` as password is registered in UAA

If you're having a browser-based application and would like to use the implicit flow it is very similar.
The main difference is that you won't have to provide the credentials in the request body but redirect the user to the same URL.
User authentication will happen through a login form and the `access_token` will appear as a parameter in the redirect URI.
You can simply try this out by opening the same URL in a browser. (Of course the redirect won't be successful with the URI above but the redirect URL will appear in the browser with the access token as a parameter if UAA is properly configured)


### Authorization code flow

The authorization code flow is the most common one - it is used mostly by standard web applications that have some server side code besides the frontend.
It's main advantage against the implicit flow is that the token doesn't show up in the browser, only an authorization code is sent back by the identity server to the browser and it will be exchanged for an access token later in some kind of server side code.
We're using the authorization code flow with Uluwatu that's written in *node.js* so I'll show some *node.js* examples here

The first part of the authorization code flow is almost exactly the same as the browser-based implicit flow: you'll have to redirect the user to the `oauth/authorize` endpoint, but with a different `response_type` (*code*). The response is a redirect again but instead of the access token an authorization code is sent back as a parameter. You can still try it out in a browser - of course the redirect won't be successful if there's nothing listening on the redirect URI but the code will appear in the browser.

A somewhat simplified version of the code we're using [in Uluwatu](https://github.com/sequenceiq/uluwatu/blob/master/server.js#L123) to start the process looks like this:
```
  var authUrl = uaaAddress
    + 'oauth/authorize?response_type=code'
    + '&client_id=' + clientId
    + '&scope=' + clientScopes
    + '&redirect_uri=' + redirectUri
  if (!req.session.token){
    res.redirect(authUrl)
  } else {
    res.render('index');
  }
```

*notes:*

- the `response_type=code` part tells the identity server to return an authorization code instead of an access token

- UAA must be available on the address specified in the uaaAddress variable

- there is a registered client in UAA with `authorization_code` as *authorized_grant_type*, and its *client ID* and *redirect URI* parameters must be specified in the `clientId` and `redirectUri` variables

- we're using the [Express](http://expressjs.com) web framework for node.js.

The second part is about exchanging the authorization code for an access token. To try it out you'll need a web server that will handle the redirect URI. In our case it is done by the [Uluwatu backend](https://github.com/sequenceiq/uluwatu/blob/master/server.js#L100) on the `/authorize` endpoint.

```
var optionsAuth = { user: clientId, password: clientSecret },
    identityServerClient = new restClient.Client(optionsAuth);

identityServerClient.registerMethod("retrieveToken", uaaAddress + "oauth/token", "POST");

app.get('/authorize', function(req, res, next){
  var args = {
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    data:
      'grant_type=authorization_code'
      + '&redirect_uri=' + redirectUri
      + '&code=' + req.query.code
  }
  identityServerClient.methods.retrieveToken(args, function(data, response){
    req.session.token=data.access_token;
    res.redirect('/');
  });
});
```

*notes:*

- the *POST* request must be made to the `oauth/token` endpoint
- the client must authenticate himself by putting the *client id* and *client secret* in a standard basic authentication header. The base64 encoding is done by the client library we're using.
- the access token arrives in the response body along with a refresh token that can be used to renew the access token when it expires

### Client credentials flow

This one is a bit different from the previous ones because this flow is used when a client would like to access some resources by itself, not on behalf of a user.
A common use case with UAA is when we'd like to access the [SCIM](http://www.simplecloud.info/) endpoints for describing or registering users.
[Sultans](https://github.com/sequenceiq/sultans) is the user management service for the SequenceIQ platform. The following example is from the [source](https://github.com/sequenceiq/sultans/blob/master/main.js#L216) of this application.

```
var options = {
  headers: { 'Authorization': 'Basic ' + new Buffer(clientId + ':'+ clientSecret).toString('base64') }
}
needle.post(uaaAddress + '/oauth/token', 'grant_type=client_credentials', options,
  function(err, tokenResp) {
    var token = tokenResp.body.access_token;
  });
```

*notes:*

  - the scopes of a client is described in the authorities property in the UAA configuration.

  - [Needle](https://github.com/tomas/needle) is used to send the HTTP request


## Using the access token to make requests to a resource server

The [Bearer Token Usage part](http://self-issued.info/docs/draft-ietf-oauth-v2-bearer.html) of the OAuth 2.0 specification talks about how to include the access token in a request. According to the specification there are several ways to send the token:

- in the Authorization request header field

- in a form-encoded body parameter

- in a URI query parameter

Only the first of these (the Authorization header) *must* be supported by resource servers, the others are only optional.
Here's how the Authorization header should look like:

```
GET /resource HTTP/1.1
Host: server.example.com
Authorization: Bearer mF_9.B5f-4.1JqM
```

## Checking the token in the resource server

Now that we are able to deploy and configure an UAA identity server, obtain tokens from it in client applications and send these in resource server requests there's only one thing left: how should we implement the resource server part of our infrastructure to handle the token requests. The OAuth 2.0 specification leaves it up to the implementor but with UAA there is one recommended way, the `/check_token` [endpoint](https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#oauth2-token-validation-service-post-check_token).

The boundaries of resource servers and OAuth2 providers are often blurred and they are in the same application therefore checking a token can be implemented in place by going directly to a token store or decoding the JWT token. If the components are correctly separated this can only be done if the token is encrypted with a shared secret between the provider and the resource server. If it's not the case the resource server must reach out to the identity server to check the validity of the token. In case of UAA this can be achieved with the help of the `check_token` endpoint.

Our resource servers are implemented in Java and are using Spring. Spring has great support for [OAuth](http://projects.spring.io/spring-security-oauth/) but it could feel like **magic** if you don't know what's behind it.

```
@Configuration
@EnableResourceServer
protected static class ResourceServerConfiguration extends ResourceServerConfigurerAdapter {

    @Bean
    RemoteTokenServices remoteTokenServices() {
        RemoteTokenServices rts = new RemoteTokenServices();
        rts.setClientId(clientId);
        rts.setClientSecret(clientSecret);
        rts.setCheckTokenEndpointUrl(identityServerUrl + "/check_token");
        return rts;
    }

    @Override
    public void configure(ResourceServerSecurityConfigurer resources) throws Exception {
        resources.resourceId("cloudbreak");
        resources.tokenServices(remoteTokenServices());
    }

    @Override
    public void configure(HttpSecurity http) throws Exception {
        http
            .authorizeRequests()
            .antMatchers("/user/blueprints").access("#oauth2.hasScope('cloudbreak.blueprints')")
            .antMatchers("/user/templates").access("#oauth2.hasScope('cloudbreak.templates')");
    }
```

With these few lines you'll have a fully functioning resource server that checks every incoming token on the two endpoints defined in the second `configure` method.
The `EnableResourceServer` annotation will include a new [filter](https://github.com/spring-projects/spring-security-oauth/blob/master/spring-security-oauth2/src/main/java/org/springframework/security/oauth2/provider/authentication/OAuth2AuthenticationProcessingFilter.java#L95) in the security filter chain that will use the [RemoteTokenServices class](https://github.com/spring-projects/spring-security-oauth/blob/master/spring-security-oauth2/src/main/java/org/springframework/security/oauth2/provider/token/RemoteTokenServices.java#L95) to make a request to the `check_token` endpoint. If the response doesn't contain errors it uses a custom [authentication manager](https://github.com/spring-projects/spring-security-oauth/blob/master/spring-security-oauth2/src/main/java/org/springframework/security/oauth2/provider/authentication/OAuth2AuthenticationManager.java#L77) to put the authentication in the Spring authentication context (username will be available through the `Principal` object). It is also very easy to configure which scopes are needed for specific endpoints - the expressions used in the configuration are processed by the [OAuth2SecurityExpressionMethods class](https://github.com/spring-projects/spring-security-oauth/blob/master/spring-security-oauth2/src/main/java/org/springframework/security/oauth2/provider/expression/OAuth2SecurityExpressionMethods.java).

The `check_token` endpoint in UAA uses basic authentication with the **resource server's** client id and client secret as username and password. That's why the *resource server must be configured in UAA as a client* as well. The access token must be included in the request body:

```
POST /check_token HTTP/1.1
Host: server.example.com
Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==
Content-Type: application/x-www-form-encoded

token=eyJ0eXAiOiJKV1QiL
```

A successful response will include the decoded parts of the JWT token such as `exp`, `scope`, `user_name` or `client_id`. See an example [here](https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-APIs.rst#oauth2-token-validation-service-post-check_token).

## Resources

I haven't included an example for the password grant type because we are not using it in our projects but you can check it out in the [**Tokens part**](https://github.com/cloudfoundry/uaa/blob/master/docs/UAA-Tokens.md#getting-started) of the UAA documentation. If you'd like to learn more about UAA, check out its [documentation](https://github.com/cloudfoundry/uaa/tree/master/docs) or the source code of our projects in our [Github repo](https://github.com/sequenceiq/). Also feel free to ask anything in the comments section.

For updates follow us on [LinkedIn](https://www.linkedin.com/company/sequenceiq), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).
