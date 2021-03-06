      SUBROUTINE TRNSPS (Z,IZ)        
C        
C     MATRIX TRANSPOSE ROUTINE REPLACING NASTRAN ORIGINAL TRNSP, WHICH  
C     IS AT LEAST 2 TO 4 TIMES SLOWER (COMPARISON DONE ON VAX), AND     
C     USING UP TO 8 SCRATCH FILES        
C        
C     WITH BOTH IN-CORE AND OUT-OF-CORE LOGICS        
C     (USE TRANSP FOR IN-CORE MATRIX TRANSPOSE)        
C        
C     IF DGFLAG = -123457890 (SET BY DTRANP), AND INPUT IS A UPPER OR   
C     LOWER TRIANGULAR MATRIX, THE DIAGONAL ELEMENTS ARE REPLACED BY    
C     UNITY (1.0)        
C        
C     CALLER MUST SUPPLY A SCRATCH FILE ISCR, IF MATRIX TO BE TRANSPOSED
C     IS SQUARE, RECTANGULAR, LOWER, AND UPPER TRIAGULAR (FORM 1,2,4,5).
C        
C     THIS ROUTINE SETS UP THE OUTPUT MATRIX TRAILER WORDS IN NAMEAT    
C     (FILEAT) BUT IT DOES NOT CALL WRTTRL TO WRITE THEM OUT        
C        
C     WRITTEN BY G.CHAN/UNISYS  12/91        
C        
      LOGICAL          DEBUG        
      INTEGER          IZ(2),SYSBUF,BASE,FILE,DGFLAG,FILEA(7),FILEAT(7) 
      DIMENSION        Z(6),A(2),NAM(2)        
      DOUBLE PRECISION DA        
      CHARACTER        UFM*23,UWM*25,UIM*29        
      COMMON /XMSSG /  UFM,UWM,UIM        
      COMMON /BLANK /  DGFLAG        
      COMMON /TRNSPX/  NAMEA, NCOLA, NROWA, IFORMA,ITYPA, IA(2),        
     1                 NAMEAT,NCOLAT,NROWAT,IFORAT,ITYPAT,IAT(2),       
     2                 LCORE,NSCR,ISCR        
      COMMON /SYSTEM/  SYSBUF,NOUT        
      COMMON /PACKX /  IOTYP,IOTYPA,IP,JP,INCR        
      COMMON /UNPAKX/  IOTYP1,IU,JU,INCR1        
      COMMON /TYPE  /  RC(2),IWORDS(4)        
      COMMON /NAMES /  RD,RDREW,WRT,WRTREW,CLSREW        
      EQUIVALENCE      (FILEA(1),NAMEA),(FILEAT(1),NAMEAT),(A(1),DA)    
      DATA    NAM   /  4HTRNS,4HPS    /, DEBUG / .FALSE. /        
C        
      CALL SSWTCH (19,I)        
      IF (I .EQ. 1) DEBUG = .TRUE.        
      LAST   = 1        
      NTYPE  = IOTYPA        
      IF (NTYPE .EQ. 3) NTYPE = 2        
      IBUF1  = LCORE - SYSBUF        
      IBUF   = IBUF1 - SYSBUF        
      NZ     = IBUF  - 1        
      IMHERE = 10        
      IF (NZ .LE. 0) GO TO 820        
      NREC   = 0        
      FILE   = NAMEA        
      IF (IFORMA.GT.2 .OR. NCOLA.EQ.1)        
     1    CALL OPEN (*800,NAMEA,Z(IBUF1),RDREW)        
      DO 10 I = 2,7        
   10 FILEAT(I) = FILEA(I)        
      IF (DEBUG) WRITE (NOUT,20) FILEAT        
   20 FORMAT (' TRNSPS/@5 BEFORE TRANSPOSE, TRAIL-AT =',7I8)        
      GO TO (30,30,530,600,600,500,730,550), IFORMA        
