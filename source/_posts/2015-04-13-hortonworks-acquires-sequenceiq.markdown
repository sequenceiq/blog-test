---
layout: post
title: "Hortonworks acquires SequenceIQ"
date: 2015-04-13 17:00:10 +0200
comments: true
categories: [Hortonworks]
author: Janos Matyas
published: true
---

Today we are extremely excited to [announce](http://hortonworks.com/press-releases/hortonworks-to-acquire-sequenceiq-to-speed-hadoop-deployments-into-the-cloud/) that SequenceIQ has joined forces with Hortonworks to accelerate our work to simplify the provisioning of Hadoop clusters across any environments. The SequenceIQ technologies will be integrated with the Hortonworks Data Platform and contributed to the Apache open source community later this year.

Our journey started late February, 2014 when we got together in a co-working office space and started to work on a few different projects mainly focusing on a big data pipeline which abstracted the underlying runtimes of MR2, Tez and Spark. Alongside this journey we were provisioning large clusters accross different environments using the full Hadoop stack. As we all have a strong DevOps mindset, we always automate every recurring steps  - and we found Docker a perfect fit for our task.

Around spring 2014, things started to speed up and our innovative vision of running the complete Hadoop ecosystem in containers started to gain traction. The Docker containers for Apache Hadoop, Ambari, and Spark quickly became the most popular/downloaded containers on the Docker Hub (Apache Hadoop over 42000, Apache Ambari over 8200, and Apache Spark over 6600 downloads).

This led to a project we call [Cloudbreak](http://sequenceiq.com/cloudbreak/) - an infrastructure agnostic and secure Hadoop as a Service API for multi-tenant clusters. It was the first beta release (July, 2014) when we started to collaborate with Hortonworks on the project - and the Docker container based Hadoop provisioning was presented at the Hadoop summit in San Jose. The reception from the open source community was terrific - and what was even more amazing was that large enterprises started to PoC and deploy Hadoop clusters with Cloudbreak.

As we were focusing mostly on cloud and container-based environments, that raised another idea - elasticity. As a startup we were extremely cost aware, and provisioning on-demand large (few hundred nodes) clusters daily in all major cloud environments (Amazon AWS, Microsoft Azure, Google Cloud Platform and OpenStack) had a significant financial cost. To address this, we started work on a project we call [Periscope](http://sequenceiq.com/periscope/) - to bring SLA policy based autoscaling to Hadoop and provide QoS for your running applications. Same as Cloudbreak, Periscope is built on top of Apache Ambari and Apache YARN - and leverages the latest cutting edge features of these projects.

At this point we'd like to thank Google for seeing the value in our technology and supporting us with $100,000 Google Cloud Platform credits and our investors from Euroventures who understood the value of elastic cloud technologies such as Cloudbreak and Periscope in managing the cost of cloud providers every month.

##The Power of Open Source Community

When we started the company, it was very clear that everything we do will be released under an Apache Software License V2. Nevertheless these projects (Cloudbreak and Periscope) would have not been possible without having access to open source technologies such as Apache Ambari. The Apache Ambari community helped us a lot, and our efforts were made easier by having access to the source code and being able to define and take part in the future of project. We became active contributors and ultimately committers into many Apache Software Foundation projects in the Hadoop ecosystem.

We are excited to be joining the Hortonworks team as we continue our work within the Apache open source community to deliver on our founding vision of simplifying and speeding Hadoop adoption.

Thanks to the team and everyone who has helped us in the journey so far. We believe that by bringing this simplified approach of provisioning Hadoop in open source, we can significantly accelerate enterprise adoption of Hadoop even beyond the phenomenal traction we are already seeing.

Stay tuned for more news in the near term.  
