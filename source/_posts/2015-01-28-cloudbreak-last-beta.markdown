---
layout: post
title: "Cloudbreak new features"
date: 2015-01-28 11:00:00 +0200
comments: true
categories: [Cloudbreak]
author: Janos Matyas
published: true
---

We are happy to announce that the `Release Candidate` version of Cloudbreak is almost around the corner. This major release is the last one in the `public beta program` and contains quite a few new features and architectural changes.

All theses new major features will be covered in the coming weeks on our blog, but in the meantime let us do a quick skim through.

###Accounts

We have introduced the concept of `accounts` - after a user registers/signs in the first time will have the option to invite other people in the `account`. Being the administrator of the account, will have the option to activate, deactive and give admin rights for all the invited users.

Users can share `resources` (such as: cloud credentials, templates, blueprints, clusters) within the account by making it `public in account` but at the same time can create his own private resources as well. As you might be already aware, we use OAuth2 to make all these possible.

###Usage explorer

We have built a unified (accross all cloud providers) usage explorer tool, where you can drill down into details to learn your (or in your account if you have admin rights) usage history. You can filter by date, users, cloud providers, region, etc - and generate a consolidated table/chart overview.

###Heterogenous clusters

This was a feature many have asked - and we are happy to deliver it. Up till now all the nodes in your YARN clusters were built on the same cloud `instance types`. While this was an easy an convenient way to build a cluster (as far as we are aware all the Hadoop as a Service providers are doing it this way) back in the MR1 era, times changed now and with the emergence of `YARN` different workloads are running within a cluster.

While for example Spark jobs require a high memory instance a legacy MR2 code might require a high CPU instance, whereas a HBase RegionServer likes better a high I/O throughput one.

At SequenceIQ we have quickly realized this and the new release allows you to apply different `stack templates` to all these YARN services/components. We do the heavy lifting for you in the background - the only thing you will have to do is to associate stack templates to Ambari `hostgroups`.

This is a major step forward when you are using and running different workloads on your YARN cluster - and not just saving on costs but at the same time increasing your cluster throughput.

###Hostgroup based autoscaling

Cloudbreak now integrates with [Periscope](http://sequenceiq.com/periscope) - and allows you to set up alarms and autoscaling SLA policies based on YARN metrics. Having done the heterogenous cluster integration, now it's time to apply `autoscaleing` for those nodes based on Ambari Blueprints.

###Recipes

While Cloudbreak and Ambari combined are a pretty powerful way to configure your Hadoop cluster, sometimes there are manuall steps required to reconfigure services, build dependent cluster architectures (e.g.: permanent and ephemeral clusters), etc - the list can be long.
Even a simple configuration on a large (thousands nodes) cluster is a tedious job - and usually people use Ansible, Chef, Puppet or Saltstack to do so - however these all have some drawback and are not integrated with Cloudbreak. As Cloudbreak under the hood uses Consul, we came up with a simple solution which facilitates creating, applying and running `recipes` on your already provisioned cluster - pre/post Ambari installation. A follow up blog post will be released in the coming days whch will explain the concept, architecture and gives you a few sample recipes.


###OpenStack

This was one of the other highly desired features - and a perfect use case for Docker. You might be aware that we run the full Hadoop stack inside Docker container - and Cloudbreak's integration with the cloud provider is pretty thin. This gives us the option to add quick integration with a new cloud provider - the full OpenStack integration with Cloudbreak took few weeks only.

Long story short - Cloudbreak now support and automates provisioning of Hadoop clusters with custom blueprints on OpenStack. Give it a try and let us know how it works for you.


Make sure you check back soon to our [blog](http://blog.sequenceiq.com/) or follow us
on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook).
