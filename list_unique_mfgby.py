#!/usr/bin/env python3
import csv
from collections import Counter

def list_unique_mfgby():
    input_file = 'asset/item.csv'
    mfgby_values = []

    with open(input_file, 'r', encoding='utf-8') as file:
        reader = csv.reader(file)

        for row in reader:
            if len(row) >= 3:  # Ensure we have enough columns
                mfgby = row[2]  # MFGBY is the 3rd column (index 2)
                if mfgby.strip():  # Only add non-empty values
                    mfgby_values.append(mfgby.strip())

    # Get unique values and count occurrences
    unique_mfgby = sorted(set(mfgby_values))
    mfgby_counts = Counter(mfgby_values)

    print(f"Found {len(unique_mfgby)} unique MFGBY values:\n")

    # Print in alphabetical order with counts
    for mfgby in unique_mfgby:
        count = mfgby_counts[mfgby]
        print(f"{mfgby}: {count} entries")

    print(f"\nTotal unique MFGBY values: {len(unique_mfgby)}")
    print(f"Total entries processed: {len(mfgby_values)}")

if __name__ == "__main__":
    list_unique_mfgby()