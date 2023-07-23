# CREATING **EKS** CLUSTER WITH **TERRAFORM**
## The provided files are used to create fully eks with aspnet application and 3 kinds of databases provided in the cluster

-----

## 1- Building the image from the docker file and push it to ECR or any image registry 
- Using the repo provided [aspnet original app](https://github.com/docker/awesome-compose/tree/master/aspnet-mssql) and getting a domain name from one of domains providers.
```
- docker build -t <imagename> .  -
- aws ecr --region <region> | docker login -u AWS -p <encrypted_token> <repo_uri>  
- docker tag <source_image_tag> <target_ecr_repo_uri>  
- docker push <ecr-repo-uri>  
```
-----

## 2- Authenticate the cluster with ECR 

```
- cat ~/.docker/config.json | base64
```

- Get the value of this command and put it as **base64config_secret** variable in tfvars file

-----

## 3- How will terraform work ?
###  1\) VPC 
After providing the needed variables the **VPC module** will start to create the vpc and subnets according to provided az and cidr blocks with the nat and ig on the network
> **NOTE**: You can provide the subnet and vpc cidr block as variables


### 2\) EKS 
After creating vpc and subnets, comes the role of **EKS module** which will create full eks cluster with eks managed instances which will take care of configurations and auto-scalling including :
- adding security group rule to allow inbound trafic from the alb (which we will add later).  
- attach policy to worker nodes to accept the ingress load-balancer controller.  
- installing the ingress alb controlplane using helm chart to the cluster.  
> **NOTE** : you can attach any security group you prefer to the worker or master nodes

### 3\) KUBECTL COMMANDS
The directory **yaml_files** contains all the yaml file needed for this cluster to be up and run including:
- Storage class for dynamic volumes and statefulset 
- Statefulset files for **Mongodb,mssql and redis**
- Deployment of the **ASPNet** app
- Secrets, configmaps, PV and pvc for different uses
- Ingress manifstation **as a resource in terraform file** for ssl after creating record in route 53 and adding ssl in certificate management pointing to the asp.net app
> **NOTE:** The Domain name that been purchased should be provided in tfvars 
-----
## And this will be the architecture of it:
![](https://github.com/abdulrahman102/aspnet_terraform/blob/master/AWS%20EKS%20cluster%20by%20terraform.jpg)

