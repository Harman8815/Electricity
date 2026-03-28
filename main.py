import random
import csv

FIRST_NAMES = ["01","02","03","04","05","06","07","08","09","10"]
LAST_NAMES = ["01","02","03","04","05","06","07","08","09","10"]
CITIES = ["01","02","03","04","05","06","07","08","09","10"]

def generate_master_data(n):
    data = []
    for _ in range(n):
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        city = random.choice(CITIES)
        area = str(random.randint(100000, 999999))
        address = f"{random.randint(1,999):03d}"
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
    with open("master.csv", "w", newline="") as f:
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
    with open("dataset/customer.dat", "w") as f:
        for row in data:
            first, last, area, address, city, prev, curr = row
            units = curr - prev

            record = (
                pad(first, 2) +
                pad(last, 2) +
                pad(area, 6) +
                pad(address, 3) +
                pad(city, 2) +
                pad(units, 3)
            )
            f.write(record + "\n")

def create_meter_file(data):
    with open("dataset/meter.dat", "w") as f:
        for row in data:
            _, _, _, _, _, prev, curr = row

            record = (
                pad(prev, 4) +
                pad(curr, 4)
            )
            f.write(record + "\n")

def create_bill_file(data, rate=5):
    with open("dataset/bill.dat", "w") as f:
        for row in data:
            first, last, _, _, _, prev, curr = row
            units = curr - prev
            amount = units * rate

            record = (
                pad(first, 2) +
                pad(last, 2) +
                pad(units, 3) +
                pad(amount, 5)
            )
            f.write(record + "\n")

def main():
    n = 100
    data = generate_master_data(n)

    write_master_csv(data)
    create_customer_file(data)
    create_meter_file(data)
    create_bill_file(data)
    print("Files generated in dataset/ folder with digits only format")

if __name__ == "__main__":
    main()