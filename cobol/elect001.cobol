       IDENTIFICATION DIVISION.
       PROGRAM-ID.  ELECT.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

           SELECT TI01-CUST-FILE  ASSIGN TO CUSTFILE
           ORGANIZATION           IS SEQUENTIAL
           ACCESS MODE            IS SEQUENTIAL
           FILE STATUS            IS WS-CUST-STATUS.

           SELECT MO01-CUST-KSDS  ASSIGN TO CUSTKSDS
           ORGANIZATION           IS INDEXED
           ACCESS MODE            IS RANDOM
           RECORD KEY             IS CF-O-CUST-ID
           FILE STATUS            IS WS-KSDS-STATUS.

           SELECT TO01-CUST-ERR   ASSIGN TO CUSTERR
           ORGANIZATION           IS SEQUENTIAL
           ACCESS MODE            IS SEQUENTIAL
           FILE STATUS            IS WS-ERR-STATUS.

       DATA DIVISION.

       FILE SECTION.

       FD TI01-CUST-FILE
           RECORD CONTAINS         137   CHARACTERS.

       01 TI01-CUST-RECORD.
          05 IN-FNAME       PIC X(15).
          05 IN-LNAME       PIC X(15).
          05 IN-AREACODE    PIC X(7).
          05 IN-ADDRESS1    PIC X(30).
          05 IN-LOCALITY    PIC X(30).
          05 IN-CITY        PIC X(20).
          05 IN-UNITS       PIC X(10).
          05 IN-STATUS      PIC X(10).

       FD MO01-CUST-KSDS
           RECORD CONTAINS         149   CHARACTERS.

       01 MO01-CUSTOMER-RECORD.
          05 CF-O-CUST-ID  PIC X(12).
          05 OUT-FNAME     PIC X(15).
          05 OUT-LNAME     PIC X(15).
          05 OUT-AREACODE  PIC X(7).
          05 OUT-ADDRESS1  PIC X(30).
          05 OUT-LOCALITY  PIC X(30).
          05 OUT-CITY      PIC X(20).
          05 OUT-UNITS     PIC X(10).
          05 OUT-STATUS    PIC X(10).

       FD TO01-CUST-ERR
           RECORDING MODE          IS F
           RECORD CONTAINS         137  CHARACTERS.

       01 TO01-CUST-ERR-RECORD.
          05 ERR-FNAME       PIC X(15).
          05 ERR-LNAME       PIC X(15).
          05 ERR-AREACODE    PIC X(7).
          05 ERR-ADDRESS1    PIC X(30).
          05 ERR-LOCALITY    PIC X(30).
          05 ERR-CITY        PIC X(20).
          05 ERR-UNITS       PIC X(10).
          05 ERR-STATUS      PIC X(10).

       WORKING-STORAGE SECTION.

       01 WS-FILE-STATUS-CODES.
          05 WS-CUST-STATUS        PIC X(02).
             88 CUST-IO-STATUS     VALUE '00'.
             88 CUST-EOF           VALUE '10'.
             88 CUST-ROW-NOTFND    VALUE '23'.
          05 WS-KSDS-STATUS        PIC X(02).
             88 KSDS-IO-STATUS     VALUE '00'.
             88 KSDS-ROW-NOTFND    VALUE '23'.
          05 WS-ERR-STATUS         PIC X(02).
             88 ERR-IO-STATUS      VALUE '00'.

       01 WS-DATE-VARIABLES.
          05 WS-DATE               PIC 9(08).
          05 WS-DATE-ID REDEFINES WS-DATE.
             10 WS-CC              PIC 99.
             10 WS-YY              PIC 99.
             10 WS-MM              PIC 99.
             10 WS-DD              PIC 99.

       01  WS-RANDOM-NUMBER-GEN.
           05  WS-RAND-SEED        PIC S9(09) COMP-3 VALUE +0.
           05  WS-RAND-RESULT      PIC S9(09) COMP-3 VALUE +0.
           05  WS-RAND-4DIGIT      PIC 9(04)         VALUE 0.
           05  WS-RAND-DISPLAY     PIC X(04)         VALUE SPACES.
           05  WS-ID-RAND          PIC X(04).
           05  WS-RETRY-CTR        PIC 9(02)         VALUE 0.

       01 WS-RAND-NUM-GEN.
          05 WS-RAND-NUM           PIC 9(08).
          05 WS-SEED-VALUE         PIC 9(08).

       01 WS-SUBS.
          05 I                     PIC 9(04) VALUE 1.
          05 J                     PIC 9(04) VALUE 1.

       01 WS-CUST-ID-GEN.
          05 WS-FN-PREFIX        PIC X(2).
          05 WS-LN-PREFIX        PIC X(2).
          05 WS-AREA-PREFIX      PIC X(4).
          05 WS-RAND-4CH         PIC X(4).

       01 WS-ERROR-FLAGS.
          05 WS-ERROR-RECORD-FLAG  PIC 9.
             88 VALID-RECORD-FLAG  VALUE 1.
             88 ERROR-RECORD-FLAG  VALUE 2.

       01 WS-COUNTERS.
          05 WS-READ-CTR           PIC 9(04) VALUE ZEROS.
          05 WS-WRITE-CTR          PIC 9(04) VALUE ZEROS.
          05 WS-UPDT-CTR           PIC 9(04) VALUE ZEROS.
          05 WS-AT-CTR             PIC 9(04) VALUE ZEROS.
          05 WS-PTR                PIC 9(02) VALUE ZEROS.

       PROCEDURE DIVISION.
       0000-MAIN-LINE   SECTION.

           PERFORM 1000-INITIALIZE.

           PERFORM 2000-PROCESS.

           PERFORM 9000-TERMINATE.

       1000-INITIALIZE  SECTION.

           DISPLAY '----------------------------------------'
           DISPLAY 'PCIB0010 EXECUTION BEGINS HERE .........'
           DISPLAY '----------------------------------------'

           ACCEPT WS-DATE FROM DATE YYYYMMDD.

       2000-PROCESS     SECTION.

           PERFORM 2100-OPEN-FILES.

           PERFORM 2200-READ-CUST-FILE UNTIL CUST-EOF.

       2100-OPEN-FILES  SECTION.

           OPEN INPUT TI01-CUST-FILE.
           IF NOT CUST-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING CUSTOMER INPUT FILE       '
              DISPLAY 'FILE  STATUS ', ' ',    WS-CUST-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           OPEN OUTPUT MO01-CUST-KSDS
           IF NOT KSDS-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING CUSTOMER LSDS MASTER      '
              DISPLAY 'FILE  STATUS ', ' ',    WS-KSDS-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           OPEN OUTPUT TO01-CUST-ERR
           IF NOT ERR-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING CUSTOMER ERR  FILE        '
              DISPLAY 'FILE  STATUS ', ' ',    WS-ERR-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           DISPLAY '----------------------------------------'
           DISPLAY 'CUSTOMERINPUT FILE OPENED ..............'
           DISPLAY 'CUSTOMER MASTER KSDS IS OPENED .........'
           DISPLAY 'CUSTOMER ERROR FILE IS OPENED ..........'
           DISPLAY '----------------------------------------'
           .

       2200-READ-CUST-FILE  SECTION.

           READ TI01-CUST-FILE

                AT END  SET CUST-EOF TO TRUE
                DISPLAY '----------------------------------------'
                DISPLAY 'NO MORE RECORDS IN CUST-FILE    --------'
                DISPLAY '----------------------------------------'

                NOT AT END  ADD 1  TO WS-READ-CTR
                            PERFORM 2300-VALIDATE-CUSTOMER

           END-READ.

       2300-VALIDATE-CUSTOMER SECTION.

           SET VALID-RECORD-FLAG       TO TRUE.

           IF IN-FNAME  IS EQUAL TO SPACES OR
              IN-LNAME  IS EQUAL TO SPACES OR
              IN-CITY   IS EQUAL TO SPACES
              DISPLAY 'NAME/CITY ERROR'
              SET ERROR-RECORD-FLAG         TO TRUE
              MOVE TI01-CUST-RECORD      TO TO01-CUST-ERR-RECORD
              WRITE TO01-CUST-ERR-RECORD
           END-IF.

           IF VALID-RECORD-FLAG
              PERFORM 2400-WRITE-CUST-KSDS
           END-IF.

       2400-WRITE-CUST-KSDS SECTION.

           MOVE IN-FNAME                 TO OUT-FNAME.
           MOVE IN-LNAME                 TO OUT-LNAME.
           MOVE IN-AREACODE              TO OUT-AREACODE.
           MOVE IN-ADDRESS1              TO OUT-ADDRESS1.
           MOVE IN-LOCALITY              TO OUT-LOCALITY.
           MOVE IN-CITY                  TO OUT-CITY.
           MOVE IN-UNITS                 TO OUT-UNITS.
           MOVE IN-STATUS                TO OUT-STATUS.

           MOVE ZEROES                   TO WS-RETRY-CTR.

       2410-GENERATE-ID.
      *    ------------------------------------------------------------
      *    Generate unique customer ID from FN(2) + LN(2) + AREA(4) + RAND(4)
      *    = 12 chars total for better uniqueness
      *    ------------------------------------------------------------
           COMPUTE WS-RAND-SEED =
               FUNCTION MOD(
                  ( WS-RAND-SEED * 1103515245 + 1345 + WS-RETRY-CTR)
                  ,2147483647 )

           COMPUTE WS-RAND-RESULT =
               FUNCTION MOD((WS-RAND-SEED * 1664525
                             + 1013904223), 10000)

           MOVE WS-RAND-RESULT     TO WS-RAND-SEED
           MOVE WS-RAND-RESULT     TO WS-RAND-4DIGIT
           MOVE WS-RAND-DISPLAY(1:4) TO WS-RAND-4CH.

      *    Build 12-byte customer ID with AreaCode for uniqueness
           MOVE IN-FNAME(1:2)    TO WS-FN-PREFIX.
           MOVE IN-LNAME(1:2)    TO WS-LN-PREFIX.
           MOVE IN-AREACODE(4:4) TO WS-AREA-PREFIX.
           
           MOVE WS-FN-PREFIX     TO CF-O-CUST-ID(1:2).
           MOVE WS-LN-PREFIX     TO CF-O-CUST-ID(3:2).
           MOVE WS-AREA-PREFIX   TO CF-O-CUST-ID(5:4).
           MOVE WS-RAND-4CH      TO CF-O-CUST-ID(9:4).

           DISPLAY 'CUSTOMER ID IS',  ' ', CF-O-CUST-ID.

           WRITE MO01-CUSTOMER-RECORD.
           DISPLAY '1:' ' ', WS-KSDS-STATUS

           IF WS-KSDS-STATUS = '22'
              ADD 1 TO WS-RETRY-CTR
              IF WS-RETRY-CTR <= 99
                 DISPLAY 'DUPLICATE KEY - RETRYING WITH NEW ID'
                 GO TO 2410-GENERATE-ID
              ELSE
                 DISPLAY 'MAX RETRIES EXCEEDED FOR RECORD'
                 MOVE TI01-CUST-RECORD TO TO01-CUST-ERR-RECORD
                 WRITE TO01-CUST-ERR-RECORD
              END-IF
           ELSE
              ADD 1 TO WS-WRITE-CTR
           END-IF.

       9000-TERMINATE   SECTION.

           DISPLAY '----------------------------------------'
           DISPLAY ' INPUT RECORDS PROCESSED  ',  WS-READ-CTR
           DISPLAY ' OUTPUT RECORDS PROCESSED ',  WS-WRITE-CTR
           DISPLAY '----------------------------------------'

           CLOSE  TI01-CUST-FILE,
                  TO01-CUST-ERR,
                  MO01-CUST-KSDS.
           DISPLAY '----------------------------------------'
           DISPLAY 'CUSTOMER FILE        IS CLOSED          '
           DISPLAY 'CUSTOMER MASTER KSDS IS CLOSED          '
           DISPLAY 'CUSTOMER ERROR FILE  IS CLOSED          '
           DISPLAY '----------------------------------------'

           STOP RUN.
