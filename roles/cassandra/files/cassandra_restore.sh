#!/bin/bash
VERSION=1.0
# Restores from sstables backed up on S3/S4.

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/sky/bin

#Disply usage info
show_help() {
  echo << EOF
   SYNOPSIS:
   VERSION: ${VERSION}
   Restore cassandra data from backup using sstable streaming or in place sstable loading
   
   USAGE:
   Restore data by streaming sstables *
   cassandra_restore.sh -b <S3 bucket name> -k <keyspace> -e <environment> -d <restore from date> -t <address of cluster seed node>
   
   Restore single node **
   cassandra_restore.sh -b <S3 bucket name> -k <keyspace> -e <environment> -d <restore from date> -n <address of host to restore>
   
   NOTES:
   The date string currently provides a restore based on the week of the year in which the date string falls.
   
   * This command is run from a host outside of the cluster
   ** This command is run on the node being restored.
EOF
  exit 0
}


while getopts ":k:b:d:n:t:c:e:h" opt ; do
   echo "Found $opt, with $OPTARG"
   case $opt in
     b)
       BUCKET_NAME=s3://$OPTARG
         ;;
     d)
       DATE_STRING=$OPTARG
         ;;
     e)
       ENVIRONMENT=$OPTARG
         ;;
     k)
       KEYSPACE=$OPTARG
         ;;
     t)
       TARGET_NODE=$OPTARG
         ;;
     h)
       show_help
         ;;
     n)
       NODE=$OPTARG
         ;;
     \?)
        echo "ERROR: Invalid option: - ${OPTARG}" >&2
        exit 1
        ;;
     :)
        if [ ! grep "[kbed]" $opt ]
        then
          echo "ERROR: Missing value for $opt"
          exit 1
        fi
        ;;
   esac
done

if [[ "p${NODE}" == "p" && "p${TARGET_NODE}" == "p" ]]
then
  echo "You must supply either -t <node address> or -n <node address> at the command line."
  exit 0
fi

TABLE_LIST=( 'household' 'householddevice' 'householddeviceactivity' 'householddevicechangeexception' 'householddevicehistory' 'householdparentalcontrol' 'householdrule' )
DAY=$(date -d "$DATE_STRING" +%u)
WEEK=$(date -d "$DATE_STRING" +%V)
YEAR=$(date --date="$DATE_STRING" +%Y)
BASE_PATH=${ENVIRONMENT}/${YEAR}/${WEEK}
RESTORE_DIR="/apps/restore"
BKUP_DATA_DIR=${RESTORE_DIR}/data
BIN_DIR=/apps/cassandra/bin
LOG_FILE="/tmp/restore.${YEAR}.${WEEK}.${DAY}"
S3CMD_BIN=/usr/local/bin/s3cmd
PID_FILE=/var/run/cassandra/restore.pid
CASSANDRA_DATA_DIR=/apps/data/cassandra/data
JAVA_HOME=/usr/lib/jvm/default-java
CASSANDRA_HOME=/apps/cassandra
CASSANDRA_BIN_DIR=${CASSANDRA_HOME}/bin
CASSANDRA_INCLUDE=${CASSANDRA_BIN_DIR}/cassandra.in.sh
CASSANDRA_YAML=$CASSANDRA_HOME/conf/cassandra.yaml
PATH=${CASSANDRA_BIN_DIR}:$JAVA_HOME/bin:$PATH
COMMIT_LOG_DIR=/apps/data/cassandra/commit_logs
SAVED_CACHE_DIR=/apps/data/cassandra/saved_caches
CASSANDRA_USER=cassandra

if [[ -f $CASSANDRA_INCLUDE ]]
then
  . $CASSANDRA_INCLUDE
