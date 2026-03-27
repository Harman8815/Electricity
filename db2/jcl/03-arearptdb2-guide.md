# AREARPTDB2 - Area Wise Consumption Report

## Overview

**Program:** `AREARPTDB2`  
**Source:** `arearptdb2.cobol`  
**Purpose:** Generates area-wise electricity consumption report by reading from DB2 CUSTOMER table and transaction file

## What This Program Does

1. **Connects to DB2** database (`ELECTDB`)
2. **Opens cursor on CUSTOMER table** to fetch all customers ordered by area code
3. **Reads transaction records** (meter readings) from sequential file
4. **For each customer:**
   - Fetches associated meter from DB2 METER table
   - Matches meter readings from transaction file
   - Calculates consumption and bill amount (rate: 5.50)
5. **Generates formatted report** with:
   - Area-wise customer details
   - Consumption and bill amounts
   - Area subtotals
   - Grand totals

## Prerequisites

### Required DB2 Tables
```sql
CREATE TABLE CUSTOMER (
    CUST_ID              CHAR(14),
    FIRST_NAME           CHAR(15),
    LAST_NAME            CHAR(15),
    AREA_CODE            CHAR(7),
    ADDRESS_LINE_1       CHAR(30),
    ADDRESS_LINE_2       CHAR(30),
    CITY                 CHAR(20),
    TOTAL_UNITS_CONSUMED CHAR(10),
    STATUS               CHAR(10)
);

CREATE TABLE METER (
    METER_ID      CHAR(14),
    CUST_ID       CHAR(14),
    INSTALL_DATE  CHAR(12),
    STATUS        CHAR(1)
);
```

### Required Datasets
| DD Name | Description | DCB Attributes |
|---------|-------------|----------------|
| `READTXN` | Meter reading transactions | RECFM=FB, LRECL=29 |
| `REPORTDD` | Output report file | RECFM=FBA, LRECL=133 |

### Transaction File Format (29 bytes)
| Field | Position | Length | Description |
|-------|----------|--------|-------------|
| METER_ID | 1-14 | 14 | Meter identifier |
| READ_DATE | 15-24 | 10 | Reading date (YYYY-MM-DD) |
| PREV_READ | 25-33 | 9(7)V99 | Previous reading |
| CURR_READ | 34-42 | 9(7)V99 | Current reading |

## JCL to Execute

```jcl
//AREARPT  JOB 'AREA REPORT','DB2 REPORT',CLASS=A,MSGCLASS=H,
//         NOTIFY=&SYSUID,MSGLEVEL=(1,1)
//*
//* STEP 1: COMPILE AND LINK COBOL PROGRAM
//*--------------------------------------------------------------------
//COBOL    EXEC PGM=IGYCRCTL,PARM='SQL,APOST,DYNAM,RENT'
//STEPLIB  DD DSN=IGY.SIGYCOMP,DISP=SHR
//         DD DSN=DSN.V12R1.SDSNLOAD,DISP=SHR
//SYSIN    DD DSN=YOUR.COBOL.SOURCE(AREARPTDB2),DISP=SHR
//SYSLIB   DD DSN=DSN.V12R1.SDSNMACS,DISP=SHR
//DBRMLIB  DD DSN=YOUR.DBRMLIB(AREARPTDB2),DISP=SHR
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
//SYSLMOD  DD DSN=YOUR.LOADLIB(AREARPTDB2),DISP=SHR
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
    BIND PACKAGE(YOURCOLL) MEMBER(AREARPTDB2) ACT(REP) -
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
//READTXN  DD DSN=YOUR.INPUT.READINGS,DISP=SHR
//REPORTDD DD DSN=YOUR.OUTPUT.AREARPT,DISP=(NEW,CATLG,DELETE),
//         SPACE=(CYL,(10,5),RLSE),
//         DCB=(RECFM=FBA,LRECL=133,BLKSIZE=27930)
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CEEDUMP  DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
    DSN SYSTEM(YOURDB2)
    RUN PROGRAM(AREARPTDB2) PLAN(YOURPLAN) LIB('YOUR.LOADLIB')
    END
/*
//*
```

## Expected Output

### Console Messages
```
----------------------------------------
AREA WISE CONSUMPTION REPORT COMPLETE
TOTAL CUSTOMERS: 000185
TOTAL UNITS: 00000452917.35
TOTAL AMOUNT: $249,104.54
```

### Report Format (133 characters)
```
     ABC ELECTRICITY - AREA WISE CONSUMPTION REPORT    DATE: 26-03-2026    PAGE: 01
---------------------------------------------------------------------------------
AREA CODE   CUSTOMER ID  CUSTOMER NAME       METER ID        CONSUMPTION  BILL AMOUNT   STATUS      
---------   -----------  -------------       --------        ---------    -----------   --------    
DELHI01   ABKODEL123456  ABHINAV KODURU      MTR-AB031596847      552.35    $3,037.93   BILLED      
DELHI01   RJSHDEL789012  RAJESH SHARMA       MTR-RS071234567      325.50    $1,790.25   BILLED      
...
*** AREA TOTAL ***                      45 CUSTOMERS           12,345.67    $67,901.19
...
*** GRAND TOTAL ***                     185 CUSTOMERS          45,291.35  $249,104.54
```

### Expected Results
| Metric | Expected Value |
|--------|---------------|
| Total Customers | All active customers with valid meters/readings |
| Area Breakdown | Customers grouped by AREA_CODE |
| Calculation | Consumption = Current - Previous; Bill = Consumption × 5.50 |
| Status Values | BILLED, NO METER, NO READING, DB2 ERROR |

### Status Indicators
| Status | Meaning |
|--------|---------|
| BILLED | Successfully calculated bill |
| NO METER | Customer has no meter in DB2 |
| NO READING | Meter found but no matching transaction |
| DB2 ERROR | Database error during meter fetch |

### Error Conditions Handled
| SQLCODE | Meaning | Action |
|---------|---------|--------|
| 0 | Success | Process normally |
| 100 | No data | Display appropriate status |
| Other | DB2 Error | Log and continue |

### Output Files
1. **Report File** - Formatted area-wise consumption report

## Troubleshooting

### SQLCODE -501 (Cursor Not Open)
- Check DB2 connection established
- Verify cursor declared and opened

### No Customers Reported
- Verify CUSTOMER table has data
- Check AREA_CODE values are populated

### Zero Consumption for All
- Verify READTXN file matches meter IDs in DB2
- Check transaction file format

### Report Format Issues
- Ensure RECFM=FBA for carriage control
- Verify LRECL=133

## Notes

- Report shows customers sorted by AREA_CODE then CUST_ID
- New page header printed every 55 lines
- Area totals printed when area code changes
- Unit rate is hardcoded at 5.50
