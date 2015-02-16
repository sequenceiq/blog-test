---
layout: post
title: "OpenStack integration to Cloudbreak"
date: 2015-02-17 11:00:00 +0200
comments: true
categories: [Cloudbreak]
author: Attila Kanto
published: true
---

Cloudbreak can provision HDP clusters on different public cloud providers like Amazon Web Services (AWS), Google Cloud Platform (GCP) and Microsoft Azure. Starting from the upcoming release the Cloudbreak is going to support provision Hadoop on [OpenStack](https://www.openstack.org/) which is probably the most popular open-source cloud computing platform for private clouds. This blogpost is explains in a nutshell how OpenStack integration was done into Cloudbreak in order to provision Hadoop, but if you are just interested in playing with OpenStack then it is also worth to read because the **Set Up Your Own Private Cloud** section explains how to install a DevStack (Openstack suitable for development purposes) with just a few lines of commands.

##Public and Private Clouds
The overly simplified definition of the two deployment models:

 * **public cloud** consists of services that are usually purchased on-demand and provided off-site over the Internet by cloud provider
 * **private cloud** is one in which the services and infrastructure are purchased, maintained and managed within the company

From Cloudbreak point of view the most important difference is that the services and API of a public cloud is consistent within a provider and it does not really depends on tenants, in other words the AWS provides the same API and same services independently whether Company A or Company B is using it. In case of private cloud, the situation is not so simple, since even if cloud platform is the same the provided services could be very different. If we take the OpenStack as example then one company can use [XEN](http://www.xenproject.org/) as hypervisor, [Ceph](http://ceph.com/ceph-storage/block-storage/) as block storage and the Nova network for networking, but another company might use [KVM](http://www.linux-kvm.org/), [Cinder](https://wiki.openstack.org/wiki/Cinder) and [Neutron](https://wiki.openstack.org/wiki/Neutron) to provide the same functionality. This divergence makes the integration of cloud platforms like OpenStack much more challenging than integrating a public cloud provider.

##Orchestration
Because of the diversity of OpenStack deployments we decided to use the [Heat](https://wiki.openstack.org/wiki/Heat) orchestration service. With the template mechanism of Heat we can describe the infrastructure resources like servers, floating IPs, volumes and security groups for a cloud application in a text file (JSON, YAML or HOT synax) and we can easily adapt this template description in order support different deployments without changing the code of Cloudbreak.

To make it easier to understand you can take a look at the following template snippet:
```yaml
heat_template_version: 2014-10-16

resources:
  app_network:
    type: OS::Neutron::Net
    properties:
      admin_state_up: true
      name: app_network

  app_subnet:
    type: OS::Neutron::Subnet
    properties:
      network_id: { get_resource: app_network }
      cidr: 10.10.1.0/24
      gateway_ip: 10.10.1.1
      allocation_pools:
        - start: 10.10.1.4
          end: 10.10.1.254

  ... other resources defined here ...

```

In the above Heat template fragment Neutron (OS::Neutron::Subnet) is used to provide networking service, but in deployments where the Neutron is not supported we would use another type of Network resource definition like Rackspace::Cloud::Network in case of [Rackspace](http://www.rackspace.com/cloud/private) based deployments:

```yaml
heat_template_version: 2014-10-16

resources:
  app_network:
    type: Rackspace::Cloud::Network
    properties:
      cidr: 10.10.1.0/24
      label: app_network

  ... other resources defined here ...

```

The Heat stack is a model that holds the Heat template, parameters and other meta data related to it, when the infrastructure is changed (e.g. new VM is added or removed, or the CIDR of network is changed) then template needs to be modified and can be used to update your existing stack and the Heat knows how to make the necessary changes in the infrastructure in order to satisfy the resource definition described in the updated template.

Although the Heat can manage the whole lifecycle of the application the Cloudbreak uses it only for infrastructure management and the Hadoop provisioning is done by using Ambari and Docker containers exactly in the same way as we do it for  public cloud providers.

## Set Up Your Own Private Cloud
To try out the OpenStack integration you need to have OpenStack. If you don't already have one then for development purposes the  [DevStack](https://wiki.openstack.org/wiki/DevStack) can be used to quickly deploy an OpenStack cloud. When we started with the integration we have realised that finding a proper configuration and install guide for DevStack is not an easy task. Of course there are plenty of documentations, but rest of them are not very accurate or extremely long or a bit outdated, therefore we have gathered all necessary piece of information to set up OpenStack development environment with Neutron, Cinder, Glance, Nova, Horizon and created an Ansible Playbook wich we added to Vagrant config, therefore staring and installing a VM with DevStack is as simple as:

```bash
$ git clone https://github.com/sequenceiq/sequenceiq-samples
$ cd sequenceiq-samples/devstack/vagrant/devstack-neutron
$ vagrant up
```
_Note: you need to have Vagrant, VirtualBox and Ansible installed before using vagrant up command_

The installation takes at least 30mins, but after it Horizon UI will be available at [http://192.168.60.10/](http://192.168.60.10/) and you can login with user _admin_  and _openstack_ password. The most important configuration values used for setting up the DevStack can be found [here](https://github.com/sequenceiq/sequenceiq-samples/blob/master/devstack/ansible/local-vagrant-vm.yml).

So we have launched a whole OpenStack cloud in one single VM running in VirtualBox, as you might guessed already that is just for demonstration purpose of the Ansible install scripts, because as you can see from the configuration [file](https://github.com/sequenceiq/sequenceiq-samples/blob/master/devstack/ansible/local-vagrant-vm.yml) that in OpenStack launched on VirtualBox the [QEMU](http://wiki.qemu.org/Main_Page) emulation is used therefore the OpenStack VM instances will be to slow and not suitable for Hadoop installation. But based on this you can install just configure the  [devstack.yml](https://github.com/sequenceiq/sequenceiq-samples/blob/master/devstack/ansible/devstack.yml) and [hosts](https://github.com/sequenceiq/sequenceiq-samples/blob/master/devstack/ansible/hosts) and set up the DevStack on a physical machine with KVM virtualisation support. After the OpenStack is running you can launch a VM and install a Cloudbreak on it and use that Cloudbreak to set up VMs and provision HDP on them.

##Future plans
With the current implementation the Hadoop is provisioned into VMs running on OpenStack, but we are also experimenting with  [DockerInc::Docker::Container](http://docs.openstack.org/developer/heat/template_guide/contrib.html#DockerInc::Docker::Container) in order to provision Hadoop cluster directly on the physical machines and avoid the overhead caused by VMs.

Make sure you check back soon to our [blog](http://blog.sequenceiq.com/) or follow us
on [LinkedIn](https://www.linkedin.com/company/sequenceiq/), [Twitter](https://twitter.com/sequenceiq) or [Facebook](https://www.facebook).
