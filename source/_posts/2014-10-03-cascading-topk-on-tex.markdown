---
layout: post
title: "Cascading TopK on Tez"
date: 2014-10-01 18:00:00 +0200
comments: true
categories: [Cascading, Apache Tez]
author: Oliver Szabo
published: false
---

## Casxading on Apache Tez

In one of our previous example we shown how to count top-k on Apache Tez.
Now we show that how to use it with our favorite compute engine, Cascading.
Earlier we also presented how to write and test jobs with Scalding (Cascading DSL), but be honest, we owe an introduction about Cascading.
Now Cascading supports Apache Tez, so we are going to play with it.
Our goal here is to demonstrate that how much simpler to write a Tez job with Cascading.

## TopK Cascading Application

Cascading data flows can be constructed from Source taps (input), Sink taps(output) and Pipes.
At first, we have to setup our properties for the Cascading flow.

``` java
        Properties properties = AppProps.appProps()
                .setJarClass(Main.class)
                .buildProperties();

        properties = FlowRuntimeProps.flowRuntimeProps()
                .setGatherPartitions(4)
                .buildProperties(properties);
```
Then in order to use the Apache Tez, setup the Tez specific Flow Connector.
``` java
FlowConnector flowConnector = new Hadoop2TezFlowConnector(properties);
```
After that we do the algorithm part of the flow. We need an input and output which comes as command-line arguments.
We are going to work on CSV files, so we have to use TextDelimited scheme. Also we need to define our input pipe and taps (source/sink).
We can compute Top K with 2 [group](http://docs.cascading.org/cascading/2.5/userguide/html/ch03s03.html#N205A3) and 2 [every](http://docs.cascading.org/cascading/2.5/userguide/html/ch03s03.html#N20438) operation.

``` java
        final String inputPath = args[0];
        final String outputPath = args[1];

        final Fields fields = new Fields("userId", "data1", "data2", "data3");
        final Scheme scheme = new TextDelimited(fields, false, true, ",");

        final Pipe inPipe = new Pipe("inPipe");
        final Tap inTap = new Hfs(scheme, inputPath);
        // Get TOP K by userId
        Pipe topUsersPipe = new GroupBy("topUsers", inPipe, new Fields("userId"));
        topUsersPipe = new Every(topUsersPipe, new Fields("userId"), new Count(), Fields.ALL);
        topUsersPipe = new GroupBy(topUsersPipe, new Fields("userId"), new Fields("count"), true);
        topUsersPipe = new Every(topUsersPipe, Fields.RESULTS, new FirstNBuffer(20));

        final Scheme outputScheme = new TextDelimited(new Fields("userId", "count"), false, true, ",");
        Tap sinkTap = new Hfs(outputScheme, outputPath);
```
Finally, setup the flow:
``` java
        FlowDef flowDef = FlowDef.flowDef()
                .setName("TopK-TEZ")
                .addSource(inPipe, inTap)
                .addTailSink(topUsersPipe, sinkTap);

        Flow flow = flowConnector.connect(flowDef);
        flow.complete();
```

To build the project use this command from our [GitHub examples](https://github.com/sequenceiq/sequenceiq-samples) cascading-topk directory:

```bash
./gradlew clean build
```
