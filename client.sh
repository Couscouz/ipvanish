#!/bin/bash

command_name="ipvanish"
config_dir="/opt/ipvanish/config"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -eq 0 ]
  then echo "Usage: $command_name { CountryCode | City }"
       echo "For example, try 'ipvanish EE'."
  exit
fi

if [ $# -gt 1 ]
  then echo "$command_name: too many arguments"
  exit
fi

countries=$(ls "$config_dir" | awk -F'-' '{print $2}' | sort -u)
cities=$(ls "$config_dir" | awk -F'-' '{ for(i=3; i<NF-1; i++) printf "%s ", $i; print "" }' | sort -u)

if [[ $countries != *$1* && $cities != *$1* ]]
  then echo "argument is neither a valid country or a city"
       echo "Try 'ipvanish --help' for more information."
  exit
fi

files_list=()

# Remplissage du tableau avec les fichiers correspondants
while IFS= read -r -d '' file; do
  files_list+=("$file")
done < <(find "$config_dir" -type f -name "*$1*" -print0)

files_list=($(find "$config_dir" -type f -name "*$1*" -exec printf "%s\n" {} +))
index=$((RANDOM%${#files_list[@]}))
ovpn_file=${files_list[index]}

echo "Using $ovpn_file"
openvpn --config "$ovpn_file"

exit
