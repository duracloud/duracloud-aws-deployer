# duracloud-aws-deployer
A set of terraform scripts for automatically deploying a DuraCloud to AWS.

## Requirements
terraform  (https://www.terraform.io/downloads.html)

## Installation

After installing terraform 
```
git clone https://github.com/duracloud/duracloud-aws-deployer
cd duracloud-aws-deployer
cd shared
terraform init
cd ../mill
terraform init
```

Then set up an aws profile in ~/.aws/config
(c.f. https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)

## Deploy and initialize shared resources 
```
cd shared
terraform apply -var 'aws_profile=<your profile>'
```

## Deploy the Mill
```
cd mill
terraform apply -var 'aws_profile=<your profile>'  -var 'ec2_keypair=<your ec2 keypair name>'
```

## Deploy the Management Console 
TDB 

NB: make sure that the aws bucket you designate does not already exist.  Also once created, do not put anything in it that you do not want deleted on teardown.

## Tear it down
```
cd mill
terraform destroy -var 'aws_profile=<your profile>' -var 'ec2_keypair=<your ec2 keypair name>'


cd ../shared
terraform destroy -var 'aws_profile=<your profile>'
```

##  Other variables
See ./mill/variables.tf for a complete list of optional parameters.


