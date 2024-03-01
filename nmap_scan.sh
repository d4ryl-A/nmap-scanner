#!/bin/bash


mkdir "nmap_scan"

read -p "Enter the target IP address: " target_IP

ports=$(nmap -p- --min-rate=1000 -n -T4 -Pn "$target_IP" | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//);\

nmap -Pn -sC -sV -p "$ports" "$target_IP" -oN nmap_scan/scan.txt --reason --script=vuln
