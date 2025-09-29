#!/bin/bash
FILE="dns-list"
TRIES=3
RESULTS="dns-results.txt"

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

echo "🔎 Checking DNS servers ($TRIES tries per DNS)"
echo "-----------------------------------------------"
rm -f "$RESULTS"

for server in "${dns_list[@]}"; do
  total_rt=0
  success=0
  last_ip=""
  for i in $(seq 1 $TRIES); do
    # สร้าง subdomain แบบสุ่มทุกครั้ง เพื่อลดโอกาสโดน DNS server เข้าใจผิด
    subdomain="test-$(date +%s%3N).example.com"
    START=$(date +%s%3N)
    result=$(dig @"$server" "$subdomain" +time=2 +tries=1 +short 2>/dev/null)
    END=$(date +%s%3N)
    if [ -n "$result" ]; then
      RT=$((END - START))
      total_rt=$((total_rt + RT))
      success=$((success + 1))
      last_ip="$result"
    fi
  done
  if [ "$success" -gt 0 ]; then
    avg_rt=$((total_rt / success))
    echo "[OK] $server → $last_ip (avg $avg_rt ms over $success tries)"
    echo "$avg_rt $server" >> "$RESULTS"
  else
    echo "[FAIL] $server → no response"
  fi
done

# --- Show Top 3 DNS ---
if [ -s "$RESULTS" ]; then
  echo ""
  echo "✅ Top 3 fastest usable DNS:"
  sort -n "$RESULTS" | head -n 3 | awk '{print $2, "(" $1 " ms)"}'
else
  echo ""
  echo "❌ No DNS responded successfully."
fi
