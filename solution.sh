#!/bin/bash

# ==========================================
# 1. GENERATE DATA (orders.jsonl)
# ==========================================
OUTPUT_DATA="orders.jsonl"
names=("Andi_Pratama" "Siti_Rahma" "Budi_Santoso" "Dewi_Lestari" "Eko_Wahyudi" "Rini_Astuti" "Ahmad_Fauzi" "Mega_Utami" "Dedi_Kurniawan" "Fitri_Handayani")
customer_count=${#names[@]}

> "$OUTPUT_DATA"
echo "Generating 500 records..."

for i in $(seq 1 500)
do
    order_id=$(printf "ORD-%03d" $i)
    cust_idx=$((RANDOM % customer_count))
    customer_name="${names[$cust_idx]}"
    customer_id=$(printf "C-%03d" $((cust_idx + 1)))
    item_count=$(( (RANDOM % 5) + 1 ))
    
    items_json="["
    total_asli=0
    for j in $(seq 1 $item_count)
    do
        sku=$(printf "SKU-%03d" $(( (RANDOM % 20) + 1 )))
        qty=$(( (RANDOM % 5) + 1 ))
        price=$(( ((RANDOM % 15) + 1) * 10000 ))
        total_asli=$((total_asli + (qty * price)))
        
        items_json="${items_json}{\"sku\":\"$sku\",\"qty\":$qty,\"price\":$price}"
        [ $j -lt $item_count ] && items_json="${items_json},"
    done
    items_json="${items_json}]"

    # Inject Bug Data Mismatch sekitar 10%
    if [ $(( (RANDOM % 10) + 1 )) -eq 1 ]; then
        total_final=$((total_asli + 5000))
    else
        total_final=$total_asli
    fi

    # Date Generator (Span Mei 2026)
    day=$(printf "%02d" $(( (RANDOM % 22) + 1 )))
    created_at="2026-05-${day}T14:23:45Z"

    echo "{\"order_id\":\"$order_id\",\"customer\":{\"id\":\"$customer_id\",\"name\":\"$customer_name\"},\"items\":$items_json,\"total\":$total_final,\"created_at\":\"$created_at\"}" >> "$OUTPUT_DATA"
done
echo "orders.jsonl berhasil dibuat!"
echo "----------------------------------------"

# ==========================================
# 2. PROCESSING JAWABAN SOAL 1 - 5
# ==========================================
mkdir -p output

echo "Processing Soal 1..."
echo "--- Top 5 Customer Berdasarkan Total Spending ---" > output/soal1_top_customers.txt
jq -r '[.customer.id, .total] | @tsv' orders.jsonl | awk '{sum[$1]+=$2} END {for(c in sum) print sum[c], c}' | sort -rn | head -n 5 >> output/soal1_top_customers.txt

echo "Processing Soal 2..."
echo "--- Order ID Mismatch (Bug Data) ---" > output/soal2_mismatch_orders.txt
jq -r 'select((.total == ([.items[] | .qty * .price] | add)) | not) | [.order_id, .total, ([.items[] | .qty * .price] | add)] | @tsv' orders.jsonl >> output/soal2_mismatch_orders.txt

echo "Processing Soal 3..."
echo "--- Top 10 SKU Paling Sering Dibeli ---" > output/soal3_top_sku.txt
jq -r '.items[] | .sku' orders.jsonl | sort | uniq -c | sort -rn | head -n 10 >> output/soal3_top_sku.txt

echo "Processing Soal 4..."
echo "order_id,customer_id,customer_name,item_count,total,created_at" > output/orders_flat.csv
jq -r '[.order_id, .customer.id, .customer.name, (.items | length), .total, .created_at] | @csv' orders.jsonl >> output/orders_flat.csv

echo "Processing Soal 5..."
echo "--- Average Order Value Per Minggu ---" > output/soal5_weekly_average.txt
jq -r '[.created_at, .total] | @tsv' orders.jsonl | awk -F'\t' '{
    cmd = "date -d \"" $1 "\" +%V"; cmd | getline week; close(cmd)
    sum[week] += $2; count[week]++
} END { for(w in sum) printf "Minggu ke-%s: Rata-rata = Rp %.2f\n", w, sum[w]/count[w] }' >> output/soal5_weekly_average.txt

echo "Semua file jawaban sukses diproses dan disimpan di folder exercise-3-json/output/!"