C        
C     SQUARE AND RECTANGULAR MATRICES        
C     ===============================        
C        
   30 IF (NCOLA .EQ. 1) GO TO 580        
      NROWAT = NCOLA        
      NCOLAT = 0        
      IAT(1) = 0        
      IAT(2) = 0        
      IP   = 1        
      JP   = NROWAT        
      INCR = 1        
      NWD  = IWORDS(ITYPA)        
      NWD1 = NWD - 1        
      NWDS = NCOLA*NWD        
      IF (NREC .NE. 0) GO TO 40        
      IRAT = MIN0(MAX0((LCORE/100000+4)*NCOLA/NROWA,3),10)        
      IEND = (IBUF1-1-NWDS)/IRAT        
      IEND = MAX0(IEND,5000)        
      IEND1= IEND + 1        
      CALL UNPSCR (FILEA,ISCR,Z,IBUF1,IBUF,IEND,0,1)        
      NREC = FILEA(4)/10        
   40 FILE = ISCR        
      CALL OPEN (*800,ISCR,Z(IBUF1),RDREW)        
      J    = FILEA(6) - IEND*IRAT        
      IF (J .GT. 0) GO TO 200        
C        
C     ENTIRE FILEA (FROM ISCR FILE) FITS INTO CORE        
C        
      IF (DEBUG) WRITE (NOUT,50) UIM        
   50 FORMAT (A29,', MATRIX TRANSPOSE WAS PORCESSED BY THE NEW TRNSP ', 
     1        'IN-CORE METHOD')        
      CALL FWDREC (*810,ISCR)        
      LL = NWDS + 1        
      DO 60 I = 1,NREC        
      CALL READ (*810,*60,ISCR,Z(LL),IEND1,1,K)        
      IMHERE = 60        
      GO TO 820        
   60 LL = LL + K        
      CALL CLOSE (ISCR,CLSREW)        
C        
      FILE = NAMEAT        
      CALL OPEN (*800,NAMEAT,Z(IBUF1),WRTREW)        
      CALL FNAME (NAMEAT,A(1))        
      CALL WRITE (NAMEAT,A(1),2,1)        
C        
      DO 160 K = 1,NROWA        
      DO 70  J = 1,NWDS        
   70 Z(J) = 0.0        
      BASE = NWDS + 2        
      IF (NWD-2) 130,110,80        
   80 DO 100 I = 1,NCOLA        
      II = IZ(BASE-1)        
      JJ = IZ(BASE  )        
      IF (K.LT.II .OR. K.GT.JJ) GO TO 100        
      KX = (K-II)*NWD + BASE        
      LX = (I- 1)*NWD        
      DO 90 J = 1,NWD        
   90 Z(J+LX) = Z(J+KX)        
  100 BASE = BASE + (JJ-II+1)*NWD + 2        
      GO TO 150        
  110 DO 120 I = 1,NCOLA        
      II = IZ(BASE-1)        
      JJ = IZ(BASE  )        
      IF (K.LT.II .OR. K.GT.JJ) GO TO 120        
      KX = (K-II)*2 + BASE        
      LX = (I- 1)*2        
      Z(LX+1) = Z(KX+1)        
      Z(LX+2) = Z(KX+2)        
  120 BASE = BASE + (JJ-II+2)*2        
      GO TO 150        
  130 DO 140 I = 1,NCOLA        
      II = IZ(BASE-1)        
      JJ = IZ(BASE  )        
      IF (K.LT.II .OR. K.GT.JJ) GO TO 140        
      KX = K - II + BASE        
      Z(I) = Z(KX+1)        
  140 BASE = BASE + JJ - II + 3        
  150 CALL PACK (Z(1),NAMEAT,NAMEAT)        
  160 CONTINUE        
      GO TO 450        
C        
C     ENTIRE FILEA CAN NOT FIT INTO CORE        
C        
C     OPEN CORE ALLOCATION -             N1    N2              NZ       
C                                        /     /  <-- IEND --> /        
C     +----------------------------------+-----+---------------+---+---+
C      /          OPEN CORE               /     /                GINO   
C     I1                                 I2    I3               BUFFERS 
C        
C      Z(I1)... Z(N1) FOR TRANSPOSED OUTPUT MATRIX NAMEAT        
C     IZ(I2)...IZ(N2) IS A (3 x NREC) TABLE, (MIN, MAX, COLUMN COUNTER) 
C               CONTROLLING DATA TRANSFER FROM SCRATCH FILE ISCR.       
C      Z(I3)... Z(NZ) FOR INPUT MATRIX NAMEA COMING FROM ISCR        
C        
C     NOTE - THE RATIO OF (N1-I1)/(NZ-I3), WHICH IS IRAT, IS A FUNCTION 
C            OF OPEN CORE SIZE, AND THE MATRIX COLUMN AND ROW SIZES.    
C            IRAT IS LIMITED TO 10:1        
C     NCPP = NO. OF COULMNS PER PASS, OF THE TRANSPOSE MATRIX NAMEAT    
C        
C     THE TERMS 'ROW' AND 'COLUMN' ARE LOOSELY DEFINED IN COMMENT LINES 
C        
  200 N2   = NZ - IEND        
      I3   = N2 + 1        
      N1   = N2 - 3*NREC        
      I2   = N1 + 1        
