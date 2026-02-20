#!/bin/bash
 set -uo pipefail
 
 target_IP="${1:?Usage: $0 <target_ip>}"
 outdir="nmap_${target_IP}_$(date +%Y%m%d_%H%M%S)"
 mkdir -p "$outdir"
 
 echo "[*] TCP full port scan on $target_IP..."
 tcp_ports=$(nmap -p- --min-rate=5000 -n -T4 -Pn "$target_IP" 2>/dev/null \
   | awk '/^[0-9]+\/tcp/ {split($1,a,"/"); printf a[1] ","}' \
   | sed 's/,$//')
 
 if [[ -n "$tcp_ports" ]]; then
   echo "[+] TCP open ports: $tcp_ports"
   echo "[*] Enumerating TCP services..."
   nmap -Pn -sC -sV -p "$tcp_ports" "$target_IP" \
     --reason -oA "$outdir/tcp_full" 2>/dev/null
   echo "[*] Running vuln scripts on TCP..."
   nmap -Pn -p "$tcp_ports" "$target_IP" \
     --script=vuln -oA "$outdir/tcp_vuln" 2>/dev/null
 else
   echo "[-] No TCP ports found."
 fi
 
 echo "[*] UDP top 200 scan..."
 udp_ports=$(nmap -sU --top-ports 200 --min-rate=5000 -n -Pn -T4 --open \
   "$target_IP" 2>/dev/null \
   | awk '/^[0-9]+\/udp/ {split($1,a,"/"); printf a[1] ","}' \
   | sed 's/,$//')
 
 if [[ -n "$udp_ports" ]]; then
   echo "[+] UDP open ports: $udp_ports"
   nmap -sU -p "$udp_ports" -sC -sV -n -Pn \
     "$target_IP" -oA "$outdir/udp_full" 2>/dev/null
 else
   echo "[-] No UDP ports detected."
 fi
 
 echo "[*] Results in $outdir/"
 echo "[*] Done."
