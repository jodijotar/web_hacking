#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  s3_enum.sh — S3 Bucket Enumerator
#  Usage: ./s3_enum.sh buckets.txt [output.txt]
#  Each line in buckets.txt = one bucket name to test
# ─────────────────────────────────────────────────────────────

INPUT="${1:-buckets.txt}"
OUTPUT="${2:-s3_results.txt}"
SLEEP=0.3

# Colors
RED='\033[0;31m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

# Counters
count_200=0
count_301=0
count_403=0
count_404=0
count_other=0

# ─── Validate input ───────────────────────────────────────────
if [[ ! -f "$INPUT" ]]; then
  echo -e "${RED}[ERROR]${RESET} File not found: $INPUT"
  echo "Usage: $0 buckets.txt [output.txt]"
  exit 1
fi

total=$(grep -c '.' "$INPUT")

# ─── Header ───────────────────────────────────────────────────
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║         S3 Bucket Enumerator                     ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo -e "  Input  : ${BOLD}$INPUT${RESET} ($total names)"
echo -e "  Output : ${BOLD}$OUTPUT${RESET}"
echo -e "  Delay  : ${BOLD}${SLEEP}s${RESET} between requests"
echo ""
echo -e "  ${GREEN}[200]${RESET} Public listing  ${YELLOW}[301]${RESET} Exists/wrong region  ${ORANGE}[403]${RESET} Exists/private  ${GRAY}[404]${RESET} Not found"
echo ""

# Clear output file
> "$OUTPUT"
echo "S3 Enumeration Results - $(date)" >> "$OUTPUT"
echo "Input: $INPUT" >> "$OUTPUT"
echo "================================================" >> "$OUTPUT"

# ─── Main loop ────────────────────────────────────────────────
current=0

while IFS= read -r name || [[ -n "$name" ]]; do

  # Skip empty lines and comments
  [[ -z "$name" || "$name" == \#* ]] && continue

  # Trim whitespace
  name=$(echo "$name" | tr -d '[:space:]')
  ((current++))

  # Progress indicator
  progress="[${current}/${total}]"

  # Make the request
  response=$(curl -si --max-time 10 \
    "https://s3.amazonaws.com/${name}/" 2>/dev/null)

  code=$(echo "$response" | grep -m1 "^HTTP" | awk '{print $2}')
  region=$(echo "$response" | grep -i "x-amz-bucket-region" | awk '{print $2}' | tr -d '\r')
  endpoint=$(echo "$response" | grep -i "<Endpoint>" | sed 's/.*<Endpoint>\(.*\)<\/Endpoint>.*/\1/')

  case "$code" in

    200)
      ((count_200++))
      echo -e "${GREEN}${BOLD}[200 PUBLIC]${RESET} $progress ${BOLD}$name${RESET} ← LISTING OPEN"
      echo "[200 PUBLIC] $name | Region: ${region:-unknown}" >> "$OUTPUT"
      echo "  → aws s3 ls s3://${name}/ --no-sign-request ${region:+--region $region}" >> "$OUTPUT"
      # Auto-enumerate top level
      echo -e "         ${GREEN}↳ Enumerating...${RESET}"
      aws s3 ls "s3://${name}/" --no-sign-request ${region:+--region "$region"} 2>/dev/null \
        | head -20 \
        | while read -r line; do
            echo -e "           ${GREEN}$line${RESET}"
            echo "    $line" >> "$OUTPUT"
          done
      echo "" >> "$OUTPUT"
      ;;

    301)
      ((count_301++))
      real_region=$(curl -si --max-time 10 \
        "https://s3.amazonaws.com/${name}/" 2>/dev/null \
        | grep -i "x-amz-bucket-region" | awk '{print $2}' | tr -d '\r')
      echo -e "${YELLOW}${BOLD}[301 EXISTS]${RESET} $progress ${BOLD}$name${RESET} → Region: ${real_region:-check manually}"
      echo "[301 EXISTS] $name | Region: ${real_region:-unknown} | Endpoint: $endpoint" >> "$OUTPUT"

      # Auto-follow to correct region
      if [[ -n "$real_region" ]]; then
        follow_code=$(curl -so /dev/null -w "%{http_code}" --max-time 10 \
          "https://${name}.s3.${real_region}.amazonaws.com/")
        echo -e "         ${YELLOW}↳ ${name}.s3.${real_region}.amazonaws.com → ${follow_code}${RESET}"
        echo "  → Follow: https://${name}.s3.${real_region}.amazonaws.com/ [${follow_code}]" >> "$OUTPUT"

        if [[ "$follow_code" == "200" ]]; then
          echo -e "         ${GREEN}↳ LISTING OPEN after redirect!${RESET}"
          echo "  → LISTING OPEN after redirect!" >> "$OUTPUT"
          aws s3 ls "s3://${name}/" --no-sign-request --region "$real_region" 2>/dev/null \
            | head -20 >> "$OUTPUT"
        fi
      fi
      echo "" >> "$OUTPUT"
      ;;

    403)
      ((count_403++))
      echo -e "${ORANGE}[403 PRIVATE]${RESET} $progress $name ${region:+| Region: $region}"
      echo "[403 PRIVATE] $name | Region: ${region:-unknown}" >> "$OUTPUT"
      echo "  → Test write: aws s3 cp /tmp/test.txt s3://${name}/test.txt --no-sign-request ${region:+--region $region}" >> "$OUTPUT"
      ;;

    404|"")
      ((count_404++))
      echo -e "${GRAY}[404]${RESET} $progress $name"
      ;;

    *)
      ((count_other++))
      echo -e "${RED}[${code}]${RESET} $progress $name"
      echo "[${code}] $name" >> "$OUTPUT"
      ;;

  esac

  sleep "$SLEEP"

done < "$INPUT"

# ─── Summary ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║                   SUMMARY                       ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
echo -e "  ${GREEN}${BOLD}200 Public listing  : $count_200${RESET}"
echo -e "  ${YELLOW}${BOLD}301 Exists/redirect : $count_301${RESET}"
echo -e "  ${ORANGE}403 Exists/private  : $count_403${RESET}"
echo -e "  ${GRAY}404 Not found       : $count_404${RESET}"
echo -e "  Total tested        : $((count_200 + count_301 + count_403 + count_404 + count_other))"
echo ""
echo -e "  Full results saved to: ${BOLD}$OUTPUT${RESET}"
echo ""

# ─── Next steps for hits ──────────────────────────────────────
if [[ $count_200 -gt 0 || $count_301 -gt 0 ]]; then
  echo -e "${BOLD}Next Steps for Hits:${RESET}"
  echo -e "  ${GREEN}200s${RESET} → Already auto-enumerated above. Check $OUTPUT for keys."
  echo -e "  ${YELLOW}301s${RESET} → Already followed. Test write:"
  echo -e "         aws s3 cp /tmp/test.txt s3://BUCKET/test.txt --no-sign-request --region REGION"
  echo -e "  ${ORANGE}403s${RESET} → Bucket exists. Test anonymous write:"
  echo -e "         aws s3 cp /tmp/test.txt s3://BUCKET/test.txt --no-sign-request"
fi
