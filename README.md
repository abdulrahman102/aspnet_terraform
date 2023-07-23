# CREATING **EKS** CLUSTER WITH **TERRAFORM**
## The provided files are used to create fully eks with aspnet application and 3 kinds of databases provided in the cluster
-----

## 1- Building the image from the docker file and push it to ECR or any image registry 
'''
docker build -t <imagename> .  
aws ecr --region <region> | docker login -u AWS -p <encrypted_token> <repo_uri>  
docker tag <source_image_tag> <target_ecr_repo_uri>  
docker push <ecr-repo-uri>  
'''