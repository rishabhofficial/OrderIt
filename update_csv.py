#!/usr/bin/env python3
import csv
import sys

def update_csv():
    input_file = 'asset/item.csv'
    temp_file = 'asset/item_temp.csv'

    updated_rows = []
    changes_made = 0

    with open(input_file, 'r', encoding='utf-8') as file:
        reader = csv.reader(file)

        for row in reader:
            if len(row) >= 5:  # Ensure we have enough columns
                icode, iname, mfgby, unit, compdiv = row[0], row[1], row[2], row[3], row[4]

                # Apply the rules
                if mfgby == 'ARI' and compdiv.strip() == '':
                    compdiv = 'Genetica'
                    changes_made += 1
                    print(f"Updated {icode}: ARI with blank COMPDIV -> Genetica")
                elif mfgby == 'AR' and compdiv.strip() == '':
                    compdiv = 'TF'
                    changes_made += 1
                    print(f"Updated {icode}: AR with blank COMPDIV -> TF")

                # Update the row
                row[4] = compdiv
                updated_rows.append(row)
            else:
                # Keep rows that don't have enough columns as is
                updated_rows.append(row)

    # Write the updated data back to the original file
    with open(input_file, 'w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerows(updated_rows)

    print(f"\nTotal changes made: {changes_made}")
    print("Changes applied:")
    print("- For MFGBY = 'ARI' with blank COMPDIV: set to 'Genetica'")
    print("- For MFGBY = 'AR' with blank COMPDIV: set to 'TF'")

if __name__ == "__main__":
    update_csv()