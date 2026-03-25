       IDENTIFICATION DIVISION.
       PROGRAM-ID.  MTR001.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

           SELECT TI01-METER-FILE  ASSIGN TO METERIN
           ORGANIZATION           IS SEQUENTIAL
           ACCESS MODE            IS SEQUENTIAL
           FILE STATUS            IS WS-METER-STATUS.

           SELECT MO01-METER-KSDS  ASSIGN TO MTRKSDS
           ORGANIZATION           IS INDEXED
           ACCESS MODE            IS RANDOM
           RECORD KEY             IS METER-ID
           FILE STATUS            IS WS-KSDS-STATUS.

           SELECT TO01-METER-ERR   ASSIGN TO METERERR
           ORGANIZATION           IS SEQUENTIAL
           ACCESS MODE            IS SEQUENTIAL
           FILE STATUS            IS WS-ERR-STATUS.

       DATA DIVISION.

       FILE SECTION.

       FD TI01-METER-FILE
           RECORD CONTAINS         22  CHARACTERS.

       01 TI01-METER-RECORD.
          05 IN-CUST-ID    PIC X(10).
          05 IN-INSTALL-DT PIC X(11).
          05 IN-STATUS     PIC X(1).

       FD MO01-METER-KSDS
           RECORD CONTAINS         34  CHARACTERS.

       01 MO01-METER-RECORD.
          05 METER-ID       PIC X(14).
          05 OUT-CUST-ID    PIC X(9).
          05 OUT-INSTALL-DT PIC X(10).
          05 OUT-STATUS     PIC X(1).

       FD TO01-METER-ERR
           RECORDING MODE          IS F
           RECORD CONTAINS         20 CHARACTERS.

       01 TO01-METER-ERR-RECORD.
          05 ERR-CUST-ID    PIC X(9).
          05 ERR-INSTALL-ID PIC X(10).
          05 ERR-STATUS     PIC X(1).

       WORKING-STORAGE SECTION.

       01 WS-FILE-STATUS-CODES.
          05 WS-METER-STATUS       PIC X(02).
             88 METER-IO-STATUS    VALUE '00'.
             88 METER-EOF          VALUE '10'.
             88 METER-ROW-NOTFND   VALUE '23'.
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

       01 WS-RAND-NUM-GEN.
          05 WS-RAND-NUM           PIC 9(08).
          05 WS-SEED-VALUE         PIC 9(08).

       01 WS-SUBS.
          05 I                     PIC 9(04) VALUE 1.
          05 J                     PIC 9(04) VALUE 1.
          05 WS-RETRY-CTR          PIC 9(04) VALUE 0.
       01 WS-METER-ID-GEN.
          05 WS-MTR-PREFIX         PIC X(4) VALUE 'MTR-'.
          05 WS-MTR-SEQ            PIC 9(3) VALUE ZERO.
          05 WS-MTR-CUST-CH1       PIC X.
          05 WS-MTR-CUST-CH2       PIC X.
          05 WS-MTR-DD             PIC 99.
          05 WS-MTR-MM             PIC 99.
          05 WS-MTR-RAND           PIC 9999.

       01 WS-METER-ID-OUT          PIC X(7).

       01 WS-ERROR-FLAGS.
          05 WS-ERROR-RECORD-FLAG  PIC 9.
             88 VALID-RECORD-FLAG  VALUE 1.
             88 ERROR-RECORD-FLAG  VALUE 2.

       01 WS-COUNTERS.
          05 WS-READ-CTR           PIC 9(04) VALUE ZEROS.
          05 WS-DUP-CTR            PIC 9(04) VALUE ZEROS.
          05 WS-ERROR-CTR          PIC 9(04) VALUE ZEROS.
          05 WS-WRITE-CTR          PIC 9(04) VALUE ZEROS.
          05 WS-UPDT-CTR           PIC 9(04) VALUE ZEROS.
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

           PERFORM 2200-READ-METER-FILE UNTIL METER-EOF.

       2100-OPEN-FILES  SECTION.

           OPEN INPUT TI01-METER-FILE.
           IF NOT METER-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING CUSTOMER INPUT FILE       '
              DISPLAY 'FILE  STATUS ', ' ',    WS-METER-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           OPEN OUTPUT MO01-METER-KSDS
           IF NOT KSDS-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING CUSTOMER LSDS MASTER      '
              DISPLAY 'FILE  STATUS ', ' ',    WS-KSDS-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           OPEN OUTPUT TO01-METER-ERR
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

       2200-READ-METER-FILE  SECTION.

           READ TI01-METER-FILE

                AT END  SET METER-EOF TO TRUE
                DISPLAY '----------------------------------------'
                DISPLAY 'NO MORE RECORDS IN METER-FILE    --------'
                DISPLAY '----------------------------------------'

                NOT AT END  ADD 1  TO WS-READ-CTR
                            PERFORM 2300-VALIDATE-METER

           END-READ.

       2300-VALIDATE-METER SECTION.

           SET VALID-RECORD-FLAG       TO TRUE.

           IF IN-CUST-ID IS EQUAL TO SPACES
              DISPLAY 'CUSTOMER ID ERROR'
              SET ERROR-RECORD-FLAG         TO TRUE
              MOVE TI01-METER-RECORD      TO TO01-METER-ERR-RECORD
              WRITE TO01-METER-ERR-RECORD
           END-IF.

           IF VALID-RECORD-FLAG
              PERFORM 2400-WRITE-METER-KSDS
           END-IF.

       2400-WRITE-METER-KSDS SECTION.

           MOVE IN-CUST-ID               TO OUT-CUST-ID.
           MOVE IN-INSTALL-DT            TO OUT-INSTALL-DT.
           MOVE IN-STATUS                TO OUT-STATUS.
           MOVE 0                        TO WS-RETRY-CTR.
           MOVE 99                       TO WS-KSDS-STATUS.

           PERFORM 2410-GENERATE-UNIQUE-METER-ID
               UNTIL WS-KSDS-STATUS = '00' OR WS-RETRY-CTR > 100.

           IF WS-KSDS-STATUS = '00'
              ADD 1 TO WS-WRITE-CTR
              DISPLAY 'METER ID WRITTEN: ' METER-ID
           ELSE
              ADD 1 TO WS-ERROR-CTR
              DISPLAY 'ERROR: UNABLE TO WRITE RECORD FOR CUST:'
                       IN-CUST-ID ' STATUS: ' WS-KSDS-STATUS
              DISPLAY 'MAX RETRIES EXCEEDED FOR THIS RECORD'
           END-IF.

       2410-GENERATE-UNIQUE-METER-ID SECTION.

           COMPUTE WS-RAND-SEED =
              FUNCTION MOD(
                 ( WS-RAND-SEED * 1103515245 + 12345 + WS-RETRY-CTR)
                 ,2147483647 )

           COMPUTE WS-RAND-RESULT =
               FUNCTION MOD((WS-RAND-SEED * 1664525
                             + 1013904223), 1000000)
           MOVE WS-RAND-RESULT     TO WS-RAND-4DIGIT
           MOVE WS-RAND-4DIGIT     TO WS-RAND-DISPLAY
           MOVE WS-RAND-DISPLAY    TO WS-ID-RAND.

           MOVE IN-CUST-ID(1:1)  TO WS-MTR-CUST-CH1.
           MOVE IN-CUST-ID(2:1)  TO WS-MTR-CUST-CH2.

           MOVE WS-DD                    TO WS-MTR-DD.
           MOVE WS-MM                    TO WS-MTR-MM.
           MOVE WS-ID-RAND               TO WS-MTR-RAND.
           STRING WS-MTR-PREFIX WS-MTR-CUST-CH1 WS-MTR-CUST-CH2
                  WS-MTR-DD WS-MTR-MM WS-MTR-RAND
                  DELIMITED BY SIZE
                  INTO METER-ID
           END-STRING.
           DISPLAY 'ATTEMPTING METER ID : ' METER-ID.

           WRITE MO01-METER-RECORD
               INVALID KEY
                   IF WS-KSDS-STATUS = '22'
                      DISPLAY 'DUPLICATE KEY DETECTED: ' METER-ID
                              ' - RETRYING...'
                      ADD 1 TO WS-DUP-CTR
                      ADD 1 TO WS-RETRY-CTR
                   ELSE
                      DISPLAY 'WRITE ERROR - STATUS: ' WS-KSDS-STATUS
                   END-IF
               NOT INVALID KEY
                   MOVE '00' TO WS-KSDS-STATUS
           END-WRITE.

       9000-TERMINATE   SECTION.

           DISPLAY '----------------------------------------'
           DISPLAY ' INPUT RECORDS PROCESSED  ',  WS-READ-CTR
           DISPLAY ' OUTPUT RECORDS WRITTEN   ',  WS-WRITE-CTR
           DISPLAY ' DUPLICATE KEY RETRIES    ',  WS-DUP-CTR
           DISPLAY ' ERROR RECORDS            ',  WS-ERROR-CTR
           DISPLAY '----------------------------------------'

           CLOSE  TI01-METER-FILE,
                  TO01-METER-ERR,
                  MO01-METER-KSDS.
           DISPLAY '----------------------------------------'
           DISPLAY 'METER FILE        IS CLOSED          '
           DISPLAY 'METER MASTER KSDS IS CLOSED          '
           DISPLAY 'METER ERROR FILE  IS CLOSED          '
           DISPLAY '----------------------------------------'

           STOP RUN.
