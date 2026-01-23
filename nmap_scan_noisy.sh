#!/bin/bash
set -euo pipefail

mkdir -p nmap_scan_2

read -rp "Enter the target IP address: " target_IP

echo "[*] TCP full port scan..."
tcp_ports=$(nmap -p- --min-rate=1000 -n -T4 -Pn "$target_IP" \
  | awk '/^[0-9]+\/tcp/ {split($1,a,"/"); printf a[1] ","}' \
  | sed 's/,$//')

echo "[*] UDP full port discovery (this may take a bit)..."
udp_ports=$(nmap -sU -p- -n -Pn -T4 --min-rate=1000 --open \
  "$target_IP" \
  | awk '/^[0-9]+\/udp/ {split($1,a,"/"); printf a[1] ","}' \
  | sed 's/,$//')

if [[ -n "${udp_ports}" ]]; then
  echo "[+] UDP open ports: ${udp_ports}"

  echo "[*] Enumerating UDP services..."
  nmap -sU -p "${udp_ports}" -n -Pn \
    --script=default,discovery,vuln \
    "$target_IP" -oN nmap_scan_2/udp_scan.txt
else
  echo "[-] No UDP ports detected as open."
fi

if [[ -n "${tcp_ports}" ]]; then
  echo "[*] Enumerating TCP services..."
  nmap -Pn -sC -sV -p "${tcp_ports}" "$target_IP" \
    --reason --script=vuln \
    -oN nmap_scan_2/tcp_scan.txt
fi

echo "[*] Done."
