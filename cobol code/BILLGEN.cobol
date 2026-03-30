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
           RECORD CONTAINS         72 CHARACTERS.

       01 TO01-BILL-RPT-RECORD PIC X(72).

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
          05 WS-BILL-SEQUENCE     PIC 9(04) VALUE 0000.
          05 WS-TEMP-BILL-ID       PIC X(12).
          05 WS-BILL-SUBSCRIPT     PIC 9(04) VALUE ZEROS.
          05 WS-BILL-INDEX         PIC 9(04) VALUE ZEROS.

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
          05 WS-MAX-LINES          PIC 9(03) VALUE 10.
          05 WS-TOTAL-BILLS        PIC 9(04) VALUE 0.
          05 WS-TOTAL-AMOUNT       PIC 9(10)V99 VALUE 0.

       01 WS-COUNTERS.
          05 WS-READ-CTR           PIC 9(04) VALUE ZEROS.
          05 WS-WRITE-CTR          PIC 9(04) VALUE ZEROS.
          05 WS-ERROR-CTR          PIC 9(04) VALUE ZEROS.
          05 WS-SKIP-CTR           PIC 9(04) VALUE ZEROS.

       01 WS-BILL-TEMP-STORAGE.
          05 WS-BILL-TEMP-TABLE.
             10 WS-BILL-TEMP-RECORD OCCURS 1000 TIMES
                                 INDEXED BY WS-BILL-IDX.
                15 WS-T-BILL-ID          PIC X(12).
                15 WS-T-BILL-CUST-ID     PIC X(12).
                15 WS-T-BILL-MTR-ID      PIC X(14).
                15 WS-T-BILL-FIRST-NAME  PIC X(10).
                15 WS-T-BILL-LAST-NAME   PIC X(10).
                15 WS-T-BILL-AREA-CODE   PIC X(6).
                15 WS-T-BILL-ADDRESS     PIC X(29).
                15 WS-T-BILL-UNITS       PIC 9(6).
                15 WS-T-BILL-AMOUNT      PIC 9(8)V99.
          05 WS-BILL-COUNT         PIC 9(04) VALUE ZEROS.
          05 WS-MAX-BILLS          PIC 9(04) VALUE 1000.

       01 WS-REPORT-HEADER1.
          05 FILLER               PIC X(32) VALUE SPACES.
          05 FILLER               PIC X(18) VALUE 'ELE BILLING Report'.
          05 FILLER               PIC X(17) VALUE SPACES.
          05 FILLER               PIC X(5)  VALUE 'PAGE'.
          05 WS-RPT-PAGE-NUM      PIC ZZ9.

       01 WS-REPORT-HEADER2.
          05 FILLER               PIC X(32) VALUE SPACES.
          05 FILLER               PIC X(14) VALUE '--------------'.
          05 FILLER               PIC X(26) VALUE SPACES.

       01 WS-REPORT-HEADER3.
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 FILLER               PIC X(7)  VALUE 'BILL ID'.
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 FILLER               PIC X(7)  VALUE 'CUST ID'.
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 FILLER               PIC X(10) VALUE 'FIRST NAME'.
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 FILLER               PIC X(9)  VALUE 'LAST NAME'.
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 FILLER               PIC X(4)  VALUE 'AREA'.
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 FILLER               PIC X(5)  VALUE 'UNITS'.
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 FILLER               PIC X(10) VALUE 'AMOUNT(Rs)'.
          05 FILLER               PIC X(12) VALUE SPACES.

       01 WS-REPORT-DETAIL.
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 WS-RPT-BILL-ID       PIC X(12).
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 WS-RPT-CUST-ID       PIC X(13).
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 WS-RPT-FIRST-NAME    PIC X(10).
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 WS-RPT-LAST-NAME     PIC X(9).
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 WS-RPT-AREA          PIC X(6).
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 WS-RPT-UNITS         PIC ZZ9.
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 WS-RPT-AMOUNT        PIC ZZZ9.
          05 FILLER               PIC X(12) VALUE SPACES.

       01 WS-REPORT-TOTAL.
          05 FILLER               PIC X(1)  VALUE SPACES.
          05 FILLER               PIC X(11) VALUE 'TOTAL BILLS:'.
          05 WS-RPT-TOTAL-BILLS   PIC ZZZ9.
          05 FILLER               PIC X(5)  VALUE SPACES.
          05 FILLER               PIC X(12) VALUE 'TOTAL AMOUNT:'.
          05 WS-RPT-TOTAL-AMOUNT  PIC ZZZZZ9.
          05 FILLER               PIC X(30) VALUE SPACES.

       01 WS-REPORT-FOOTER.
          05 FILLER               PIC X(60) VALUE SPACES.
          05 FILLER               PIC X(5)   VALUE 'PAGE:'.
          05 WS-FTR-PAGE          PIC ZZ9.

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

           PERFORM 2100-OPEN-FILES-PHASE1.
           PERFORM 2200-PROCESS-METER-RECORDS.
           PERFORM 2300-CLOSE-FILES-PHASE1.
           
           PERFORM 2400-OPEN-FILES-PHASE2.
           PERFORM 2500-WRITE-BILL-RECORDS.
           PERFORM 2600-CLOSE-FILES-PHASE2.
           
           PERFORM 2800-WRITE-REPORT-TOTALS
           PERFORM 2760-WRITE-FOOTER.

       2100-OPEN-FILES-PHASE1  SECTION.

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

           OPEN OUTPUT TO01-BILL-RPT.
           IF NOT RPT-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING BILL REPORT FILE          '
              DISPLAY 'FILE  STATUS ', ' ',    WS-RPT-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           PERFORM 2750-WRITE-PAGE-HEADERS

           DISPLAY '----------------------------------------'
           DISPLAY 'METER KSDS    OPENED (PHASE 1) ............'
           DISPLAY 'CUSTOMER KSDS OPENED (PHASE 1) ............'
           DISPLAY 'BILL RPT      OPENED (PHASE 1) ............'
           DISPLAY '----------------------------------------'.

       2200-PROCESS-METER-RECORDS  SECTION.

           PERFORM 2210-READ-METER-KSDS UNTIL MTR-EOF.

       2210-READ-METER-KSDS  SECTION.

           READ MI01-METER-KSDS
                AT END  SET MTR-EOF TO TRUE
                DISPLAY '----------------------------------------'
                DISPLAY 'NO MORE METER RECORDS FOR BILLING ------'
                DISPLAY '----------------------------------------'

                NOT AT END  ADD 1  TO WS-READ-CTR
                            PERFORM 2220-READ-CUSTOMER

           END-READ.

       2220-READ-CUSTOMER SECTION.

           MOVE MTR-CUST-ID TO CUST-KEY.

           READ MI01-CUSTOMER-KSDS
                INVALID KEY
                   DISPLAY 'CUSTOMER NOT FOUND: ' CUST-KEY
                   ADD 1 TO WS-ERROR-CTR
                NOT INVALID KEY
                   PERFORM 2230-CALCULATE-BILL
           END-READ.

       2230-CALCULATE-BILL SECTION.

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

              PERFORM 2240-GENERATE-BILL-ID
              PERFORM 2250-STORE-BILL-TEMP
           END-IF.

       2240-GENERATE-BILL-ID SECTION.

           ADD 1 TO WS-BILL-SEQUENCE.
           
      *    Generate fully populated 12-character bill ID with leading zeros
           MOVE SPACES TO WS-TEMP-BILL-ID
           STRING "BILL-" DELIMITED BY SIZE
                  WS-BILL-SEQUENCE DELIMITED BY SIZE
                  INTO WS-TEMP-BILL-ID
           MOVE WS-TEMP-BILL-ID TO BILL-ID
           
           DISPLAY 'GENERATED BILL ID: ' WS-TEMP-BILL-ID.

       2250-STORE-BILL-TEMP SECTION.

           IF WS-BILL-COUNT >= WS-MAX-BILLS
              DISPLAY 'ERROR: BILL STORAGE FULL - MAX ' WS-MAX-BILLS
              ADD 1 TO WS-ERROR-CTR
           ELSE
              COMPUTE WS-BILL-COUNT = WS-BILL-COUNT + 1
              MOVE WS-BILL-COUNT TO WS-BILL-SUBSCRIPT
              SET WS-BILL-IDX TO WS-BILL-SUBSCRIPT
              
              MOVE WS-TEMP-BILL-ID 
                  TO WS-T-BILL-ID(WS-BILL-IDX)
              MOVE MTR-CUST-ID 
                  TO WS-T-BILL-CUST-ID(WS-BILL-IDX)
              MOVE MTR-ID 
                  TO WS-T-BILL-MTR-ID(WS-BILL-IDX)
              MOVE CUST-FIRST-NAME 
                  TO WS-T-BILL-FIRST-NAME(WS-BILL-IDX)
              MOVE CUST-LAST-NAME 
                  TO WS-T-BILL-LAST-NAME(WS-BILL-IDX)
              MOVE CUST-AREA-CODE 
                  TO WS-T-BILL-AREA-CODE(WS-BILL-IDX)
              MOVE CUST-ADDRESS 
                  TO WS-T-BILL-ADDRESS(WS-BILL-IDX)
              MOVE WS-UNITS-CONSUMED 
                  TO WS-T-BILL-UNITS(WS-BILL-IDX)
              MOVE WS-BILL-AMOUNT 
                  TO WS-T-BILL-AMOUNT(WS-BILL-IDX)
              
              ADD WS-BILL-AMOUNT TO WS-TOTAL-AMOUNT
              
              PERFORM 2700-WRITE-REPORT-LINE
           END-IF.

       2300-CLOSE-FILES-PHASE1  SECTION.

           CLOSE MI01-METER-KSDS,
                 MI01-CUSTOMER-KSDS.

           DISPLAY '----------------------------------------'
           DISPLAY 'METER KSDS    CLOSED (PHASE 1) ............'
           DISPLAY 'CUSTOMER KSDS CLOSED (PHASE 1) ............'
           DISPLAY '----------------------------------------'.

       2400-OPEN-FILES-PHASE2  SECTION.

           OPEN OUTPUT MO01-BILL-KSDS.
           IF NOT BILL-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING BILL MASTER KSDS (PHASE 2) '
              DISPLAY 'FILE  STATUS ', ' ',    WS-BILL-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           DISPLAY '----------------------------------------'
           DISPLAY 'BILL KSDS     OPENED (PHASE 2) ............'
           DISPLAY '----------------------------------------'.

       2500-WRITE-BILL-RECORDS SECTION.

           DISPLAY '----------------------------------------'
           DISPLAY 'WRITING ' WS-BILL-COUNT ' BILL RECORDS TO KSDS'
           DISPLAY '----------------------------------------'

           PERFORM VARYING WS-BILL-INDEX FROM 1 BY 1
                     UNTIL WS-BILL-INDEX > WS-BILL-COUNT
              SET WS-BILL-IDX TO WS-BILL-INDEX
              PERFORM 2510-WRITE-SINGLE-BILL
           END-PERFORM.

       2510-WRITE-SINGLE-BILL SECTION.

           MOVE WS-T-BILL-ID(WS-BILL-IDX) TO BILL-ID.
           MOVE WS-T-BILL-CUST-ID(WS-BILL-IDX) TO BILL-CUST-ID.
           MOVE WS-T-BILL-MTR-ID(WS-BILL-IDX) TO BILL-MTR-ID.
           MOVE WS-T-BILL-FIRST-NAME(WS-BILL-IDX) TO BILL-FIRST-NAME.
           MOVE WS-T-BILL-LAST-NAME(WS-BILL-IDX) TO BILL-LAST-NAME.
           MOVE WS-T-BILL-AREA-CODE(WS-BILL-IDX) TO BILL-AREA-CODE.
           MOVE WS-T-BILL-ADDRESS(WS-BILL-IDX) TO BILL-ADDRESS.
           MOVE WS-T-BILL-UNITS(WS-BILL-IDX) TO BILL-UNITS.
           MOVE WS-T-BILL-AMOUNT(WS-BILL-IDX) TO BILL-AMOUNT.

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
           END-WRITE.

       2600-CLOSE-FILES-PHASE2  SECTION.

           CLOSE MO01-BILL-KSDS.

           DISPLAY '----------------------------------------'
           DISPLAY 'BILL KSDS     CLOSED (PHASE 2) ............'
           DISPLAY '----------------------------------------'.

       2700-WRITE-REPORT-LINE SECTION.

           IF WS-LINE-COUNT >= WS-MAX-LINES
               PERFORM 2760-WRITE-FOOTER
               PERFORM 2750-WRITE-PAGE-HEADERS
           END-IF

           MOVE WS-T-BILL-ID(WS-BILL-IDX) TO WS-RPT-BILL-ID.
           MOVE WS-T-BILL-CUST-ID(WS-BILL-IDX) TO WS-RPT-CUST-ID.
           MOVE WS-T-BILL-FIRST-NAME(WS-BILL-IDX) TO WS-RPT-FIRST-NAME.
           MOVE WS-T-BILL-LAST-NAME(WS-BILL-IDX) TO WS-RPT-LAST-NAME.
           MOVE WS-T-BILL-AREA-CODE(WS-BILL-IDX) TO WS-RPT-AREA.
           MOVE WS-T-BILL-UNITS(WS-BILL-IDX) TO WS-RPT-UNITS.
           MOVE WS-T-BILL-AMOUNT(WS-BILL-IDX) TO WS-RPT-AMOUNT.

           WRITE TO01-BILL-RPT-RECORD FROM WS-REPORT-DETAIL

           ADD 1 TO WS-LINE-COUNT.

       2750-WRITE-PAGE-HEADERS SECTION.

           MOVE WS-PAGE-NUM TO WS-RPT-PAGE-NUM

           WRITE TO01-BILL-RPT-RECORD FROM WS-REPORT-HEADER1
           WRITE TO01-BILL-RPT-RECORD FROM WS-REPORT-HEADER2
           WRITE TO01-BILL-RPT-RECORD FROM WS-REPORT-HEADER3

           MOVE 3 TO WS-LINE-COUNT

           ADD 1 TO WS-PAGE-NUM.

       2760-WRITE-FOOTER SECTION.

           MOVE WS-PAGE-NUM TO WS-FTR-PAGE

           WRITE TO01-BILL-RPT-RECORD FROM WS-REPORT-FOOTER.

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

           CLOSE TO01-BILL-RPT.

           DISPLAY '----------------------------------------'
           DISPLAY 'BILL RPT      IS CLOSED          '
           DISPLAY '----------------------------------------'

           STOP RUN.
