# DTS

The [dts-hosting/duracloud-aws-deployer](https://github.com/dts-hosting/duracloud-aws-deployer)
repository is a downstream fork of the [duracloud/duracloud-aws-deployer](https://github.com/duracloud/duracloud-aws-deployer)
(upstream) project.

The dts deployer `main` branch is kept in a one-to-one relationship with the upstream
`main` branch. Upstream and DTS changes are integrated into the `deployments` branch,
which is where the various DuraCloud environments are defined and is the default branch
in GitHub (TODO).

## Repository setup

### Install local dependencies (optional)

First install:

- [Rbenv](https://github.com/rbenv/rbenv)
- [Tfenv](https://github.com/tfutils/tfenv)

Then run:

```bash
make install
```

### Sync with upstream

To work with the upstream DuraCloud deployer project:

```bash
git clone https://github.com/dts-hosting/duracloud-aws-deployer.git
git remote add upstream https://github.com/duracloud/duracloud-aws-deployer.git
```

Running `git remote -v` should show something like:

```txt
origin   https://github.com/dts-hosting/duracloud-aws-deployer.git (fetch)
origin   https://github.com/dts-hosting/duracloud-aws-deployer.git (push)
upstream https://github.com/duracloud/duracloud-aws-deployer.git (fetch)
upstream https://github.com/duracloud/duracloud-aws-deployer.git (push)
```

To incorporate upstream changes into the dts downstream fork:

```bash
git fetch --all
git checkout main
git rebase upstream/main
git push --force origin main
```

The upstream and downstream main branches are now equivalent.

### Update the deployments branch from main

```bash
git fetch --all
git checkout deployments
git checkout -b deployments-sync-$date
git merge main
git push origin deployments-sync-$date
```

Make a PR to the `deployments` branch.

## AWS accounts / DuraCloud environments

For general considerations around AWS profile configurations refer to the
[infra](https://github.com/dts-hosting/infra/blob/main/docs/AWS.md) repository.

For DuraCloud AWS cli interactions define profiles for dev, prod & test:

```txt
[duraclouddev]
role_arn = arn:aws:iam::380144836391:role/OrganizationAccountAccessRole
source_profile = default
region = us-west-2

[duracloudprod]
role_arn = arn:aws:iam::863649442906:role/OrganizationAccountAccessRole
source_profile = default
region = us-east-1

[duracloudtest]
role_arn = arn:aws:iam::442366795148:role/OrganizationAccountAccessRole
source_profile = default
region = us-west-2
```

To use the profiles you'll generally need to add `--profile $profile` to
any AWS command examples provided in the upstream documentation.

For example, to check for a required parameter:

```bash
aws ssm get-parameter --name duracloud_artifact_bucket --profile duraclouddev
```

## Google reCAPTCHA

TODO: add details for this here.
