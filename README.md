# CREATING **EKS** CLUSTER WITH **TERRAFORM**
## The provided files are used to create fully eks with aspnet application and 3 kinds of databases provided in the cluster

![](https://github.com/abdulrahman102/aspnet_terraform/blob/master/AWS%20EKS%20cluster%20by%20terraform.jpg)
-----

## 1- Building the image from the docker file and push it to ECR or any image registry 
- Using the repo provided [aspnet original app](https://github.com/docker/awesome-compose/tree/master/aspnet-mssql)
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

Get the value of this command and put it as **base64config_secret** variable in tfvars file

-----

## 3- How will terraform work ?

After providing the needed variables the **VPC module** will start to create the 