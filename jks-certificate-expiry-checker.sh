#!/bin/bash

########################################################
#
#       Check certificates inside a java keystore
#
#       https://gist.github.com/zatarra/5570733
#
########################################################
TIMEOUT="timeout -k 10s 5s "
KEYTOOL="$TIMEOUT keytool"
THRESHOLD_IN_DAYS="30"
KEYSTORE=""
PASSWORD=""

ARGS=$(getopt -o "p:k:t:" -l "password:,keystore:,threshold:" -n "$0" -- "$@")

function usage {
  echo "Usage: $0 --keystore <keystore> [--password <password>] [--threshold <number of days until expiry>]"
  exit
}

function start {
  RET=0
  CURRENT=$(date +%s)

  THRESHOLD=$(($CURRENT + ($THRESHOLD_IN_DAYS * 24 * 60 * 60)))
  if [ $THRESHOLD -le $CURRENT ]; then
    echo "[ERROR] Invalid date."
    exit 1
  fi
  echo "Looking for certificates inside the keystore $(basename $KEYSTORE) expiring in $THRESHOLD_IN_DAYS day(s)..."

  $KEYTOOL -list -v -keystore "$KEYSTORE" $PASSWORD 2>&1 >/dev/null
  if [ $? -gt 0 ]; then
    echo "Error opening the keystore."
    exit 1
  fi

  $KEYTOOL -list -v -keystore "$KEYSTORE" $PASSWORD | grep Alias | gawk 'match($0, /(Alias name: )(.*)/, e) {print e[2]; }' | {
    while read ALIAS; do
      # Iterate through all the certificate alias
      EXPIRACY=$($KEYTOOL -list -v -keystore "$KEYSTORE" $PASSWORD -alias "$ALIAS" | grep Valid)
      UNTIL=$($KEYTOOL -list -v -keystore "$KEYSTORE" $PASSWORD -alias "$ALIAS" | grep Valid | perl -ne 'if(/until: (.*?)\n/) { print "$1\n"; }')
      UNTIL_SECONDS=$(date -d "$UNTIL" +%s)
      REMAINING_DAYS=$((($UNTIL_SECONDS - $(date +%s)) / 60 / 60 / 24))
      if [ $THRESHOLD -le $UNTIL_SECONDS ]; then
        echo "[OK]      Certificate $ALIAS expires in '$UNTIL' ($REMAINING_DAYS day(s) remaining)."
      else
        RET=1
        echo "[WARNING] Certificate $ALIAS expires in '$UNTIL' ($REMAINING_DAYS day(s) remaining)."
      fi
    done
    echo "Finished..."
    exit $RET
  }
}

eval set -- "$ARGS"

while true; do
  case "$1" in
  -p | --password)
    if [ -n "$2" ]; then PASSWORD=" -storepass $2"; else
      echo "Invalid password"
      exit 1
    fi
    shift 2
    ;;
  -k | --keystore)
    if [ ! -f "$2" ]; then
      echo "Keystore not found: $1"
      exit 1
    else KEYSTORE=$2; fi
    shift 2
    ;;
  -t | --threshold)
    if [ -n "$2" ] && [[ $2 =~ ^[0-9]+$ ]]; then THRESHOLD_IN_DAYS=$2; else
      echo "Invalid threshold"
      exit 1
    fi
    shift 2
    ;;
  --)
    shift
    break
    ;;
  esac
done

if [ -n "$KEYSTORE" ]; then
  start
else
  usage
fi
