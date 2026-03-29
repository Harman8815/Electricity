import csv

# Read the CSV file
data = []
with open(r'c:\Users\intel\Downloads\New folder\data\master.csv', 'r') as file:
    reader = csv.DictReader(file)
    for row in reader:
        # Calculate units consumed
        prev_read = int(row['prev_read'])
        curr_read = int(row['curr_read'])
        units_consumed = curr_read - prev_read
        
        data.append({
            'first_name': row['first_name'],
            'last_name': row['last_name'], 
            'area_code': row['area_code'],
            'address_line': row['address_line'],
            'city': row['city'],
            'prev_read': prev_read,
            'curr_read': curr_read,
            'units_consumed': units_consumed
        })

# Sort by units consumed (descending)
sorted_data = sorted(data, key=lambda x: x['units_consumed'], reverse=True)

print('TOP 5 HIGHEST UNITS CONSUMERS:')
print('=' * 80)
print(f'{"RANK":<5} {"NAME":<20} {"AREA":<8} {"CITY":<12} {"UNITS":<8}')
print('-' * 80)

for i, row in enumerate(sorted_data[:5], 1):
    name = f"{row['first_name']} {row['last_name']}"
    print(f'{i:<5} {name:<20} {row["area_code"]:<8} {row["city"]:<12} {row["units_consumed"]:<8}')

print()
print('FULL CALCULATION DETAILS (Top 10):')
print('=' * 80)
print(f'{"NAME":<20} {"PREV":<6} {"CURR":<6} {"UNITS":<8}')
print('-' * 80)

for row in sorted_data[:10]:  # Show top 10 for context
    name = f"{row['first_name']} {row['last_name']}"
    print(f'{name:<20} {row["prev_read"]:<6} {row["curr_read"]:<6} {row["units_consumed"]:<8}')

print()
print('COBOL WS-TOP5 expected values:')
print('=' * 40)
for i, row in enumerate(sorted_data[:5], 1):
    print(f'WS-TOP-UNITS({i}) = {row["units_consumed"]:06d}')
    print(f'WS-TOP-IDX({i})   = {i:04d}')  # Index would be based on original order
