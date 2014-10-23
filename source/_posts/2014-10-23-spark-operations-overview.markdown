---
layout: post
title: "Apache Spark RDD operation examples"
date: 2014-10-23 16:00:00 +0200
comments: true
categories: [Spark, YARN]
author: Oliver Szabo
published: true
---

Recently we blogged about how you can write simple Apache Spark jobs and how to test them. Now we'd like to introduce all basic RDD operations with easy examples (our goal is to come up with examples as simply as possible). The Spark [documentation](http://spark.apache.org/docs/latest/programming-guide.html#rdd-operations) explains well what each operations is doing in detail. We made tests for most of the RDD operations with good ol' `TestNG`. e.g.:

```scala
 @Test
  def testRightOuterJoin() {
    val input1 = sc.makeRDD(Seq((1, 4)))
    val input2 = sc.makeRDD(Seq((1, '1'), (2, '2')))
    val expectedOutput = Array((1, (Some(4), '1')), (2, (None, '2')))

    val output = input1.rightOuterJoin(input2)

    Assert.assertEquals(output.collect(), expectedOutput)
  }
```
<!-- more -->

##Sample

Get the code from our GitHub repository [GitHub examples](https://github.com/sequenceiq/sequenceiq-samples) and build the project inside the `spark-samples` directory. For running the examples, you do not need any pre-installed Hadoop/Spark clusters or anything else.

```bash
git clone https://github.com/sequenceiq/sequenceiq-samples.git
cd sequenceiq-samples/spark-samples/
./gradlew clean build
```

All the other RDD operations are covered in the example (makes no sense listing them here).

##Spark on YARN

Should you want to run your Spark code on a YARN cluster you have several options.

* Use our Spark Docker [container](https://github.com/sequenceiq/docker-spark)
* Use our multi-node Hadoop [cluster](http://blog.sequenceiq.com/blog/2014/06/19/multinode-hadoop-cluster-on-docker/)
* Use [Cloudbreak](http://sequenceiq.com/cloudbreak/) to provision a YARN cluster on your favorite cloud provider


In order to help you get on going with Spark on YARN read our previous blog post about how to [submit a Spark](http://blog.sequenceiq.com/blog/2014/08/22/spark-submit-in-java/) job into a cluster.

If you have any questions or suggestions you can reach us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).
