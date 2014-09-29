---
layout: post
title: "Apache Spark - Job creation and testing"
date: 2014-09-29 15:42:24 +0200
comments: true
categories: [Spark, MLlib, Correlation, Testing]
author: Oliver Szabo
published: true
---

At [SequenceIQ](http://sequenceiq.com/) we use different runtimes (MR2, Spark, Tez) when submitting jobs from [Banzai](http://docs.banzai.apiary.io/reference) to a YARN clusters.
Some of these jobs are quite simple (filtering, sorting, projection etc.), but most of them can be complicated or not so oblivious at first (e.g.: complex machine learning algorithms).
From Banzai’s perspective/looking from outside a YARN cluster, what only matters is the input and the output dataset - as we have abstracted all the pipeline steps -  so testing of this steps properly is a must.
In this post we’d like to show such an example that - a correlation job on vectors with [Apache Spark](https://spark.apache.org/) and how we test it.

## Correlation example (on vectors) with Apache Spark

Suppose that we have an input dataset (CSV file for the sake of simplicity of the sample code) and we want to reveal the dependency between all of the columns. (all data is vectorized, if not you will have to vectorize your data first).
If we want to build a `testable` job, we have to focus only on the algorithm part. Our goal here is to work only on the Resilient Distributed Dataset and take the context creation outside of the job.
This way you cab run and create your `SparkContext `locally and substitute an HDFS data source (or something else) with simple objects.

Interface: (output: vector index pairs with their correlation coefficient)

``` scala
abstract class CorrelationJob {

  def computeCorrelation(input: RDD[String]) : Array[(Int, Int, Double)]

  def d2d(d: Double) : Double = new java.text.DecimalFormat("#.######").format(d).toDouble

}
```

<!-- more -->
Below we show you how a Pearson correlation job implementation looks like with RDD functions. First, you need to gather all combinations of the vector indices and count the size of the dataset.
After that, the only thing what you need is to compute the [correlation coefficient](http://www.statisticshowto.com/what-is-the-correlation-coefficient-formula/) on all column combinations (based on the square, dot product and sum of the fields per line). It takes 1 map and 1 reduce operation per pairs. (`iterative` -> typical example where you need to use Spark instead of MR2)

``` scala
  override def computeCorrelation(input: RDD[String]) : Array[(Int, Int, Double)] = {
    val numbersInput = input
      .map(line => line.split(",").map(_.toDouble))
      .cache()

    val combinedFields = (0 to numbersInput.first().size - 1).combinations(2)
    val size = numbersInput.count()
    val res = for (field <- combinedFields) yield {
      val col1Index = field.head
      val col2Index = field.last
      val tempData = numbersInput.map{arr => {
        val data1 = arr(col1Index)
        val data2 = arr(col2Index)
        (data1, data2, data1 * data2, math.pow(data1, 2), math.pow(data2, 2))
      }}
      val (sum1: Double, sum2: Double, dotProduct: Double, sq1: Double, sq2: Double) = tempData.reduce {
        case ((a1, a2, aDot, a1sq, a2sq), (b1, b2, bDot, b1sq, b2sq)) =>
          (a1 + b1, a2 + b2, aDot + bDot, a1sq + b1sq, a2sq + b2sq)
      }
      val corr = pearsonCorr(size, sum1, sum2, sq1, sq2, dotProduct)
      (col1Index, col2Index, d2d(corr))
    }
    res.toArray
  }

  // correlation formula
  def pearsonCorr(size: Long, sum1: Double, sum2: Double, sq1: Double, sq2: Double, dotProduct: Double): Double = {
    val numerator = (size * dotProduct) - (sum1 * sum2)
    val denominator = scala.math.sqrt(size * sq1 - sum1 * sum1) * scala.math.sqrt(size * sq2 - sum2 * sum2)
    numerator / denominator
  }
```

## MLlib Statistics

By the way [Spark Release 1.1.0](https://spark.apache.org/releases/spark-release-1-1-0.html) contains an algorithm for correlation computation, thus we now show you how to use that instead of the above one.
With [Statistics](https://github.com/apache/spark/blob/master/mllib/src/main/scala/org/apache/spark/mllib/stat/Statistics.scala) you can produce a correlation matrix from vectors. For obtaining the correlation coefficient pairs, we just need to get the upper triangular matrix without diagonal. It looks much simpler, isn't is?

``` scala
  override def computeCorrelation(input: RDD[String]) : Array[(Int, Int, Double)] = {
    val vectors = input
      .map(line => Vectors.dense(line.split(",").map(_.toDouble)))
      .cache()

    val corr: Matrix = Statistics.corr(vectors, "pearson")
    val num = corr.numRows

    // upper triangular matrix without diagonal
    val res = for ((x, i) <- corr.toArray.zipWithIndex if (i / num) < i % num )
    yield ((i / num), (i % num), d2d(x))

    res
  }
```
## Testing

For testing Spark jobs we use the Specs2 framework. We do not want to start a Spark context before every test case, so we just start/end it before/after steps.
In order to run Spark locally set master to "local". In our example (for demonstration purposes) we do not turn off Spark logging (or set to warn level) but it is recommended.

``` scala
abstract class SparkJobSpec extends SpecificationWithJUnit with BeforeAfterExample {

  @transient var sc: SparkContext = _

  def beforeAll = {
    System.clearProperty("spark.driver.port")
    System.clearProperty("spark.hostPort")

    val conf = new SparkConf()
      .setMaster("local")
      .setAppName("test")
    sc = new SparkContext(conf)
  }

  def afterAll = {
    if (sc != null) {
      sc.stop()
      sc = null
      System.clearProperty("spark.driver.port")
      System.clearProperty("spark.hostPort")
    }
  }

  override def map(fs: => Fragments) = Step(beforeAll) ^ super.map(fs) ^ Step(afterAll)

}

```
In our test specification we check that both correlation implementations are correct or not.
``` scala
@RunWith(classOf[JUnitRunner])
class CorrelationJobTest extends SparkJobSpec {

  "Spark Correlation implementations" should {
    val input = Seq("1,2,9,5", "2,7,5,6","4,5,3,4","6,7,5,6")
    val correctOutput = Array(
      (0, 1, 0.620299),
      (0, 2, -0.627215),
      (0, 3, 0.11776),
      (1, 2, -0.70069),
      (1, 3, 0.552532),
      (2, 3, 0.207514)
      )

    "case 1 : return with correct output (custom spark correlation)" in {
      val inputRDD = sc.parallelize(input)
      val customCorr = new CustomCorrelationJob().computeCorrelation(inputRDD, sc)
      customCorr must_== correctOutput
    }
    "case 2: return with correct output (stats spark correlation)" in {
      val inputRDD = sc.parallelize(input)
      val statCorr = new StatsCorrelationJob().computeCorrelation(inputRDD, sc)
      statCorr must_== correctOutput
    }
    "case 3: equal to each other" in {
      val inputRDD = sc.parallelize(input)
      val statCorr = new StatsCorrelationJob().computeCorrelation(inputRDD, sc)
      val customCorr = new CustomCorrelationJob().computeCorrelation(inputRDD, sc)
      statCorr must_== customCorr
    }
  }
}
```

To build and test the project use this command from our [GitHub examples](https://github.com/sequenceiq/sequenceiq-samples) spark-correlation directory:

```bash
./gradlew clean build
```

You can run this correlation example in our free Docker based Apache Spark container as well. (with [spark-submit](https://github.com/apache/spark/blob/master/bin/spark-submit) script). You can get the Spark container from the official [Docker registry](https://registry.hub.docker.com/u/sequenceiq/spark/) or from our [GitHub](https://github.com/sequenceiq/docker-spark) repository. The source code is available at [SequenceIQ's GitHub repository](https://github.com/sequenceiq/sequenceiq-samples/tree/master/spark-correlation).

If you have any questions or suggestions you can reach us on [LinkedIn](https://www.linkedin.com/company/sequenceiq/),
 [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook.com/sequenceiq).
