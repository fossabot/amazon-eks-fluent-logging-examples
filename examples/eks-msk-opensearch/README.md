## Multi-Tenant logging using Fluent-bit, EKS , Amazon MSK and  Amazon OpenSearch

In this example,we will showcase how to send your application logs from EKS's selective namespace(useful when you are using namesapce as tenant isolatio) and forward logs Amazon Managed Service for Kafka to store andto OpeneSearch for visualization. To achieve this, we will deploy Fluent Bit as a DaemonSet to tail /var/log/containers/*.log on the EKS cluster and use fluent-bit annotations to configure desired parser for pod's ina namespace enabled for logging via variable using terraform.This will create one topic for each namespace(enabled for logging) in Amazon MSK and then using MSK connector for OpenSearch we will send these logs to Opensearch such that each namespace(tenant) will have one Index.In the end there is a link to OpenSearch multi-tenancy configuration using RBAC from OpneSearch .

There is terraform code in terraform directory which you will use to create an EKS cluster, MSK cluster, Kafka custom plugin,MSK Connector for OpenSearch  and OpenSearch domain in one VPC.

Reference Architecure ![Architecture](Ref-Architecture.png?raw=true "Title")
This solution can be enhanced to fan out logs from each namespace to multiple destination to duplicate or selectively send to other destination likes S3 etc. you can write customer kafka consumer for logs which might require further processing/filteration.

#### Pre-requisites

* . A S3 bucket for terraform backend
* . An EC2 instance or Cloud9 instace with IAM permissions to create resources
* . Install kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) and  kafka clients binaries to verify your KAFKA brokers (optional).

#### Instructions

* To get started, edit 0-proivder.tf to update backend S3 bucket , region and key prefix.

* Follow terraform instructions from section below ,terraform will create EKS cluster/MSK and OpenSearch compnonents and install fluent-bit in 'logging' namespace and also create a 'example' namespace.

* [Optional] Edit 3-variables.tf to create/edit more namespaces and enable logging on them.
```
default = [
    {
      "name" : "logging",
      "enable_logs_to_es" = false,
    },
    {
      "name" : "example",
      "enable_logs_to_es" = true,
```
* Note. Terraform code will create VPC and all required components. But your OpenSearch dashboard will not be accessible over internet, so you might consider using a AWS client VPN ( or any connectivity method to allow you access to dashboard). you can also launch use a Microsoft windows instance in same VPC and access it via RDP and then access your OpenSearch dashboard 

1. run 
```
terraform init

```


* Wait for terraform to complete 
2. Deploy a sample nginx pod and service  in 'example' namespace.
```
kubectl config set-context --current --namespace=example
kubectl apply -f example-deployment.yaml
kubectl get svc nginx-service-loadbalancer

```
* Note down the name of LoadBalancer and copy it in your browser and hit few times to generate access logs.

3. Login to EC2 instance which have KAFKA client binary are installed and   list KAFKA topics to verify logs_example and logs_logging topics are created and logs are sent to them.
 
```
./bin/kafka-topics.sh --bootstrap-server=<<list of your brokers>>  --list
./bin/kafka-console-consumer.sh --bootstrap-server <<list of your brokers>. --topic logs_example    

```
4. Login to your OpenSearch Dashboard as admin and verify the indexes are created for each of namespace enabled to log to OpenSearch. 


* Fluent-bit allows you to choose your parser. Annotate your pods with following to choose your parser.
   ```
      fluentbit.io/parser: apache
   ```
* If you want to completely opt out of logging for any of your pods. Use

```
fluentbit.io/exclude: "true"

```
* To configure and use RBAC with OpenSearch , you can follow instructions from https://aws.amazon.com/blogs/apn/storing-multi-tenant-saas-data-with-amazon-opensearch-service/