C     I1   = 1        
      NCPP = N1/NWDS        
      NCP7 = NCPP*7        
      NPAS = (NCOLA+NCPP-1)/NCPP        
C     NCP3 = NCPP*3        
C     NCM3 = NCPP*(NPAS-3)        
      IF (.NOT.DEBUG .AND. J.GT.3*NZ) GO TO 230        
      WRITE  (NOUT,210) UIM,NPAS,J        
  210 FORMAT (A29,', MATRIX TRANSPOSE WAS PROCESSED BY THE NEW TRNSP ', 
     1        'OUT-OF-CORE METHOD WITH',I5,' NO. OF PASSES', /5X,       
     2        '(FOR MAXIMUM EFFECIENCY, THE IN-CORE METHOD COULD BE ',  
     3        'ACTIVATED WITH',I9,' ADDITIONAL OPEN CORE WORDS)')       
      WRITE  (NOUT,220) N1,IEND,IRAT,NCPP,NPAS,NREC        
  220 FORMAT (/5X,'OPEN CORE -',I9,' WORDS USED FOR TRANSPOSE OUTPUT ', 
     1       'MATRIX, AND',I8,' WORDS FOR INPUT MATRIX (',I2,'/1 RATIO)'
     2,      /5X,'NO. OF COLUMNS PER PASS =',I5,',  NO. OF PASSES =',I6,
     3       ',  INPUT MATRIX REWRITTEN IN',I4,' RECORDS')        
  230 FILE = NAMEAT        
      CALL OPEN  (*800,NAMEAT,Z(IBUF),WRTREW)        
      CALL FNAME (NAMEAT,A(1))        
      CALL WRITE (NAMEAT,A(1),2,1)        
      DO 240 MM = I2,N2,3        
      IZ(MM  ) = NROWA        
  240 IZ(MM+1) = 0        
      CALL TMTOGO (T1)        
C        
C     OUTER KB-KE LOOP        
C        
C     MAP DATA INTO TRANSPOSE OUTPUT MATRIX SPACE, Z(I1)...Z(N1), BY    
C     PASSES. EACH PASS RANGES FROM KB THRU KE COLUMNS        
C        
      FILE = ISCR        
      KE = 0        
  250 KB = KE + 1        
      KE = KE + NCPP        
      IF (KE .GT. NROWA) KE = NROWA        
      IF (KE .NE.  NCP7) GO TO 270        
      IF (DEBUG) WRITE (NOUT,260) (IZ(J),J=I2,N2)        
  260 FORMAT ('  IZ(I2...N2) =',18I6, /,(15X,18I6))        
      CALL TMTOGO (T2)        
      T1 = (T1-T2)*0.143        
      T1 = T1*FLOAT(NPAS)        
      IF (T1 .GT. T2) GO TO 880        
  270 CALL REWIND (ISCR)        
      CALL FWDREC (*810,ISCR)        
      KBE = (KE-KB+1)*NWDS        
      DO 280 J = 1,KBE        
  280 Z(J) = 0.0        
      MM = N1 - 3        
      LL = 0        
      BASE = 2        
C        
C     MIDDLE I-LOOP        
C        
C     LOAD DATA FROM ISCR/NAMEA INTO Z(I3)...Z(NZ) WHEN NEEDED.        
C     AND RUN THRU EACH ROW OF MATRIX NAMEA IN THIS LOOP        
C        
      I  = 0        
  300 I  = I + 1        
      IF (I .GT. NCOLA) GO TO 430        
      IF (BASE .LT. LL) GO TO 340        
      MM = MM + 3        
      IF (KB .EQ. 1) GO TO 320        
