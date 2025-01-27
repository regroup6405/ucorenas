#!/bin/bash

ZFSNAP="$(whereis zfsnap | awk '{print $2}')"
[ ! -f "$ZFSNAP" ] && exit 1

"$ZFSNAP" destroy -r "${1}"

zfs list \
  | grep -v "^NAME" \
  | awk '{print $1}' \
  | while IFS= read -r i; do
      zfs set refreservation=none "$i"
    done

"$ZFSNAP" snapshot -a 3d -r "${1}"

zfs list -t snap \
  | grep -v "^NAME" \
  | awk '{$2=$2}$1' \
  | sort -h -k 4,4 \
  | while IFS= read -r i; do
      echo "$i" | cut -d' ' -f4 | grep -q "K" && zfs destroy "$(echo "$i" | awk '{print $1}')"
    done

exit 0
