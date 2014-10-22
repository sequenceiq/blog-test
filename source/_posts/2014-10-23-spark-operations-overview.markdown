---
layout: post
title: "Apache Spark RDD operation examples"
date: 2014-10-23 16:00:00 +0200
comments: true
categories: [Spark]
author: Oliver Szabo
published: false
---

In the previous weeks we demonstrated how you can write simple Apache Spark jobs, and how to test them. Now we introduce all basic RDD operations with easy examples. (our goal here is that It has to be as simply as possible) The [documentation](http://spark.apache.org/docs/latest/programming-guide.html#rdd-operations) explains well what each operations is doing. We made tests for most of the RDD operations with good ol' `TestNG`. e.g.:

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
## Sample

Get the code from our GitHub repository [GitHub examples](https://github.com/sequenceiq/sequenceiq-samples) and build the project inside the `spark-samples` directory:

For running the examples, you do not need any pre-installed Hadoop/Spark clusters or anything else.
```bash
./gradlew clean build
```
