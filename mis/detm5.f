      SUBROUTINE DETM5        
C        
C     WRITES EIGENVALUE SUMMARY FOR DETERMINANT METHOD        
C        
      DOUBLE PRECISION PSAVE(1),DET(1), PS(1)        
      INTEGER IPDET(8),SYSBUF        
      DIMENSION CORE(5)        
C        
      COMMON /CONDAS/ CONSTS(5)        
      COMMON /DETMX/ P(32),N2EV,IPSAV,IPS,IDET,IPDETA,PREC,NSTART,      
     1  NDCMP,IC,NSMOVE,ITERM,IS,ND,IADD,SML1,IPDETX(4),IPDET1(4),      
     2 IFAIL,K,FACT1,IFFND,NFAIL        
      COMMON /REGEAN/ IM(26),LCORE,RMAX,RMIN,MZ, NEV, EPSI, RMINR, NE,  
     1  NIT, NEVM, SCR6, IPOUT, NFOUND, LAMA        
CZZ   COMMON /ZZDETX/ PSAVE        
      COMMON /ZZZZZZ/ PSAVE        
      COMMON /SYSTEM/SYSBUF        
C        
      EQUIVALENCE  (PSAVE(1),PS(1),DET(1),IPDET(1),CORE(1))        
      EQUIVALENCE ( CONSTS(2) , TPHI   )        
C        
C ----------------------------------------------------------------------
C        
      NZ = KORSZ(PSAVE) -LCORE-SYSBUF        
      CALL GOPEN(IPOUT,IPDET(NZ+1),1)        
      IPDET(1) = 1        
      IPDET(2) = NFOUND        
      IF(MZ .GT. 0) IPDET(2) = IPDET(2) +MZ        
      IPDET(3) = NSTART        
      IPDET(4) = IC        
      IPDET(5) = NSMOVE        
      IPDET(6) = NDCMP        
      IPDET(7) = NFAIL        
      IPDET(8) = ITERM        
      DO 10 I=9,12        
   10 IPDET(I) = 0        
      CALL WRITE(IPOUT,IPDET(1),12,0)        
      IF(NDCMP .EQ. 0) GO TO 61        
      N2EV2 = IADD+ND        
      DO 60 I=1,N2EV2        
      NND = I+IDET        
      NNP = I+IPS        
      NNI = I+IPDETA        
C        
C     PUT UUT STRRTING POINT SUMMARY        
C        
      IPDET(1) = I        
      CORE(2) = PSAVE(NNP)        
      CORE(3) = SQRT(ABS(CORE(2)))        
      CORE(4) = CORE(3)/TPHI        
      CORE(5) = PSAVE(NND)        
      IPDET(6) = IPDET(NNI)        
C        
C     SCALE DETERMINANTE FOR PRETTY PRINT        
C        
      IF(CORE(5) .EQ. 0.0) GO TO 50        
   20 IF(ABS(CORE(5)) .GE. 10.0) GO TO 40        
   30 IF(ABS(CORE(5)) .GE. 1.0) GO TO 50        
      CORE(5) = CORE(5)*10.0        
      IPDET(6) = IPDET(6)-1        
      GO TO 30        
   40 CORE(5) = CORE(5)*0.1        
      IPDET(6) = IPDET(6)+1        
      GO TO 20        
   50 CALL WRITE(IPOUT,CORE(1),6,0)        
   60 CONTINUE        
   61 CONTINUE        
      CALL WRITE(IPOUT,CORE(1),0,1)        
      CALL CLOSE(IPOUT,1)        
      RETURN        
      END        