C        
C     IF NOT FIRST PASS, CHECK KB AND KE AGAINST MIN/MAX TABLE IN IZ(I2)
C     THRU IZ(N2). IF THEY ARE OUTSIDE RANGE, SKIP NEXT DATA RECORD FROM
C     ISCR FILE AND UPDATE COLUMN COUNTER I        
C        
      IF (.NOT.(KB.GT.IZ(MM+2) .OR. KE.LT.IZ(MM+1))) GO TO 320        
C     IF (DEBUG .AND. (KE.LE.NCP3 .OR. KE.GE.NCM3))        
C    1    WRITE (NOUT,310)  I,KB,KE,(IZ(MM+J),J=1,3)        
C 310 FORMAT (' ==FWDREC==> I,KB,KE,IZ(MM+1,+2,+3) =',6I7)        
      CALL FWDREC (*810,ISCR)        
      I  = IZ(MM+3)        
      GO TO 300        
  320 CALL READ (*810,*330,ISCR,Z(I3),IEND1,1,LL)        
      IMHERE = 160        
      GO TO 820        
  330 LL = N2 + LL        
      BASE = N2 + 2        
  340 II = IZ(BASE-1)        
      JJ = IZ(BASE  )        
      IF (KB .GT. 1) GO TO 350        
C        
C     DURING FIRST PASS, SAVE MIN-II, MAX-JJ, AND COLUMN I IN IZ(MM)    
C     TABLE. MM RUNS FROM I2 THRU N2.        
C        
      IF (II .LT. IZ(MM+1)) IZ(MM+1) = II        
      IF (JJ .GT. IZ(MM+2)) IZ(MM+2) = JJ        
      IZ(MM+3) = I        
C        
  350 IIKB = MAX0(II,KB)        
      JJKE = MIN0(JJ,KE)        
      IF (JJKE .LT. IIKB) GO TO 420        
C        
C     INNER K-LOOP        
C        
C     RUN THRU THE IIKB-JJKE ELEMENTS FOR EACH ROW OF MATRIX NAMEA,     
C        
C     KK = (IIKB-KB)*NWDS        
C     LX = (I-1)*NWD + KK + 1        
C     KK = BASE -  II*NWD + 1        
C        
      LX = (I-1)*NWD + (IIKB-KB)*NWDS + 1        
      KX = (IIKB-II)*NWD + BASE + 1        
      IF (NWD-2) 360,380,400        
  360 DO 370 K = IIKB,JJKE        
      Z(LX) = Z(KX)        
      KX = KX + 1        
  370 LX = LX + NWDS        
      GO TO 420        
  380 DO 390 K = IIKB,JJKE        
      Z(LX  ) = Z(KX  )        
      Z(LX+1) = Z(KX+1)        
      KX = KX + 2        
  390 LX = LX + NWDS        
      GO TO 420        
  400 DO 410 K = IIKB,JJKE        
      Z(LX  ) = Z(KX  )        
      Z(LX+1) = Z(KX+1)        
      Z(LX+2) = Z(KX+2)        
      Z(LX+3) = Z(KX+3)        
      KX = KX + 4        
  410 LX = LX + NWDS        
C        
C     END OF INNER K-LOOP        
C        
C     ADJUST BASE FOR ANOTHER ROW OF MATRIX NAMEA        
C        
  420 BASE = BASE + (JJ-II+1)*NWD + 2        
      GO TO 300        
C        
C     END OF MIDDLE I-LOOP        
C        
C     PACK THE KB THRU KE COLUMNS OF THE TRANSPOSE MATRIX NAMEAT OUT    
C        
  430 DO 440 J = 1,KBE,NWDS        
      CALL PACK (Z(J),NAMEAT,NAMEAT)        
  440 CONTINUE        
C        
      IF (KE .LT. NROWA) GO TO 250        
      CALL CLOSE (ISCR,1)        
C        
C     END OF OUTTER KB-KE LOOP, AND        
C     END OF SQUARE AND RECTANGULAR MATRIX TRNASPOSE        
C        
C     OPEN AND CLOSE SCRATCH FILE AGAIN TO PHYSICALLY DELETE THE FILE.  
C     MATRIX TRAILER WILL BE WRITTEN OUT BY DTRANP        
C        
  450 CALL CLOSE (NAMEAT,CLSREW)        
      CALL GOPEN (ISCR,Z(IBUF1),WRTREW)        
      CALL CLOSE (ISCR,CLSREW)        
      GO TO 900        
