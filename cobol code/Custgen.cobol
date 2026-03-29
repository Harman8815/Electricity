       IDENTIFICATION DIVISION.
       PROGRAM-ID.  CUST001.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

           SELECT TI01-CUSTOMER-FILE  ASSIGN TO CUSTIN
           ORGANIZATION           IS SEQUENTIAL
           ACCESS MODE            IS SEQUENTIAL
           FILE STATUS            IS WS-CUST-STATUS.

           SELECT MO01-CUSTOMER-KSDS  ASSIGN TO CUSTKSDS
           ORGANIZATION           IS INDEXED
           ACCESS MODE            IS RANDOM
           RECORD KEY             IS CUST-ID
           FILE STATUS            IS WS-KSDS-STATUS.

           SELECT TO01-CUSTOMER-ERR   ASSIGN TO CUSTERR
           ORGANIZATION           IS SEQUENTIAL
           ACCESS MODE            IS SEQUENTIAL
           FILE STATUS            IS WS-ERR-STATUS.

       DATA DIVISION.

       FILE SECTION.

       FD TI01-CUSTOMER-FILE
           RECORDING MODE          IS F
           RECORD CONTAINS         71  CHARACTERS.

       01 TI01-CUSTOMER-RECORD.
          05 IN-FIRST-NAME    PIC X(10).
          05 IN-LAST-NAME     PIC X(10).
          05 IN-AREA-CODE     PIC X(6).
          05 IN-SPACE         PIC X.
          05 IN-ADDRESS       PIC X(29).
          05 IN-CITY          PIC X(10).
          05 IN-UNITS         PIC X(5).

       FD MO01-CUSTOMER-KSDS
           RECORD CONTAINS         83  CHARACTERS.

       01 MO01-CUSTOMER-RECORD.
          05 CUST-ID          PIC X(12).
          05 OUT-FIRST-NAME   PIC X(10).
          05 OUT-LAST-NAME    PIC X(10).
          05 OUT-AREA-CODE    PIC X(6).
          05 OUT-SPACE        PIC X.
          05 OUT-ADDRESS      PIC X(29).
          05 OUT-CITY         PIC X(10).
          05 OUT-UNITS        PIC X(5).

       FD TO01-CUSTOMER-ERR
           RECORDING MODE          IS F
           RECORD CONTAINS         71 CHARACTERS.

       01 TO01-CUSTOMER-ERR-RECORD.
          05 ERR-FIRST-NAME   PIC X(10).
          05 ERR-LAST-NAME    PIC X(10).
          05 ERR-AREA-CODE    PIC X(6).
          05 ERR-SPACE        PIC X.
          05 ERR-ADDRESS      PIC X(29).
          05 ERR-CITY         PIC X(10).
          05 ERR-UNITS        PIC X(5).

       WORKING-STORAGE SECTION.

       01 WS-FILE-STATUS-CODES.
          05 WS-CUST-STATUS       PIC X(02).
             88 CUST-IO-STATUS    VALUE '00'.
             88 CUST-EOF          VALUE '10'.
             88 CUST-ROW-NOTFND   VALUE '23'.
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

       01 WS-CUST-ID-GEN.
          05 WS-CUST-PREFIX        PIC X VALUE 'C'.
          05 WS-CUST-FN-CHARS      PIC X(2).
          05 WS-CUST-LN-CHARS      PIC X(2).
          05 WS-CUST-AREA-4        PIC 9(4).
          05 WS-CUST-RAND-3        PIC 9(3).

       01 WS-ERROR-FLAGS.
          05 WS-ERROR-RECORD-FLAG  PIC 9.
             88 VALID-RECORD-FLAG  VALUE 1.
             88 ERROR-RECORD-FLAG  VALUE 2.

       01 WS-COUNTERS.
          05 WS-READ-CTR           PIC 9(04) VALUE ZEROS.
          05 WS-DUP-CTR            PIC 9(04) VALUE ZEROS.
          05 WS-ERROR-CTR          PIC 9(04) VALUE ZEROS.
          05 WS-WRITE-CTR          PIC 9(04) VALUE ZEROS.

       PROCEDURE DIVISION.
       0000-MAIN-LINE   SECTION.

           PERFORM 1000-INITIALIZE.

           PERFORM 2000-PROCESS.

           PERFORM 9000-TERMINATE.

       1000-INITIALIZE  SECTION.

           DISPLAY '----------------------------------------'
           DISPLAY 'CUST001 EXECUTION BEGINS HERE ..........'
           DISPLAY '  CUSTOMER GENERATION PROGRAM            '
           DISPLAY '----------------------------------------'

           ACCEPT WS-DATE FROM DATE YYYYMMDD.

       2000-PROCESS     SECTION.

           PERFORM 2100-OPEN-FILES.

           PERFORM 2200-READ-CUSTOMER-FILE UNTIL CUST-EOF.

       2100-OPEN-FILES  SECTION.

           OPEN INPUT TI01-CUSTOMER-FILE.
           IF NOT CUST-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING CUSTOMER INPUT FILE       '
              DISPLAY 'FILE  STATUS ', ' ',    WS-CUST-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           OPEN OUTPUT MO01-CUSTOMER-KSDS
           IF NOT KSDS-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING CUSTOMER MASTER KSDS      '
              DISPLAY 'FILE  STATUS ', ' ',    WS-KSDS-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           OPEN OUTPUT TO01-CUSTOMER-ERR
           IF NOT ERR-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING CUSTOMER ERR FILE         '
              DISPLAY 'FILE  STATUS ', ' ',    WS-ERR-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           DISPLAY '----------------------------------------'
           DISPLAY 'CUSTOMER INPUT FILE OPENED ..............'
           DISPLAY 'CUSTOMER MASTER KSDS IS OPENED ..........'
           DISPLAY 'CUSTOMER ERROR FILE IS OPENED ..........'
           DISPLAY '----------------------------------------'
           .

       2200-READ-CUSTOMER-FILE  SECTION.

           READ TI01-CUSTOMER-FILE

                AT END  SET CUST-EOF TO TRUE
                DISPLAY '----------------------------------------'
                DISPLAY 'NO MORE RECORDS IN CUSTOMER-FILE --------'
                DISPLAY '----------------------------------------'

                NOT AT END  ADD 1  TO WS-READ-CTR
                            PERFORM 2300-VALIDATE-CUSTOMER

           END-READ.

       2300-VALIDATE-CUSTOMER SECTION.

           SET VALID-RECORD-FLAG       TO TRUE.

           IF IN-FIRST-NAME IS EQUAL TO SPACES OR
              IN-LAST-NAME IS EQUAL TO SPACES
              DISPLAY 'CUSTOMER NAME ERROR - FIRST/LAST NAME REQUIRED'
              SET ERROR-RECORD-FLAG         TO TRUE
              MOVE TI01-CUSTOMER-RECORD     TO TO01-CUSTOMER-ERR-RECORD
              WRITE TO01-CUSTOMER-ERR-RECORD
           END-IF.

           IF VALID-RECORD-FLAG
              PERFORM 2400-WRITE-CUSTOMER-KSDS
           END-IF.

       2400-WRITE-CUSTOMER-KSDS SECTION.

           MOVE IN-FIRST-NAME        TO OUT-FIRST-NAME.
           MOVE IN-LAST-NAME         TO OUT-LAST-NAME.
           MOVE IN-AREA-CODE         TO OUT-AREA-CODE.
           MOVE IN-SPACE             TO OUT-SPACE.
           MOVE IN-ADDRESS           TO OUT-ADDRESS.
           MOVE IN-CITY              TO OUT-CITY.
           MOVE IN-UNITS             TO OUT-UNITS.

           MOVE IN-FIRST-NAME(1:2)   TO WS-CUST-FN-CHARS.
           MOVE IN-LAST-NAME(1:2)    TO WS-CUST-LN-CHARS.
           MOVE IN-AREA-CODE(1:4)    TO WS-CUST-AREA-4.
           COMPUTE WS-RAND-SEED = FUNCTION RANDOM * 1000.
           COMPUTE WS-CUST-RAND-3 = FUNCTION MOD(WS-RAND-SEED, 1000).

           STRING WS-CUST-PREFIX WS-CUST-FN-CHARS WS-CUST-LN-CHARS
                  WS-CUST-AREA-4 WS-CUST-RAND-3
                  DELIMITED BY SIZE
                  INTO CUST-ID
           END-STRING.

           DISPLAY 'ATTEMPTING CUSTOMER ID : ' CUST-ID.

           WRITE MO01-CUSTOMER-RECORD
               INVALID KEY
                   IF WS-KSDS-STATUS = '22'
                      DISPLAY 'DUPLICATE KEY DETECTED: ' CUST-ID
                              ' - RETRYING...'
                      ADD 1 TO WS-DUP-CTR
                      ADD 1 TO WS-RETRY-CTR
                   ELSE
                      DISPLAY 'WRITE ERROR - STATUS: ' WS-KSDS-STATUS
                   END-IF
               NOT INVALID KEY
                   MOVE '00' TO WS-KSDS-STATUS
                   ADD 1 TO WS-WRITE-CTR
           END-WRITE.

       9000-TERMINATE   SECTION.

           DISPLAY '----------------------------------------'
           DISPLAY ' INPUT RECORDS PROCESSED  ',  WS-READ-CTR
           DISPLAY ' OUTPUT RECORDS PROCESSED ',  WS-WRITE-CTR
           DISPLAY '----------------------------------------'

           CLOSE  TI01-CUSTOMER-FILE,
                  TO01-CUSTOMER-ERR,
                  MO01-CUSTOMER-KSDS.
           DISPLAY '----------------------------------------'
           DISPLAY 'CUSTOMER FILE        IS CLOSED          '
           DISPLAY 'CUSTOMER MASTER KSDS IS CLOSED          '
           DISPLAY 'CUSTOMER ERROR FILE  IS CLOSED          '
           DISPLAY '----------------------------------------'

           STOP RUN.