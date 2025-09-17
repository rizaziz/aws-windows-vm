#!/bin/bash

set -euo pipefail

cache_dir=$(pwd)/cache

if [[ ${1:-} == "--refresh" ]]; then
    rm -rf $cache_dir
fi

if [[ ! -d "$cache_dir" ]]; then
    mkdir $cache_dir
fi


regions_list=
cache_file="${cache_dir}/regions_list.txt"
if [[ ! -f "${cache_file}" ]]; then
    regions_list="$(aws ec2 describe-regions --region us-east-1 | jq -r ".Regions[].RegionName" | sort | uniq)"
    for region in $regions_list; do
        echo $region >> "$cache_file"
    done
else
    regions_list=$(cat "$cache_file")
fi


data=
PS3="Choose Region: "
select region in $regions_list; do
    cache_file="${cache_dir}/data_${region}.json"
    if [[ ! -f "${cache_file}" ]]; then
        data=$(aws ec2 describe-images --region $region)
        echo $data | jq -r > "${cache_file}"
        echo "Selected region: $region"
    else
        data=$(cat "$cache_file" | jq -r)
    fi        
    break
done

# Trim
data=$(echo $data | jq -r ".Images")


PS3="Choose Image Owner: "
owners_list=
cache_file="$cache_dir/owners_list.txt"
if [[ ! -f "$cache_file" ]]; then
    owners_list="$(echo $data | jq -r ".[].ImageOwnerAlias" | sort | uniq)"
    for owner in $owners_list; do
        echo $owner >> $cache_file
    done
else
    owners_list=$(cat $cache_file)
fi

select owner in $owners_list; do
    cache_file=$cache_dir/data_${owner}.json
    if [[ ! -f "$cache_file" ]]; then
        data=$(echo $data | jq -r "map(select(.ImageOwnerAlias == \"${owner}\"))")
        echo $data | jq -r > $cache_file
    else
        data=$(cat $cache_file | jq -r)
    fi
    break
done


PS3="Choose Platform: "
platforms_list=
cache_file="$cache_dir/platforms_list.txt"
if [[ ! -f "$cache_file" ]]; then
    platforms_list="$(echo $data | jq -r ".[].PlatformDetails" | sort | uniq)"
    for platform in "${platforms_list[@]}"; do
        echo $platform >> $cache_file
    done        
else
    platforms_list=$(cat $cache_file)
fi


select platform in "$platforms_list"; do
    cache_file=$cache_dir/data_${platform}.json
    if [[ ! -f "$cache_file" ]]; then
        data=$(echo $data | jq -r "map(select(.PlatformDetails == \"${platform}\"))")
        echo $data | jq -r > $cache_file
    else
        data=$(cat $cache_file | jq -r)
    fi
    break
done


# echo $data | jq -r ".PlatformDetails" | sort | uniq

# PS3="Choose Windows Server Version: "
# options=("Core" "Full" "All")

# win_server_version=

# select option in "${options[@]}"; do
#     case $option in 
#         "Core")
#             win_server_version=Core
#             break
#             ;;
#         "Full")
#             win_server_version=Full
#             break
#             ;;
#         "All")
#             win_server_version=*
#             break
#             ;;
#         *)
#             echo "Invalid option. Please try again"
#             echo $option
#             ;;
#     esac
# done

# S3="Choose Additional Software: "
# options=("SQL_2019_Enterprise" "SQL_2022_Express" "EKS_Optimized" "SQL_2019_Standard" "ECS_Optimized" "All")

# win_server_software=

# select option in "${options[@]}"; do
#     case $option in 
#         "SQL_2019_Enterprise")
#             win_server_software=SQL_2019_Enterprise
#             break
#             ;;
#         "SQL_2022_Express")
#             win_server_software=SQL_2022_Express
#             break
#             ;;
#         "SQL_2019_Standard")
#             win_server_software=SQL_2019_Standard
#             break
#             ;;
#         "EKS_Optimized")
#             win_server_software=EKS_Optimized
#             break
#             ;;
#         "ECS_Optimized")
#             win_server_software=ECS_Optimized
#             break
#             ;;
#         "All")
#             win_server_software=*
#             break
#             ;;
#         *)
#             echo "Invalid option. Please try again"
#             echo $option
#             ;;
#     esac
# done




# aws ec2 describe-images \
# 	--region=us-east-1 \
#     --owners amazon \
# 	--filters "Name=platform,Values=windows" "Name=name,Values=Windows_Server-${win_server_year}-English-${win_server_version}-${win_server_software}-*" \
# 	--query "Images[*].[ImageId,Name,PlatformDetails]" \
# 	--output table