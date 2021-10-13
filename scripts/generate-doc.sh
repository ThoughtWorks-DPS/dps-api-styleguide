#!/bin/bash

function usage {
  echo "${0}  file.mdx ..."
}

function add_hash {
  local txt=$1
  local len=$2

  while [[ -z "${len}" ]] && [[ ${len} -gt 0 ]]
  do
    len=$(( len-1 ))
    txt="#${txt}"
  done
  echo "${txt}"
}

function process_file {
  local file=$1
  local offset
  local tmpOutput="/tmp/doc"
  local sedFile="/tmp/sed"
  local basePath
  local hashes

  basePath=$(dirname "${file}")
  tmpOutput=$(mktemp /tmp/doc.XXXXXXXX)

  while read -r mdfile offset
  do
    sedFile=$(mktemp /tmp/sed.XXXXXXXX)
    hashes=$(add_hash "#" "${offset}" )
    echo "s/^#/${hashes}/" >> "${sedFile}"
    sed -f "${sedFile}" "${basePath}"/"${mdfile}" >> "${tmpOutput}"
    echo >> "${tmpOutput}"
    rm "${sedFile}"
  done < "${file}"

  cp "${tmpOutput}" "${file/mdx/md}"

  rm "${tmpOutput}"

}

while [ $# -gt 0 ]
do
  case $1 in
  --help) usage; exit 0;;
  --*) echo "Invalid option [$1]"; usage; exit 1;;
  *) process_file "${1}";;
  esac
  shift
done