C        
C     SYMMETRIC MATRIX        
C     ================        
C        
  500 IF (NCOLA .EQ. NROWA) GO TO 520        
      CALL FNAME (NAMEA,A)        
      WRITE  (NOUT,510) UWM,A,NCOLA,NROWA        
  510 FORMAT (A25,' FROM TRNSP, ',2A4,' MATRIX (',I7,4H BY ,I7,        
     1        ') IS NOT SYMMETRIC NOR SQUARE ', /5X,        
     2        'IT WILL BE TREATED AS RECTANGULAR')        
      CALL CLOSE (NAMEA,CLSREW)        
      GO TO 30        
  520 FILE   = NAMEAT        
      CALL OPEN (*800,NAMEAT,Z(IBUF),WRTREW)        
      CALL CPYFIL (NAMEA,NAMEAT,Z(1),NZ,K)        
      CALL CLOSE (NAMEAT,CLSREW)        
      CALL CLOSE (NAMEA, CLSREW)        
      IF (DEBUG) WRITE (NOUT,525) FILEAT        
  525 FORMAT (' TRNSPS/@525 AFTER TRANSPOSE, TRAIL-AT =',7I8)        
      GO TO 900        
C        
C     DIAGONAL MATRIX        
C     ===============        
C     DIAGONAL MATRIX (IFORMA=3) IS A ONE-COLUMN MATRIX. (1xN)        
C        
C     THE MATRIX AT RIGHT IS SQUARE (IFORMA=1),      1.  0.  0.        
C     OR RECTANGULAR (IFORMA=2), AND IS NOT          0.  2.  0.        
C     DIAGONAL (IFORMA=3) IN NASTRAN TERMINOLOGY     0.  0.  1.        
C        
  530 GO TO 520        
C        
C     IDENTITY MATRIX        
C     ===============        
C     SIMILAR TO DIAGONAL MATRIX, INDENTITY MATRIX (IFORMA = 8) IS ALSO 
C     IN ONE-COLUMN MATRIX FORM        
C        
C     ALSO, THE IDENTITY MATRIX MAY EXIST ONLY IN THE MATRIX TRAILER.   
C     IT DOES NOT PHYSICALLY EXIST.        
C        
C        
  550 CALL READ (*900,*900,NAMEA,Z(1),1,1,J)        
      CALL BCKREC (NAMEA)        
      GO TO 520        
C        
C     ONE-COLUMN (1xN) RECTANGUALR MATRIX        
C     ===================================        
C     TRANSPOSE IS A ROW VECTOR, FORM=7. THE TRAILER REMAINS 1xN.       
C        
  580 IF (NCOLA .NE. 1) GO TO 860        
      IFORAT = 8        
      GO TO 520        
