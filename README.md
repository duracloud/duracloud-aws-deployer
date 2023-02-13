# duracloud-aws-deployer
A set of terraform scripts for automatically deploying a DuraCloud to AWS.

## Requirements
terraform 1.3.5 (https://www.terraform.io/downloads.html)

### Install terraform environment manager:
```
brew install tfenv
``
### Install the required version of terraform
```
tfenv install 1.3.5
```

## Clone the Repo 

```
git clone https://github.com/duracloud/duracloud-aws-deployer
cd duracloud-aws-deployer
```

## Create a new environment by copying the sample.  
This will create a set of directories with sample tfvar files and symbolic links to
the *.tf files.
 
```
ENV=my-env

cp -aR env/sample env/$ENV

```

## Set up an aws profile
Then set up an aws profile in ~/.aws/config
(c.f. https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html)

## Create your terraform state bucket
```
aws s3 mb s3://<terraform-state-bucket>
``

## Configure your secrets 
Set up the following key value pairs in the AWS parameter store replacing <value> with your secret values.
```
export AWS_REGION=your-aws-region
export AWS_PROFILE=your-aws-profile
aws ssm put-parameter --name "duracloud_master_database_password" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_sumo_access_id" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_sumo_access_key" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_mill_db_user" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_mill_db_password" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_account_db_user"--value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_account_db_password" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_notification_recipients" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_notification_recipients_non_tech" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_notification_user" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_notification_password" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_notification_sender" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_notification_from_address" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_notification_admin_address" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_mc_host" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_mc_domain" --value="<value>" --region $AWS_REGION --type SecureString
aws ssm put-parameter --name "duracloud_certificate_arn" --value="<value>" --region $AWS_REGION --type SecureString
```
Please note, if you want to customize any of the key names,  please update the appropriate key name in one of the tfvars files beneath ./env/<your env>/

## Customize the non-sensitive parameters in the tfvars files 
Open the following files and fill in appropriate values:
./env/<your env>/shared/shared.auto.tfvar
./env/<your env>/management-console/manage-console.auto.tfvar
./env/<your env>/duracloud/duracloud.auto.tfvar
./env/<your env>/mill/mill.auto.tfvar

## Create shared resources
```
cd env/<your env>/shared 
terraform init
terraform apply 
```
# import old database (ie mysql < database.sql) or create your database.


# Create artifact bucket 
```
aws s3 cp <duracloud_zip> s3://<duracloud arifact bucket>/
```
# Create the mill
```
cd env/<your env>/mill
terraform init
terraform apply  
```

# Create Management Console
```
cd env/<your env>/management-console
terraform init
terraform apply 
```

# Create DuraCloud
```
# upload your DuraCloud zip file.
aws s3 cp <duracloud_zip> s3://<duracloud arifact bucket>/

cd env/<your env>/duracloud
terraform init
terraform apply
```
