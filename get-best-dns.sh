#!/bin/bash

FILE="dns-list"
DOMAIN="openai.com"
RESULTS="dns-results.txt"
extra_dns=()

# --- ฟังก์ชันช่วยแสดง usage ---
usage() {
  echo "Usage: $0 [-d domain] [-a dns1 dns2 ...]"
  echo "  -d domain   Specify the domain to query (default: openai.com)"
  echo "  -a dns...   Additional extra DNS server(s) to test"
  exit 1
}

# --- parse options ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d)
      shift
      [[ -z "$1" ]] && usage
      DOMAIN="$1"
      shift
      ;;
    -a)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
        extra_dns+=("$1")
        shift
      done
      ;;
    *)
      usage
      ;;
  esac
done

# --- อ่าน DNS จากไฟล์ dns-list ---
dns_list=()
while read -r line; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue  # skip empty or comment
  dns_list+=("$line")
done < "$FILE"

# --- เพิ่ม DNS จาก -l option ---
dns_list+=("${extra_dns[@]}")

# --- เช็ค DNS ---
echo "🔎 Checking DNS servers (query: $DOMAIN)"
echo "-----------------------------------------------"
rm -f "$RESULTS"

for server in "${dns_list[@]}"; do
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
done

# --- แสดง Top 3 fastest DNS ---
if [[ -f "$RESULTS" ]]; then
  echo ""
  echo "✅ Top 3 fastest DNS:"
  sort -n "$RESULTS" | head -n 3 | awk '{print $2, "(" $1 " ms)"}'
else
  echo ""
  echo "⚠️ No DNS responded."
fi
