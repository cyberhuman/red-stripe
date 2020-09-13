#!/bin/bash

SELF="./$(basename "$0")"

check()
{
  if ! command -v "$1" >/dev/null; then
    echo "$SELF: required tool \`$1' not found." >&2
    exit 1
  fi
}

check exempi
check xmlstarlet
check ffmpeg

if [[ $# != 1 ]]; then
  echo "Usage: $SELF input.mp4" >&2
  exit 1
fi

decode_time()
{
  set -- $(
    echo "${1#time:}" |
    tr 'd' '\n' |
    sed 's#f#/#' |
    bc -l
  )
  echo "-ss $1 -t $2"
}

INPUT="$1"
exempi -x "$INPUT" -o /dev/stderr 2>&1 >/dev/null |
xmlstarlet sel \
  -N 'x=adobe:ns:meta/' \
  -N 'rdf=http://www.w3.org/1999/02/22-rdf-syntax-ns#' \
  -N 'xmpMM=http://ns.adobe.com/xap/1.0/mm/' \
  -N 'stRef=http://ns.adobe.com/xap/1.0/sType/ResourceRef#' \
  -t -m '/x:xmpmeta/rdf:RDF/rdf:Description/xmpMM:Ingredients/rdf:Bag/rdf:li' \
  -v 'stRef:fromPart' -o ' ' -v 'stRef:toPart' -o ' ' -v 'stRef:filePath' -n |
nl -s' ' -nrz |
while read index fromPart toPart fileName; do
  set -- $(decode_time "$toPart")
  ffmpeg -i "$INPUT" "$@" -frames:v 1 "N${index}_${fileName}"
done
