#!/bin/bash

# Loop through all the positional parameters
while [[ $# -gt 0 ]]; do
    case $1 in
        -drive)
            drive_val="$2"
            shift 2 
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

#echo $drive_val
fdisk -l /dev/$drive_val
