---
layout: post
title: "Cascading on Apache Tez"
date: 2014-10-20 18:00:00 +0200
comments: true
categories: [Cascading, Apache Tez]
author: Oliver Szabo
published: true
---

In one of our previous [posts](http://blog.sequenceiq.com/blog/2014/09/23/topn-on-apache-tez/) we showed how to do a TopK using directly the Apache Tez API. In this post we’d like to show how to do a similarly complex algorithm with Cascading - running on Apache Tez. _Note: initially we wanted to do the similar algorithm but currently there are some issues - the Cascading 3.0 is still WIP._
At [SequenceIQ](http://sequenceiq.com) we use Scalding, Cascading and Spark  to write most of our jobs. For a while our big data pipeline API called [Banzai Pipeline](http://docs.banzai.apiary.io/) offers a unified API over different runtimes: MR2, Spark and Tez; recently Cascading has announced support for Apache Tez and we’d like to show you that by writing a detailed example.

## Cascading Application - GroupBy, Each, Every

Cascading data flows are to be constructed from Source taps (input), Sink taps (output) and Pipes.
At first, we have to setup our properties for the Cascading flow.

``` java
        Properties properties = AppProps.appProps()
                .setJarClass(Main.class)
                .buildProperties();

        properties = FlowRuntimeProps.flowRuntimeProps()
                .setGatherPartitions(1)
                .buildProperties(properties);
```

Then in order to use Apache Tez, setup the Tez specific `Flow Connector`.

``` java
FlowConnector flowConnector = new Hadoop2TezFlowConnector(properties);
```

After that we do the algorithm part of the flow. We need an input and output which comes as command-line arguments.
We are going to work on CSV files for the sake of simplicity, so we will use the `TextDelimited` scheme. Also we need to define our input pipe and taps (`source/sink`).
Suppose that we want to count the occurrences of users and keep them only if they occur more than once. We can compute this with 2 [GroupBy](http://docs.cascading.org/cascading/2.5/userguide/html/ch03s03.html#N205A3), 1 [Every](http://docs.cascading.org/cascading/2.5/userguide/html/ch03s03.html#N20438) and 1 [Each](http://docs.cascading.org/cascading/2.5/userguide/html/ch03s03.html#N20438) operation.
First, we group by user ids (count them with every operation), then in the second grouping we need to sort on the whole data set (by `count`) and use the [Filter](http://docs.cascading.org/cascading/2.5/javadoc/cascading/operation/Filter.html) operation to remove the unneeded lines. (here we grouping by `Fields.NONE`, that means we take all data into 1 group, in other words we force to use 1 reducer)

``` java
        final String inputPath = args[0];
        final String outputPath = args[1];

        final Fields fields = new Fields("userId", "data1", "data2", "data3");
        final Scheme scheme = new TextDelimited(fields, false, true, ",");

        final Pipe inPipe = new Pipe("inPipe");
        final Tap inTap = new Hfs(scheme, inputPath);
        final Fields groupFields = new Fields("userId");

        Pipe usersPipe = new GroupBy("usersWithCount", inPipe, groupFields);
        usersPipe = new Every(usersPipe, groupFields, new Count(), Fields.ALL);
        usersPipe = new GroupBy(usersPipe, Fields.NONE, new Fields("count", "userId"), true);
        usersPipe = new Each(usersPipe, new Fields("count"), new RegexFilter( "^(?:[2-9]|(?:[1-9][0-9]+))" ));

        final Fields resultFields = new Fields("userId", "count");
        final Scheme outputScheme = new TextDelimited(resultFields, false, true, ",");
        Tap sinkTap = new Hfs(outputScheme, outputPath);
```

Finally, setup the flow:

``` java
        FlowDef flowDef = FlowDef.flowDef()
                .setName("Cascading-TEZ")
                .addSource(inPipe, inTap)
                .addTailSink(usersPipe, sinkTap);

        Flow flow = flowConnector.connect(flowDef);
        flow.complete();
```

As you can see the codebase is a bit simpler than using directly the Apache Tez API, however you loose the low level features of the expressive data flow API. Basically it's up to the personal preference of a developer whether to use and build directly on top of the Tez API or use Cascading (we have our own internal debate among colleagues) - as Apache Tez improves the performance by multiple times.

Get the code from our GitHub repository [GitHub examples](https://github.com/sequenceiq/sequenceiq-samples) and build the project inside the `cascading-tez-sample` directory:

```bash
./gradlew clean build
```
Once your jar is ready upload it onto a Tez cluster and run the following command:
```bash
hadoop jar cascading-tez-sample-1.0.jar /input /output
```

Sample data can be generated in the same way as in [this](http://blog.sequenceiq.com/blog/2014/09/23/topn-on-apache-tez) example.

We have put together a Tez enabled Docker container, you can get it from [here](https://github.com/sequenceiq/docker-tez). Pull the container, and follow the instructions.

If you have any questions or suggestions you can reach us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).
