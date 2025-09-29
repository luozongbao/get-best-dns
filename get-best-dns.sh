#!/bin/bash
FILE="dns-list"
DOMAIN="openai.com"
RESULTS="dns-results.txt"

# --- Read DNS from file ---
dns_list=()
while read -r line; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  dns_list+=("$line")
done < "$FILE"

# --- Add any IPs from command-line arguments ---
if [ "$#" -gt 0 ]; then
  for arg in "$@"; do
    dns_list+=("$arg")
  done
fi

# --- Start testing ---
echo "🔎 Checking DNS servers (query: $DOMAIN)"
echo "-----------------------------------------------"
rm -f "$RESULTS"

for server in "${dns_list[@]}"; do
  # Test DNS and capture only the first A record
  result=$(dig @"$server" "$DOMAIN" +time=2 +tries=1 +short A 2>/dev/null)
  
  if [ -n "$result" ]; then
    # Only measure RT for successful query
    START=$(date +%s%3N)
    dig @"$server" "$DOMAIN" +time=2 +tries=1 +short A >/dev/null 2>&1
    END=$(date +%s%3N)
    RT=$((END - START))

    echo "[OK] $server → $result ($RT ms)"
    echo "$RT $server" >> "$RESULTS"
  else
    echo "[FAIL] $server did not respond"
    # Do NOT log anything for failed queries
  fi
done

# --- Show Top 3 fastest usable DNS ---
if [ -s "$RESULTS" ]; then
  echo ""
  echo "✅ Top 3 fastest usable DNS:"
  sort -n "$RESULTS" | head -n 3 | awk '{print $2, "(" $1 " ms)"}'
else
  echo ""
  echo "❌ No DNS servers responded successfully."
fi
