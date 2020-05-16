#!/usr/bin/env bash

# Constants

readonly LINE="================================================================"

# Functions

# function to obtain a token from file
# newlines and spaces are trimmed
# $1 - path to file containing the token
get_token()
{
    local token=$(tr -d "[:space:]" < $1)
    echo $token
}

# Script

LOGFILE="<log_path>"                                                  # location of the log file to which the output will be sent
(
RETRYIN="1h"                                                          # time after which the operation will be retried, in case of error

DAYLIMIT=15                                                           # defines limit value for first half of the month snapshot
MONTHLIMIT=2                                                          # defines number of months that are stored in snapshots

DAY=$(date +'%d')                                                     # actual day
MONTH=$(date +'%m')                                                   # actual month

V0=($((10#$MONTH % 10#$MONTHLIMIT)))                                  # mod based value, 1-January, 2-February, March-0, and onwards...

if [ $DAY -lt $DAYLIMIT ]; then V1=0;                                 # 0 for the first half of the month
else V1=1;                                                            # 1 for the second half of the month
fi

if [ $# -eq 0 ]; then                                                 # if there are no args, use default scheduled version
  VERSION=$V0"-"$V1;                                                  # snapshot version number (0..2)-(0..1)
  else VERSION=$1;                                                    # if an arg was provided, use it as version identifier
fi

DATE=$(date +'%d-%m-%Y')                                              # current date
AUTH="<auth_URL>"                                                     # REST API authentication URL
TOKENPATH="<token_path>"                                              # path to file containing the authentication token
TOKEN=$(get_token $TOKENPATH)                                         # authentication token
FOLDER="Eden/<machine>/"                                              # folder where the image will be saved
IMAGE=$FOLDER"<machine>-Backup-"$VERSION                              # name of the snapshot to be created
DESCR="<machine_descr> - Backup - "$DATE                              # description of the snapshot to be created
STARTTIME=$(date +'%X %d-%m-%Y')                                      # time at which the snapshot process started

echo $LINE
echo "Saving image - "$IMAGE
echo "Starting upload - "$STARTTIME

until snf-mkimage / -u $IMAGE.diskdump -r "$DESCR" \
-a $AUTH -t $TOKEN \
--print-syspreps \
--disable-sysprep shrink \
--disable-sysprep cleanup-userdata \
--disable-sysprep cleanup-passwords \
--force

# --disable-sysprep shrink will avoid image shrinking, required due to a snf-mkimage and GRUB related error
# --disable-sysprep cleanup-passwords will avoid accounts to be locked and passwords deleted
# --disable-sysprep cleanup-userdata will avoid user data to be deleted
# --force will overwrite any snapshot with the same name

do
  echo "Error uploading snapshot"
  echo "Will retry operation in "$RETRYIN
    sleep $RETRYIN
    TOKEN=$(get_token $TOKENPATH)
    echo $LINE
    echo "Restarting - "$(date +'%X %d-%m-%Y')
  done

  ENDTIME=$(date +'%X %d-%m-%Y')                                      # time at which the snapshot process ended
  echo "Upload finished - "$ENDTIME
  echo $LINE
  echo
  ) |& tee -a "$LOGFILE"                                              # output is both sent to stdout and log file
