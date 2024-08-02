Content-Type: multipart/mixed; boundary="===============2205584129673038508=="
MIME-Version: 1.0

--===============2205584129673038508==
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config"

#cloud-config
# Cloud-Init Hints:
# * Some default settings are in /etc/cloud/cloud.cfg
# * Some examples at: http://bazaar.launchpad.net/~cloud-init-dev/cloud-init/trunk/files/head:/doc/examples/
# * CloudInit Module sourcecode at: http://bazaar.launchpad.net/~cloud-init-dev/cloud-init/trunk/files/head:/cloudinit/config/

preserve_hostname: true
manage_etc_hosts: false

# make user-data scripts always run on boot
cloud_final_modules:
 - rightscale_userdata
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - [scripts-user, always]
 - keys-to-console
 - phone-home
 - final-message

# Add apt repositories
apt_sources:
 # Enable "multiverse" repos
 #- source: deb $MIRROR $RELEASE multiverse
 #- source: deb-src $MIRROR $RELEASE multiverse
 #- source: deb $MIRROR $RELEASE-updates multiverse
 #- source: deb-src $MIRROR $RELEASE-updates multiverse
 #- source: deb http://security.ubuntu.com/ubuntu $RELEASE-security multiverse
 #- source: deb-src http://security.ubuntu.com/ubuntu $RELEASE-security multiverse
 # Enable "partner" repos
 #- source: deb http://archive.canonical.com/ubuntu $RELEASE partner
 #- source: deb-src http://archive.canonical.com/ubuntu $RELEASE partner

# Run 'apt-get update' on first boot
apt_update: true

# Run 'upgrade' on first boot
apt_upgrade: true

# Reboot after package install/upgrade if needed (e.g. if kernel update)
apt_reboot_if_required: True

# Install additional packages on first boot
packages:
 - docker

# run commands
# runcmd contains a list of either lists or a string
# each item will be executed in order
runcmd:
 - mkdir -p /efs
 - echo "${efs_dns_name}:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0" >> /etc/fstab
 - mount -a -t nfs4
 # Tell sudo to respect SSH Agent forwarding
 - [sh, -c, "umask 0226; echo 'Defaults env_keep += \"SSH_AUTH_SOCK\"' > /etc/sudoers.d/ssh-auth-sock"]
 # Install AWS CLI
 - curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
 - unzip awscliv2.zip
 - ./aws/install
 - systemctl start docker
 - systemctl enable docker 
  
# set the locale
locale: en_US.UTF-8

# timezone: set the timezone for this instance
timezone: UTC

# Log all cloud-init process output (info & errors) to a logfile
output: {all: ">> /var/log/cloud-init-output.log"}

# final_message written to log when cloud-init processes are finished
final_message: "System boot (via cloud-init) is COMPLETE, after $UPTIME seconds. Finished at $TIMESTAMP"

--===============2205584129673038508==
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="user-script"

#!/bin/bash


millHome=/root/mill-home
mkdir -p $millHome

#copy configuration bucket contents to mill home
aws s3 cp --recursive s3://${mill_s3_config_location} $millHome/

instanceId=`ls /var/lib/cloud/instances`

docker rm -f  duracloud-mill && echo "duracloud-mill removed" || echo "duracloud-mill does not exist, ignoring."

docker run -d --rm -it -v /sys/fs/cgroup/:/sys/fs/cgroup:ro --cap-add SYS_ADMIN -e HOST_NAME="${instance_prefix}-${node_type}-$instanceId" -e LOG_LEVEL="${log_level}" -e DOMAIN=${domain} -e NODE_TYPE="${node_type}" -e MAX_WORKER_THREADS="${max_worker_threads}" -e AWS_REGION="${aws_region}" -v $millHome:/mill-home  -v /efs:/efs --name=duracloud-mill  ${mill_docker_container}:${mill_version};

--===============2205584129673038508==--
