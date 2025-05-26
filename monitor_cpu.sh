#!/bin/bash

# File lưu dữ liệu
CSV_FILE="cpu_usage.csv"
DURATION=50  # thời gian chạy (giây)

# Ghi header nếu file chưa có
echo "timestamp,cpu_usage_percent" > "$CSV_FILE"

echo "[+] Đang ghi log CPU vào $CSV_FILE trong $DURATION giây..."

START_TS=$(date +%s)

while true; do
    CURRENT_TS=$(date +%s)
    ELAPSED=$((CURRENT_TS - START_TS))
    if [ "$ELAPSED" -ge "$DURATION" ]; then
        echo "[+] Hoàn tất ghi CPU sau $DURATION giây."
        break
    fi

    # Lấy phần trăm idle từ mpstat, rồi tính usage
    IDLE=$(mpstat 1 1 | awk '/^Average:/ && $NF ~ /^[0-9.]+$/ {print $NF}')
    USAGE=$(echo "scale=2; 100 - $IDLE" | bc)

    # Ghi vào file CSV
    echo "$CURRENT_TS,$USAGE" >> "$CSV_FILE"
done

