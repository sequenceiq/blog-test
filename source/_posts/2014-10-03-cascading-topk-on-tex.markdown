---
layout: post
title: "Cascading on Apache Tez"
date: 2014-10-03 18:00:00 +0200
comments: true
categories: [Cascading, Apache Tez]
author: Oliver Szabo
published: false
---


In one of our previous [posts](http://blog.sequenceiq.com/blog/2014/09/23/topn-on-apache-tez/) we show you how to do a topK using the Apache Tez API. In this post we’d like to show how to do it using Cascading - running on Apache Tez.
At [SequenceIQ](http://sequenceiq.com) we use Cascading and Scalding to write most of our jobs (mostly running on MR2). For a while our big data pipeline API called Banzai Pipeline[http://docs.banzai.apiary.io/] offers a unified view over different runtimes: MR2, Spark and Tez; recently Cascading has announced support for Apache Tez and we’d like to show you that.
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

Then in order to use Apache Tez, setup the Tez specific Flow Connector.

``` java
FlowConnector flowConnector = new Hadoop2TezFlowConnector(properties);
```
After that we do the algorithm part of the flow. We need an input and output which comes as command-line arguments.
We are going to work on CSV files for the sake of simplicity, so we have to use the `TextDelimited` scheme. Also we need to define our input pipe and taps (`source/sink`).
We can compute a TopK with 2 [groups](http://docs.cascading.org/cascading/2.5/userguide/html/ch03s03.html#N205A3) and 2 [every](http://docs.cascading.org/cascading/2.5/userguide/html/ch03s03.html#N20438) operations.

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

Get the code from our GitHub repository [GitHub examples](https://github.com/sequenceiq/sequenceiq-samples) and build the project inside the `cascading-topk` directory:

```bash
./gradlew clean build
```

First of all you will need a Tez cluster - we have put together a real one, you can get it from [here](http://blog.sequenceiq.com/blog/2014/09/19/apache-tez-cluster/). Pull the container, and follow the instructions.

If you have any questions or suggestions you can reach us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).
