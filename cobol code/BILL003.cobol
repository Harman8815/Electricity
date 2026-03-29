       IDENTIFICATION DIVISION.
       PROGRAM-ID.  BILL003.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

           SELECT MI01-METER-KSDS   ASSIGN TO MTRKSDS
           ORGANIZATION           IS INDEXED
           ACCESS MODE            IS SEQUENTIAL
           RECORD KEY             IS MTR-CUST-ID
           FILE STATUS            IS WS-MTR-STATUS.

           SELECT MI01-CUSTOMER-KSDS ASSIGN TO CUSTKSDS
           ORGANIZATION           IS INDEXED
           ACCESS MODE            IS RANDOM
           RECORD KEY             IS CUST-KEY
           FILE STATUS            IS WS-CUST-STATUS.

           SELECT MO01-BILL-KSDS   ASSIGN TO BILLKSDS
           ORGANIZATION           IS INDEXED
           ACCESS MODE            IS RANDOM
           RECORD KEY             IS BILL-ID
           FILE STATUS            IS WS-BILL-STATUS.

           SELECT TO01-BILL-RPT    ASSIGN TO BILLRPT
           ORGANIZATION           IS SEQUENTIAL
           ACCESS MODE            IS SEQUENTIAL
           FILE STATUS            IS WS-RPT-STATUS.

       DATA DIVISION.

       FILE SECTION.

       FD MI01-METER-KSDS
           RECORD CONTAINS         38  CHARACTERS.

       01 MI01-METER-RECORD.
          05 MTR-ID           PIC X(14).
          05 MTR-CUST-ID      PIC X(12).
          05 MTR-PREV-READ    PIC 9(06).
          05 MTR-CURR-READ    PIC 9(06).

       FD MI01-CUSTOMER-KSDS
           RECORD CONTAINS         83  CHARACTERS.

       01 MI01-CUSTOMER-RECORD.
          05 CUST-KEY         PIC X(12).
          05 CUST-FIRST-NAME  PIC X(10).
          05 CUST-LAST-NAME  PIC X(10).
          05 CUST-AREA-CODE  PIC X(6).
          05 CUST-SPACE      PIC X.
          05 CUST-ADDRESS     PIC X(29).
          05 CUST-CITY        PIC X(10).
          05 CUST-UNITS       PIC X(5).

       FD MO01-BILL-KSDS
           RECORD CONTAINS         104 CHARACTERS.

       01 MO01-BILL-RECORD.
          05 BILL-ID          PIC X(12).
          05 BILL-CUST-ID     PIC X(12).
          05 BILL-MTR-ID      PIC X(14).
          05 BILL-FIRST-NAME  PIC X(10).
          05 BILL-LAST-NAME   PIC X(10).
          05 BILL-AREA-CODE   PIC X(6).
          05 BILL-ADDRESS     PIC X(29).
          05 BILL-UNITS       PIC 9(6).
          05 BILL-AMOUNT      PIC 9(8)V99.

       FD TO01-BILL-RPT
           RECORDING MODE          IS F
           RECORD CONTAINS         133 CHARACTERS.

       01 TO01-BILL-RPT-RECORD PIC X(133).

       WORKING-STORAGE SECTION.

       01 WS-FILE-STATUS-CODES.
          05 WS-MTR-STATUS       PIC X(02).
             88 MTR-IO-STATUS    VALUE '00'.
             88 MTR-EOF          VALUE '10'.
          05 WS-CUST-STATUS      PIC X(02).
             88 CUST-IO-STATUS   VALUE '00'.
             88 CUST-NOT-FOUND   VALUE '23'.
          05 WS-BILL-STATUS      PIC X(02).
             88 BILL-IO-STATUS   VALUE '00'.
          05 WS-RPT-STATUS       PIC X(02).
             88 RPT-IO-STATUS    VALUE '00'.

       01 WS-DATE-VARIABLES.
          05 WS-DATE               PIC 9(08).
          05 WS-DATE-FORMAT.
             10 WS-CC              PIC 99.
             10 WS-YY              PIC 99.
             10 WS-MM              PIC 99.
             10 WS-DD              PIC 99.
          05 WS-REPORT-DATE        PIC X(10).

       01 WS-BILL-ID-GEN.
          05 WS-BILL-PREFIX        PIC X(4) VALUE 'BILL'.
          05 WS-BILL-YY            PIC 99.
          05 WS-BILL-MM            PIC 99.
          05 WS-BILL-RAND          PIC 9999.

       01 WS-CALC-VARIABLES.
          05 WS-PREV-READ-NUM      PIC 9(06) VALUE 0.
          05 WS-CURR-READ-NUM      PIC 9(06) VALUE 0.
          05 WS-UNITS-CONSUMED     PIC 9(06) VALUE 0.
          05 WS-BILL-AMOUNT        PIC 9(08)V99 VALUE 0.
          05 WS-RATE               PIC 9(02)V99 VALUE 0.
             88 LOW-RATE           VALUE 10.00.
             88 HIGH-RATE          VALUE 15.00.

       01 WS-REPORT-VARIABLES.
          05 WS-PAGE-NUM           PIC 9(03) VALUE 1.
          05 WS-LINE-COUNT         PIC 9(03) VALUE 0.
          05 WS-MAX-LINES          PIC 9(03) VALUE 55.
          05 WS-TOTAL-BILLS        PIC 9(04) VALUE 0.
          05 WS-TOTAL-AMOUNT       PIC 9(10)V99 VALUE 0.

       01 WS-COUNTERS.
          05 WS-READ-CTR           PIC 9(04) VALUE ZEROS.
          05 WS-WRITE-CTR          PIC 9(04) VALUE ZEROS.
          05 WS-ERROR-CTR          PIC 9(04) VALUE ZEROS.
          05 WS-SKIP-CTR           PIC 9(04) VALUE ZEROS.

       01 WS-REPORT-HEADER1.
          05 FILLER               PIC X(40) VALUE SPACES.
          05 FILLER               PIC X(30) VALUE 'ELECTRICITY BILLING REPORT'.
          05 FILLER               PIC X(53) VALUE SPACES.
          05 FILLER               PIC X(5)  VALUE 'PAGE'.
          05 WS-RPT-PAGE-NUM      PIC ZZ9.

       01 WS-REPORT-HEADER2.
          05 FILLER               PIC X(40) VALUE SPACES.
          05 FILLER               PIC X(30) VALUE '----------------------------'.

       01 WS-REPORT-HEADER3.
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 FILLER               PIC X(8)  VALUE 'BILL ID'.
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 FILLER               PIC X(12) VALUE 'CUST ID'.
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 FILLER               PIC X(10) VALUE 'FIRST NAME'.
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 FILLER               PIC X(10) VALUE 'LAST NAME'.
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 FILLER               PIC X(6)  VALUE 'AREA'.
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 FILLER               PIC X(10) VALUE 'UNITS'.
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 FILLER               PIC X(12) VALUE 'AMOUNT(Rs)'.
          05 FILLER               PIC X(51) VALUE SPACES.

       01 WS-REPORT-DETAIL.
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 WS-RPT-BILL-ID       PIC X(12).
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 WS-RPT-CUST-ID       PIC X(12).
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 WS-RPT-FIRST-NAME    PIC X(10).
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 WS-RPT-LAST-NAME     PIC X(10).
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 WS-RPT-AREA          PIC X(6).
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 WS-RPT-UNITS         PIC ZZZ,ZZ9.
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 WS-RPT-AMOUNT        PIC Z,ZZZ,ZZ9.99.
          05 FILLER               PIC X(51) VALUE SPACES.

       01 WS-REPORT-TOTAL.
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 FILLER               PIC X(20) VALUE 'TOTAL BILLS:'.
          05 WS-RPT-TOTAL-BILLS   PIC Z,ZZ9.
          05 FILLER               PIC X(20) VALUE SPACES.
          05 FILLER               PIC X(15) VALUE 'TOTAL AMOUNT:'.
          05 WS-RPT-TOTAL-AMOUNT  PIC Z,ZZZ,ZZZ,ZZ9.99.

       PROCEDURE DIVISION.
       0000-MAIN-LINE   SECTION.

           PERFORM 1000-INITIALIZE.
           PERFORM 2000-PROCESS.
           PERFORM 9000-TERMINATE.

       1000-INITIALIZE  SECTION.

           DISPLAY '----------------------------------------'
           DISPLAY 'BILL003 EXECUTION BEGINS HERE ..........'
           DISPLAY '  BILL GENERATION PROGRAM               '
           DISPLAY '----------------------------------------'

           ACCEPT WS-DATE FROM DATE YYYYMMDD.
           MOVE WS-DD TO WS-REPORT-DATE(1:2)
           MOVE '/'   TO WS-REPORT-DATE(3:1)
           MOVE WS-MM TO WS-REPORT-DATE(4:2)
           MOVE '/'   TO WS-REPORT-DATE(6:1)
           MOVE WS-YY TO WS-REPORT-DATE(7:2).

       2000-PROCESS     SECTION.

           PERFORM 2100-OPEN-FILES.

           PERFORM 2200-READ-METER-KSDS UNTIL MTR-EOF.

           PERFORM 2800-WRITE-REPORT-TOTALS.

       2100-OPEN-FILES  SECTION.

           OPEN INPUT MI01-METER-KSDS.
           IF NOT MTR-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING METER MASTER KSDS         '
              DISPLAY 'FILE  STATUS ', ' ',    WS-MTR-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           OPEN INPUT MI01-CUSTOMER-KSDS.
           IF NOT CUST-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING CUSTOMER MASTER KSDS      '
              DISPLAY 'FILE  STATUS ', ' ',    WS-CUST-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           OPEN OUTPUT MO01-BILL-KSDS.
           IF NOT BILL-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING BILL MASTER KSDS          '
              DISPLAY 'FILE  STATUS ', ' ',    WS-BILL-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           OPEN OUTPUT TO01-BILL-RPT.
           IF NOT RPT-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING BILL REPORT FILE          '
              DISPLAY 'FILE  STATUS ', ' ',    WS-RPT-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           DISPLAY '----------------------------------------'
           DISPLAY 'METER KSDS    OPENED ..............'
           DISPLAY 'CUSTOMER KSDS OPENED ..............'
           DISPLAY 'BILL KSDS     OPENED .............'
           DISPLAY 'BILL RPT      OPENED .............'
           DISPLAY '----------------------------------------'.

       2200-READ-METER-KSDS  SECTION.

           READ MI01-METER-KSDS
                AT END  SET MTR-EOF TO TRUE
                DISPLAY '----------------------------------------'
                DISPLAY 'NO MORE METER RECORDS FOR BILLING ------'
                DISPLAY '----------------------------------------'

                NOT AT END  ADD 1  TO WS-READ-CTR
                            PERFORM 2300-READ-CUSTOMER

           END-READ.

       2300-READ-CUSTOMER SECTION.

           MOVE MTR-CUST-ID TO CUST-KEY.

           READ MI01-CUSTOMER-KSDS
                INVALID KEY
                   DISPLAY 'CUSTOMER NOT FOUND: ' CUST-KEY
                   ADD 1 TO WS-ERROR-CTR
                NOT INVALID KEY
                   PERFORM 2400-CALCULATE-BILL
           END-READ.

       2400-CALCULATE-BILL SECTION.

           COMPUTE WS-PREV-READ-NUM = MTR-PREV-READ
           COMPUTE WS-CURR-READ-NUM = MTR-CURR-READ

           IF WS-CURR-READ-NUM < WS-PREV-READ-NUM
              DISPLAY 'ERROR: CURR < PREV FOR CUST ' CUST-KEY
              ADD 1 TO WS-ERROR-CTR
           ELSE
              COMPUTE WS-UNITS-CONSUMED = 
                      WS-CURR-READ-NUM - WS-PREV-READ-NUM

              IF WS-UNITS-CONSUMED < 100
                 MOVE 10.00 TO WS-RATE
              ELSE
                 MOVE 15.00 TO WS-RATE
              END-IF

              COMPUTE WS-BILL-AMOUNT = 
                      WS-UNITS-CONSUMED * WS-RATE

              PERFORM 2500-GENERATE-BILL-ID
              PERFORM 2600-WRITE-BILL-KSDS
              PERFORM 2700-WRITE-REPORT-LINE
           END-IF.

       2500-GENERATE-BILL-ID SECTION.

           MOVE WS-YY TO WS-BILL-YY.
           MOVE WS-MM TO WS-BILL-MM.
           COMPUTE WS-BILL-RAND = FUNCTION RANDOM * 10000.

           STRING WS-BILL-PREFIX WS-BILL-YY WS-BILL-MM WS-BILL-RAND
                  DELIMITED BY SIZE
                  INTO BILL-ID
           END-STRING.

       2600-WRITE-BILL-KSDS SECTION.

           MOVE BILL-ID          TO BILL-CUST-ID.
           MOVE MTR-CUST-ID      TO BILL-CUST-ID.
           MOVE MTR-ID           TO BILL-MTR-ID.
           MOVE CUST-FIRST-NAME  TO BILL-FIRST-NAME.
           MOVE CUST-LAST-NAME   TO BILL-LAST-NAME.
           MOVE CUST-AREA-CODE   TO BILL-AREA-CODE.
           MOVE CUST-ADDRESS     TO BILL-ADDRESS.
           MOVE WS-UNITS-CONSUMED TO BILL-UNITS.
           MOVE WS-BILL-AMOUNT   TO BILL-AMOUNT.

           WRITE MO01-BILL-RECORD
               INVALID KEY
                   IF WS-BILL-STATUS = '22'
                      DISPLAY 'DUPLICATE BILL ID: ' BILL-ID
                      ADD 1 TO WS-ERROR-CTR
                   ELSE
                      DISPLAY 'WRITE ERROR - STATUS: ' WS-BILL-STATUS
                      ADD 1 TO WS-ERROR-CTR
                   END-IF
               NOT INVALID KEY
                   ADD 1 TO WS-WRITE-CTR
                   ADD 1 TO WS-TOTAL-BILLS
                   ADD WS-BILL-AMOUNT TO WS-TOTAL-AMOUNT
           END-WRITE.

       2700-WRITE-REPORT-LINE SECTION.

           IF WS-LINE-COUNT >= WS-MAX-LINES
              PERFORM 2750-WRITE-PAGE-HEADERS
           END-IF.

           MOVE BILL-ID          TO WS-RPT-BILL-ID.
           MOVE MTR-CUST-ID      TO WS-RPT-CUST-ID.
           MOVE CUST-FIRST-NAME  TO WS-RPT-FIRST-NAME.
           MOVE CUST-LAST-NAME   TO WS-RPT-LAST-NAME.
           MOVE CUST-AREA-CODE   TO WS-RPT-AREA.
           MOVE WS-UNITS-CONSUMED TO WS-RPT-UNITS.
           MOVE WS-BILL-AMOUNT   TO WS-RPT-AMOUNT.

           WRITE TO01-BILL-RPT-RECORD FROM WS-REPORT-DETAIL.
           ADD 1 TO WS-LINE-COUNT.

       2750-WRITE-PAGE-HEADERS SECTION.

           MOVE WS-PAGE-NUM TO WS-RPT-PAGE-NUM.
           WRITE TO01-BILL-RPT-RECORD FROM WS-REPORT-HEADER1.
           WRITE TO01-BILL-RPT-RECORD FROM WS-REPORT-HEADER2.
           WRITE TO01-BILL-RPT-RECORD FROM WS-REPORT-HEADER3.
           MOVE 3 TO WS-LINE-COUNT.
           ADD 1 TO WS-PAGE-NUM.

       2800-WRITE-REPORT-TOTALS SECTION.

           MOVE WS-TOTAL-BILLS  TO WS-RPT-TOTAL-BILLS.
           MOVE WS-TOTAL-AMOUNT TO WS-RPT-TOTAL-AMOUNT.
           WRITE TO01-BILL-RPT-RECORD FROM WS-REPORT-TOTAL.

       9000-TERMINATE   SECTION.

           DISPLAY '----------------------------------------'
           DISPLAY ' INPUT RECORDS PROCESSED  ',  WS-READ-CTR
           DISPLAY ' BILLS WRITTEN            ',  WS-WRITE-CTR
           DISPLAY ' ERRORS                   ',  WS-ERROR-CTR
           DISPLAY '----------------------------------------'

           CLOSE  MI01-METER-KSDS,
                  MI01-CUSTOMER-KSDS,
                  MO01-BILL-KSDS,
                  TO01-BILL-RPT.

           DISPLAY '----------------------------------------'
           DISPLAY 'METER KSDS    IS CLOSED          '
           DISPLAY 'CUSTOMER KSDS IS CLOSED          '
           DISPLAY 'BILL KSDS     IS CLOSED          '
           DISPLAY 'BILL RPT      IS CLOSED          '
           DISPLAY '----------------------------------------'

           STOP RUN.
