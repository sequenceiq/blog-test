---
layout: post
title: "SQL on HBase with Apache Phoenix"
date: 2014-09-04 14:24:11 +0200
comments: true
categories: [HBase, Apache Phoenix, Jooq, SQL]
author: Krisztian Horvath
published: true
---

At [SequenceIQ](http://sequenceiq.com/) we use HBase to store large amounts of high velocity data and interact with them - many times we use native HBase interfaces but recently there was a need (internal and external) to access the data through an SQL interface.

## Introduction

HBase is an open-source, distributed, versioned, non-relational database modeled after Google's Bigtable. It's designed to handle
billions of rows and millions of columns. However, using it as a relational database where you would store your data normalized,
split into multiple tables is not easy and most likely you will struggle with it as you would do in any other non-relational database.
Here comes [Apache Phoenix](http://phoenix.apache.org/) in the picture. It's an SQL skin over HBase delivered as a
client-embedded JDBC driver targeting low latency queries. The project is in incubating state and under heavy development, but you
can already start embracing it.

## Installation
Download the appropriate distribution from [here](http://xenia.sote.hu/ftp/mirrors/www.apache.org/phoenix/):

 * Phoenix 3.x - HBase 0.94.x
 * Phoenix 4.x - HBase 0.98.1+

_Note the compatibilities between the HBase and Phoenix versions_

Alternatively you can clone the [repository](https://github.com/apache/phoenix/tree/4.0) and build it yourself (mvn clean install -DskipTests).
It should produce a jar file like this: phoenix-`version`-client.jar. Copy it to HBase's classpath (easiest way is to copy into
HBASE_HOME/lib). If you have multiple nodes it has to be there on every node. Restart the RegionServers and you are good to go. That's it?
Yes!

## Sample
We've pre-cooked a [Docker](https://github.com/sequenceiq/phoenix-docker) image for you so you can follow this sample and play with it (the image is based on Hadoop 2.5, HBase 0.98.5, Phoenix 4.1.0):

###Normal launch

`docker run -it sequenceiq/phoenix:v4.1onHbase-0.98.5`

###Alternative launch with sqlline
`docker run -it sequenceiq/phoenix:v4.1onHbase-0.98.5 /etc/bootstrap-phoenix.sh -sqlline`


<!-- more -->

### Create tables

The downloaded or built distribution's bin directory contains a pure-Java console based utility called sqlline.py. You can use this
to connect to HBase via the Phoenix JDBC driver. You need to specify the Zookeeper's QuorumPeer's address. If the default (2181) port is
used then type *sqlline.py localhost* (to quit type: !quit). Let's create two different tables:
```mysql
CREATE TABLE CUSTOMERS (ID INTEGER NOT NULL PRIMARY KEY, NAME VARCHAR(40) NOT NULL, AGE INTEGER NOT NULL, CITY CHAR(25));
CREATE TABLE ORDERS (ID INTEGER NOT NULL PRIMARY KEY, DATE DATE, CUSTOMER_ID INTEGER, AMOUNT DOUBLE);
```
It's worth checking which [datatypes](http://phoenix.apache.org/language/datatypes.html) and
[functions](http://phoenix.apache.org/language/functions.html) are currently supported. These tables will be translated into
HBase tables and the metadata is stored along with it and versioned, such that snapshot queries over prior versions will automatically
use the correct schema. You can check with HBase shell as `describe 'CUSTOMERS'`
```
DESCRIPTION                                                                                                                         ENABLED
 'CUSTOMERS', {TABLE_ATTRIBUTES => {coprocessor$1 => '|org.apache.phoenix.coprocessor.ScanRegionObserver|1|', coprocessor$2 => '|or true
 g.apache.phoenix.coprocessor.UngroupedAggregateRegionObserver|1|', coprocessor$3 => '|org.apache.phoenix.coprocessor.GroupedAggreg
 ateRegionObserver|1|', coprocessor$4 => '|org.apache.phoenix.coprocessor.ServerCachingEndpointImpl|1|', coprocessor$5 => '|org.apa
 che.phoenix.hbase.index.Indexer|1073741823|index.builder=org.apache.phoenix.index.PhoenixIndexBuilder,org.apache.hadoop.hbase.inde
 x.codec.class=org.apache.phoenix.index.PhoenixIndexCodec'}, {NAME => '0', DATA_BLOCK_ENCODING => 'FAST_DIFF', BLOOMFILTER => 'ROW'
 , REPLICATION_SCOPE => '0', VERSIONS => '1', COMPRESSION => 'NONE', MIN_VERSIONS => '0', TTL => '2147483647', KEEP_DELETED_CELLS =
 > 'true', BLOCKSIZE => '65536', IN_MEMORY => 'false', BLOCKCACHE => 'true'}
```
As you can see there are bunch of co-processors. Co-processors were introduced in version 0.92.0 to push arbitrary computation out
to the HBase nodes and run in parallel across all the RegionServers. There are two types of them: `observers` and `endpoints`.
Observers allow the cluster to behave differently during normal client operations. Endpoints allow you to extend the cluster’s
capabilities, exposing new operations to client applications. Phoenix uses them to translate the SQL queries to scans and that's
why it can operate so quickly. It is also possible to map an existing HBase table to a Phoenix table. In this case the binary
representation of the row key and key values must match one of the Phoenix data types.

### Load data

After the tables are created fill them with data. For this purpose we'll use the [Jooq](http://www.jooq.org/) library's fluent API.
The related sample project (Spring based) can be found in our
[GitHub](https://github.com/sequenceiq/sequenceiq-samples/tree/master/phoenix-jooq) repository. To connect you'll need Phoenix's
JDBC driver on your classpath (org.apache.phoenix.jdbc.PhoenixDriver). The url to connect to should be familiar as it uses the same Zookeeper QuorumPeer's address:
`jdbc:phoenix:localhost:2181`. Unfortunately Jooq's insert statement is not suitable for us since the JDBC driver only supports the
upsert statement so we cannot make use of the fluent API here.
```java
String userSql = String.format("upsert into customers values (%d, '%s', %d, '%s')",
                    i,
                    escapeSql(names.get(random.nextInt(names.size() - 1))),
                    random.nextInt(40) + 18,
                    escapeSql(locales[random.nextInt(locales.length - 1)].getDisplayCountry()));
String orderSql = String.format("upsert into orders values (%d, CURRENT_DATE(), %d, %d)",
                    i,
                    i,
                    random.nextInt(1_000_000));
dslContext.execute(userSql);
dslContext.execute(orderSql);
```

### Query

On the generated data let's create queries:
```java
dslContext
          .select()
          .from(tableByName("customers").as("c"))
          .join(tableByName("orders").as("o")).on("o.customer_id = c.id")
          .where(fieldByName("o.amount").lessThan(amount))
          .orderBy(fieldByName("c.name").asc())
          .fetch();
```
This query resulted the following:
```
+----+------------+-----+-----------+----+----------+-------------+--------+
|C.ID|C.NAME      |C.AGE|C.CITY     |O.ID|O.DATE    |O.CUSTOMER_ID|O.AMOUNT|
+----+------------+-----+-----------+----+----------+-------------+--------+
| 976|Bogan, Elias|   26|Japan      | 976|2014-04-20|          976|  8664.0|
| 827|Constrictor |   29|{null}     | 827|2014-04-20|          827|  7856.0|
| 672|Hardwire    |   31|Tunisia    | 672|2014-04-20|          672|  9292.0|
| 746|Lady Killer |   37|Cyprus     | 746|2014-04-20|          746|  1784.0|
| 242|Lifeforce   |   35|Switzerland| 242|2014-04-20|          242|  5406.0|
| 487|Topspin     |   48|{null}     | 487|2014-04-20|          487|  6512.0|
+----+------------+-----+-----------+----+----------+-------------+--------+
```
The same thing could've been achieved with sqlline also.
```mysql
select c.name as name, o.amount as amount, o.date as date from customers as c inner join orders as o on o.id = c.id where o.amount < 10000;
```
Nested queries are not supported yet, but it will come soon.

## Summary
As you saw it is pretty easy to get started with Phoenix both command line and programmatically. There are lots of lacking features, but
the contributors are dedicated and working hard to make this project moving forward. Next step? ORM for HBase? It is also ongoing.. :)

Follow up with [us](https://www.linkedin.com/company/sequenceiq/) if you are interested in HBase and building an SQL interface on top.
Don't hesitate to contact us should you have any questions.

[SequenceIQ](http://sequenceiq.com/)
