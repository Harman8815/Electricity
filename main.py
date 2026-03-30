import random
import csv
import os

FIRST_NAMES = ["Aman","Riya","Karan","Neha","Rahul","Priya","Arjun","Sneha","Vikram","Anjali"]
LAST_NAMES = ["Sharma","Verma","Patel","Singh","Gupta","Nair","Reddy","Iyer","Yadav","Das"]
CITIES = ["Indore","Bangalore","Ahmedabad","Delhi","Lucknow","Kochi","Hyderabad","Chennai","Patna","Kolkata"]

# Static area codes for grouping people
AREA_CODES = [
    "110001",  # Delhi North
    "110002",  # Delhi South  
    "400001",  # Mumbai Central
    "400002",  # Mumbai West
    "560001",  # Bangalore East
    "560002",  # Bangalore West
    "380001",  # Ahmedabad North
    "380002",  # Ahmedabad South
    "500001",  # Hyderabad Central
    "500002"   # Hyderabad East
]

ADDRESSES = [
    "123 MG Road, Sector 7",
    "456 Park Avenue, Block 3", 
    "789 Lake View Apartments",
    "321 Palm Street, Flat 102",
    "654 Green Valley Colony",
    "987 River Side Road",
    "147 Hill Top Residency",
    "258 Sunshine Enclave",
    "369 Garden View Layout",
    "753 City Center Plaza"
]

def ensure_data_folder():
    if not os.path.exists("data"):
        os.makedirs("data")

def clear_old_files():
    files = ["master.csv", "customer.dat", "meter.dat", "bill.dat"]
    for f in files:
        path = os.path.join("data", f)
        if os.path.exists(path):
            os.remove(path)
            print(f"Deleted old file: {path}")

def generate_master_data(n):
    data = []
    
    # Randomly assign area codes to people (not evenly distributed)
    for i in range(n):
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        city = random.choice(CITIES)
        area = random.choice(AREA_CODES)  # Random selection from static area codes
        address = random.choice(ADDRESSES)
        prev = random.randint(50, 300)
        curr = prev + random.randint(10, 100)

        data.append([
            first,
            last,
            area,
            address,
            city,
            prev,
            curr
        ])
    return data

def write_master_csv(data):
    with open("data/master.csv", "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([
            "first_name",
            "last_name",
            "area_code",
            "address_line",
            "city",
            "prev_read",
            "curr_read"
        ])
        writer.writerows(data)

def pad(value, length):
    return str(value).ljust(length)[:length]

def create_customer_file(data):
    with open("data/customer.dat", "w") as f:
        for row in data:
            first, last, area, address, city, prev, curr = row
            units = curr - prev

            record = (
                first[:10].ljust(10) +
                last[:10].ljust(10) +
                area[:6].ljust(6) +
                " " +
                address[:29].ljust(29) +
                city[:10].ljust(10) +
                str(units)[:5].ljust(5)
            )
            f.write(record + "\n")

def create_meter_file(data):
    with open("data/meter.dat", "w") as f:
        for row in data:
            _, _, _, _, _, prev, curr = row

            record = (
                pad(prev, 6) +
                pad(curr, 6)
            )
            f.write(record + "\n")

def create_bill_file(data, rate=5):
    with open("data/bill.dat", "w") as f:
        for row in data:
            first, last, _, _, _, prev, curr = row
            units = curr - prev
            amount = units * rate

            record = (
                first[:10].ljust(10) +
                last[:10].ljust(10) +
                str(units)[:5].ljust(5) +
                str(amount)[:8].rjust(8)
            )
            f.write(record + "\n")

def main():
    n = 100
    
    ensure_data_folder()
    clear_old_files()
    
    data = generate_master_data(n)

    write_master_csv(data)
    create_customer_file(data)
    create_meter_file(data)
    create_bill_file(data)
    print("Files generated in data/ folder with digits only format")

if __name__ == "__main__":
    main()