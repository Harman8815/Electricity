import random
import datetime


# =============================================================================
# Customer Record Generator
# =============================================================================
# CUSTOMER Table Schema (per readme.md ER diagram):
#   cust_id          X(9)   - Format: XXYY-#### (AreaCode + Sequence)
#   first_name       X(15)  - Customer first name
#   last_name        X(15)  - Customer last name
#   area_code        X(7)   - Area identifier
#   address_line_1   X(30)  - Street address
#   address_line_2   X(30)  - City/State
#   city             X(20)  - City name
#   total_units      X(10)  - Total units consumed
#   status           X(10)  - Active/Inactive
# =============================================================================

FIRST_NAMES = [
    "James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda",
    "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph",
    "Jessica", "Thomas", "Sarah", "Charles", "Karen", "Christopher", "Nancy",
    "Daniel", "Lisa", "Matthew", "Betty", "Anthony", "Margaret", "Mark", "Sandra"
]

LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
    "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson",
    "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson"
]

STREETS = [
    "Main Street", "Oak Avenue", "Park Road", "Elm Street", "Washington Ave",
    "Lake View Drive", "Maple Lane", "Cedar Court", "Pine Street", "Broadway",
    "Market Street", "River Road", "Highland Ave", "Forest Drive", "Church Street"
]

CITIES = [
    "Springfield", "Franklin", "Greenville", "Madison", "Clayton", "Georgetown",
    "Salem", "Riverside", "Fairview", "Kingston", "Auburn", "Bristol", "Clinton",
    "Dayton", "Elkton", "Fulton", "Hamilton", "Irvington", "Jackson", "Lincoln"
]

AREA_CODES = ["AR01", "AR02", "BR01", "BR02", "CR01", "CR02", "DR01", "DR02"]


def format_field(value, length):
    """Format value to fixed length, left-justified."""
    return str(value).ljust(length)[:length]


def generate_customer_record(index):
    """Generate a customer record."""
    
    # Generate Customer ID: Area Code + 4-digit sequence
    area_code = random.choice(AREA_CODES)
    cust_seq = 1001 + (index % 999)
    cust_id = f"{area_code}-{cust_seq:04d}"
    
    # Generate Name
    first_name = random.choice(FIRST_NAMES)
    last_name = random.choice(LAST_NAMES)
    
    # Generate Address
    address_line_1 = f"{random.randint(100, 9999)} {random.choice(STREETS)}"
    city = random.choice(CITIES)
    state = random.choice(["CA", "TX", "FL", "NY", "PA", "IL", "OH", "GA", "NC", "MI"])
    address_line_2 = f"{city}, {state} {random.randint(10000, 99999)}"
    
    # Total units consumed (initially 0 for new customers)
    total_units = "0"
    
    # Status
    status = random.choice(["ACTIVE", "INACTIVE"])
    
    # Build fixed-width record
    record = (
        format_field(cust_id, 9) +           # 9 bytes
        format_field(first_name, 15) +       # 15 bytes
        format_field(last_name, 15) +        # 15 bytes
        format_field(area_code, 7) +         # 7 bytes
        format_field(address_line_1, 30) +   # 30 bytes
        format_field(address_line_2, 30) +   # 30 bytes
        format_field(city, 20) +             # 20 bytes
        format_field(total_units, 10) +      # 10 bytes
        format_field(status, 10)             # 10 bytes
    )
    
    return record


# =============================================================================
# File Generation
# =============================================================================

if __name__ == "__main__":
    
    with open("customer_fixed_200.txt", "w") as f:
        for i in range(200):
            f.write(generate_customer_record(i) + "\n")
    
    print("=" * 60)
    print("Generated customer_fixed_200.txt")
    print("=" * 60)
    print(f"Record size: 146 bytes (fixed width)")
    print(f"  - CUST_ID:       9 bytes")
    print(f"  - FIRST_NAME:    15 bytes")
    print(f"  - LAST_NAME:     15 bytes")
    print(f"  - AREA_CODE:     7 bytes")
    print(f"  - ADDRESS_LINE_1: 30 bytes")
    print(f"  - ADDRESS_LINE_2: 30 bytes")
    print(f"  - CITY:          20 bytes")
    print(f"  - TOTAL_UNITS:   10 bytes")
    print(f"  - STATUS:        10 bytes")
    print("=" * 60)
    print("Total records: 200")
    print("=" * 60)
