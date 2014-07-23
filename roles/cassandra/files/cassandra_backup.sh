#!/bin/bash 
# backs up files from backups or snapshot dir directory. 
#TODO: If you want to skip compression, specify -n (e.g. when backing up compressed files).

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/sky/bin
nice=17

#Environment variables need to run the script

while getopts ":b:e:k:t:" opt ; do
     case $opt in
         b)
           BUCKET_NAME=s3://$OPTARG
             ;;
         e)
           ENVIRONMENT=$OPTARG
             ;;
         k)
           KEYSPACE=$OPTARG
             ;;
         t)
           BKUP_TYPE=$OPTARG
             ;;
         \?)
            echo "Invalid option: - ${OPTARG}" >&2
            exit 1
            ;;
         :)
            if [ ! grep "[bek]" $opt ]
            then
              echo "Missing value for $opt"
              exit 1
            fi
            ;;
     esac
done

TABLE_LIST=( 'household' 'householddevice' 'householddeviceactivity' 'householddevicechangeexception' 'householddevicehistory' 'householdparentalcontrol' 'householdrule' )
HOSTNAME=$(hostname)
TODAY=$(date +%u)
THIS_WEEK=$(date +%V)
YEAR=$(date +%Y)
BASE_PATH=${ENVIRONMENT}/${YEAR}/${THIS_WEEK}/${HOSTNAME}/${KEYSPACE}
DATA_DIR=/apps/data/cassandra/data
BIN_DIR=/apps/cassandra/bin/
LOG_FILE="/tmp/backup.${YEAR}.${THIS_WEEK}.${TODAY}"
S3CMD_BIN=/usr/local/bin/s3cmd #full path to s3cmd executable
PID_FILE=/var/run/cassandra/backup.pid
s3_create_bucket="${S3CMD_BIN} mb ${BUCKET_NAME}"

set_bkup_type() {
  if [[ -z ${BKUP_TYPE} ]]
  then
    if [[ ${TODAY} == 7 ]]
    then
      BKUP_TYPE='full'
    else
      BKUP_TYPE='inc'
    fi
  fi
  echo "Doing backup type: ${BKUP_TYPE}"
}

#Cleanup function to be run on Sunday before backup
cleanup() {
  logit "Cleaning up previous backup files for keyspace ${KEYSPACE}"
  #First remove old incremental files
  for table in ${TABLE_LIST[@]}
  do
    for sfile in ${DATA_DIR}/${KEYSPACE}/${table}/backups/*
    do
      rm -vf ${sfile}
    done
  done
  #Now remove snapshots created with nodetool
  $BIN_DIR/nodetool -h ${HOSTNAME} clearsnapshot ${KEYSPACE}
  return $?
}

#Sync files in backup folder to S3/S4
do_sync() {
  #sync files created by incremental snapshot feature
  #should only sync file which end in Data.db (sstable files)
  for table in ${TABLE_LIST[@]}
  do
    if [[ ! -d ${DATA_DIR}/${KEYSPACE}/${table} ]]
    then
      logit "${table} column family does not exist"
      continue
    fi
    # Return if table has no data
    if [[ $(ls -A ${DATA_DIR}/${KEYSPACE}/${table} | wc -l) == 0 ]]
    then
      logit "Skipping empty table: ${table}"
      continue
    fi

    #Upload to S3
    ${S3CMD_BIN} sync  --acl-private ${DATA_DIR}/${KEYSPACE}/${table}/backups/*-{Data,Index}.db ${BUCKET_NAME}/${BASE_PATH}/${table}/
  done
}

#create snapshot on Sundays
do_snap() {
  for table in ${TABLE_LIST[@]}
  do
    if [[ ! -d ${DATA_DIR}/${KEYSPACE}/${table} ]]
    then
      logit "${table} column family does not exist"
      continue
    fi
    # Return if table has no data
    if [[ $(ls -A ${DATA_DIR}/${KEYSPACE}/${table} | wc -l) == 0 ]]
    then
      logit "Skipping empty table: ${table}"
      continue
    fi

    #Create snapshot and upload to s3
    logit "Creating snapshot for table ${table}"
    $BIN_DIR/nodetool -h ${HOSTNAME} snapshot ${KEYSPACE} -cf ${table}
  done

  #Now upload snapshot to S3.
  for table in ${TABLE_LIST[@]}
  do
    logit "Uploading snapshot for table ${table}"    
    ${S3CMD_BIN} sync --acl-private ${DATA_DIR}/${KEYSPACE}/${table}/snapshots/*/*-{Data,Index}.db ${BUCKET_NAME}/${BASE_PATH}/${table}/
  done
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
  echo "Running Cassandra backup script for keyspace ${KEYSPACE}"
  if is_running 
  then
    echo "Backup still running. Not running again"
    exit 0
  else
    echo $$ > $PID_FILE
    if [ -x ${S3CMD_BIN} ]
    then
      #Create bucket and fail silently
      echo "Creating S3 bucket ${BUCKET_NAME}"
      $s3_create_bucket
      set_bkup_type
      if [[ ${BKUP_TYPE} == 'full' ]]
      then
        echo "Running cleanup due to it being Sunday"
        cleanup
        do_snap
      else
        echo "Running sync of incrmental files due to it not being Sunday"
        do_sync
      fi
    else
      echo 'Run for the hills. It is all broken!!!!'
    fi
    rm -f $PID_FILE
  fi
}

main | cli_output_to_log

exit 0

