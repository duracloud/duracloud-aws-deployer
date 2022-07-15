# duracloud-aws-deployer
A set of terraform scripts for automatically deploying a DuraCloud to AWS.

## Requirements
terraform  (https://www.terraform.io/downloads.html)

## Installation

After installing terraform 
```
git clone https://github.com/duracloud/duracloud-aws-deployer
cd duracloud-aws-deployer
```
# set up an aws profile
Then set up an aws profile in ~/.aws/config
(c.f. https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)
```
export AWS_PROFILE=<your aws profile>
```

# Create your terraform state bucket
```
aws s3 mb s3://<terraform-state-bucket>
``
# Set up duracloud config properties
```
cp ./config/sample-duracloud-config.yml ./config/my-duracloud-config.yml
```
Enter your credentials and configuration


# Create shared resources
cd shared
terraform init
terraform apply -var 'aws_profile=<your aws profile>' -var 'aws_region=<your aws region>'  -var 'stack_name=<your stack name>' -var 'db_password=<your db password>' -var 'ec2_keypair=<your ec2 keypair>' -var 'backend_bucket=<your terraform state bucket>' -lock=false

# import old database (ie mysql < database.sql) or create your database.


# Create artifact bucket 
```
aws s3 cp <duracloud_zip> s3://<duracloud arifact bucket>/
```
# Create the mill
```
cd ../mill
terraform init
terraform apply  -lock=false -var 'aws_profile=<your aws profile>' -var 'aws_region=<your aws region>'  -var 'stack_name=<your stack name>' -var 'ec2_keypair=<your ec2 keypair>'  -var 'mill_config_yaml=./config/my-duracloud-config' -var 'mill_s3_config_bucket=<you duracloud-configuration-bucket>' -var 'mill_version=<mill-version>'
```

# Create Management Console
```
cd ../management-console
terraform init
terraform apply -var 'aws_profile=<your aws profile>' -var 'aws_region=<your aws region>'  -var 'stack_name=<your stack name>' -var 'ec2_keypair=<your ec2 keypair>' -var 'mc_config_yaml=./config/my-duracloud-config' -var 'mc_s3_config_bucket=<you duracloud-configuration-bucket>' -var 'mc_war=<path within artifact bucket to ama war>' -var 'mc_artifact_bucket=<duracloud artifact bucket>' -lock=false
```


# Create DuraCloud
```
cd ../duracloud
terraform init
aws s3 cp <duracloud_zip> s3://<duracloud arifact bucket>/

terraform apply -var 'aws_profile=<your aws profile>'  -lock=false  'aws_profile=<your aws profile>' -var 'aws_region=<your aws region>'  -var 'stack_name=<your stack name>' -var 'ec2_keypair=<your ec2 keypair>'  -var 'duracloud_config_yaml=./config/my-duracloud-config' -var 'duracloud_s3_config_bucket=<duracloud config bucket>' -var 'duracloud_zip=<path to duracloud zip in artifact bucket>' -var 'duracloud_artifact_bucket=<artifact bucket>'
```
