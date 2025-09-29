#!/bin/bash
FILE="dns-list"
DOMAIN="openai.com"
TRIES=3
RESULTS4="dns-results-v4.txt"
RESULTS6="dns-results-v6.txt"

# --- Read DNS from file ---
dns_list=()
while read -r line; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  dns_list+=("$line")
done < "$FILE"

# --- Add command-line IPs ---
if [ "$#" -gt 0 ]; then
  for arg in "$@"; do
    dns_list+=("$arg")
  done
fi

echo "🔎 Checking DNS servers (query: $DOMAIN, $TRIES tries per DNS)"
echo "-----------------------------------------------"
rm -f "$RESULTS4" "$RESULTS6"

for server in "${dns_list[@]}"; do
  # IPv4
  total_rt4=0
  success4=0
  last4=""
  for i in $(seq 1 $TRIES); do
    START=$(date +%s%3N)
    result=$(dig @"$server" "$DOMAIN" A +time=2 +tries=1 +short 2>/dev/null)
    END=$(date +%s%3N)
    if [ -n "$result" ]; then
      RT=$((END - START))
      total_rt4=$((total_rt4 + RT))
      success4=$((success4 + 1))
      last4="$result"
    fi
  done
  if [ "$success4" -gt 0 ]; then
    avg_rt=$((total_rt4 / success4))
    echo "[OK v4] $server → $last4 (avg $avg_rt ms over $success4 tries)"
    echo "$avg_rt $server" >> "$RESULTS4"
  fi

  # IPv6
  total_rt6=0
  success6=0
  last6=""
  for i in $(seq 1 $TRIES); do
    START=$(date +%s%3N)
    result=$(dig @"$server" "$DOMAIN" AAAA +time=2 +tries=1 +short 2>/dev/null)
    END=$(date +%s%3N)
    if [ -n "$result" ]; then
      RT=$((END - START))
      total_rt6=$((total_rt6 + RT))
      success6=$((success6 + 1))
      last6="$result"
    fi
  done
  if [ "$success6" -gt 0 ]; then
    avg_rt=$((total_rt6 / success6))
    echo "[OK v6] $server → $last6 (avg $avg_rt ms over $success6 tries)"
    echo "$avg_rt $server" >> "$RESULTS6"
  fi
done

# --- Show Top 3 IPv4 ---
if [ -s "$RESULTS4" ]; then
  echo ""
  echo "✅ Top 3 fastest usable IPv4 DNS:"
  sort -n "$RESULTS4" | head -n 3 | awk '{print $2, "(" $1 " ms)"}'
else
  echo ""
  echo "❌ No IPv4 DNS responded successfully."
fi

# --- Show Top 3 IPv6 ---
if [ -s "$RESULTS6" ]; then
  echo ""
  echo "✅ Top 3 fastest usable IPv6 DNS:"
  sort -n "$RESULTS6" | head -n 3 | awk '{print $2, "(" $1 " ms)"}'
else
  echo ""
  echo "❌ No IPv6 DNS responded successfully."
fi
