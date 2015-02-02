---
layout: post
title: "Cluster extensions with Cloudbreak recipes"
date: 2015-02-02 15:59:18 +0100
comments: true
published: true
author: Marton Sereg
categories: [Cloudbreak]
---

With the help of Cloudbreak it is very easy to provision Ambari clusters in the cloud from a blueprint. That's cool but it is often needed to make some additional changes on the nodes, like putting a JAR file on the Hadoop classpath or run some custom scripts. To help with these kind of situations we are introducing the concept of Cloudbreak recipes. Recipes are basically script extensions to a cluster that run on a set of nodes before or after the Ambari cluster installation.

## How does it work?

Since the latest release, Cloudbreak uses [Consul](https://consul.io) for cluster membership instead of Serf so we can make use of Consul’s other features, namely events and the key-value store. It won’t be detailed here how these features of Consul work, a whole post about Consul based clusters is coming soon. Recipes are using one more additional thing: the small [plugn](https://github.com/progrium/plugn) project by Jeff Lindsay.
The main concept behind this is the following: before the cluster install is started, a `recipe-pre-install` Consul event is sent to the cluster that triggers the `recipe-pre-install` hook of the enabled plugins, therefore executing the plugins' `recipe-pre-install` script. After the cluster installation is finished the same happens but with the `recipe-post-install` event and hook. The key-value store is used to signal plugin success or failure - after the plugins finished execution on a node, a new Consul key is added in the format `/events/<event-id>/<node-hostname>` that contains the exit status. Cloudbreak is able to check the key-value store if the recipe finished successfully or not.

<!-- more -->

## Register plugins for a cluster install

We cannot predict all the custom use cases that can come up when installing a Hadoop cluster in the cloud, so we were focusing on making this feature easily extendable. We had to find a solution that enables someone to write their own script that will be run by Cloudbreak later. That's where the *plugn* project comes handy. With a simple `plugn install` command, a new plugin can be installed from *Github* so we only need to make one plugin available by default on every node - the [one](https://github.com/sequenceiq/consul-plugins-install) that can install other plugins from a Github source. The other plugins are installed as the first step of a Cloudbreak cluster setup. This uses the same mechanism to trigger this plugin - it sends `plugin-install` events to Consul’s HTTP interface with the plugin source and name passed as parameters in the Consul event’s payload.

### Creating a plugin

We’ve created an [example plugin](https://github.com/sequenceiq/consul-plugins-gcs-connector) that downloads the [Google Cloud Storage connector for Hadoop](https://cloud.google.com/hadoop/google-cloud-storage-connector) and puts it on the Hadoop classpath. As you can see a plugin is quite simple - it consists of a `.toml` descriptor, and the hook scripts. In the example only the `recipe-pre-install` hook is implemented, there is nothing to do after the cluster installation is done.

### Adding properties to plugins

Properties can be passed to plugins by using environment variables, but we use Consul's key-value store for that purpose instead. The GCS connector mentioned above needs a few more things to work besides the JAR on the classpath. To be able to authenticate to the Google Cloud Platform the connector also needs a private key in `p12` format. We have a [plugin](https://github.com/sequenceiq/consul-plugins-gcp-p12) that does exactly this - it reads a *base64* encoded private key file located under the `recipes.gcp-p12.p12-encoded` key in the key-value store (using `curl` and some environment variables containing Consul’s HTTP address) and saves it in a local folder on the node.

## Putting things together

We already know how to write plugins, how to get properties from the key-value store inside a plugin and how these things are triggered from Cloudbreak, but the key piece is missing: how do we tell Cloudbreak which plugins to install on our cluster and which properties to use. With the latest release a new resource is available on the API, the *recipe*. To create a new recipe make a `POST` to the `account/recipes` endpoint like this one:

```
{
  "name": "gcp-extension",
  "description": "sets up Google Cloud Storage connector on an Ambari cluster",
  "properties": {
    "recipes.gcp-p12.p12-encoded": "<base64-encoded-p12-file>"
  },
  "plugins": [
    "https://github.com/sequenceiq/consul-plugins-gcs-connector.git",
    "https://github.com/sequenceiq/consul-plugins-gcp-p12.git"
  ]
}
```

To make sure that only trusted plugins are used in Cloudbreak, there is a validation on the source URL - plugins must come from a configurable trusted Github account. In case of our hosted solution the only acceptable source is configured to be sequenceiq, so if you'd like to use this feature there, please contact us first.
After the recipe is created, the API answers with the ID of the created resource, so it can be used to create a cluster. The `recipeId` field is optional, and no scripts are executed if it is missing from the cluster `POST` request.

```
{
  "name": "recipe-cluster",
  "blueprintId": 1400,
  "recipeId": 3744,
  "description": "Demonstrates the recipe feature"
}
```

The recipes are not yet available on the Cloudbreak UI, if you’d like to try it out without hacking `curl` requests with proper authentication then I suggest to try the [Cloudbreak Shell](https://github.com/sequenceiq/cloudbreak-shell). The requests above correspond to the following shell commands (assuming that the above recipe description is saved in `/tmp/test-recipe.json` and the cluster infrastructure - the stack - is already created):

```
recipe add --file /tmp/test-recipe.json
```

```
cluster create —name recipe-cluster —blueprintId 1400 —recipeId 3744 —description "Demonstrates the recipe feature"
```

## Future improvements

This feature is *just a preview* in its current state, there are a few important parts that are missing. The most important one is that the plugins are currently installed and executed in all of the `ambari-agent` containers, but there are scenarios where it is not needed or not good at all. Consider the case where you’d like to add a JAR to HDFS - it should be run on only one of the nodes. It is also possible that a script should be executed only on a set of nodes, typically the nodes in a hostgroup. This means that the API will probably change in the next few weeks, but then we’ll update our blog too.

There are a few more things that you can expect to be implemented in the long run:

- install plugins from private sources too along public Github repositories

- validate required properties when creating a new recipe

If you have any comments, questions or feature requests about this topic, feel free to create an issue on Cloudbreak’s [Github page](https://github.com/sequenceiq/cloudbreak/issues) or use the comments section below.