C        
C     UPPER OR LOWER TRIANGULAR MATRICES        
C     ==================================        
C        
C     TRANSPOSE OF UPPER TRIANGULAR MATRIX IS THE LOWER TRIANG. MATRIX  
C     AND VISE VERSA        
C        
C     (IS THIS HOW THE UPPER OR LOWER TRIANGULAR MATRIX WRITTEN? <==?   
C        
C     NO! IT IS NOT. WE STOP TRNSP SENDING THESE MATRICES OVER HERE.    
C     BESIDE, THE LOGIC OF WRITING THE MATRIX BACKWARD HERE IS NOT      
C     CORRECT. WE HAVE NOT ACCOMPLISHED THE TRANSPOSE OF THE ORIGINAL   
C     MATRIX YET. ALSO, WE SHOULD WRITE THE TRANSPOSE MATRIX OUT BY     
C     STRINGS, OR PACK THE MATRIX OUT)        
C        
  600 IMHERE = 600        
      N1   = -37        
      IF (N1 .EQ. -37) GO TO 830        
      CALL GOPEN (ISCR,Z(IBUF),WRTREW)        
      CALL SKPREC (NAMEA,NCOLA)        
      NWD  = IWORDS(ITYPA)        
      IRAT = 3        
      IEND = (IBUF-1-NWD*NCOLA)/IRAT        
      IEND1= IEND + 1        
      ISUM = 0        
      DO 720 I = 1,NCOLA        
      IU   = 0        
      CALL UNPACK (*830,NAMEA,Z(3))        
      IZ(1) = IU        
      IZ(2) = JU        
      LL   = (JU-IU+1)*NWD + 2        
      ISUM = ISUM + LL        
      IF (ISUM .LE. IEND) GO TO 610        
      NREC = NREC + 1        
      CALL WRITE (ISCR,0,0,1)        
      ISUM = LL        
  610 IF (DGFLAG .NE. -123457890) GO TO 710        
      IF (IFORMA .EQ. 5) GO TO 660        
      GO TO (620,630,640,650), ITYPA        
  620 Z(3) = 1.0        
      GO TO 710        
  630 DA = 1.0D+0        
      Z(3) = A(1)        
      Z(4) = A(2)        
      GO TO 710        
  640 Z(4) = 0.0        
      GO TO 620        
  650 Z(5) = 0.0        
      Z(6) = 0.0        
      GO TO 630        
  660 GO TO (670,680,690,700), ITYPA        
  670 Z(JU+2) = 1.0        
      GO TO 710        
  680 DA = 1.0D+0        
      Z(JU*2+1) = A(1)        
      Z(JU*2+2) = A(2)        
      GO TO 710        
  690 Z(JU*2+1) = 1.0        
      Z(JU*2+2) = 0.0        
      GO TO 710        
  700 J  = JU*4 - 3        
      DA = 1.0D+0        
      Z(J+1) = A(1)        
      Z(J+2) = A(2)        
      Z(J+3) = 0.0        
      Z(J+4) = 0.0        
  710 CALL WRITE (ISCR,Z(1),LL,0)        
      CALL BCKREC (NAMEA)        
      CALL BCKREC (NAMEA)        
  720 CONTINUE        
      NREC = NREC + 1        
      CALL WRITE (ISCR,0,0,1)        
      CALL CLOSE (NAMEA,CLSREW)        
      CALL CLOSE (ISCR ,CLSREW)        
      ITYPAT = ITYPA        
      IF (IFORMA .EQ. 4) IFORAT = 5        
      IF (IFORMA .EQ. 5) IFORAT = 4        
      IAT(1) = IA(1)        
      IAT(2) = IA(2)        
      DGFLAG = 0        
      FILEA(4) = NREC*10        
      FILEA(6) = ISUM        
      GO TO 30        
C        
C     ROW VECTOR (IFORMA=7, 1xN)        
C     ==========================        
C        
C     A ROW VECTOR IS A ROW OF MATRIX ELEMENTS STORED IN COLUMN FORMAT  
C     WITH TRAILER 1xN (NOT Nx1). THEREFORE THE TRANSPOSE OF ROW VECTOR 
C     (IFORMA=7) IS A COLUMN VECTOR, WHICH IS RECTANG. (IFORAT=2).      
C     THE TRAILER REMAINS UNCHANGED        
C        
  730 IF (NCOLA .NE. 1) GO TO 860        
      IFORAT = 2        
      GO TO 520        
C        
C     ERROR MESSAGES        
C        
  800 IF (IFORMA .EQ. 8) GO TO 900        
      N1 = -1        
      GO TO 850        
  810 N1 = -2        
      GO TO 850        
  820 N1 = -8        
  830 WRITE  (NOUT,840) IMHERE        
  840 FORMAT (/5X,'IMHERE =',I5)        
  850 CALL MESAGE (N1,FILE,NAM)        
  860 CALL FNAME (NAMEA,A)        
      WRITE  (NOUT,870) UFM,A,IFORMA,NCOLA,NROWA        
  870 FORMAT (A23,' FROM TRNSPS, INPUT MATRIX ',2A4,' IS NOT SUITABLE ',
     1        'FOR MATRIX TRANSPOSE.', /5X,'FORM, COLUMN, ROW =',3I6)   
      CALL MESAGE (-37,NAMEA,NAM)        
  880 WRITE  (NOUT,890) UFM,T1        
  890 FORMAT (A23,', INSUFFICIENT TIME REMAINING FOR MATRIX TRANSPOSE', 
     1       /5X,'ESTIMATED TIME NEEDED (FOR TRANSPOSE ALONE) =',I9,    
     2       ' CPU SECONDS')        
      CALL MESAGE (-37,0,NAM)        
C        
  900 RETURN        
      END        
