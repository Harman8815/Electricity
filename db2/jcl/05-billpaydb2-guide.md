# BILLPAYDB2 - Bill Payment Status Report

## Overview

**Program:** `BILLPAYDB2`  
**Source:** `billpaydb2.cobol`  
**Purpose:** Processes bill payments from input file, matches against DB2 BILL table, updates payment status, and generates detailed payment status report

## What This Program Does

1. **Connects to DB2** database (`ELECTDB`)
2. **Opens cursor on BILL table** to fetch all bills ordered by BILL_ID
3. **Reads payment records** from sequential file (sorted by BILL_ID)
4. **For each bill:**
   - Reads all payments for that bill ID from file
   - Calculates total paid amount
   - Determines payment status:
     - **D** (Due) = No payments made
     - **PP** (Partially Paid) = Some payment but less than bill amount
     - **P** (Paid) = Payment equals or exceeds bill amount
   - **Inserts updated record** into BILL_UPDATE table
5. **Generates formatted report** with:
   - Bill details with payment status
   - Payment count per bill
   - Summary statistics

## Prerequisites

### Required DB2 Tables
```sql
CREATE TABLE BILL (
    BILL_ID      CHAR(14),
    CUST_ID      CHAR(14),
    FIRST_NAME   CHAR(15),
    LAST_NAME    CHAR(15),
    UNITS        DECIMAL(10),
    AMOUNT       DECIMAL(10),
    STATUS       CHAR(4)
);

CREATE TABLE BILL_UPDATE (
    BILL_ID      CHAR(14),
    CUST_ID      CHAR(14),
    FIRST_NAME   CHAR(15),
    LAST_NAME    CHAR(15),
    UNITS        DECIMAL(10),
    AMOUNT       DECIMAL(10),
    PAID         DECIMAL(10),
    BALANCE      DECIMAL(10),
    STATUS       CHAR(4)
);
```

### Required Datasets
| DD Name | Description | DCB Attributes |
|---------|-------------|----------------|
| `PAYMENT` | Payment transaction file | RECFM=FB, LRECL=33 |
| `PAYRPT` | Output report file | RECFM=FBA, LRECL=133 |

### Payment File Format (33 bytes)
| Field | Position | Length | Description |
|-------|----------|--------|-------------|
| PAYMENT_ID | 1-8 | 8 | Payment transaction ID |
| BILL_ID | 9-22 | 14 | Associated bill ID |
| AMOUNT | 23-32 | 9(7)V99 | Payment amount |
| DATE | 33-42 | 10 | Payment date (YYYY-MM-DD) |

## JCL to Execute

```jcl
//BILLPAY  JOB 'PAYMENT STATUS','DB2 UPDATE',CLASS=A,MSGCLASS=H,
//         NOTIFY=&SYSUID,MSGLEVEL=(1,1)
//*
//* STEP 1: COMPILE AND LINK COBOL PROGRAM
//*--------------------------------------------------------------------
//COBOL    EXEC PGM=IGYCRCTL,PARM='SQL,APOST,DYNAM,RENT'
//STEPLIB  DD DSN=IGY.SIGYCOMP,DISP=SHR
//         DD DSN=DSN.V12R1.SDSNLOAD,DISP=SHR
//SYSIN    DD DSN=YOUR.COBOL.SOURCE(BILLPAYDB2),DISP=SHR
//SYSLIB   DD DSN=DSN.V12R1.SDSNMACS,DISP=SHR
//DBRMLIB  DD DSN=YOUR.DBRMLIB(BILLPAYDB2),DISP=SHR
//SYSLIN   DD DSN=&&LOADSET,DISP=(MOD,PASS),UNIT=SYSDA,
//         SPACE=(CYL,(1,1))
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
//* STEP 2: LINK EDIT
//*--------------------------------------------------------------------
//LKED     EXEC PGM=IEWL,PARM='XREF,LET,LIST,MAP',
//         COND=(0,NE,COBOL)
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//         DD DSN=DSN.V12R1.SDSNLOAD,DISP=SHR
//SYSLIN   DD DSN=&&LOADSET,DISP=(OLD,DELETE)
//         DD DDNAME=SYSIN
//SYSLMOD  DD DSN=YOUR.LOADLIB(BILLPAYDB2),DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
//* STEP 3: BIND PACKAGE
//*--------------------------------------------------------------------
//BIND     EXEC PGM=IKJEFT01,DYNAMNBR=20
//STEPLIB  DD DSN=DSN.V12R1.SDSNLOAD,DISP=SHR
//DBRMLIB  DD DSN=YOUR.DBRMLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
    DSN SYSTEM(YOURDB2)
    BIND PACKAGE(YOURCOLL) MEMBER(BILLPAYDB2) ACT(REP) -
         ISO(CS) ENCODING(EBCDIC) VALIDATE(RUN)
    END
/*
//*
//* STEP 4: EXECUTE PROGRAM
//*--------------------------------------------------------------------
//RUN      EXEC PGM=IKJEFT01
//STEPLIB  DD DSN=YOUR.LOADLIB,DISP=SHR
//         DD DSN=DSN.V12R1.SDSNEXIT,DISP=SHR
//         DD DSN=DSN.V12R1.SDSNLOAD,DISP=SHR
//PAYMENT  DD DSN=YOUR.INPUT.PAYMENTS,DISP=SHR
//PAYRPT   DD DSN=YOUR.OUTPUT.PAYRPT,DISP=(NEW,CATLG,DELETE),
//         SPACE=(CYL,(10,5),RLSE),
//         DCB=(RECFM=FBA,LRECL=133,BLKSIZE=27930)
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CEEDUMP  DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
    DSN SYSTEM(YOURDB2)
    RUN PROGRAM(BILLPAYDB2) PLAN(YOURPLAN) LIB('YOUR.LOADLIB')
    END
/*
//*
```

