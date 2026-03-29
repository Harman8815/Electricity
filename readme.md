
# Electricity Billing System (Mainframe Project)

## Overview

This project is a simple electricity billing system designed for a mainframe environment using COBOL, JCL, and VSAM. The focus is on keeping the system minimal, easy to understand, and straightforward to implement.

The system handles basic customer data, meter readings, and generates a monthly bill based on usage. It avoids unnecessary complexity such as historical data tracking, multiple relationships, or advanced database features.

---

## System Architecture

The system follows a simple linear flow:

Customer → Meter → Bill

- Customer stores user information  
- Meter stores current and previous readings  
- Bill stores calculated data for the current month  

---

## ER Diagram

```mermaid
erDiagram

    CUSTOMER {
        string cust_id PK
        string first_name
        string last_name
        string area_code
        string address_line
        string city
        number total_units
    }

    METER {
        string cust_id PK, FK
        string meter_id
        number prev_read
        number curr_read
    }

    BILL {
        string cust_id PK, FK
        string meter_id
        string first_name
        string last_name
        number units_used
        number bill_amount
    }

    CUSTOMER ||--|| METER : "assigned"
    CUSTOMER ||--|| BILL : "generates"
    METER ||--|| BILL : "used for billing"
````

---

## Table Description

### Customer Table

The Customer table stores basic information about each user. It acts as the main reference point for the entire system.

It includes:

- Unique customer ID
    
- First and last name
    
- Area code
    
- Address
    
- City
    
- Total units consumed so far
    

This table is used whenever customer-related data is required.

---

### Meter Table

The Meter table stores the electricity readings for each customer.

It includes:

- Customer ID
    
- Meter ID
    
- Previous reading
    
- Current reading
    

Only the latest readings are stored. There is no historical tracking, which keeps the design simple and efficient.

---

### Bill Table

The Bill table stores the calculated bill for the current month only.

It includes:

- Customer ID
    
- Meter ID
    
- Customer name (for reporting)
    
- Units consumed
    
- Final bill amount
    

This table is used for generating reports and displaying billing information.

---

## File Format Specifications

### Input Data Files (Python Generated)

| File | LRECL | RECFM | Record Layout |
|------|-------|-------|---------------|
| **customer.dat** | **71** | FB | first_name(10) + last_name(10) + area_code(6) + space(1) + address(29) + city(10) + units(5) |
| **meter.dat** | **12** | FB | prev_read(6) + curr_read(6) |
| **bill.dat** | **33** | FB | first_name(10) + last_name(10) + units(5) + amount(8) |
| **master.csv** | VAR | V | CSV format with header |

### COBOL VSAM Files

| File | LRECL | Type | Description |
|------|-------|------|-------------|
| **CUSTKSDS** | **83** | KSDS | Customer master (CUST-ID 12 + first 10 + last 10 + area 6 + space 1 + addr 29 + city 10 + units 5) |
| **TO01-CUSTOMER-ERR** | **71** | SEQ | Customer error records |
| **MO01-METER-KSDS** | **38** | KSDS | Meter master (MTR-ID 14 + MTR-CUST-ID 12 + prev 6 + curr 6) |
| **TO01-METER-ERR** | **12** | SEQ | Meter error records |

### Field Size Details

| Field | Size | Type | Used In |
|-------|------|------|---------|
| first_name | 10 | X | customer.dat, bill.dat, CUSTKSDS |
| last_name | 10 | X | customer.dat, bill.dat, CUSTKSDS |
| area_code | 6 | X | customer.dat, CUSTKSDS |
| space | 1 | X | Separator between area and address |
| address_line | 29 | X | customer.dat, CUSTKSDS |
| city | 10 | X | customer.dat, CUSTKSDS |
| units | 5 | 9 | customer.dat, bill.dat, CUSTKSDS |
| amount | 8 | 9 | bill.dat |
| prev_read | 6 | 9 | meter.dat |
| curr_read | 6 | 9 | meter.dat |
| CUST-ID | 12 | X | CUSTKSDS (C + fname(2) + lname(2) + area(4) + random(3)) |
| MTR-ID | 14 | X | MTRKSDS (MTR- + cust(2) + DD + MM + random(4)) |

---

# 📘 Data Processing Programs

1. Customer ID Generation
    
2. Meter ID Generation
    
3. Bill Generation
    
4. Area-wise Report
    
5. Highest Units Customer
    

---