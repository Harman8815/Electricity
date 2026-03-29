       IDENTIFICATION DIVISION.
       PROGRAM-ID.  MTR002.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

           SELECT TI01-METER-FILE  ASSIGN TO METERIN
           ORGANIZATION           IS SEQUENTIAL
           ACCESS MODE            IS SEQUENTIAL
           FILE STATUS            IS WS-METER-STATUS.

           SELECT MI01-CUSTOMER-KSDS  ASSIGN TO CUSTKSDS
           ORGANIZATION           IS INDEXED
           ACCESS MODE            IS SEQUENTIAL
           RECORD KEY             IS CUST-KEY
           FILE STATUS            IS WS-CUST-KSDS-STATUS.

           SELECT MO01-METER-KSDS  ASSIGN TO MTRKSDS
           ORGANIZATION           IS INDEXED
           ACCESS MODE            IS RANDOM
           RECORD KEY             IS MTR-CUST-ID
           FILE STATUS            IS WS-KSDS-STATUS.

           SELECT TO01-METER-ERR   ASSIGN TO METERERR
           ORGANIZATION           IS SEQUENTIAL
           ACCESS MODE            IS SEQUENTIAL
           FILE STATUS            IS WS-ERR-STATUS.

       DATA DIVISION.

       FILE SECTION.

       FD TI01-METER-FILE
           RECORD CONTAINS         12  CHARACTERS.

       01 TI01-METER-RECORD.
          05 IN-PREV-READ     PIC X(6).
          05 IN-CURR-READ     PIC X(6).

       FD MI01-CUSTOMER-KSDS
           RECORD CONTAINS         83  CHARACTERS.

       01 MI01-CUSTOMER-RECORD.
          05 CUST-KEY         PIC X(12).
          05 CUST-FILLER      PIC X(71).

       FD MO01-METER-KSDS
           RECORD CONTAINS         38  CHARACTERS.

       01 MO01-METER-RECORD.
          05 MTR-ID           PIC X(14).
          05 MTR-CUST-ID      PIC X(12).
          05 MTR-PREV-READ    PIC 9(06).
          05 MTR-CURR-READ    PIC 9(06).

       FD TO01-METER-ERR
           RECORDING MODE          IS F
           RECORD CONTAINS         12 CHARACTERS.

       01 TO01-METER-ERR-RECORD.
          05 ERR-PREV-READ    PIC X(6).
          05 ERR-CURR-READ    PIC X(6).

       WORKING-STORAGE SECTION.

       01 WS-FILE-STATUS-CODES.
          05 WS-METER-STATUS       PIC X(02).
             88 METER-IO-STATUS    VALUE '00'.
             88 METER-EOF          VALUE '10'.
             88 METER-ROW-NOTFND   VALUE '23'.
          05 WS-KSDS-STATUS        PIC X(02).
             88 KSDS-IO-STATUS     VALUE '00'.
             88 KSDS-ROW-NOTFND    VALUE '23'.
          05 WS-CUST-KSDS-STATUS    PIC X(02).
             88 CUST-KSDS-IO-STATUS  VALUE '00'.
             88 CUST-KSDS-EOF        VALUE '10'.
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

       01 WS-CONSUMPTION-CALC.
          05 WS-PREV-READING     PIC 9(08) VALUE 0.
          05 WS-CURR-READING     PIC 9(08) VALUE 0.

       01 WS-METER-ID-GEN.
          05 WS-MTR-PREFIX         PIC X(4) VALUE 'MTR-'.
          05 WS-MTR-CUST-CH1       PIC X.
          05 WS-MTR-CUST-CH2       PIC X.
          05 WS-MTR-DD             PIC 99.
          05 WS-MTR-MM             PIC 99.
          05 WS-MTR-RAND           PIC 9999.

       01 WS-HARDCODED-CUST-ID    PIC X(12).

       01 WS-ERROR-FLAGS.
          05 WS-ERROR-RECORD-FLAG  PIC 9.
             88 VALID-RECORD-FLAG  VALUE 1.
             88 ERROR-RECORD-FLAG  VALUE 2.

       01 WS-COUNTERS.
          05 WS-READ-CTR           PIC 9(04) VALUE ZEROS.
          05 WS-DUP-CTR            PIC 9(04) VALUE ZEROS.
          05 WS-ERROR-CTR          PIC 9(04) VALUE ZEROS.
          05 WS-WRITE-CTR          PIC 9(04) VALUE ZEROS.
          05 WS-SKIP-CTR           PIC 9(04) VALUE ZEROS.

       PROCEDURE DIVISION.
       0000-MAIN-LINE   SECTION.

           PERFORM 1000-INITIALIZE.

           PERFORM 2000-PROCESS.

           PERFORM 9000-TERMINATE.

       1000-INITIALIZE  SECTION.

           DISPLAY '----------------------------------------'
           DISPLAY 'MTR002 EXECUTION BEGINS HERE ..........'
           DISPLAY '  METER GENERATION PROGRAM               '
           DISPLAY '----------------------------------------'

           ACCEPT WS-DATE FROM DATE YYYYMMDD.

       2000-PROCESS     SECTION.

           PERFORM 2100-OPEN-FILES.

           PERFORM 2200-READ-CUSTOMER-KSDS UNTIL CUST-KSDS-EOF.

       2100-OPEN-FILES  SECTION.

           OPEN INPUT MI01-CUSTOMER-KSDS.
           IF NOT CUST-KSDS-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING CUSTOMER MASTER KSDS      '
              DISPLAY 'FILE  STATUS ', ' ',    WS-CUST-KSDS-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           OPEN INPUT TI01-METER-FILE.
           IF NOT METER-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING METER INPUT FILE       '
              DISPLAY 'FILE  STATUS ', ' ',    WS-METER-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           OPEN OUTPUT MO01-METER-KSDS
           IF NOT KSDS-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING METER MASTER KSDS         '
              DISPLAY 'FILE  STATUS ', ' ',    WS-KSDS-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           OPEN OUTPUT TO01-METER-ERR
           IF NOT ERR-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING METER ERR FILE            '
              DISPLAY 'FILE  STATUS ', ' ',    WS-ERR-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           DISPLAY '----------------------------------------'
           DISPLAY 'CUSTOMER KSDS OPENED ..............'
           DISPLAY 'METER INPUT FILE OPENED ...........'
           DISPLAY 'METER MASTER KSDS IS OPENED ..........'
           DISPLAY 'METER ERROR FILE IS OPENED ..........'
           DISPLAY '----------------------------------------'
           .

       2200-READ-CUSTOMER-KSDS  SECTION.

           READ MI01-CUSTOMER-KSDS

                AT END  SET CUST-KSDS-EOF TO TRUE
                DISPLAY '----------------------------------------'
                DISPLAY 'NO MORE CUSTOMERS FOR METER PROCESSING ---'
                DISPLAY '----------------------------------------'

                NOT AT END  ADD 1  TO WS-READ-CTR
                            PERFORM 2205-READ-METER-DATA

           END-READ.

       2205-READ-METER-DATA SECTION.

           READ TI01-METER-FILE

                AT END  SET METER-EOF TO TRUE
                DISPLAY '----------------------------------------'
                DISPLAY 'NO MORE METER READINGS AVAILABLE --------'
                DISPLAY '----------------------------------------'

                NOT AT END  PERFORM 2300-VALIDATE-METER

           END-READ.

       2300-VALIDATE-METER SECTION.

           SET VALID-RECORD-FLAG       TO TRUE.

           IF IN-PREV-READ IS EQUAL TO SPACES
              DISPLAY 'METER PREV READ ERROR - PREV_READ REQUIRED'  
                      ' FOR METER'
              SET ERROR-RECORD-FLAG         TO TRUE
              MOVE TI01-METER-RECORD     TO TO01-METER-ERR-RECORD
              WRITE TO01-METER-ERR-RECORD
           END-IF.

           IF IN-CURR-READ IS EQUAL TO SPACES
              DISPLAY 'METER CURR READ ERROR - CURR_READ REQUIRED'
                      ' FOR METER'
              SET ERROR-RECORD-FLAG         TO TRUE
              MOVE TI01-METER-RECORD     TO TO01-METER-ERR-RECORD
              WRITE TO01-METER-ERR-RECORD
           END-IF.

           IF VALID-RECORD-FLAG
              PERFORM 2400-WRITE-METER-KSDS
           END-IF.

       2400-WRITE-METER-KSDS SECTION.

           MOVE CUST-KEY(2:1)          TO WS-MTR-CUST-CH1.
           MOVE CUST-KEY(3:1)          TO WS-MTR-CUST-CH2.
           MOVE WS-DD                  TO WS-MTR-DD.
           MOVE WS-MM                  TO WS-MTR-MM.
           COMPUTE WS-MTR-RAND = FUNCTION RANDOM * 10000.

           STRING WS-MTR-PREFIX WS-MTR-CUST-CH1 WS-MTR-CUST-CH2
                  WS-MTR-DD WS-MTR-MM WS-MTR-RAND
                  DELIMITED BY SIZE
                  INTO MTR-ID
           END-STRING.

           MOVE CUST-KEY                  TO MTR-CUST-ID.
           COMPUTE MTR-PREV-READ = FUNCTION NUMVAL(IN-PREV-READ)
           COMPUTE MTR-CURR-READ = FUNCTION NUMVAL(IN-CURR-READ)

           DISPLAY 'ATTEMPTING METER: ' MTR-ID ' FOR CUST: ' MTR-CUST-ID
                   ' PREV READ: ' MTR-PREV-READ
                   ' CURR READ: ' MTR-CURR-READ.

           WRITE MO01-METER-RECORD
               INVALID KEY
                   IF WS-KSDS-STATUS = '22'
                      DISPLAY 'DUPLICATE KEY DETECTED: ' MTR-ID
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
           DISPLAY ' OUTPUT RECORDS WRITTEN   ',  WS-WRITE-CTR
           DISPLAY ' DUPLICATE KEY RETRIES    ',  WS-DUP-CTR
           DISPLAY ' ERROR RECORDS            ',  WS-ERROR-CTR
           DISPLAY '----------------------------------------'

           CLOSE  MI01-CUSTOMER-KSDS,
                  TI01-METER-FILE,
                  TO01-METER-ERR,
                  MO01-METER-KSDS.

           DISPLAY '----------------------------------------'
           DISPLAY 'CUSTOMER FILE      IS CLOSED          '
           DISPLAY 'METER INPUT FILE   IS CLOSED          '
           DISPLAY 'METER MASTER KSDS  IS CLOSED          '
           DISPLAY 'METER ERROR FILE   IS CLOSED          '
           DISPLAY '----------------------------------------'

           STOP RUN.