---
layout: post
title: "TopK on Apache Tez"
date: 2014-09-23 19:53:04 +0200
comments: true
categories: [Apache Tez]
author: Krisztian Horvath
published: true
---
The Apache Tez community draw attention last week with their latest release [0.5.0](http://tez.apache.org/releases/0.5.0/release-notes.txt)
of the application framework. At SequenceIQ we always try to find and provide the best solutions to our customers and share the experience we gain by
being involved in many open source Apache projects. We are always looking for the latest innovations, and try to apply them to our projects.
For a while we have been working hard on a new project called
[Banzai Pipeline](http://docs.banzai.apiary.io/) which we'll open source in the near future. One handy feature of the projects is the ability to run the same pipes on `MR2`, `Spark` and `Tez` - your choice.
In the next couple of posts we'll compare these runtimes using different jobs and as the first example to implement we chose TopK. Before going into
details let's revisit what Apache Tez is made of.

## Apache Tez key concepts

* One of the most important feature is that there is no heavy deployment phase which otherwise could go wrong in many ways - probably sounds familiar
for most of us. There is a nice [install guide](http://tez.apache.org/install.html) on the project's page which you can follow, but basically
you have to copy a bunch of jars to HDFS and you're almost good to go.
* Multiple versions of Tez can be used at the same time which solves a common problem, the rolling upgrades.
* Distributed data processing jobs typically look like `DAGs` (directed acyclic graphs) and Tez relies on this concept to define your jobs.
DAGs are made from `Vertices` and `Edges`. Vertices in the graph represent data transformations while edges represent the data movement
from producers to consumers. The DAG itself defines the structure of the data processing and the relationship between producers and consumers.

Tez provides faster execution and higher predictability because:

* Eliminates replicated write barriers between successive computations
* Eliminates the job launch overhead
* Eliminates the extra stage of map reads in every workflow job
* Provides better locality
* Capable to re-use containers which reduces the scheduling time and speeds up incredibly the short running tasks
* Can share in-memory data across tasks
* Can run multiple DAGs in one session
* The core engine can be customized (vertex manager, DAG scheduler, task scheduler)
* Provides an event mechanism to communicate between tasks (data movement events to inform consumers by the data location)

If you'd like to try Tez on a fully functional multi-node cluster we put together an Ambari based Docker image. Click
[here](http://blog.sequenceiq.com/blog/2014/09/19/apache-tez-cluster/) for details.

<!-- more -->

## TopK

The goal is to find the top K elements of a dataset. In this example's case is a simple CSV and we're looking for the top elements in a given column.
In order to do that we need to `group` and `sort` them to `take` the K elements. The implementation can be found in our
[GitHub](https://github.com/sequenceiq/sequenceiq-samples) repository. The important part starts
with the [DAG creation](https://github.com/sequenceiq/sequenceiq-samples/blob/master/tez-topk/src/main/java/com/sequenceiq/tez/topk/TopK.java#L136).
```java
        DataSourceDescriptor dataSource = MRInput.createConfigBuilder(new Configuration(tezConf),
                TextInputFormat.class, inputPath).build();

        DataSinkDescriptor dataSink = MROutput.createConfigBuilder(new Configuration(tezConf),
                TextOutputFormat.class, outputPath).build();

        Vertex tokenizerVertex = Vertex.create(TOKENIZER,
                ProcessorDescriptor.create(TokenProcessor.class.getName())
                        .setUserPayload(createPayload(Integer.valueOf(columnIndex))))
                .addDataSource(INPUT, dataSource);

        int topK = Integer.valueOf(top);
        Vertex sumVertex = Vertex.create(SUM,
                ProcessorDescriptor.create(SumProcessor.class.getName())
                        .setUserPayload(createPayload(topK)), Integer.valueOf(numPartitions));

        Vertex writerVertex = Vertex.create(WRITER,
                ProcessorDescriptor.create(Writer.class.getName())
                        .setUserPayload(createPayload(topK)), 1)
                .addDataSink(OUTPUT, dataSink);

        OrderedPartitionedKVEdgeConfig tokenSumEdge = OrderedPartitionedKVEdgeConfig
                .newBuilder(Text.class.getName(), IntWritable.class.getName(),
                        HashPartitioner.class.getName()).build();

        UnorderedKVEdgeConfig sumWriterEdge = UnorderedKVEdgeConfig
                .newBuilder(IntWritable.class.getName(), Text.class.getName()).build();
```
First of all we define a `DataSourceDescriptor` which represents our dataset and a `DataSinkDescriptor` where we'll
write the results to. As you can see there are plenty of utility classes to help you define your DAGs. Now that the input and output is
ready let's define our `Vertices`. You'll see the actual data transformation is really easy as Hadoop will take care of the heavy
lifting. The first Vertex is a
[tokenizer](https://github.com/sequenceiq/sequenceiq-samples/blob/master/tez-topk/src/main/java/com/sequenceiq/tez/topk/TopK.java#L198)
which does nothing more than splitting the rows of the CSV and emit a record with the selected column as the key and `1` as the value.
```java
    @Override
    public void initialize() throws Exception {
      byte[] payload = getContext().getUserPayload().deepCopyAsArray();
      ByteArrayInputStream bis = new ByteArrayInputStream(payload);
      DataInputStream dis = new DataInputStream(bis);
      columnIndex = dis.readInt();
      dis.close();
      bis.close();
    }
    @Override
    public void run() throws Exception {
      KeyValueWriter kvWriter = (KeyValueWriter) getOutputs().get(WRITER).getWriter();
      KeyValuesReader kvReader = (KeyValuesReader) getInputs().get(TOKENIZER).getReader();
      while (kvReader.next()) {
        Text word = (Text) kvReader.getCurrentKey();
        int sum = 0;
        for (Object value : kvReader.getCurrentValues()) {
          sum += ((IntWritable) value).get();
        }
        kvWriter.write(new IntWritable(sum), word);
      }
    }
```
The interesting part here is the `initialize` method which reads the `UserPayload` to find out in which column we're looking for
the top K elements. What happens after the first Vertex is that Hadoop will `group` the records by key, so we'll have all the keys
with a bunch of 1s. In the next Vertex we
[sum](https://github.com/sequenceiq/sequenceiq-samples/blob/master/tez-topk/src/main/java/com/sequenceiq/tez/topk/TopK.java#L243)
these values so we'll have all the words in the given column counted. We could emit all the values to make Hadoop sort them for us,
but we can optimize this process by reducing the data we need to send over the network. And how we are going to do that? If we
[maintain](https://github.com/sequenceiq/sequenceiq-samples/blob/master/tez-topk/src/main/java/com/sequenceiq/tez/topk/TopK.java#L340)
a `local` top K of the data which the sum tasks process and emit only these values all we have left in the last Vertex is to
select the top K results from a much smaller data set. Another important improvement here is that we can use the `UnorderedKVEdgeConfig`
to avoid sorting the data at the task output and the merge sort at the next tasks input. We used the `OrderedPartitionedKVEdgeConfig`
between the first 2 Vertices to demonstrate the different edges and as partition can be a huge asset.
```java
        @Override
        public void run() throws Exception {
            Preconditions.checkArgument(getInputs().size() == 1);
            Preconditions.checkArgument(getOutputs().size() == 1);
            KeyValueWriter kvWriter = (KeyValueWriter) getOutputs().get(WRITER).getWriter();
            KeyValuesReader kvReader = (KeyValuesReader) getInputs().get(TOKENIZER).getReader();
            while (kvReader.next()) {
                Text currentWord = (Text) kvReader.getCurrentKey();
                int sum = 0;
                for (Object value : kvReader.getCurrentValues()) {
                    sum += ((IntWritable) value).get();
                }
                localTop.store(sum, currentWord.toString());
            }

            Map<Integer, List<String>> result = localTop.getTopK();
            for (int top : result.keySet()) {
                IntWritable topWritable = new IntWritable(top);
                for (String string : result.get(top)) {
                    word.set(string);
                    kvWriter.write(topWritable, word);
                }
            }
        }
```
All we have left is to [take](https://github.com/sequenceiq/sequenceiq-samples/blob/master/tez-topk/src/main/java/com/sequenceiq/tez/topk/TopK.java#L318)
the first K elements of the reduced data set (from the local top Ks) and write it to HDFS and we're done. Except that we have to
define the data movements with edges.
```java
    DAG dag = DAG.create("topk");
    dag
        .addVertex(tokenizerVertex)
        .addVertex(sumVertex)
        .addVertex(writerVertex)
        .addEdge(Edge.create(tokenizerVertex, sumVertex, tokenSumEdge.createDefaultEdgeProperty()))
        .addEdge(Edge.create(sumVertex, writerVertex, sumWriterEdge.createDefaultBroadcastEdgeProperty()));
```
The execution of this DAG looks something like this:

![](http://yuml.me/b6bf74a3)

In the last Vertex we start collecting the grouped sorted data so we can take the first K elements. This part kills the parallelism as
we need to see the global picture here, that's why you can see that the parallelism is
[set](https://github.com/sequenceiq/sequenceiq-samples/blob/master/tez-topk/src/main/java/com/sequenceiq/tez/topk/TopK.java#L129) to `1`.
Leaving the parallelism undefined or -1 results that the number of launched tasks will be determined by the `ApplicationMaster`.

### TopK DataGen
You also can generate an arbitrary size of dataset with the
[TopKDataGen](https://github.com/sequenceiq/sequenceiq-samples/blob/master/tez-topk/src/main/java/com/sequenceiq/tez/topk/TopKDataGen.java)
job. This is a special DAG which has only 1 Vertex and no Edges.

### How to run the examples

First of all you will need a Tez cluster - we have put together a real one, you can get it from [here](http://blog.sequenceiq.com/blog/2014/09/19/apache-tez-cluster/). Pull the container, and follow the instructions below.

Build the project `mvn clean install` which will generate a jar. Copy this jar to HDFS and you are good to go. In order to make this jar
runnable we also created a
[driver](https://github.com/sequenceiq/sequenceiq-samples/blob/master/tez-topk/src/main/java/com/sequenceiq/tez/topk/TopKDriver.java)
class.
```
hadoop jar tez-topk-1.0.jar topkgen /data 1000000
hadoop jar tez-topk-1.0.jar topk /data /result 0 10
```

## What's next
In the next post we'll see how we can achieve the same with Spark and we'll do a performance comparison on a large dataset.
Cascading also works on the Tez integration, so we'll definitely report on that too.
If you have any questions or suggestions you can reach us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).
