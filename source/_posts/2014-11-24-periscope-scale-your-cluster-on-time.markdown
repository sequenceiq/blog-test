---
layout: post
title: "Periscope: time based autoscaling"
date: 2014-11-25 15:13:33 +0100
comments: true
categories: [Periscope]
author: Krisztian Horvath
published: true
---

[Periscope](http://blog.sequenceiq.com/blog/2014/08/27/announcing-periscope/) allows you to configure SLA policies for your cluster
and scale up or down on demand. You are able to set alarms and notifications for different metrics like `pending containers`,
`lost nodes` or `memory usage`, etc . Recently we got a request to scale based on `time interval`. What does this mean? It means that you can tell
Periscope to shrink your cluster down to arbitrary number of nodes after work hours or at weekends and grow it back by the time people starts to work. We thought it would make a really useful feature so we quickly implemented it and made available. You can learn more about the Periscope API [here](http://docs.periscope.apiary.io/).

### Cost efficiency

In this example we'll configure Pericope to downscale at 7PM and upscale at 8AM from Monday to Friday:

![](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/images/dowscale_diagram.png)

Just to make things easier let's assume that our cluster is homogeneous. On AWS a c3.xlarge instance costs $0.210 per hour.
Now let's do the math:

 * 24 x 0.21 x 100                      = $504
 * (11 x 0.21 x 100) + (13 x 0.21 x 10) = $260

In a month we can save **$7560** scaling from 100 to 10 and back - and the weekends are not even counted.

<!--more-->

### Cron based alarms

In order to configure such actions you'll have to set some `time alarms`.

```json
{
  "alarms": [
    {
      "alarmName": "worktime",
      "description": "Number of nodes during worktime",
      "timeZone": "Europe/Budapest",
      "cron": "0 59 07 ? * MON-FRI"
    },
    {
      "alarmName": "after work",
      "description": "Number of nodes after worktime",
      "timeZone": "Europe/Budapest",
      "cron": "0 59 18 ? * MON-FRI"
    }
  ]
}
```

Now that the alarms are set we need to tell Periscope what to do when they are triggered. Let's define the `scaling policies`:

```json
{
  "minSize": 2,
  "maxSize": 100,
  "cooldown": 30,
  "scalingPolicies": [
    {
      "name": "upscale",
      "adjustmentType": "EXACT",
      "scalingAdjustment": 100,
      "hostGroup": "slave_1",
      "alarmId": "150"
    },
    {
      "name": "downscale",
      "adjustmentType": "EXACT",
      "scalingAdjustment": 10,
      "hostGroup": "slave_1",
      "alarmId": "151"
    }
  ]
}
```
For those who are not familiar with the properties in the scaling JSON:

 * minSize: defines the minimum size of the cluster
 * maxSize: defines the maximum size of the cluster
 * cooldown: defines the time between 2 scaling activity
 * adjustmentType: can be `NODE_COUNT`, `PERCENTAGE`, or `EXACT`
 * scalingAdjustment: defines the number nodes of with to upscale or downscale and depends on the adjustment type as follows:
   * `NODE_COUNT` can be -2 (downscale with 2 nodes) or +2 (upscale with 2 nodes)
   * `PERCENTAGE` similarly can be 40% and -40%
   * `EXACT` always a positive number which can mean both upscale or downscale based on the previous size of the cluster
 * hostGroup: defines the Hadoop services installed on a host. In case of scaling we'll take or add hosts with these services.

Many people reached us with their questions of how to scale down properly as they had some concerns about it.
Generally speaking downscaling is much harder to do than upscaling. Am I going to lose portion of my data? What will happen with the running applications? What will happen with say `RegionServers`? Luckily Hadoop services provide `graceful decommission`.

_Note:When you are storing your data in a cloud object store (last week we have blogged about these [here](http://blog.sequenceiq.com/blog/2014/10/28/datalake-cloudbreak/) and [here](http://blog.sequenceiq.com/blog/2014/11/17/datalake-cloudbreak-2/)) this is less of an issue - and Periscope will not have to worry about HDFS data replications._


### Decommission flow

Let's dive through an example: Periscope instructs [Cloudbreak](http://blog.sequenceiq.com/blog/2014/07/18/announcing-cloudbreak/) - our
Hadoop as a service API - to shut down 10 nodes and Cloudbreak will make sure that nothing gets lost. First it will check which nodes are running `ApplicationMasters` to leave them out of the process. If it found all the 10 candidates for shutting down
it will decommission the necessary services from them and then it will shut down those nodes. Applications continue to run and Hadoop `master` services continue to run undisturbed.

![](https://raw.githubusercontent.com/sequenceiq/sequenceiq-samples/master/images/downscale_sequence.png)

If you have questions like these don't hesitate to contact us we'll try to help you solve your problems.
Make sure you check back soon to our [blog](http://blog.sequenceiq.com/) or follow us
on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook).
