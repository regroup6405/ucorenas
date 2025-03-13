#!/bin/bash
#set -x
ROOTDATASTORE="${1}"

[ -z ${TARGETSSH} ] && exit 1
[ -z ${KEYLOC} ] && exit 1

ZFSNAP="$(whereis zfsnap | awk '{print $2}')"
[ ! -f "$ZFSNAP" ] && exit 1

sudo "$ZFSNAP" destroy -r "${ROOTDATASTORE}"

sudo "$ZFSNAP" snapshot -a 3d -r "${ROOTDATASTORE}"

SOURCELIST="$(zfs list -t snap | grep @)"
TARGETDATASETS="$(ssh -i ${KEYLOC} -n ${TARGETSSH} 'zfs list' | awk '{print $1}' | grep '/')"
TARGETLIST="$(ssh -i ${KEYLOC} -n ${TARGETSSH} 'zfs list -t snap' | grep '@')"

echo "${SOURCELIST}" \
| grep "^${ROOTDATASTORE}@" \
| cut -d'@' -f1 \
| sort \
| uniq \
| while IFS= read -r i; do
    [ ! "$(zfs get refreservation persist/buildbot | grep '/' | awk '{print $3}' | grep -q 'none' && echo 1)" == "1" ] && sudo zfs set refreservation=none "$i"
    SOURCELATEST="$(echo "$SOURCELIST" | grep "$i" | tail -n 1 | awk '{print $1}')"
    DATASETEXISTSONTARGET="$(echo "$TARGETDATASETS" | grep -q "$i" && echo 1)"
    if [ ! "$DATASETEXISTSONTARGET" == "1" ]; then
      ssh -i ${KEYLOC} -n ${TARGETSSH} "sudo zfs create $i"
    fi
    EXISTSONTARGET="$(echo "$TARGETLIST" | grep -q "$i" && echo 1)"
    ssh -i ${KEYLOC} -n ${TARGETSSH} "sudo zfs set readonly=off $i"
    if [ "$EXISTSONTARGET" == "1" ]; then
      # echo "$i exists on target, incrementally sending..."
      TARGETLATEST="$(echo "$TARGETLIST" | grep "$i" | tail -n 1 | awk '{print $1}')"
      [ "$SOURCELATEST" == "$TARGETLATEST" ] && echo "$TARGETLATEST == $SOURCELATEST, continuing..." && continue
      # echo "$TARGETLATEST > $SOURCELATEST"
      echo sudo zfs send -i "$TARGETLATEST" "$SOURCELATEST" \| ssh -i ${KEYLOC} ${TARGETSSH} sudo zfs recv $i | bash
    else
      # echo "$i doesn't exist on target, sending from scratch..."
      SOURCEFIRST="$(echo "$SOURCELIST" | grep "$i" | head -n 1 | awk '{print $1}')"
      echo sudo zfs send "$SOURCEFIRST" \| ssh -i ${KEYLOC} ${TARGETSSH} sudo zfs recv -F $i | bash
      echo sudo zfs send -i "$SOURCEFIRST" "$SOURCELATEST" \| ssh -i ${KEYLOC} ${TARGETSSH} sudo zfs recv -F $i | bash
    fi
    ssh -i ${KEYLOC} -n ${TARGETSSH} "sudo zfs set readonly=on $i"
  done

ssh -i ${KEYLOC} -n ${TARGETSSH} "sudo zfsnap destroy -r ${ROOTDATASTORE}"
