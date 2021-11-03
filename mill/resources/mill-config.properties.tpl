#mill config: generated from template
mill.db.name=duracloud_mill
mill.db.host=${database_host}
mill.db.port=${database_port}
mill.db.user=${mill_db_user}
mill.db.pass=${mill_db_password}
 
db.name=duracloud_accounts
db.host=${database_host}
db.port=${database_port}
db.user=${account_db_user}
db.pass=${account_db_password}
db.user=accountsadmin
db.pass=hottub2017#

#########
# Queues
#########
queue.name.audit=${audit_queue_name}
queue.name.bit-integrity=${bit_queue_name}
queue.name.dup-high-priority=${dup_high_priority_queue_name}
queue.name.dup-low-priority=${dup_low_priority_queue_name}
queue.name.bit-error=${bit_error_queue_name}
queue.name.bit-report=${bit_report_queue_name}
queue.name.dead-letter=${dead_letter_queue_name}
queue.name.storagestats=${storage_stats_queue_name}

###############
# SHARED PROPS
###############

duracloud-site.domain=${domain}

# Directory that will be used to temporarily store files as they are being processed.
workdir=/tmp/duracloud

# A comma-separated list of email addresses
notification.recipients=${notification_recipients}
notification.recipients.non-tech=${notification_recipients_non_tech}
notification.sender=${notification_sender}

# Indicates that a local duplication policy directory should be used. - Optional, Primarily for development.
#local-duplication-dir=/your/path/here
  
# The last portion of the name of the S3 bucket where duplication policies can be found.
duplication-policy.bucket-suffix=duplication-policy-repo

############
# WORKMAN
############

# The frequency in milliseconds between refreshes of duplication policies.
duplication-policy.refresh-frequency=60000

# The max number of worker threads that can run at a time. The default value is 5. Setting with value will override the duracloud.maxWorkers if set in the configuration file.
max-workers=20

#############################
# LOOPING DUP TASK PRODUCER
#############################

# The frequency for a complete run through all store policies. Specify in hours (e.g. 3h), days (e.g. 3d), or months (e.g. 3m). Default is 1m - i.e. one month
looping.dup.frequency=0m

# Indicates how large the task queue should be allowed to grow before the Looping Task Producer quits.
looping.dup.max-task-queue-size=200000

#############################
# LOOPING BIT TASK PRODUCER
#############################

# The frequency for a complete run through all store policies. Specify in hours (e.g. 3h), days (e.g. 3d), or months (e.g. 3m). Default is 1m - i.e. one month
looping.bit.frequency=0d

# Indicates how large the task queue should be allowed to grow before the Looping Task Producer quits.
looping.bit.max-task-queue-size=200000

# A file containing inclusions as regular expressions, one expression per line. Expressions will be matched against the following path: /{account}/{storeId}/{spaceId}
looping.bit.inclusion-list-file=/home/duracloud/bit-inclusion.txt

# A file containing exclusions as regular expressions, one expression per line.Expressions will be matched against the following path: /{account}/{storeId}/{spaceId}
looping.bit.exclusion-list-file=/home/duracloud/bit-exclusion.txt


#############################
# LOOPING STORAGE STATS TASK PRODUCER
#############################

# The frequency for a complete run through all store policies. Specify in hours (e.g. 3h), days (e.g. 3d), or months (e.g. 3m). Default is 1m - i.e. one month
looping.storagestats.frequency=1d

# Indicates how large the task queue should be allowed to grow before the Looping Task Producer quits.
looping.storagestats.max-task-queue-size=200000

# Indicates the start time for the first stats run
looping.storagestats.start-time=20:00

# A file containing inclusions as regular expressions, one expression per line. Expressions will be matched against the following path: /{account}/{storeId}/{spaceId}
looping.storagestats.inclusion-list-file=/home/duracloud/storage-stats-inclusion.txt

# A file containing exclusions as regular expressions, one expression per line.Expressions will be matched against the following path: /{account}/{storeId}/{spaceId}
looping.storagestats.exclusion-list-file=/home/duracloud/storage-stats-exclusion.txt

###################
# MANIFEST CLEANER
###################

# Time in seconds, minutes, hours, or days after which deleted items should be purged.
# Expected format: [number: 0-n][timeunit:s,m,h,d]. For example 2 hours would be represented as 2h 
manifest.expiration-time=1d

######################
# AUDIT LOG GENERATOR 
######################

# The global repository for duracloud audit logs
audit-log-generator.audit-log-space-id=auditlogs
