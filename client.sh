#!/bin/bash

command_name="ipvanish"
config_dir="/opt/ipvanish/config"
auth_file="/opt/ipvanish/ids.txt"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -eq 0 ]
then
  if [ -e $config_dir/ca.ipvanish.com.crt ]
  then
     echo "Usage: $command_name { CountryCode | City }"
     echo "For example, try 'ipvanish EE'."
  else
     echo "You need to initialize the client."
     echo "Run 'ipvanish init' first."
  fi
  exit
fi

if [ $# -gt 1 ]
  then echo "$command_name: too many arguments"
  exit
fi

if [[ $1 == "init" || $1 == "update" ]]
then
  apt install unzip openvpn curl -y
  wget -q "https://configs.ipvanish.com/configs/configs.zip"
  unzip -qo configs.zip -d $config_dir
  rm configs.zip
  find $config_dir -type f -exec sed -i '/keysize 256/d' {} +
exit
fi

# If no arguments are given, select a random location
if [ $# -eq 0 ]
then
  echo "No location provided, selecting a random VPN location..."
  files_list=($(find "$config_dir" -type f -name "*.ovpn" -exec printf "%s\n" {} +))
  index=$((RANDOM % ${#files_list[@]}))
  ovpn_file=${files_list[$index]}
else
  countries=$(ls "$config_dir" | awk -F'-' '{print $2}' | sort -u)
  cities=$(ls "$config_dir" | awk -F'-' '{ for(i=3; i<NF-1; i++) printf "%s ", $i; print "" }' | sort -u)

  if [[ $countries != *$1* && $cities != *$1* ]]
  then
    echo "Argument is neither a valid country nor a city."
    echo "Try '$command_name --help' for more information."
    exit
  fi

  # Populate files_list based on the provided argument
  files_list=($(find "$config_dir" -type f -name "*$1*" -exec printf "%s\n" {} +))
  index=$((RANDOM % ${#files_list[@]}))
  ovpn_file=${files_list[$index]}
fi

echo "Using $ovpn_file"
openvpn --config "$ovpn_file" --ca "$config_dir/ca.ipvanish.com.crt" --auth-user-pass "$auth_file"

exit
