# ELECTDB2 - Customer Data Load Program

## Overview

**Program:** `ELECTDB2`  
**Source:** `electdb2.cobol`  
**Purpose:** Reads customer data from sequential file and inserts into DB2 CUSTOMER table

## What This Program Does

1. **Connects to DB2** database (`ELECTDB`)
2. **Reads customer records** from input file
3. **Validates data** (checks for empty name/city fields)
4. **Generates unique Customer IDs** using algorithm: `FN(2) + LN(2) + AreaCode(4) + RAND(4)` = 12 chars
5. **Inserts valid records** into DB2 CUSTOMER table
6. **Writes error records** to error file for invalid data

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
```

### Required Datasets
| DD Name | Description | DCB Attributes |
|---------|-------------|----------------|
| `CUSTFILE` | Input customer data file | RECFM=FB, LRECL=137 |
| `CUSTERR` | Output error records | RECFM=FB, LRECL=137 |

### Input File Format (137 bytes)
| Field | Position | Length | Description |
|-------|----------|--------|-------------|
| FIRST_NAME | 1-15 | 15 | Customer first name |
| LAST_NAME | 16-30 | 15 | Customer last name |
| AREA_CODE | 31-37 | 7 | Area code (e.g., DELHI01) |
| ADDRESS_LINE_1 | 38-67 | 30 | Street address |
| LOCALITY | 68-97 | 30 | Locality/area |
| CITY | 98-117 | 20 | City name |
| UNITS | 118-127 | 10 | Total units consumed |
| STATUS | 128-137 | 10 | Customer status |

## JCL to Execute

```jcl
//ELECTDB2 JOB 'CUSTOMER LOAD','DB2 LOAD',CLASS=A,MSGCLASS=H,
//         NOTIFY=&SYSUID,MSGLEVEL=(1,1)
//*
//* STEP 1: COMPILE AND LINK COBOL PROGRAM
//*--------------------------------------------------------------------
//COBOL    EXEC PGM=IGYCRCTL,PARM='SQL,APOST,DYNAM,RENT'
//STEPLIB  DD DSN=IGY.SIGYCOMP,DISP=SHR
//         DD DSN=DSN.V12R1.SDSNLOAD,DISP=SHR
//SYSIN    DD DSN=YOUR.COBOL.SOURCE(ELECTDB2),DISP=SHR
//SYSLIB   DD DSN=DSN.V12R1.SDSNMACS,DISP=SHR
//DBRMLIB  DD DSN=YOUR.DBRMLIB(ELECTDB2),DISP=SHR
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
//SYSLMOD  DD DSN=YOUR.LOADLIB(ELECTDB2),DISP=SHR
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
    BIND PACKAGE(YOURCOLL) MEMBER(ELECTDB2) ACT(REP) -
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
//CUSTFILE DD DSN=YOUR.INPUT.CUSTOMER,DISP=SHR
//CUSTERR  DD DSN=YOUR.OUTPUT.CUSTERR,DISP=(NEW,CATLG,DELETE),
//         SPACE=(CYL,(5,2),RLSE),
//         DCB=(RECFM=FB,LRECL=137,BLKSIZE=2794)
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CEEDUMP  DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
    DSN SYSTEM(YOURDB2)
    RUN PROGRAM(ELECTDB2) PLAN(YOURPLAN) LIB('YOUR.LOADLIB')
    END
/*
//*
```

## Expected Output

### Console Messages
```
----------------------------------------
ELECTDB2 EXECUTION BEGINS HERE .........
----------------------------------------
----------------------------------------
CUSTOMER INPUT FILE OPENED ..............
CUSTOMER ERROR FILE IS OPENED ..........
----------------------------------------
DB2 CONNECTION ESTABLISHED SUCCESSFULLY
CUSTOMER ID IS ABKODEL123456
CUSTOMER INSERTED SUCCESSFULLY
CUSTOMER ID IS RJSHDEL789012
CUSTOMER INSERTED SUCCESSFULLY
...
----------------------------------------
NO MORE RECORDS IN CUST-FILE    --------
----------------------------------------
----------------------------------------
 INPUT RECORDS PROCESSED    00200
 OUTPUT RECORDS PROCESSED   00195
----------------------------------------
CUSTOMER FILE        IS CLOSED          
CUSTOMER ERROR FILE  IS CLOSED          
----------------------------------------
```

### Expected Results
| Metric | Expected Value |
|--------|---------------|
| Input Records Read | All records in input file |
| Successful Inserts | ~95-99% of input records |
| Error Records | Records with blank name/city fields |
| Duplicate Key Retries | Up to 99 retries per duplicate |

### Error Conditions Handled
| SQLCODE | Meaning | Action |
|---------|---------|--------|
| 0 | Success | Continue |
| -803 | Duplicate Key | Retry with new random ID |
| Other | DB2 Error | Write to error file |

### Output Files
1. **DB2 CUSTOMER Table** - Populated with valid customer records
2. **CUSTERR File** - Contains records that failed validation or DB2 insert

## Troubleshooting

### SQLCODE -805 (Program Not Found)
- Check BIND step completed successfully
- Verify PLAN name matches

### SQLCODE -922 (Authorization Error)
- Verify user has INSERT privilege on CUSTOMER table
- Check DB2 connection credentials

### File Status Errors
| Status | Meaning | Solution |
|--------|---------|----------|
| 35 | File not found | Verify CUSTFILE dataset exists |
| 93 | File in use | Wait and retry |
