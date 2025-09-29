#!/bin/bash
FILE="dns-list"
DOMAIN="openai.com"
RESULTS="dns-results.txt"

echo "🔎 Checking DNS servers from $FILE (query: $DOMAIN)"
echo "-----------------------------------------------"
rm -f "$RESULTS"

while read -r server; do
  # Skip empty lines or comments
  [[ -z "$server" || "$server" =~ ^# ]] && continue

  START=$(date +%s%3N)  # start time in ms
  result=$(dig @"$server" "$DOMAIN" +time=2 +tries=1 +short A 2>/dev/null)
  END=$(date +%s%3N)

  if [ -n "$result" ]; then
    RT=$((END - START))
    echo "[OK] $server → $result ($RT ms)"
    echo "$RT $server" >> "$RESULTS"
  else
    echo "[FAIL] $server did not respond"
  fi
done < "$FILE"

echo ""
echo "✅ Top 3 fastest DNS:"
sort -n "$RESULTS" | head -n 3 | awk '{print $2, "(" $1 " ms)"}'
