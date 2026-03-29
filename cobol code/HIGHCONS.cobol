       IDENTIFICATION DIVISION.
       PROGRAM-ID.  highcons.

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

           SELECT TO01-HIGH-CONS-RPT ASSIGN TO HIGHCONS
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

       FD TO01-HIGH-CONS-RPT
           RECORDING MODE          IS F
           RECORD CONTAINS         139 CHARACTERS.

       01 TO01-HIGH-CONS-RPT-RECORD PIC X(133).

       WORKING-STORAGE SECTION.

       01 WS-FILE-STATUS-CODES.
          05 WS-MTR-STATUS       PIC X(02).
             88 MTR-IO-STATUS    VALUE '00'.
             88 MTR-EOF          VALUE '10'.
          05 WS-CUST-STATUS      PIC X(02).
             88 CUST-IO-STATUS   VALUE '00'.
             88 CUST-NOT-FOUND   VALUE '23'.
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

       01 WS-CALC-VARIABLES.
          05 WS-PREV-READ-NUM      PIC 9(06) VALUE 0.
          05 WS-CURR-READ-NUM      PIC 9(06) VALUE 0.
          05 WS-UNITS-CONSUMED     PIC 9(06) VALUE 0.

       01 WS-REPORT-VARIABLES.
          05 WS-PAGE-NUM           PIC 9(03) VALUE 1.
          05 WS-LINE-COUNT         PIC 9(03) VALUE 0.
          05 WS-MAX-LINES          PIC 9(03) VALUE 10.

       01 WS-COUNTERS.
          05 WS-READ-CTR           PIC 9(04) VALUE ZEROS.
          05 WS-WRITE-CTR          PIC 9(04) VALUE ZEROS.
          05 WS-ERROR-CTR          PIC 9(04) VALUE ZEROS.
          05 WS-CUSTOMER-COUNT     PIC 9(04) VALUE ZEROS.

       01 WS-HIGH-CONS-STORAGE.
          05 WS-HIGH-CONS-TABLE.
             10 WS-HIGH-CONS-RECORD OCCURS 1000 TIMES
                                 INDEXED BY WS-HIGH-IDX.
                15 WS-H-CUST-ID          PIC X(12).
                15 WS-H-FIRST-NAME       PIC X(10).
                15 WS-H-LAST-NAME        PIC X(10).
                15 WS-H-AREA-CODE        PIC X(6).
                15 WS-H-ADDRESS          PIC X(29).
                15 WS-H-CITY             PIC X(10).
                15 WS-H-UNITS            PIC 9(6).
          05 WS-HIGH-COUNT         PIC 9(04) VALUE ZEROS.
          05 WS-MAX-CUSTOMERS      PIC 9(04) VALUE 1000.

        01 WS-SORT-WORK-AREA.
          05 WS-SORT-TABLE.
             10 WS-SORT-RECORD OCCURS 1000 TIMES
                                INDEXED BY WS-SORT-IDX WS-SORT-IDX2.
                15 WS-S-UNITS-CONSUMED   PIC 9(6).
                15 WS-S-INDEX            PIC 9(4).
          05 WS-SORT-COUNT         PIC 9(04) VALUE ZEROS.

       01 WS-REPORT-HEADER1.
          05 FILLER               PIC X(40) VALUE SPACES.
          05 FILLER               PIC X(30) VALUE 'top5 high Report'.
          05 FILLER               PIC X(53) VALUE SPACES.
          05 FILLER               PIC X(5)  VALUE 'PAGE'.
          05 WS-RPT-PAGE-NUM      PIC ZZ9.
       01 WS-REPORT-HEADER2.
          05 FILLER               PIC X(40) VALUE SPACES.
          05 FILLER               PIC X(30) VALUE '--------------'.
       01 WS-REPORT-HEADER3.
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 FILLER               PIC X(8)  VALUE 'rank'.
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
       01 WS-REPORT-DETAIL.
          05 FILLER               PIC X(3)  VALUE SPACES.
          05 WS-RPT-RANK          PIC Z9.
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 WS-RPT-CUST-ID       PIC X(12).
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 WS-RPT-FIRST-NAME    PIC X(10).
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 WS-RPT-LAST-NAME     PIC X(10).
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 WS-RPT-AREA          PIC X(6).
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 WS-RPT-CITY          PIC X(10).
          05 FILLER               PIC X(2)  VALUE SPACES.
          05 WS-RPT-UNITS         PIC ZZZ,ZZ9.
          05 FILLER               PIC X(52) VALUE SPACES.

       01 WS-REPORT-FOOTER.
          05 FILLER               PIC X(120) VALUE SPACES.
          05 FILLER               PIC X(5)   VALUE 'PAGE:'.
          05 WS-FTR-PAGE          PIC ZZ9.


       01 WS-TEMP-VARIABLES.
          05 WS-TEMP-UNITS        PIC 9(06).
          05 WS-TEMP-INDEX        PIC 9(04).
          05 WS-RANK-COUNTER      PIC 9(02).
          05 WS-HIGH-LOOP-CTR     PIC 9(04).
          05 WS-SORT-LOOP-CTR     PIC 9(04).
          05 WS-TEMP-SORT-IDX     PIC 9(04).
          05 WS-TEMP-RANK-IDX     PIC 9(04).
          05 WS-TEMP-LOOP-CTR1    PIC 9(04).
          05 WS-TEMP-LOOP-CTR2    PIC 9(04).

       01 WS-TOP5.
          05 WS-TOP-UNITS OCCURS 5 TIMES PIC 9(06) VALUE ZEROS.
          05 WS-TOP-IDX   OCCURS 5 TIMES PIC 9(04) VALUE ZEROS.

       PROCEDURE DIVISION.
       0000-MAIN-LINE   SECTION.

           PERFORM 1000-INITIALIZE.
           PERFORM 2000-PROCESS.
           PERFORM 9000-TERMINATE.
       1000-INITIALIZE  SECTION.

           DISPLAY '----------------------------------------'
           DISPLAY 'HIGHCONS EXECUTION BEGINS HERE ........'
           DISPLAY '  TOP 5 HIGH UNITS CONSUMERS REPORT      '
           DISPLAY '----------------------------------------'

           ACCEPT WS-DATE FROM DATE YYYYMMDD.
           MOVE WS-DD TO WS-REPORT-DATE(1:2)
           MOVE '/'   TO WS-REPORT-DATE(3:1)
           MOVE WS-MM TO WS-REPORT-DATE(4:2)
           MOVE '/'   TO WS-REPORT-DATE(6:1)
           MOVE WS-YY TO WS-REPORT-DATE(7:2).

       2000-PROCESS     SECTION.

           PERFORM 2100-OPEN-FILES.
           PERFORM 2200-PROCESS-METER-RECORDS.
           PERFORM 2300-SORT-HIGH-CONSUMERS.
           PERFORM 2400-WRITE-TOP-FIVE-REPORT.
           PERFORM 2500-CLOSE-FILES.

       2100-OPEN-FILES SECTION.

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
              DISPLAY 'ERROR OPENING CUSTOMER MASTER KSDS          '
              DISPLAY 'FILE  STATUS ', ' ',    WS-CUST-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           OPEN OUTPUT TO01-HIGH-CONS-RPT.
           IF NOT RPT-IO-STATUS
              DISPLAY '----------------------------------------'
              DISPLAY 'ERROR OPENING highcons REPORT FILE      '
              DISPLAY 'FILE  STATUS ', ' ',    WS-RPT-STATUS
              DISPLAY '----------------------------------------'
              STOP RUN
           END-IF.

           PERFORM 2750-WRITE-PAGE-HEADERS
           DISPLAY '----------------------------------------'
           DISPLAY 'METER KSDS    OPENED ..............'
           DISPLAY 'CUSTOMER KSDS OPENED ..............'
           DISPLAY 'highcons      OPENED .............'
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
                   PERFORM 2230-CALCULATE-units
           END-READ.

       2230-CALCULATE-units SECTION.

           COMPUTE WS-PREV-READ-NUM = MTR-PREV-READ
           COMPUTE WS-CURR-READ-NUM = MTR-CURR-READ

           IF WS-CURR-READ-NUM < WS-PREV-READ-NUM
              DISPLAY 'ERROR: CURR < PREV FOR CUST ' CUST-KEY
              ADD 1 TO WS-ERROR-CTR
           ELSE
              COMPUTE WS-UNITS-CONSUMED =
                      WS-CURR-READ-NUM - WS-PREV-READ-NUM

              PERFORM 2240-STORE-HIGH-CONS
           END-IF.

       2240-STORE-HIGH-CONS  SECTION.

           IF WS-HIGH-COUNT >= WS-MAX-CUSTOMERS
              DISPLAY 'ERROR: HIGH CONS STORAGE FULL - MAX '
                      WS-MAX-CUSTOMERS
              ADD 1 TO WS-ERROR-CTR
           ELSE
              COMPUTE WS-HIGH-COUNT = WS-HIGH-COUNT + 1
              SET WS-HIGH-IDX TO WS-HIGH-COUNT

              MOVE MTR-CUST-ID
                  TO WS-H-CUST-ID(WS-HIGH-IDX)
              MOVE CUST-FIRST-NAME
                  TO WS-H-FIRST-NAME(WS-HIGH-IDX)
              MOVE CUST-LAST-NAME
                  TO WS-H-LAST-NAME(WS-HIGH-IDX)
              MOVE CUST-AREA-CODE
                  TO WS-H-AREA-CODE(WS-HIGH-IDX)
              MOVE CUST-ADDRESS
                  TO WS-H-ADDRESS(WS-HIGH-IDX)
              MOVE CUST-CITY
                  TO WS-H-CITY(WS-HIGH-IDX)
              MOVE WS-UNITS-CONSUMED
                  TO WS-H-UNITS(WS-HIGH-IDX)

              ADD 1 TO WS-CUSTOMER-COUNT
           END-IF.

       2300-SORT-HIGH-CONSUMERS SECTION.
           DISPLAY '----------------------------------------'
           DISPLAY 'SORTING ' WS-CUSTOMER-COUNT
                   ' CUSTOMERS BY UNITS CONSUMED ......'
           DISPLAY '----------------------------------------'

           MOVE WS-CUSTOMER-COUNT TO WS-SORT-COUNT

           PERFORM VARYING WS-HIGH-LOOP-CTR FROM 1 BY 1
                     UNTIL WS-HIGH-LOOP-CTR > WS-SORT-COUNT
              SET WS-HIGH-IDX TO WS-HIGH-LOOP-CTR
              SET WS-SORT-IDX TO WS-HIGH-LOOP-CTR
              MOVE WS-H-UNITS(WS-HIGH-IDX)
                  TO WS-S-UNITS-CONSUMED(WS-SORT-IDX)
              MOVE WS-HIGH-LOOP-CTR TO WS-S-INDEX(WS-SORT-IDX)
           END-PERFORM

           PERFORM 2360-FIND-TOP5.

      2360-FIND-TOP5 SECTION.

       DISPLAY '----- FINDING TOP 5 CONSUMERS -----'

       PERFORM VARYING WS-HIGH-LOOP-CTR FROM 1 BY 1
               UNTIL WS-HIGH-LOOP-CTR > WS-HIGH-COUNT

           SET WS-HIGH-IDX TO WS-HIGH-LOOP-CTR
           MOVE 'N' TO WS-FOUND-FLAG

           PERFORM VARYING WS-RANK-COUNTER FROM 1 BY 1
                   UNTIL WS-RANK-COUNTER > 5
                      OR WS-FOUND-FLAG = 'Y'

               IF WS-H-UNITS(WS-HIGH-IDX) >
                  WS-TOP-UNITS(WS-RANK-COUNTER)

                  * Shift values down
                  PERFORM VARYING WS-TEMP-LOOP-CTR1 FROM 5 BY -1
                          UNTIL WS-TEMP-LOOP-CTR1 <= WS-RANK-COUNTER

                      MOVE WS-TOP-UNITS(WS-TEMP-LOOP-CTR1 - 1)
                          TO WS-TOP-UNITS(WS-TEMP-LOOP-CTR1)

                      MOVE WS-TOP-IDX(WS-TEMP-LOOP-CTR1 - 1)
                          TO WS-TOP-IDX(WS-TEMP-LOOP-CTR1)

                  END-PERFORM

                  * Insert value
                  MOVE WS-H-UNITS(WS-HIGH-IDX)
                      TO WS-TOP-UNITS(WS-RANK-COUNTER)

                  MOVE WS-HIGH-LOOP-CTR
                      TO WS-TOP-IDX(WS-RANK-COUNTER)

                  MOVE 'Y' TO WS-FOUND-FLAG

               END-IF

           END-PERFORM

       END-PERFORM. 
      2400-WRITE-TOP-FIVE-REPORT SECTION.
           DISPLAY '----------------------------------------'
           DISPLAY 'WRITING TOP 5 HIGH CONSUMERS REPORT .....'
           DISPLAY '----------------------------------------'

           PERFORM VARYING WS-RANK-COUNTER FROM 1 BY 1
                     UNTIL WS-RANK-COUNTER > 5
              IF WS-RANK-COUNTER <= WS-SORT-COUNT
                 PERFORM 2410-WRITE-SINGLE-RECORD
              END-IF
           END-PERFORM.

       2410-WRITE-SINGLE-RECORD SECTION.
           MOVE WS-RANK-COUNTER TO WS-TEMP-RANK-IDX
           SET WS-SORT-IDX TO WS-TEMP-RANK-IDX
           SET WS-HIGH-IDX TO WS-S-INDEX(WS-SORT-IDX)

           IF WS-LINE-COUNT >= WS-MAX-LINES
               PERFORM 2760-WRITE-FOOTER
               PERFORM 2750-WRITE-PAGE-HEADERS
           END-IF

           MOVE WS-RANK-COUNTER TO WS-RPT-RANK
           MOVE WS-H-CUST-ID(WS-HIGH-IDX) TO WS-RPT-CUST-ID
           MOVE WS-H-FIRST-NAME(WS-HIGH-IDX) TO WS-RPT-FIRST-NAME
           MOVE WS-H-LAST-NAME(WS-HIGH-IDX) TO WS-RPT-LAST-NAME
           MOVE WS-H-AREA-CODE(WS-HIGH-IDX) TO WS-RPT-AREA
           MOVE WS-H-CITY(WS-HIGH-IDX) TO WS-RPT-CITY
           MOVE WS-H-UNITS(WS-HIGH-IDX) TO WS-RPT-UNITS

           WRITE TO01-HIGH-CONS-RPT-RECORD FROM WS-REPORT-DETAIL

           ADD 1 TO WS-LINE-COUNT
           ADD 1 TO WS-WRITE-CTR.

       2500-CLOSE-FILES  SECTION.

           CLOSE MI01-METER-KSDS,
                 MI01-CUSTOMER-KSDS,
                 TO01-HIGH-CONS-RPT.

           DISPLAY '----------------------------------------'
           DISPLAY 'METER KSDS    CLOSED ........................'
           DISPLAY 'CUSTOMER KSDS CLOSED ........................'
           DISPLAY 'HIGH CONS RPT CLOSED ........................'
           DISPLAY '----------------------------------------'.

       2750-WRITE-PAGE-HEADERS SECTION.

           MOVE WS-PAGE-NUM TO WS-RPT-PAGE-NUM

           WRITE TO01-HIGH-CONS-RPT-RECORD FROM WS-REPORT-HEADER1
           WRITE TO01-HIGH-CONS-RPT-RECORD FROM WS-REPORT-HEADER2
           WRITE TO01-HIGH-CONS-RPT-RECORD FROM WS-REPORT-HEADER3

           MOVE 3 TO WS-LINE-COUNT

           ADD 1 TO WS-PAGE-NUM.
       2760-WRITE-FOOTER SECTION.

           MOVE WS-PAGE-NUM TO WS-FTR-PAGE
           WRITE TO01-HIGH-CONS-RPT-RECORD FROM WS-REPORT-FOOTer.
       9000-TERMINATE   SECTION.

           DISPLAY '----------------------------------------'
           DISPLAY ' INPUT RECORDS PROCESSED  ',  WS-READ-CTR
           DISPLAY ' BILLS WRITTEN            ',  WS-WRITE-CTR
           DISPLAY ' ERRORS                   ',  WS-ERROR-CTR
           DISPLAY ' TOTAL CUSTOMERS         ',  WS-CUSTOMER-COUNT
           DISPLAY '----------------------------------------'

           STOP RUN.