## Expected Output

### Console Messages
```
BILL PAYMENT STATUS PROCESSING COMPLETE
TOTAL BILLS: 00150
DUE: 00025
PARTIALLY PAID: 00045
FULLY PAID: 00080
PAYMENTS PROCESSED: 00215
TOTAL BILL AMOUNT: 000000824567.34
TOTAL PAID: 000000695432.18
TOTAL BALANCE: 000000129135.16
```

### Report Format (133 characters)
```
  ABC ELECTRICITY - BILL PAYMENT STATUS REPORT    DATE: 26-03-2026    PAGE: 01
---------------------------------------------------------------------------------
BILL ID       CUSTOMER ID   BILL AMOUNT       PAID AMOUNT   BALANCE DUE    STATUS       PAYMENTS  
------------- -----------   -----------       -----------   -----------    --------     --------  
BILL001234567 CUST12345678     $1,234.56          $1,234.56          $0.00   P            1
BILL001234568 CUST12345679     $2,345.67          $1,000.00      $1,345.67   PP           1
BILL001234569 CUST12345680     $3,456.78              $0.00      $3,456.78   D            0
BILL001234570 CUST12345681     $1,567.89          $2,000.00        -$432.11   P            2
...
---------------------------------------------------------------------------------
*** PAYMENT STATUS SUMMARY ***           
DUE (D):              25    PARTIAL (PP):              45    PAID (P):              80

---------------------------------------------------------------------------------
*** GRAND TOTAL ***                      
   150 BILLS       $82,456.74      $69,543.22    $12,913.52
```

### Expected Results
| Metric | Expected Value |
|--------|---------------|
| Total Bills | All bills from BILL table |
| D (Due) | Bills with zero payments |
| PP (Partially Paid) | Bills with some but insufficient payment |
| P (Paid) | Bills fully or over-paid |
| Payments Processed | Total payment records read |
| Total Bill Amount | Sum of all bill amounts |
| Total Paid | Sum of all payment amounts |
| Total Balance | Bill Amount - Paid Amount |

### Status Codes
| Status | Meaning | Calculation |
|--------|---------|-------------|
| D | Due | PAID = 0 |
| PP | Partially Paid | 0 < PAID < AMOUNT |
| P | Paid | PAID >= AMOUNT |

### Error Conditions Handled
| SQLCODE | Meaning | Action |
|---------|---------|--------|
| 0 | Success | Continue |
| 100 | End of cursor | Stop processing |
| Other | DB2 Error | Log and continue |

### Output Files
1. **Report File** - Payment status report
2. **BILL_UPDATE Table** - Updated bill records with payment info

## Troubleshooting

### SQLCODE -803 on Insert
- BILL_UPDATE table may already have records
- Clear table or use REPLACE option

### Payments Not Matching Bills
- Verify PAYMENT file is sorted by BILL_ID (ascending)
- Check BILL_ID format matches between tables and file

### Wrong Balance Calculations
- Verify AMOUNT field is numeric
- Check payment amounts are positive

### Missing Bills in Report
- Verify BILL table has records
- Check cursor opened successfully

## Notes

- Payment file must be sorted by BILL_ID for matching logic to work
- Each bill can have multiple payments (one-to-many relationship)
- Overpayments result in negative balance
- BILL_UPDATE table serves as audit trail of payment processing
- Report shows overpayments with negative balance (e.g., -$432.11)