fi
cleanup() {
  # Cleanup old backup data
  if [[ -d ${BKUP_DATA_DIR} && $(ls -A ${BKUP_DATA_DIR} | wc -l) != 0 ]]
  then
    rm -vrf ${BKUP_DATA_DIR}/*
  fi
}

has_sudo() {
 exit 0 
}

# Preparatory steps for restore
init() {
  # Create restore and backup_data dir if they don't exist
  test -d ${BKUP_DATA_DIR} || mkdir -p ${BKUP_DATA_DIR}

  # Ensure that schema of keyspace and/or column families has been defined
  # ToDo
}

# ToDo: Check for success/failure of download
get_backups() {
  echo "INFO: Obtaining backup files for ${KEYSPACE} keyspace"
  # Get backup files from S3
  # /restore_dir/backups/cass_node/tables/
  # sstableloader expects /restore_dir/keyspace/table
  ${S3CMD_BIN} get --recursive ${BUCKET_NAME}/${BASE_PATH}/${HOSTNAME}/${KEYSPACE} ${CASSANDRA_DATA_DIR}/
}

# Load SSTable
load_sstables() {
  # Loop over backups of each cassandra node
  cd ${BKUP_DATA_DIR}
  for node in *
  do
    cd ${node}
    # Load SSTable of each column family
    for table in ${KEYSPACE}/*
    do
      echo "INFO: Loading sstables from ${table} from ${node} using ${TARGET_NODE}"
      echo "DEBUG: Using command: ${BIN_DIR}/sstableloader -d ${TARGET_NODE} ${table}"
      ${BIN_DIR}/sstableloader -d ${TARGET_NODE} ${table}
    done
    cd ../
  done
}

#restore single node from snapshots and incremental sstable backups
restore_node() {
    echo "INFO: Step 1. Shutdown Cassandra"
    sudo service cassandra stop
    sleep 20
    if [[ prgrep -f cassandra ]]
    then
      echo "ERROR: Not continuing while cassandra is running"
      return 1
    else
      echo "INFO: Step 2. Cleanup commit logs, saved caches and sstables"
      sudo su - ${CASSANDRA_USER} -c "rm -f $COMMIT_LOG_DIR/*"
      sudo su - ${CASSANDRA_USER} -c "rm -f $SAVED_CACHE_DIR/*"
      sudo su - ${CASSANDRA_USER} -c "find ${BKUP_DATA_DIR}/${KEYSPACE} -type f -name *.db -exec rm -f '{}' ';'"
      sudo su - ${CASSANDRA_USER} -c "find ${BKUP_DATA_DIR}/${KEYSPACE} -type f -name *.txt -exec rm -f '{}' ';'"
      echo "INFO: Step 3: Copy in backup sstables from s3"
      sudo su - ${CASSANDRA_USER} -c "${S3CMD_BIN} get --recursive ${BUCKET_NAME}/${BASE_PATH}/ ${BKUP_DATA_DIR}/"
      echo "INFO: Step 4: Now restart cassandra"
      sudo service cassandra start
      echo "INFO: Step5. Trigger nodetool repair"
      sudo su - ${CASSANDRA_USER} -c "${CASSANDRA_BIN_DIR}/nodetool repair -pr -local"
    fi
}

#check if backup script is running 
is_running() {
  if [[ -f $PID_FILE ]]
  then
    PID=`cat $PID_FILE`
    if [[ $PID -gt 0 ]]
    then
      if [[ `ps -ef | awk '{print $2}' | grep ^${PID}$ | wc -l` == 0 ]]
      then
        return 1
      else
        return 0
      fi
    fi
  else
   return 1
  fi
}

#generic log function
logit() {
  TS=`date '+%x %T'`
  echo "${TS} $*" >> $LOG_FILE
}

cli_output_to_log() {
  while read l
  do
    logit $l
  done
}

#main part of script
main() {
  echo "INFO: Running Cassandra restore script for keyspace ${KEYSPACE}"
  if is_running
  then
    echo "WARN: Backup still running. Not running again"
    exit 0
  else
    echo $$ > $PID_FILE
    cleanup
    init
    if [ -x ${S3CMD_BIN} ]
    then
      echo "INFO: Cassandra keyspace restore from S3 bucket ${BUCKET_NAME}"
      get_backups
      if [[ "x${NODE}" = "x" ]]
      then
        echo "INFO: Streaming sstables for restore"
        load_sstables
      else
        echo "INFO: Restoring single node"
        restore_node
      fi
    else
      echo "ERROR: Missing ${S3CMD_BIN}"
    fi
    echo "INFO: Removing PID file ${PID_FILE} after run"
    rm -vf $PID_FILE 2>/dev/null
  fi
}

main | cli_output_to_log


exit 0

