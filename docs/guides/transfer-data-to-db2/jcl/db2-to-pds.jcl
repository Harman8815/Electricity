//*--------------------------------------------------------------------
//* JCL TO UNLOAD DB2 TABLE TO PDS USING DSNUTILB
//*--------------------------------------------------------------------
//DB22PDS  JOB  'DB2 TO PDS','UNLOAD DATA',CLASS=A,MSGCLASS=H,
//         NOTIFY=&SYSUID,MSGLEVEL=(1,1)
//*
//* STEP 1: UNLOAD DATA FROM DB2 TABLE TO SEQUENTIAL DATASET
//*--------------------------------------------------------------------
//UNLOAD   EXEC PGM=DSNUTILB,PARM='YOURDB2,UNLOAD'
//SYSPRINT DD SYSOUT=*
//UTPRINT  DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSREC   DD DSN=&&UNLOADDS,DISP=(NEW,PASS),
//         SPACE=(CYL,(10,5),RLSE),
//         DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920)
//SYSIN    DD *
    UNLOAD DATA FROM TABLE YOUR_SCHEMA.YOUR_TABLE
    INTO TABLESPACE YOUR_DB.YOUR_TABLESPACE
    ;
/*
//*
//* STEP 2: COPY SEQUENTIAL DATA TO PDS MEMBER USING IEBGENER
//*--------------------------------------------------------------------
//COPY2PDS EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT1   DD DSN=&&UNLOADDS,DISP=(OLD,DELETE)
//SYSUT2   DD DSN=YOUR.PDS.LIBRARY(MEMBER),DISP=SHR
//*
