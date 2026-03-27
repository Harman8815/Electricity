# HIGHCONSDB2 - Top 5 Highest Consuming Customers Report

## Overview

**Program:** `HIGHCONSDB2`  
**Source:** `highconsdb2.cobol`  
**Purpose:** Identifies and reports the top 5 highest electricity consuming customers using tiered billing rates

## What This Program Does

1. **Connects to DB2** database (`ELECTDB`)
2. **Reads all transaction records** (meter readings) from sequential file
3. **For each transaction:**
   - Fetches meter from DB2 METER table using METER_ID
   - Fetches customer from DB2 CUSTOMER table using CUST_ID
   - Calculates consumption = Current Reading - Previous Reading
   - Applies **tiered billing rates**:
     - 0-100 units: 3.50 per unit
     - 101-300 units: 5.50 per unit
     - 301-500 units: 5.50 per unit
     - 501+ units: 7.50 per unit (flagged as HIGH)
4. **Maintains TOP 5 list** of highest consumers in memory
5. **Generates formatted report** showing:
   - Top 5 customers ranked by consumption
   - Consumption levels and bill amounts
   - Status indicators (NORMAL, MEDIUM, HIGH ALERT)
   - Summary statistics

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
| `HIGHRPT` | Output report file | RECFM=FBA, LRECL=133 |

### Transaction File Format (29 bytes)
| Field | Position | Length | Description |
|-------|----------|--------|-------------|
| METER_ID | 1-14 | 14 | Meter identifier |
| READ_DATE | 15-24 | 10 | Reading date (YYYY-MM-DD) |
| PREV_READ | 25-33 | 9(7)V99 | Previous reading |
| CURR_READ | 34-42 | 9(7)V99 | Current reading |

### Tiered Rate Structure
| Consumption Range | Rate per Unit | Classification |
|-------------------|---------------|----------------|
| 0 - 100 units | 3.50 | Low |
| 101 - 300 units | 5.50 | Medium |
| 301 - 500 units | 5.50 | Medium |
| 501+ units | 7.50 | High |

## JCL to Execute

```jcl
//HIGHCONS JOB 'TOP 5 REPORT','DB2 REPORT',CLASS=A,MSGCLASS=H,
//         NOTIFY=&SYSUID,MSGLEVEL=(1,1)
//*
//* STEP 1: COMPILE AND LINK COBOL PROGRAM
//*--------------------------------------------------------------------
//COBOL    EXEC PGM=IGYCRCTL,PARM='SQL,APOST,DYNAM,RENT'
//STEPLIB  DD DSN=IGY.SIGYCOMP,DISP=SHR
//         DD DSN=DSN.V12R1.SDSNLOAD,DISP=SHR
//SYSIN    DD DSN=YOUR.COBOL.SOURCE(HIGHCONSDB2),DISP=SHR
//SYSLIB   DD DSN=DSN.V12R1.SDSNMACS,DISP=SHR
//DBRMLIB  DD DSN=YOUR.DBRMLIB(HIGHCONSDB2),DISP=SHR
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
//SYSLMOD  DD DSN=YOUR.LOADLIB(HIGHCONSDB2),DISP=SHR
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
    BIND PACKAGE(YOURCOLL) MEMBER(HIGHCONSDB2) ACT(REP) -
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
//HIGHRPT  DD DSN=YOUR.OUTPUT.HIGHRPT,DISP=(NEW,CATLG,DELETE),
//         SPACE=(CYL,(5,2),RLSE),
//         DCB=(RECFM=FBA,LRECL=133,BLKSIZE=27930)
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CEEDUMP  DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
    DSN SYSTEM(YOURDB2)
    RUN PROGRAM(HIGHCONSDB2) PLAN(YOURPLAN) LIB('YOUR.LOADLIB')
    END
/*
//*
```

## Expected Output

### Console Messages
```
TOP 5 HIGHEST CONSUMING CUSTOMERS REPORT COMPLETE
TOTAL PROCESSED: 000200
HIGH CONSUMERS (>500): 00023

TOP 5 CUSTOMERS:
RANK 01: ABKODEL123456 - 001234.56 UNITS
RANK 02: RJSHDEL789012 - 001187.45 UNITS
RANK 03: SKMABOM456789 - 001023.78 UNITS
RANK 04: VKCHCHE654321 - 000956.34 UNITS
RANK 05: NNGABAN987654 - 000845.67 UNITS
```

### Report Format (133 characters)
```
  ABC ELECTRICITY - TOP 5 HIGHEST CONSUMING CUSTOMERS    DATE: 26-03-2026    PAGE: 01
---------------------------------------------------------------------------------
HIGH CONSUMPTION THRESHOLD: > 500 UNITS

RANK  CUSTOMER ID   CUSTOMER NAME         AREA       METER ID        CONSUMPTION   BILL AMOUNT      STATUS       
----  -----------   -------------         -----      --------        -----------   -----------      --------       
  1   ABKODEL123456 ABHINAV KODURU        DELHI01    MTR-AB031596847      1,234.56    $9,259.20   HIGH ALERT   
  2   RJSHDEL789012 RAJESH SHARMA         DELHI01    MTR-RS071234567      1,187.45    $8,905.88   HIGH ALERT   
  3   SKMABOM456789 SURESH KUMAR          BOMBAY02   MTR-SK041596847      1,023.78    $7,678.35   HIGH ALERT   
  4   VKCHCHE654321 VIJAY KUMAR           CHENNAI03  MTR-VK051234567        956.34    $7,172.55   HIGH ALERT   
  5   NNGABAN987654 NARENDRA GUPTA        BANGAL04   MTR-NG081596847        845.67    $6,342.53   HIGH ALERT   

---------------------------------------------------------------------------------
*** SUMMARY ***                                                         
                                      200 PROCESSED    23 HIGH >500  
```

### Expected Results
| Metric | Expected Value |
|--------|---------------|
| Total Processed | All transactions in input file |
| High Consumers (>500) | Customers with consumption > 500 units |
| Top 5 Ranking | Sorted by consumption descending |
| Bill Calculation | Uses tiered rates based on consumption |

### Status Indicators
| Status | Consumption Range | Description |
|--------|-------------------|-------------|
| NORMAL | 0 - 300 units | Standard consumption |
| MEDIUM | 301 - 500 units | Above average |
| HIGH ALERT | 501+ units | Flagged for attention |

### Error Conditions Handled
| SQLCODE | Meaning | Action |
|---------|---------|--------|
| 0 | Success | Add to TOP 5 consideration |
| 100 | No data | Skip record |
| Other | DB2 Error | Log and continue |

### Output Files
1. **Report File** - Top 5 customers report

## Troubleshooting

### Less Than 5 Customers in Report
- Check if fewer than 5 customers have valid readings
- Verify transaction file has matching meter IDs

### All Zero Consumption
- Check transaction file format
- Verify CURR_READ > PREV_READ in all records

### Wrong Bill Amounts
- Verify tiered rate thresholds in code
- Check arithmetic calculations

### SQLCODE -904 (Resource Unavailable)
- DB2 table may be locked
- Wait and retry

## Notes

- TOP 5 list maintained in memory using array with shifting logic
- When new high consumer found, entries shift down
- Threshold of 500 units for "HIGH ALERT" status
- Rates are hardcoded; modify source to change
