# METERDB2 - Meter Data Load Program

## Overview

**Program:** `METERDB2`  
**Source:** `meterdb2.cobol`  
**Purpose:** Reads meter data from sequential file and inserts into DB2 METER table with consumption calculations

## What This Program Does

1. **Connects to DB2** database (`ELECTDB`)
2. **Reads meter records** from input file
3. **Validates data** (checks for empty meter ID)
4. **Generates unique Meter IDs** using algorithm: `MTR- + chars + date + random`
5. **Inserts valid records** into DB2 METER table
6. **Calculates consumption data** for each meter (simulated readings)
7. **Writes error records** to error file

## Prerequisites

### Required DB2 Tables
```sql
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
| `METERIN` | Input meter data file | RECFM=FB, LRECL=21 |
| `METERERR` | Output error records | RECFM=FB, LRECL=20 |

### Input File Format (21 bytes)
| Field | Position | Length | Description |
|-------|----------|--------|-------------|
| METER_ID | 1-7 | 7 | Original meter ID |
| (FILLER) | 8-9 | 2 | Spaces |
| INSTALL_DATE | 10-19 | 10 | Installation date (YYYY-MM-DD) |
| (FILLER) | 20 | 1 | Space |
| STATUS | 21 | 1 | Meter status (A=Active, I=Inactive) |

## JCL to Execute

```jcl
//METERDB2 JOB 'METER LOAD','DB2 LOAD',CLASS=A,MSGCLASS=H,
//         NOTIFY=&SYSUID,MSGLEVEL=(1,1)
//*
//* STEP 1: COMPILE AND LINK COBOL PROGRAM
//*--------------------------------------------------------------------
//COBOL    EXEC PGM=IGYCRCTL,PARM='SQL,APOST,DYNAM,RENT'
//STEPLIB  DD DSN=IGY.SIGYCOMP,DISP=SHR
//         DD DSN=DSN.V12R1.SDSNLOAD,DISP=SHR
//SYSIN    DD DSN=YOUR.COBOL.SOURCE(METERDB2),DISP=SHR
//SYSLIB   DD DSN=DSN.V12R1.SDSNMACS,DISP=SHR
//DBRMLIB  DD DSN=YOUR.DBRMLIB(METERDB2),DISP=SHR
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
//SYSLMOD  DD DSN=YOUR.LOADLIB(METERDB2),DISP=SHR
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
    BIND PACKAGE(YOURCOLL) MEMBER(METERDB2) ACT(REP) -
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
//METERIN  DD DSN=YOUR.INPUT.METER,DISP=SHR
//METERERR DD DSN=YOUR.OUTPUT.METERERR,DISP=(NEW,CATLG,DELETE),
//         SPACE=(CYL,(5,2),RLSE),
//         DCB=(RECFM=FB,LRECL=20,BLKSIZE=2794)
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//CEEDUMP  DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
    DSN SYSTEM(YOURDB2)
    RUN PROGRAM(METERDB2) PLAN(YOURPLAN) LIB('YOUR.LOADLIB')
    END
/*
//*
```

## Expected Output

### Console Messages
```
----------------------------------------
METERDB2 EXECUTION BEGINS HERE .........
----------------------------------------
----------------------------------------
METER INPUT FILE OPENED ...............
METER ERROR FILE IS OPENED ..........
----------------------------------------
DB2 CONNECTION ESTABLISHED SUCCESSFULLY
ATTEMPTING METER ID : MTR-AB031596847
METER INSERTED SUCCESSFULLY: MTR-AB031596847
  CONSUMPTION DATA FOR METER: MTR-AB031596847
    Current Reading: 00008457
    Previous Reading: 00002934
    Units Consumed: 00005523
    Unit Rate: 000008.50
    Bill Amount: 000469455.50
ATTEMPTING METER ID : MTR-CD071234567
...
----------------------------------------
NO MORE RECORDS IN METER-FILE    --------
----------------------------------------
----------------------------------------
 INPUT RECORDS PROCESSED    00200
 OUTPUT RECORDS WRITTEN   00198
 DUPLICATE KEY RETRIES    00045
 ERROR RECORDS            00002
----------------------------------------
METER FILE        IS CLOSED          
METER ERROR FILE  IS CLOSED          
----------------------------------------
```

### Expected Results
| Metric | Expected Value |
|--------|---------------|
| Input Records Read | All records in input file |
| Successful Inserts | ~98-99% of input records |
| Duplicate Key Retries | Varies based on ID generation |
| Error Records | Records with blank meter IDs |

### Consumption Calculation
The program simulates meter readings using random number generation:
- **Current Reading**: Random value (0-9999)
- **Previous Reading**: Random value (0-9999)
- **Units Consumed**: Current - Previous
- **Unit Rate**: 8.50 (fixed)
- **Bill Amount**: Units Consumed × Unit Rate

### Error Conditions Handled
| SQLCODE | Meaning | Action |
|---------|---------|--------|
| 0 | Success | Continue |
| -803 | Duplicate Key | Retry up to 100 times |
| Other | DB2 Error | Log error, continue |

### Output Files
1. **DB2 METER Table** - Populated with meter records
2. **METERERR File** - Contains invalid records

## Troubleshooting

### High Duplicate Count
- Increase random seed range in code
- Check if meter IDs are truly unique in input

### Zero Consumption
- Verify random number generation is working
- Check arithmetic logic

### SQLCODE -501 (Cursor Issues)
- Not applicable for this program (uses singleton SELECT)
- Check DB2 connection

## Notes

- Generated Meter ID format: `MTR-XXDDMMRRRR` where:
  - `MTR-` = Fixed prefix
  - `XX` = First 2 chars of input meter ID
  - `DD` = Current day
  - `MM` = Current month  
  - `RRRR` = Random 4 digits
