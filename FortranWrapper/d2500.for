*+
      PROGRAM D2500
*   --------------------------------------------------------------------
*     PURPOSE - ZERO LIFT WAVE DRAG - ENTIRE CONFIGURATION
*          (THIS PROGRAM IS AN EXTENDED VERSION OF D0712)
*
*
*     AUTHORS - Evelyn Eminton, Royal Aircraft Establishment
!               Armand Sigalla, Boeing Co.
!               Grant Erwin, Boeing Co.
!               Charlotte Craidon, NASA Langley
!               Roy Harris, NASA Langley
!               Arnie McCullers, NASA Langley
!               Bo Walkley, NASA Langley
!               Ralph Carmichael, Public Domain Aeronautical Software
!                  and maybe more
*
*     REVISION HISTORY
*   DATE  VERS PERSON  STATEMENT OF CHANGES
!   1956   xxx   EE    Publication of paper with the numerical algorithm
!   1959   xxx AS & GE Original coding for IBM 704. Known as TA-14
!   1963   xxx   RH    Publication of NASA TM X-947
!    ??    xxx   CC    Creation of d2500. Non-circular fuselage.
!    ??    xxx   ??    Loop to reshape body. With restraint points.
! 10Feb95  1.0   RLC   Adapted to PC(little needed). OPEN statements
!   May95  1.1   RLC   Added comments
! 14Jun95  1.2   RLC   Rearranged output to fit 80-column screen
! 19Jun95  1.21  RLC   Put character data in common /TEXT/
! 28Jun95  1.3   RLC   Output file for gnuplot
! 25Aug95  1.4   RLC   Added MODIFIER
!  1Nov95  1.5   RLC   Ask for input file name
! 25Nov95  1.6   RLC   Lots of additional comments; print R on next areas
! 29Nov96  1.7   RLC   Print error if unable to open output
!                      Numerous nnHxxxxxxx strings changed to 'xxxxxxx'
! 29Dec96  1.8   RLC   Changed unit numbers of input&output to 1 & 2
!                      Some compilers make 5 & 6 equivalent to *
! 06May09  1.9   RLC   Changed the tolerance in OVL10, loop 270 from 1E-8 to 1E-7
*
*     NOTES-
*
*     HISTORY -
!
*
!     REFERENCES -
!       1. Whitcomb, Richard T.: A Study of the Zero-Lift Drag-Rise
!          Characteristics of Wing-Body Combinations Near the Speed of
!          Sound. NACA Report 1273, 1956. (supersedes NACA RM L52H08.)
!       2. Jones, Robert T.: Theory of Wing-Body Drag at Supersonic
!          Speeds. NACA Report 1284, 1956. (supersedes NACA RM A53H18a.)
!       3. Eminton, Evelyn: On the Minimisation and Numerical Evaluation
!          of Wave Drag. Report No. 2564, Royal Aircraft Establishment,
!          Nov.1955.
!       4. Harris, Roy V.,Jr.: An Analysis and Correlation of Aircraft
!          Wave Drag. NASA TM X-947, March 1964.
!       5. COSMIC Program Distribution LAR-13666.
!
!     BUG LIST -
!       1. No test made to insure NTHETA is a multiple of 4
!       2. Seems to write a lot of stuff to tape12 but never reads it.
!       3. Max value for NX is 100. Never checked.
!       4. VAriable ABC is REAL(20) to hold 80 characters.
      
      IMPLICIT NONE                                       ! added by RLC
************************************************************************
*     C O N S T A N T S                                                *
************************************************************************
      CHARACTER GREETING*60, AUTHOR*63, VERSION*30, FAREWELL*60
      CHARACTER MODIFIER*63
      PARAMETER (GREETING=' d2500 - Compute zero-lift wave drag.')
      PARAMETER (AUTHOR='Grant Erwin, Charlotte Craidon, many others')
      PARAMETER (MODIFIER=' ')
      PARAMETER (VERSION=' 1.9 (6 May 2009)' )
      PARAMETER (FAREWELL=
     &   'File wavedrag.out has been added to your directory.')
************************************************************************
*     V A R I A B L E S                                                *
************************************************************************
      INTEGER errCode         ! set by IOSTAT in OPEN statement
      CHARACTER fileName*80   ! name of the input file
      INTEGER FLAG    ! =0 if Mach>1; =1 if Mach <1
      INTEGER I       ! just a loop counter
      INTEGER KEY     ! =0 then set to 1 indicating matrix is inverted
      INTEGER MACH    ! Mach number*1000
      INTEGER MMACH   ! =0 then set to MACH after one cycle
      INTEGER MMMM    ! =0 then set to 1 after call to OVL20
      INTEGER NCON    ! ust tells if another configuration follows
      INTEGER NKODE   ! =0 then set to 1 after restraint points are read
************************************************************************
*     A R R A Y S                                                      *
************************************************************************

************************************************************************
*     C O M M O N   B L O C K   D E F I N I T I O N S                  *
************************************************************************
      REAL ABC(20)
      INTEGER NCASE
      COMMON /TEXT/ ABC, NCASE

      INTEGER J0,J1,J2,J3,J4,J5,J6  ! input flage
      INTEGER NWAF,NWAFOR
      INTEGER NFUS,NRADX(4),NFORX(4)
      INTEGER NP,NPODOR
      INTEGER NF,NFINOR
      INTEGER NCAN,NCANOR
!
      INTEGER J2TEST  !
      INTEGER LERR    !
      INTEGER NRICH   !
      INTEGER NX      ! number of ???
      INTEGER NTHETA  ! number of ???
      INTEGER NREST   ! number of fuselage restraint points
      INTEGER KKODE   !
      INTEGER JRST    !
      INTEGER KKKDE   !
      INTEGER IPLOT   ! never used
      REAL REFA       ! reference area
      REAL XMACH      ! Mach Number (deduced from MACH (integer) )
      REAL XREST(10)  ! the x-coordinated of the fuselage restraint pts.
!
      COMMON J0,J1,J2,J3,J4,J5,J6,
     1 NWAF,NWAFOR,NFUS,NRADX,NFORX,NP,NPODOR,
     2 NF,NFINOR,NCAN,NCANOR,
     3 J2TEST,LERR,NRICH,REFA,
     4 XMACH,NX,NTHETA,NREST,XREST,
     5 KKODE,JRST,KKKDE,IPLOT
*
      INTEGER KATE
      COMMON/BLK1/KATE
*
      REAL V,XFUS1,XFUSN
      COMMON/BLK2/V,XFUS1,XFUSN          ! used??
*
      INTEGER NNX
      COMMON/BLK3/NNX
*
      REAL XXA(37),XXB(37),XAC(37,5),XBC(37,5),VSUM    ! used??
      COMMON/BLK4/XXA,XXB,XAC,XBC,VSUM    ! used??
*
      INTEGER NFUSX
      REAL FUSAX(101),RFUS(101)
      COMMON/BLK5/NFUSX,FUSAX,RFUS
*
      REAL ARNO(4),ARBA(4)
      COMMON/BLK6/ARNO,ARBA
*
!!! blank common is referenced in subroutines OVL10, ADIST
!!! /BLK1/  is referenced in subroutines OVL10, OVL50
!!! /BLK2/  is referenced in subroutine  OVL10, OVL60
!!! /BLK3/  is referenced in subroutines OVL40
!!! /BLK4/  is referenced in subroutines OVL50,OVL60
!!! /BLK5/  is referenced in subroutines OVL10,OVL20,OVL60
!!! /BLK6/  is referenced in subroutines OVL10,OVL50,OVL60
!!! /CYC/   is referenced in subroutines OVL10,OVL30,OVL50,OVL60
!!! /ESEG/  is referenced in subroutines OVL10,OVL60
!!! /FILES/ is referenced in subroutines OVL10,OVL30,OVL50,OVL60
!!! /SAVE/  is referenced in subroutines OVL60
!!! /WING/  is referenced in subroutines OVL10,OVL50
!!! /FUSE/  is referenced in subroutines OVL10,OVL30,OVL50
!!! /POD/   is referenced in subroutines OVL10,OVL30,OVL50
!!! /FIN/   is referenced in subroutines OVL10,OVL50
!!! /CAN/   is referenced in subroutines OVL10,OVL50
!!! /LINXZ/ is referenced in subroutines OVL10,OVL60

*
      INTEGER KOCYC   ! =0 then set to 1 in OVL60
      INTEGER ICYC    ! number of optimization cycles (input)
!                        1 is added to whatever is input. This becomes
!                        the count of the number of times thru the
!                        big 150 loop.
      INTEGER ICY     ! loop counter in optimization loop
      INTEGER KSTOP   ! =1 to jump out of optimization loop
      REAL CDW,CDWSV
      REAL FOPX(30,4),FOPZ(30,4),FOPS(30,4)   ! fuselage optimums
      COMMON/CYC/KOCYC,ICYC,ICY,CDW,CDWSV,KSTOP,FOPX,FOPZ,FOPS

      REAL XBEG(4),XEND(4)
      COMMON/ESEG/XBEG,XEND

      REAL FDIR(35),DIRBUF(512)      ! never used ?????
      COMMON/FILES/FDIR,DIRBUF       ! never used ?????

      REAL SAVES(101,2),SAVEX(101,2)   ! used in OVL60 to save fus.
      INTEGER NSAVE
      COMMON/SAVE/SAVES,SAVEX,NSAVE

      REAL XI(101,4),ZI(101,4),RX(101,4)
      COMMON/XZR/XI,ZI,RX

      REAL XAF(30),WAFORG(20,4),W(20,4)
      REAL WAFORD(20,3,30),TZORD(20,30),ORDMAX(20,2)
      COMMON/WING/XAF,WAFORG,W,WAFORD,TZORD,ORDMAX

      REAL XFUS(30,4),ZFUS(30,4),FUSARD(30,4)
      REAL FUSRAD(30,4),SFUS(30,30,8)
      COMMON/FUSE/XFUS,ZFUS,FUSARD,FUSRAD,SFUS

      REAL PODORG(9,3),XPOD(9,30),PODORD(9,30)
      COMMON/POD/PODORG,XPOD,PODORD

      REAL FINORG(6,2,4),XFIN(6,10),FINORD(6,2,10)
      REAL FINX2(6,2,10),FINX3(6,2,10),FINMX1(6),FINMX2(6)
      REAL FINTH1(6),FINTH2(6)
      COMMON/FIN/FINORG,XFIN,FINORD,
     &   FINX2,FINX3,FINMX1,FINMX2,FINTH1,FINTH2

      REAL CANORG(2,2,4),XCAN(2,10),CANORD(2,2,10)
      REAL CANOR1(2,2,10),CANORX(2,2,10),CANMAX(2,2,2)
      COMMON/CAN/CANORG,XCAN,CANORD,CANOR1,CANORX,CANMAX

      REAL XLINE(401),YLINE(401)
      COMMON/LINXZ/XLINE,YLINE

C     COMMON/LAST/S(101,5)    ?????
*-----------------------------------------------------------------------
      NRICH=101                              ! never changes
      KOCYC=0
      CDWSV=0.
      KSTOP=0
      ICY=1
      KKODE=0
      KKKDE=0
      MMACH=0
      KEY=0
      FLAG=0
      WRITE(*,*) GREETING
      WRITE(*,*) AUTHOR
      IF (MODIFIER .NE. ' ') WRITE(*,*) 'Modified by '//MODIFIER
      WRITE(*,*) 'Version '//VERSION

    5 WRITE(*,*) 'Enter the input file name:'
      READ(*,'(A)') fileName
      IF (fileName .EQ. ' ') STOP
      OPEN(1,FILE=fileName,STATUS='OLD',IOSTAT=errCode)
      IF (errCode .NE. 0) THEN
        WRITE(*,*) 'Unable to open this file. Try again.'
        GOTO 5
      END IF

      OPEN(2,FILE= 'wavedrag.out', STATUS='REPLACE', IOSTAT=errCode)
      IF (errCode .NE. 0) STOP 'Unable to open output file.'
      OPEN(12,STATUS='SCRATCH',FORM='UNFORMATTED')
      OPEN(10,STATUS='SCRATCH',FORM='UNFORMATTED')
      OPEN(9,STATUS='SCRATCH',FORM='UNFORMATTED',ACCESS='DIRECT',RECL=4)
!
      WRITE(2,*) '       PROGRAM D2500     ZERO LIFT WAVE DRAG'
C
C         INPUT 1ST TWO CARDS
C
!..... After all calculatiuons are finished, control returns to 
!      this point so that one may stack up multiple cases in one 
!      input file. This is a carry-over from the old batch days
!      when your access to the computer was strictly rationed.
!
15    FORMAT (20A4)
20    READ(1,15,END=999) ABC   ! first record (20 reals=80 char)
      WRITE(2,35) ABC
35    FORMAT ('   CONFIGURATION DESCRIPTION'//1X,20A4/)
!!!40    FORMAT (1X,8A10/)
      READ(1,45) J0,J1,J2,J3,J4,J5,J6,NWAF,NWAFOR,NFUS,  ! 2nd card
     & (NRADX(I),NFORX(I),I=1,4),NP,NPODOR,NF,NFINOR,NCAN,NCANOR
45    FORMAT (24I3)
C
C         INPUT CONFIGURATION DESCRIPTION AND INITIALIZE
C
      CALL OVL10                      ! reads all the geometry data
      NKODE=0
      MMMM=0
C
C
C         INPUT CASE CARD
C
55    READ(1,60,END=999) NCASE,MACH,NX,NTHETA,NREST,NCON,
     & ICYC,KKODE,JRST,IPLOT  ! end of input, but cases may be stacked
60    FORMAT (A4,9I4)
      ICYC=ICYC+1                       ! after this, ICYC never changes
70    XMACH=REAL(MACH)/1000.0
C
C    COMPUTE FUSELAGE COEFFICIENTS
C
      IF(IABS(J2).NE.1) GO TO 71
      IF(JRST.NE.0) GO TO 71
      IF(MMMM.NE.0) GO TO 71
      WRITE(*,*) 'Calling OVL20'
      CALL OVL20
C     CALL OVERLAY(CBC,2,0,0)
      MMMM=1                                  ! next time, skip all this
 71   CONTINUE
      LERR=0
      IF (MACH-1000) 80,75,90
75    XMACH=1.000001
      GO TO 90
  80  WRITE(2,85) ABC,NCASE,XMACH
85    FORMAT ('1 ',20A4//6X,'CASE NO.',A4,3X,'MACH = ',F6.4)
      FLAG=1    ! indicates that Mach < 1.  Don't compute drag
C     GO TO 140
90    CONTINUE
!
!
!..... Begin big loop for ICYC cycles of fuselage shaping...............
      DO 150 ICY=1,ICYC                              ! icy,icyc in /CYC/
      IF(FLAG.EQ.1) GO TO 92
      IF (KOCYC.EQ.0) GO TO 92
      IF (J0.NE.0) J0=2
      IF (J1.NE.0) J1=2
      IF (J3.NE.0) J3=2
      IF (J4.NE.0) J4=2
      IF (J5.NE.0) J5=2
      J2=-1
      J6=0
      CALL OVL10                 ! read geometry again, but all but j2=2
      CALL OVL20
C     CALL OVERLAY (CBC,1,0,0)
C     CALL OVERLAY (CBC,2,0,0)
92    CONTINUE
      IF (FLAG.EQ.1) GO TO 95
      IF (J2.EQ.0.AND.J3.EQ.0) GO TO 95
C
C         CHECK BODY SLOPES   (if there are pods or a fuselage)
      IF(KKODE.NE.0) GO TO 95
      IF(MACH.LE.MMACH.AND.KKKDE.EQ.0) GO TO 95
C
94    FORMAT(' GOTO OVL30')
      CALL OVL30                                     ! check body slopes
C     CALL OVERLAY (CBC,3,0,0)
95    CONTINUE
      IF (FLAG.EQ.1) GO TO 110                         ! FLAG=1 if M < 1
      IF (NTHETA.EQ.1) GO TO 110
C
C         COMPUTE INVERTED MATRIX
C
      IF (KEY.EQ.0) GO TO 100
      IF (NNX.EQ.NX) GO TO 105
100   KEY=1
      NNX=NX
      CALL OVL40
C     CALL OVERLAY (CBC,4,0,0)
*
105   CONTINUE
110   CONTINUE
C
C         INPUT RESTRAINT POINTS
C
      IF (FLAG.EQ.1) GO TO 120                         ! FLAG=1 if M < 1
      IF (.NOT.(NKODE.EQ.0.AND.NREST.NE.0)) GO TO 120
      READ(1,115) XREST                                 ! dimensioned 10
115   FORMAT (10F7.0)
      NKODE=1                             ! so you don't read them again
120   CONTINUE
C
C         COMPUTE S(X,THETA)
C
      IF (FLAG.EQ.1) GO TO 140
      CALL OVL50
C     CALL OVERLAY (CBC,5,0,0)
C
C         PRINT AND PLOT
C
      CALL OVL60
C     CALL OVERLAY (CBC,6,0,0)
*
      IF (LERR.EQ.0) GO TO 130
      WRITE(2,125)
  125 FORMAT (/,' BODY SLOPE EQUALS OR EXCEEDS MACH ANGLE'/
     & ' ANY SIMIARITY BETWEEN THE COMPUTED DRAG AND'/
     & ' THE CORRECT VALUE IS PURELY COINCIDENTAL' )
      GO TO 140
130   WRITE(2,*) 'Cycle completed successfully'
140   WRITE(2,145)
      FLAG=0
145   FORMAT ('1')
      MMACH=MACH
      IF (KSTOP.EQ.1) GO TO 151
150   CONTINUE           ! end of big loop of cycles of fuselage shaping



151   CONTINUE
      WRITE(*,*) 'End of this case.'
      WRITE(2,*) 'End of this case.'
      KOCYC=0
      KSTOP=0
      ICY=1
      IF (NCON.EQ.0) GO TO 55
      GO TO 20                  ! allows cases to be stacked
!
  999 CONTINUE    ! jump here on EOF on 5
      WRITE(*,*) FAREWELL
      WRITE(2,*) FAREWELL
      STOP 'Normal exit from d2500'
      END   ! -------------------------------- End of main Program D2500
*+
      SUBROUTINE OVL10
*   --------------------------------------------------------------------
*     PURPOSE -INPUTS AND INITIALIZES CONFIGURATION DESCRIPTION
*
*     NOTES- Apparently known as START at one time
*
 !!!   IMPLICIT NONE
*
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
      REAL PI
      INTEGER I30
      PARAMETER (PI=3.14159265, I30=30)
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
      REAL FDRAG(4)
      REAL XF(28),SF(28),R(28)
      REAL SI(101,4),XSAV(101,4),ZSAV(101,4),RSAV(101,4)
C     REAL XLINE(401),ZLINE(401)
************************************************************************
*     C O M M O N   B L O C K   D E F I N I T I O N S                  *
************************************************************************
      COMMON /TEXT/ ABC(20),NCASE
      COMMON J0,J1,J2,J3,J4,J5,J6,
     1NWAF,NWAFOR,NFUS,NRADX(4),NFORX(4),NP,NPODOR,
     2NF,NFINOR,NCAN,NCANOR,
     3J2TEST,LERR,NRICH,REFA,
     4 XMACH,NX,NTHETA,NREST,XREST(10)
     5,KKODE,JRST,KKKDE,IPLOT
      COMMON/BLK1/KATE
      COMMON/BLK2/V,XFUS1,XFUSN
      COMMON/BLK5/NFUSX,FUSAX(101),RFUS(101)
      COMMON/BLK6/ARNO(4),ARBA(4)
      COMMON/CYC/KOCYC,ICYC,ICY,CDW,CDWSV,KSTOP,
     1FOPX(30,4),FOPZ(30,4),FOPS(30,4)
      COMMON/ESEG/XBEG(4),XEND(4)
      COMMON/FILES/FDIR(35),DIRBUF(512)
      COMMON/XZR/XI(101,4),ZI(101,4),RX(101,4)
      COMMON/WING/XAF(30),WAFORG(20,4),W(20,4),
     1WAFORD(20,3,30),TZORD(20,30),ORDMAX(20,2)
      COMMON/FUSE/XFUS(30,4),ZFUS(30,4),FUSARD(30,4),
     1FUSRAD(30,4),SFUS(30,30,8)
      COMMON/POD/PODORG(9,3),XPOD(9,30),PODORD(9,30)
      COMMON/FIN/FINORG(6,2,4),XFIN(6,10),FINORD(6,2,10),
     1FINX2(6,2,10),FINX3(6,2,10),FINMX1(6),FINMX2(6),
     2FINTH1(6),FINTH2(6)
      COMMON/CAN/CANORG(2,2,4),XCAN(2,10),CANORD(2,2,10),
     1CANOR1(2,2,10),CANORX(2,2,10),CANMAX(2,2,2)
      COMMON/LINXZ/XLINE(401),ZLINE(401)
*-----------------------------------------------------------------------
C
      WRITE(*,*) 'Entering subroutine OVL10 (START)'
      WRITE(2,*) 'Entering subroutine OVL10 (START)'
10    FORMAT (8A10)
15    FORMAT (1X,8A10)
20    FORMAT (10F7.0)
C
C         REFERENCE AREA
C
      IF (J0.NE.1) GO TO 35
      READ(1,20) REFA
C
C         WING
C
  35  IF(J1.NE.2) GO TO 40
C     READ(9,REC=1)BLOCK(1)
      GO TO 160
 40   V=0.
      IF (J1.EQ.0) GO TO 160
      N=IABS(NWAFOR)
      NREC=(N+9)/10
      I1=-9
      I2=0
      DO 45 NN=1,NREC
      I1=I1+10
      I2=I2+10
      READ(1,20) (XAF(I),I=I1,I2)
45    CONTINUE
      DO 50 I=1,NWAF
      READ(1,20) (WAFORG(I,J),J=1,4)
50    CONTINUE
      IF (J1.LT.0) GO TO 65
      DO 60 NN=1,NWAF
      I1=-9
      I2=0
      DO 55 N1=1,NREC
      I1=I1+10
      I2=I2+10
      READ(1,20) (TZORD(NN,I),I=I1,I2)
55    CONTINUE
60    CONTINUE
      GO TO 75
65    DO 70 I=1,NWAF
      DO 70 K=1,N
70    TZORD(I,K)=0.
75    L=1
      IF (NWAFOR.LT.0) L=2
      DO 85 NN=1,NWAF
      DO 85 K=1,L
      I1=-9
      I2=0
      DO 80 N1=1,NREC
      I1=I1+10
      I2=I2+10
      READ(1,20) (WAFORD(NN,K,I),I=I1,I2)
80    CONTINUE
85    CONTINUE
      IF (NWAFOR.LT.0) GO TO 95
      DO 90 NN=1,NWAF
      DO 90 K=1,N
90    WAFORD(NN,2,K)=WAFORD(NN,1,K)
95    CONTINUE
      NWAFOR=IABS(NWAFOR)
      J1=IABS(J1)
C
C          TEST FOR CONVEX LEADING, TRAILING EDGES  (obsolete?)
C
      KATE=0
      IF (NWAF-2) 120,120,100
100   N=NWAF-1
      DXA=W(NWAF,1)-W(1,1)
      DXB=DXA+W(NWAF,4)-W(1,4)
      DY=W(NWAF,2)-W(1,2)
      DO 115 I=2,N
      IF ((W(1,1)-W(I,1))*DY+(W(I,2)-W(1,2))*DXA) 110,110,105
105   KATE=1       ! never used
      GO TO 120
110   IF ((W(I,1)+W(I,4)-W(1,1)-W(1,4))*DY-(W(I,2)-W(1,2))*DXB)
     &   115,115,105
115   CONTINUE
C
C          COMPUTE VOLUME OF EXTERNAL WING
C
120   V=0.0
      DO 130 I=2,NWAF
      DY=WAFORG(I,2)-WAFORG(I-1,2)
      E1=.01*WAFORG(I-1,4)
      E2=.01*WAFORG(I,4)
      DO 125 J=2,NWAFOR
      DX=XAF(J)-XAF(J-1)
      DX1=DX*E1
      DX2=DX*E2
      DZ1=(WAFORD(I-1,1,J-1)+WAFORD(I-1,2,J-1)+
     &    WAFORD(I-1,1,J)+WAFORD(I-1,2,J))*E1
      DZ2=(WAFORD(I,1,J-1)+WAFORD(I,2,J-1)+
     &    WAFORD(I,1,J)+WAFORD(I,2,J))*E2
125   V=V+DY*(DX1*(2.0*DZ1+DZ2)+DX2*(DZ1+2.0*DZ2))/6.0
130   CONTINUE
C
C          TRANSFORM WING COORDINATES FROM PCT-CHORD TO ACTUAL UNITS
C          OF LENGTH, REFERRED TO COMMON ORIGIN OF PROBLEM. COMPUTE
C          MAXIMUM ORDINATE OF EACH AIRFOIL.
C
      DO 140 I=1,NWAF
      E=.01*WAFORG(I,4)
      E3=WAFORG(I,3)
      DO 135 J=1,NWAFOR
      WAFORD(I,1,J)=E*WAFORD(I,1,J)+E3+TZORD(I,J)
      WAFORD(I,2,J)=-E*WAFORD(I,2,J)+E3+TZORD(I,J)
135   WAFORD(I,3,J)=WAFORG(I,1)+E*XAF(J)
140   CONTINUE
      DO 150 I=1,NWAF
      ORDMAX(I,1)=WAFORD(I,1,1)
      ORDMAX(I,2)=WAFORD(I,2,1)
      DO 145 J=2,NWAFOR
      ORDMAX(I,1)=MAX(ORDMAX(I,1),WAFORD(I,1,J))
145   ORDMAX(I,2)=MIN(ORDMAX(I,2),WAFORD(I,2,J))
150   CONTINUE
C155  WRITE(9,REC=1)BLOCK(1)
  160 CONTINUE
C
C         FUSELAGE
C
      IF(J2.NE.2) GO TO 165
C     READ(9,REC=7501)BLOCK(1)
C     READ(9,REC=15001)XLINE(1)
C     READ(9,REC=15402)ZLINE(1)
      GO TO 355
 165  IF (J2.EQ.0) GO TO 355
      J2TEST=3
      IF (J2.EQ.-1.AND.J6.EQ.-1) J2TEST=1
      IF (J2.EQ.-1.AND.J6.EQ.0) J2TEST=2
      IF (J6.EQ.1) J2TEST=1
      J2=1
      IF (KOCYC.EQ.0) GO TO 169
      DO 167 NFU=1,NFUS
      N=NFORX(NFU)
      DO 167 NNN=1,N
      XFUS(NNN,NFU)=FOPX(NNN,NFU)
      ZFUS(NNN,NFU)=FOPZ(NNN,NFU)
      FUSARD(NNN,NFU)=FOPS(NNN,NFU)
167   CONTINUE
169   CONTINUE
      NSUM=1
      DO 170 NFU=1,NFUS
170   NSUM=NSUM+NFORX(NFU)-1
      IF (NSUM.LE.101) GO TO 180
      WRITE(2,175)
175   FORMAT (//'Too many fuselage points!!'//)
      STOP 'Too many fuselage points'
180   CONTINUE
      DO 295 NFU=1,NFUS
      N=NFORX(NFU)
      NRAD=NRADX(NFU)
      IF (KOCYC.NE.0) GO TO 186
      NREC=(N+9)/10
      I1=-9
      I2=0
      DO 185 N1=1,NREC
      I1=I1+10
      I2=I2+10
      READ(1,20) (XFUS(I,NFU),I=I1,I2)
185   CONTINUE
186   CONTINUE
      IF (NFU.NE.1) GO TO 190
      XFUS1=XFUS(1,1)
      XFUSN=XFUS(N,1)
190   XFUS1=MIN(XFUS1,XFUS(1,NFU))
      XFUSN=MAX(XFUSN,XFUS(N,NFU))
      IF (J2TEST.NE.2) GO TO 200
      IF (KOCYC.NE.0) GO TO 246
      I1=-9
      I2=0
      DO 195 N1=1,NREC
      I1=I1+10
      I2=I2+10
      READ(1,20) (ZFUS(I,NFU),I=I1,I2)
195   CONTINUE
      GO TO 210
200   DO 205 I=1,N
205   ZFUS(I,NFU)=0.
210   IF (J2TEST.NE.3) GO TO 240
      NCARD=(NRAD+9)/10
      DO 225 LN=1,N
      DO 220 K=1,2
      KK=K+(NFU-1)*2
      II=10
      I1=-9
      I2=0
      DO 215 NN=1,NCARD
      IF (NN.EQ.NCARD) II=MOD(NRAD,10)
      IF (II.EQ.0) II=10
      I1=I1+10
      I2=I2+II
      READ(1,20) (SFUS(I,LN,KK),I=I1,I2)
215   CONTINUE
220   CONTINUE
225   CONTINUE
C
C         COMPUTE AREAS AND CENTROIDS
C
      KK=1+(NFU-1)*2
      DO 230 I=1,N
      SI(I,NFU)=0.
      ZSAV(I,NFU)=0.
      DO 230 K=2,NRAD
      ABAR=SFUS(K-1,I,KK)*SFUS(K,I,KK+1)-SFUS(K,I,KK)*SFUS(K-1,I,KK+1)
      ZBAR=(SFUS(K-1,I,KK+1)+SFUS(K,I,KK+1))/3.
      ZSAV(I,NFU)=ZSAV(I,NFU)+ABAR*ZBAR
      SI(I,NFU)=SI(I,NFU)+ABAR
230   CONTINUE
      ARNO(NFU)=SI(1,NFU)
      ARBA(NFU)=SI(N,NFU)
      DO 235 I=1,N
      IF (SI(I,NFU).GT..0001) GO TO 232
      ZSAV(I,NFU)=(SFUS(NRAD,I,KK+1)-SFUS(1,I,KK+1))/2.+SFUS(1,I,KK+1)
      GO TO 235
232   ZSAV(I,NFU)=ZSAV(I,NFU)/SI(I,NFU)
235   XSAV(I,NFU)=XFUS(I,NFU)
      GO TO 295
240   I1=-9
      I2=0
      DO 245 N1=1,NREC
      I1=I1+10
      I2=I2+10
      READ(1,20) (FUSARD(I,NFU),I=I1,I2)
245   CONTINUE
246   CONTINUE
      DO 250 I=1,N
250   FUSRAD(I,NFU)=SQRT(FUSARD(I,NFU)/PI)
C
C          FIT EMINTON-LORD OPTIMUM AREA DISTRIBUTION OF FUSELAGE
C
      ELL=XFUS(N,NFU)-XFUS(1,NFU)
      SN=FUSARD(1,NFU)
      SB=FUSARD(N,NFU)
      NN=N-2
      DO 255 I=1,NN
      XF(I)=(XFUS(I+1,NFU)-XFUS(1,NFU))/ELL
255   SF(I)=FUSARD(I+1,NFU)
      K=1
      CALL EMLORD (ELL,SN,SB,NN,XF,SF,FDRAG(NFU),R,K)
      XI(1,NFU)=XFUS(1,NFU)
      XI(NRICH,NFU)=XFUS(N,NFU)
      SI(1,NFU)=SN
      SI(NRICH,NFU)=SB
      NRICH1=NRICH-1
      EINT=NRICH1
      DO 280 I=2,NRICH1
      Z=I-1
      EX=Z/EINT
      XI(I,NFU)=EX*ELL+XI(1,NFU)
      SUM=0.0
      DO 270 J=1,NN
      Y=XF(J)
      E=(EX-Y)**2
      E1=EX+Y-2.0*EX*Y
      E2=2.0*SQRT(EX*Y*(1.0-EX)*(1.0-Y))
      IF (E-1.E-7) 265,265,260
260   E3=.5*E*ALOG((E1-E2)/(E1+E2))+E1*E2
      GO TO 270
265   E3=E1*E2
270   SUM=SUM+E3*R(J)
      E4=(ACOS(1.0-2.0*EX)-(2.0-4.0*EX)*SQRT(EX-EX**2))/PI
      SI(I,NFU)=SN+(SB-SN)*E4+SUM
      IF (SI(I,NFU).GE.0.) GO TO 280
      WRITE(2,275) NFU,XI(I,NFU)
275   FORMAT (//' NEGATIVE AREA COMPUTED FOR FUSELAGE',
     &   I2,' AT X =',F8.4/'1')
      STOP
280   CONTINUE
      IPTQ=-1
      DO 285 I=1,NRICH
      RX(I,NFU)=SQRT(SI(I,NFU)/PI)
285   CALL IUNI(I30,N,XFUS(1,NFU),1,ZFUS(1,NFU),1,XI(I,NFU),ZI(I,NFU),
     1IPTQ,IERR)
C
C         SAVE FUSELAGE AREA DISTRIBUTION FOR PRINTING
C
      DO 290 I=1,NRICH
      XSAV(I,NFU)=XI(I,NFU)
      ZSAV(I,NFU)=ZI(I,NFU)
290   RSAV(I,NFU)=RX(I,NFU)
      ARNO(NFU)=SN                                           ! nose area
      ARBA(NFU)=SB                                           ! base area
295   CONTINUE
      IF (J2TEST.EQ.3) GO TO 320
C
C         ARRANGE X,Z,AND S IN CONTINUOUS LINE FOR CIRCULAR BODY
C
      WRITE(*,296)
296   FORMAT(' CIRCULAR BODY')
      DO 300 N=1,NFUS
      DO 300 NN=1,NRICH1
      NK=NN+(N-1)*NRICH1
      XLINE(NK)=XI(NN,N)
300   ZLINE(NK)=ZI(NN,N)
      NK=NFUS*NRICH1+1
      XLINE(NK)=XI(NRICH,NFUS)
      ZLINE(NK)=ZI(NRICH,NFUS)
      NFUSX=1
      RFUS(1)=0.
      FUSAX(1)=XFUS(1,1)
      G=ARNO(1)
      DO 315 NFU=1,NFUS
      N=NFORX(NFU)
      IF (NFU.EQ.1) GO TO 305
      G=G+ARNO(NFU)-ARBA(NFU-1)
305   DO 310 I=2,N
      NFUSX=NFUSX+1
      RFUS(NFUSX)=FUSARD(I,NFU)-G
310   FUSAX(NFUSX)=XFUS(I,NFU)
C      IF(ICY.EQ.1) WRITE(12) G
315   CONTINUE
      GO TO 355
C
C         SUBTRACT CAPTURE AREAS FOR ARBITRARY BODY
C
320   G=ARNO(1)
      DO 335 NFU=1,NFUS
      N=NFORX(NFU)
      IF (NFU.EQ.1) GO TO 325
      G=G+ARNO(NFU)-ARBA(NFU-1)
325   DO 330 I=1,N
330   RSAV(I,NFU)=SI(I,NFU)-G
      IF(ICY.EQ.1) WRITE(12) G
335   CONTINUE
C
C         ARRANGE X,Z,AND S IN CONTINUOUS LINE FOR ARBITRARY BODY
C
      WRITE(*,336)
336   FORMAT(' ARBITRARY BODY')
      XLINE(1)=XSAV(1,1)
      FUSAX(1)=XSAV(1,1)
      RFUS(1)=RSAV(1,1)
      ZLINE(1)=ZSAV(1,1)
      NFUSX=1
      DO 345 NFU=1,NFUS
      N=NFORX(NFU)
      DO 340 I=2,N
      NFUSX=NFUSX+1
      XLINE(NFUSX)=XSAV(I,NFU)
      FUSAX(NFUSX)=XSAV(I,NFU)
      RFUS(NFUSX)=RSAV(I,NFU)
340   ZLINE(NFUSX)=ZSAV(I,NFU)
345   CONTINUE
C350  WRITE(9,REC=7501)BLOCK(1)
C     WRITE(9,REC=15001)XLINE(1)
C     WRITE(9,REC=15402)ZLINE(1)
C
C         NACELLES
C
  355 IF(J3.NE.2) GO TO 360
C     READ(9,REC=15803)BLOCK(1)
      GO TO 385
 360  IF (J3.EQ.0) GO TO 385
      N=NPODOR
      NREC=(N+9)/10
      DO 375 NN=1,NP
      READ(1,20) (PODORG(NN,I),I=1,3)
      I1=-9
      I2=0
      DO 365 N1=1,NREC
      I1=I1+10
      I2=I2+10
      READ(1,20) (XPOD(NN,I),I=I1,I2)
365   CONTINUE
      I1=-9
      I2=0
      DO 370 N1=1,NREC
      I1=I1+10
      I2=I2+10
      READ(1,20) (PODORD(NN,I),I=I1,I2)
370   CONTINUE
375   CONTINUE
C380  WRITE(9,REC=15803)BLOCK(1)
C
C         FINS
C
  385 IF(J4.NE.2) GO TO 390
C     READ(9,REC=23303)BLOCK(1)
      GO TO 425
 390  IF (J4.EQ.0) GO TO 425
      N=NFINOR
      DO 395 NN=1,NF
      READ(1,20) ((FINORG(NN,I,J),J=1,4),I=1,2)
      READ(1,20) (XFIN(NN,I),I=1,N)
      READ(1,20) (FINORD(NN,1,J),J=1,N)
C     READ(1,20) (FINORD(NN,2,J),J=1,N)
      DO 391 J=1,N
      FINORD(NN,2,J)=FINORD(NN,1,J)
  391 CONTINUE
395   CONTINUE
C
C          TRANSFORM FIN COORDINATES TO ACTUAL UNITS.
C          COMPUTE MAXIMUMS.
C
      DO 405 LQ=1,NF
      DO 405 I=1,2
      J=3-I
      E=.01*FINORG(LQ,J,4)
      E2=FINORG(LQ,J,2)
      DO 400 K=1,NFINOR
      EE=FINORD(LQ,J,K)*E
      FINORD(LQ,J,K)=E2+EE
      FINX2(LQ,J,K)=E2-EE
400   FINX3(LQ,J,K)=FINORG(LQ,J,1)+E*XFIN(LQ,K)
405   CONTINUE
      DO 415 LQ=1,NF
      FINMX1(LQ)=0.
      FINMX2(LQ)=0.
      DO 410 K=1,NFINOR
      FINMX1(LQ)=MAX(FINMX1(LQ),FINORD(LQ,1,K))
      FINMX2(LQ)=MAX(FINMX2(LQ),FINORD(LQ,2,K))
410   CONTINUE
      FINTH1(LQ)=2.*(FINMX1(LQ)-FINORG(LQ,1,2))
      FINTH2(LQ)=2.*(FINMX2(LQ)-FINORG(LQ,2,2))
415   CONTINUE
C420  WRITE(9,REC=23303)BLOCK(1)
C
C         CANARDS
C
 425  IF(J5.NE.2) GO TO 430
C     READ(9,REC=30803)BLOCK(1)
      GO TO 495
 430  IF (J5.EQ.0) GO TO 495
      N=IABS(NCANOR)
      DO 445 NN=1,NCAN
      READ(1,20) ((CANORG(NN,I,J),J=1,4),I=1,2)
      READ(1,20) (XCAN(NN,I),I=1,N)
      READ(1,20) (CANORD(NN,1,J),J=1,N)
C     READ(1,20) (CANORD(NN,2,J),J=1,N)
      DO 431 J=1,N
      CANORD(NN,2,J)=CANORD(NN,1,J)
  431 CONTINUE
      IF (NCANOR.LT.0) GO TO 440
      DO 435 J=1,N
      DO 435 I=1,2
      CANOR1(NN,I,J)=CANORD(NN,I,J)
435   CONTINUE
      GO TO 445
  440 CONTINUE
      READ(1,20) (CANOR1(NN,1,J),J=1,N)
C     READ(1,20) (CANOR1(NN,2,J),J=1,N)
      DO 441 J=1,N
      CANOR1(NN,2,J)=CANOR1(NN,1,J)
  441 CONTINUE
445   CONTINUE
      NCANOR=IABS(NCANOR)
C
C          TRANSFORM CANARD COORDINATES TO ACTUAL UNITS.
C          COMPUTE MAXIMUMS.
C
      DO 460 NN=1,NCAN
      DO 455 K=1,2
      I=3-K
      E=.01*CANORG(NN,I,4)
      E3=CANORG(NN,I,3)
      DO 450 J=1,NCANOR
      CANORD(NN,I,J)=E*CANORD(NN,I,J)+E3
      CANOR1(NN,I,J)=-E*CANOR1(NN,I,J)+E3
450   CANORX(NN,I,J)=CANORG(NN,I,1)+E*XCAN(NN,J)
455   CONTINUE
460   CONTINUE
      DO 485 NN=1,NCAN
      DO 480 I=1,2
      DO 465 J=2,NCANOR
      K=J-1
      IF (CANORD(NN,I,K)-CANORD(NN,I,J)) 465,470,470
465   CONTINUE
470   CANMAX(NN,I,1)=CANORD(NN,I,K)
      DO 475 J=2,NCANOR
      K=J-1
      IF (CANOR1(NN,I,K)-CANOR1(NN,I,J)) 480,480,475
475   CONTINUE
480   CANMAX(NN,I,2)=CANOR1(NN,I,K)
485   CONTINUE
C490  WRITE(9,REC=30803)BLOCK(1)
495   CONTINUE
C
C         UPDATE UNIT 12
C
      IF (J2.NE.1) GO TO 560
      IF (J2TEST.EQ.3) GO TO 530
C
C         PRINT FUSELAGE AREA DISTRIBUTION
!..... modified to fit 80 col screen   RLC  8Jun95
C
      DO 525 NFU=1,NFUS
      WRITE(2,505) ABC
505   FORMAT (2X,20A4)
!!!      WRITE(2,502) ICY
!!!502   FORMAT (//46X,'CYCLE ',I3//)
      WRITE(2,510) ICY,NFU,FDRAG(NFU)
510   FORMAT (//'CYCLE=',I3,4X,'FUSELAGE SEGMENT ',I2,
     & '    AREA DISTRIBUTION (D/Q =', F9.5, ')'//
     & 8X,'N',8X,'X',10X,'Z',10X,'R',10X,'S')
!      IJK2=(NRICH+1)/2
!      IJK3=NRICH1/2
      DO 520 M=1,NRICH
!      N1=M-1
!      N2=N1+IJK3
!      N3=M+IJK3
      WRITE(2,515) M-1,XSAV(M,NFU),ZSAV(M,NFU),RSAV(M,NFU),SI(M,NFU)
515   FORMAT (I9,4F11.4)
520   CONTINUE
      XBEG(NFU)=XSAV(1,NFU)
      XEND(NFU)=XSAV(NRICH,NFU)
525   CONTINUE
      GO TO 560
!
530   WRITE(2,535) ABC
535   FORMAT (2X,20A4//10X, 'ARBITRARY BODY AREAS')
!!!      WRITE(2,537) ICY
!!!537   FORMAT (//36X,'CYCLE ',I3//)
      DO 555 NFU=1,NFUS
      WRITE(2,540) ICY,NFU
540   FORMAT (//'CYCLE=',I3,10X,'BODY SEGMENT',I2, //
     &  16X,'X',11X,'S',11X,'Z',9X,'R(EQ)',7X,'S(EQ)')
      N=NFORX(NFU)
      DO 550 I=1,N
      RPRIN=SIGN(SQRT(ABS(RSAV(I,NFU)/PI)),RSAV(I,NFU))
      WRITE(2,545) XSAV(I,NFU),SI(I,NFU),ZSAV(I,NFU),RPRIN,RSAV(I,NFU)
545   FORMAT (9X,5F12.4)
      WRITE(12) XSAV(I,NFU),SI(I,NFU)
550   CONTINUE
      XBEG(NFU)=XSAV(1,NFU)
      XEND(NFU)=XSAV(N,NFU)
555   CONTINUE
560   CONTINUE
!
      WRITE(*,*) 'Leaving OVL10 (START)'
      WRITE(2,*) 'Leaving OVL10 (START)'
!!!      REWIND 9   ! commented out by RLC   7Nov94
      END   ! ------------------- End of Subroutine OVL10 (called START)
*+
      SUBROUTINE OVL20
*   --------------------------------------------------------------------
*     PURPOSE - (FUSFIT) COMPUTE CURVE FIT COEFFICIENTS FOR 
*        INPUT BODY SEGMENTS
*
*     NOTES-
*
 !!!   IMPLICIT NONE
*
*      EXTERNAL
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
      REAL PI
      PARAMETER (PI=3.14159265)
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
      DIMENSION IPI(99),PQ(99,99),IND(99,2),Q(99),C(99)
************************************************************************
*     C O M M O N   B L O C K   D E F I N I T I O N S                  *
************************************************************************
      COMMON/BLK5/NFUSX,FUSAX(101),RFUS(101)
*-----------------------------------------------------------------------
      WRITE(*,*) 'Entering OVL20 (FUSFIT)'
      WRITE(2,*) 'Entering OVL20 (FUSFIT)'
*
      NN=NFUSX-2
      SN=RFUS(1)
      SB=RFUS(NFUSX)
      ELL=FUSAX(NFUSX)-FUSAX(1)
      FUSX1=FUSAX(1)
      DO 10 N=1,NN
      RFUS(N)=RFUS(N+1)
10    FUSAX(N)=(FUSAX(N+1)-FUSX1)/ELL

      DO 40 N=1,NN
      X=FUSAX(N)
      Q(N)=(ACOS(1.0-2.0*X)-(2.0-4.0*X)*SQRT(X-X**2))/PI
      DO 25 M=N,NN
      Y=FUSAX(M)
      E=(X-Y)**2
      E1=X+Y-2.0*X*Y
      E2=2.0*SQRT(X*Y*(1.0-X)*(1.0-Y))
      IF (E) 15,20,15
15    PQ(M,N)=.5*E*ALOG((E1-E2)/(E1+E2))+E1*E2
      GO TO 25
20    PQ(M,N)=E1*E2
25    CONTINUE
      NK=N-1
      IF (NK) 40,40,30
30    DO 35 M=1,NK
      E=PQ(N,M)
35    PQ(M,N)=E
40    CONTINUE
      
      CALL MATINV (99,NN,PQ,0,B,1,DET,IKK,IPI,IND)
      DO 45 N=1,NN
45    C(N)=RFUS(N)-SN-(SB-SN)*Q(N)
      
      DO 55 M=1,NN
      SUM=0.0
      DO 50 N=1,NN
50    SUM=SUM+PQ(M,N)*C(N)
55    RFUS(M)=SUM
      
      WRITE(*,*) 'Leaving OVL20 (FUSFIT)'
      WRITE(2,*) 'Leaving OVL20 (FUSFIT)'
      END   ! ------------------------- End of Subroutine OVL20 (FUSFIT)
*+
      SUBROUTINE OVL30
*   --------------------------------------------------------------------
*     PURPOSE - (SLOPE) CHECKS BODY SLOPES AGAINST MACH ANGLE
*
*     NOTES-
*
 !!!   IMPLICIT NONE
*
*      EXTERNAL
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
      REAL PI,PI2
      PARAMETER (PI=3.14159265, PI2=0.5*PI)
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
************************************************************************
*     C O M M O N   B L O C K   D E F I N I T I O N S                  *
************************************************************************
      COMMON /TEXT/ ABC(20),NCASE
      COMMON J0,J1,J2,J3,J4,J5,J6,
     1NWAF,NWAFOR,NFUS,NRADX(4),NFORX(4),NP,NPODOR,
     2NF,NFINOR,NCAN,NCANOR,
     3J2TEST,LERR,NRICH,REFA,
     4 XMACH,NX,NTHETA,NREST,XREST(10)
     5,KKODE,JRST,KKKDE,IPLOT
      COMMON/CYC/KOCYC,ICYC,ICY,CDW,CDWSV,KSTOP,
     1FOPX(30,4),FOPZ(30,4),FOPS(30,4)
      COMMON/FILES/FDIR(35),DIRBUF(512)
      COMMON/XZR/XI(101,4),ZI(101,4),RX(101,4)
      COMMON/FUSE/XFUS(30,4),ZFUS(30,4),FUSARD(30,4),
     1FUSRAD(30,4),SFUS(30,30,8)
      COMMON/POD/PODORG(9,3),XPOD(9,30),PODORD(9,30)

*-----------------------------------------------------------------------
      WRITE(*,*) 'Entering OVL30 (SLOPE)'
      WRITE(2,*) 'Entering OVL30 (SLOPE)'
*
      KKKDE=0
10    FORMAT ('1',26X,20A4//60X,'CASE NO. ',A4/45X,'MACH = ',
     1 F6.3,6X,'NX =',I3,6X,'NTHETA =',I3/47X,
     2 'BODY SLOPE EQUALS OR EXCEEDS MACH ANGLE'//)
15    FORMAT (//56X,'FUSELAGE NUMBER',I3//)
20    FORMAT (//59X,'POD NUMBER',I3//)
25    FORMAT (19X,'X1',10X,'Y1',10X,'Z1',14X,'X1',10X,'Y1',10X,
     &   'Z2',15X,'THETA',10X,'PHI')
30    FORMAT (12X,3F12.4,4X,3F12.4,F18.3,F14.3)
35    FORMAT (31X,'X',17X,'RADIUS 1', 11X,'X',27X,'RADIUS 2',
     &   12X,'THETA',10X, 'PHI')
40    FORMAT (24X,2F12.4,4X,2F12.4,F18.3,F14.3)
45    FORMAT (7X,'X1',10X,'Y1',10X,'Z1',11X,'PHI 1',16X,'X2',10X,
     1 'Y2',10X,'Z2',11X,'PHI 2',8X,'THETA')
50    FORMAT (3F12.4,F14.3,8X,3F12.4,2F14.3)
      LL=NTHETA+1
      IF (NTHETA.EQ.1) LL=1
      DTHETA=PI/NTHETA
      T=1./SQRT(XMACH**2-1.)
!!!      WRITE(*,53)T
53    FORMAT(' T = ',F8.3)
C     READ(9,REC=7501)BLOCK(1)
      IF (J2.EQ.0) GO TO 170
      GO TO (55,90,125), J2TEST
C
C         CIRCULAR BODY
C
55    DO 85 NFU=1,NFUS
      KODE=0
      M=NRADX(NFU)
      DELPHI=PI/(M-1)
      DO 80 NN=2,NRICH
      DO 75 MM=1,M
      PHI=-PI2+(MM-1)*DELPHI
      DO 70 L=1,LL
      THETA=-PI2+(L-1)*DTHETA
      D=((RX(NN,NFU)-RX(NN-1,NFU))*COS(THETA-PHI))/
     &    (XI(NN,NFU)-XI(NN-1,NFU))
      IF (D.LT.T) GO TO 70
      IF (LERR.EQ.1) GO TO 60
      LERR=1
      WRITE(2,10) ABC,NCASE,XMACH,NX,NTHETA
      WRITE(2,57) ICY
57    FORMAT (//60X,'CYCLE ',I3//)
60    IF (KODE.EQ.1) GO TO 65
      KODE=1
      KKKDE=1
      WRITE(2,15) NFU
      WRITE(2,35)
65    TPRINT=THETA*57.29578
      PHIPR=PHI*57.29578
      WRITE(2,40) XI(NN-1,NFU), RX(NN-1,NFU), XI(NN,NFU),
     & RX(NN,NFU),TPRINT,PHIPR
70    CONTINUE
75    CONTINUE
80    CONTINUE
85    CONTINUE
      GO TO 170
C
C         CIRCULAR BODY WITH WARP
C
90    DO 120 NFU=1,NFUS
      KODE=0
      M=NRADX(NFU)
      DELPHI=PI/(M-1)
      DO 115 NN=2,NRICH
      DO 110 MM=1,M
      PHI=-PI2+(MM-1)*DELPHI
      DO 105 L=1,LL
      THETA=-PI2+(L-1)*DTHETA
      CTP=COS(THETA-PHI)
      STHET=SIN(THETA)
91    FORMAT(' STHET=',F8.4,1X,F8.4,1X,F8.4,1X,F8.4,1X,F8.4)
92    FORMAT(' RX =',F8.4,1X,F8.4,1X,F8.4)
      D=(STHET*(ZI(NN,NFU)-ZI(NN-1,NFU))+CTP*(RX(NN,NFU)-RX(NN-1,NFU)))/
     1 (XI(NN,NFU)-XI(NN-1,NFU))
      IF (D.LT.T) GO TO 105
      IF (LERR.EQ.1) GO TO 95
      LERR=1
      WRITE(2,10) ABC,NCASE,XMACH,NX,NTHETA
95    IF (KODE.EQ.1) GO TO 100
      KODE=1
      KKKDE=1
      WRITE(2,15) NFU
      WRITE(2,25)
100   CPHI=COS(PHI)
      SPHI=SIN(PHI)
      Y1=RX(NN-1,NFU)*CPHI
      Z1=RX(NN-1,NFU)*SPHI+ZI(NN-1,NFU)
      Y2=RX(NN,NFU)*CPHI
      Z2=RX(NN,NFU)*SPHI+ZI(NN,NFU)
      TPRINT=THETA*57.29578
      PHIPR=PHI*57.29578
      WRITE(2,30) XI(NN-1,NFU),Y1,Z1,XI(NN,NFU),Y2,Z2,TPRINT,PHIPR
105   CONTINUE
110   CONTINUE
115   CONTINUE
120   CONTINUE
      GO TO 170
C
C         ARBITRARY BODY
C
125   DO 165 NFU=1,NFUS
      KODE=0
      KK=2*NFU-1
      M=NRADX(NFU)
      N=NFORX(NFU)
      DO 160 NN=2,N
      DO 155 MM=1,M
      Y1=SFUS(MM,NN-1,KK)
      Z1=SFUS(MM,NN-1,KK+1)
      Y2=SFUS(MM,NN,KK)
      Z2=SFUS(MM,NN,KK+1)
      PHI1=0.
      RHO1=SQRT(Y1*Y1+Z1*Z1)
      IF (RHO1.LT..00001) GO TO 130
      PHI1=ATAN2(Y1,Z1)
130   CONTINUE
      PHI2=0.
      RHO2=SQRT(Y2*Y2+Z2*Z2)
      IF (RHO2.LT..00001) GO TO 135
      PHI2=ATAN2(Y2,Z2)
135   CONTINUE
      DO 150 L=1,LL
      THETA=-PI2+(L-1)*DTHETA
      RHOP1=RHO1*COS(PI2-THETA-PHI1)
      RHOP2=RHO2*COS(PI2-THETA-PHI2)
      D=(RHOP2-RHOP1)/(XFUS(NN,NFU)-XFUS(NN-1,NFU))
      IF (D.LT.T) GO TO 150
      IF (LERR.EQ.1) GO TO 140
      LERR=1
      WRITE(2,10) ABC,NCASE,XMACH,NX,NTHETA
140   IF (KODE.EQ.1) GO TO 145
      KODE=1
      KKKDE=1
      WRITE(2,15) NFU
      WRITE(2,45)
145   TPRINT=THETA*57.29578
      PHI1P=PHI1*57.29578
      PHI2P=PHI2*57.29578
      WRITE(2,50) XFUS(NN-1,NFU),Y1,Z1,PHI1P,XFUS(NN,NFU),
     & Y2,Z2,PHI2P,TPRINT
150   CONTINUE
155   CONTINUE
160   CONTINUE
165   CONTINUE
170   CONTINUE
      IF (J3.EQ.0) GO TO 205
      IF (KOCYC.NE.0) GO TO 205
C     READ(9,REC=15803)BLOCK(1)
C
C         PODS
C
      M=13                   ! 12 segments on the half-shell
      DELPHI=PI/(M-1)
      DO 200 NPOD=1,NP
      KODE=0
      DO 195 NN=2,NPODOR
      DO 190 MM=1,M
      PHI=-PI2+(MM-1)*DELPHI
      DO 185 L=1,LL
      THETA=-PI2+(L-1)*DTHETA
      D=((PODORD(NPOD,NN)-PODORD(NPOD,NN-1))*COS(THETA-PHI))/
     & (XPOD(NPOD,NN)-XPOD(NPOD,NN-1))
      IF (D.LT.T) GO TO 185
      IF (LERR.EQ.1) GO TO 175
      LERR=1
      WRITE(2,10) ABC,NCASE,XMACH,NX,NTHETA
175   IF (KODE.EQ.1) GO TO 180
      KODE=1
      KKKDE=1
      WRITE(2,20) NPOD
      WRITE(2,35)
180   TPRINT=THETA*57.29578
      PHIPR=PHI*57.29578
      WRITE(2,40) XPOD(NPOD,NN-1), PODORD(NPOD,NN-1), XPOD(NPOD,NN),
     & PODORD(NPOD,NN), TPRINT, PHIPR
185   CONTINUE
190   CONTINUE
195   CONTINUE
200   CONTINUE
205   CONTINUE
!
      WRITE(*,*) 'Leaving OVL30 (SLOPE)'
      WRITE(2,*) 'Leaving OVL30 (SLOPE)'
      END   ! -------------------------- End of Subroutine OVL30 (SLOPE)
*+
      SUBROUTINE OVL40
*   --------------------------------------------------------------------
*     PURPOSE - (XMAT) COMPUTES,INVERTS,AND STORES (NX-1)X(NX-1) MATRIX
*
*     NOTES- Writes NNX records on unit 10. Each has length of NNX-1.
!      The first record is the Q-matrix. The next NNX-1 records are
!      the inverse of the PQ matrix.
*
 !!!   IMPLICIT NONE
*
*      EXTERNAL
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
      REAL PI
      PARAMETER (PI=3.14159265)
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
      REAL E,E1,E2
      INTEGER I,J,M,N,NN
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
      DIMENSION PQ(99,99),Q(99),XX(99),IPI(99),IND(99,2)
************************************************************************
*     C O M M O N   B L O C K   D E F I N I T I O N S                  *
************************************************************************
      COMMON/BLK3/NNX
*-----------------------------------------------------------------------
      WRITE(*,*) 'Entering OVL40 (XMAT)'
      WRITE(2,*) 'Entering OVL40 (XMAT)'
*
      REWIND 10
      NN=NNX-1
      XN=FLOAT(NNX)
      DO 10 J=1,NN
      E=J
10    XX(J)=E/XN                      ! xx=1/nnx, 2/nnx,..., (nnx-1)/nnx
      DO 40 N=1,NN
      X=XX(N)
      Q(N)=(ACOS(1.-2.*X)-(2.-4.*X)*SQRT(X-X**2))/PI
      DO 25 M=N,NN
      Y=XX(M)
      E=(X-Y)**2
      E1=X+Y-2.*X*Y
      E2=2.*SQRT(X*Y*(1.-X)*(1.-Y))
      IF (E) 15,20,15
15    PQ(M,N)=.5*E*ALOG((E1-E2)/(E1+E2))+E1*E2
      GO TO 25
20    PQ(M,N)=E1*E2
25    CONTINUE
      NK=N-1
      IF (NK) 40,40,30
30    DO 35 M=1,NK
      E=PQ(N,M)
35    PQ(M,N)=E
40    CONTINUE
! following statement gets flagged as warning by some compilers
! B is not an array. This is OK because 4th argument is zero
      CALL MATINV (99,NN,PQ,0,B,1,DET,IKK,IPI,IND)
      WRITE(10) (Q(I),I=1,NN)
      DO 45 N=1,NN
      DO 42 I=1,NN
42    Q(I)=PQ(N,I)
      WRITE(10) (Q(I),I=1,NN)
45    CONTINUE
!
      WRITE(*,*) 'Leaving OVL40 (XMAT)'
      WRITE(2,*) 'Leaving OVL40 (XMAT)'
      END   ! --------------------------- End of Subroutine OVL40 (XMAT)
*+
      SUBROUTINE OVL50
*   --------------------------------------------------------------------
*     PURPOSE - COMPUTES AREA DISTRIBUTION FOR ANY OF 5 COMPONENTS
*
*     NOTES- Originally called ADIST
*        PP may be used before set
*
 !!!   IMPLICIT NONE
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
      INTEGER NSECP   ! number of segments dividing 2pi
      REAL PI
      PARAMETER (PI=3.14159265, NSECP=24)   ! each segment=15 deg
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
!!!      DIMENSION R(99),XF(99),SF(99)
      REAL P(8,3)                         ! never used ???
      REAL XP(101),RP(101)
      DIMENSION XARR(101),PP(4,4),S(101,5)
      DIMENSION XAFUS(4),XBFUS(4)
      DIMENSION JJ5(5)
************************************************************************
*     C O M M O N   B L O C K   D E F I N I T I O N S                  *
************************************************************************
      COMMON J0,J1,J2,J3,J4,J5,J6,
     1NWAF,NWAFOR,NFUS,NRADX(4),NFORX(4),NP,NPODOR,
     2NF,NFINOR,NCAN,NCANOR,
     3J2TEST,LERR,NRICH,REFA,
     4 XMACH,NX,NTHETA,NREST,XREST(10)
     5,KKODE,JRST,KKKDE,IPLOT
      COMMON/BLK1/KATE
      COMMON/BLK4/XXA(37),XXB(37),XAC(37,5),XBC(37,5),VSUM
      COMMON/BLK6/ARNO(4),ARBA(4)
      COMMON/CYC/KOCYC,ICYC,ICY,CDW,CDWSV,KSTOP,
     1FOPX(30,4),FOPZ(30,4),FOPS(30,4)
      COMMON/FILES/FDIR(35),DIRBUF(512)
      COMMON/XZR/XI(101,4),ZI(101,4),RX(101,4)
      COMMON/WING/XAF(30),WAFORG(20,4),W(20,4),
     1WAFORD(20,3,30),TZORD(20,30),ORDMAX(20,2)
      COMMON/FUSE/XFUS(30,4),ZFUS(30,4),FUSARD(30,4),
     1FUSRAD(30,4),SFUS(30,30,8)
      COMMON/POD/PODORG(9,3),XPOD(9,30),PODORD(9,30)
      COMMON/FIN/FINORG(6,2,4),XFIN(6,10),FINORD(6,2,10),
     1FINX2(6,2,10),FINX3(6,2,10),FINMX1(6),FINMX2(6),
     2FINTH1(6),FINTH2(6)
      COMMON/CAN/CANORG(2,2,4),XCAN(2,10),CANORD(2,2,10),
     1CANOR1(2,2,10),CANORX(2,2,10),CANMAX(2,2,2)
C     COMMON/LAST/S(101,5)
C
*-----------------------------------------------------------------------
      WRITE(*,*) 'Entering OVL50 (ADIST)'
      WRITE(2,*) 'Entering OVL50 (ADIST)'
*
      VSUM=0.0
      BETA=SQRT(XMACH**2-1.)
      XN=NX
      NN=NX+1
      XL=NTHETA
      LL=NTHETA+1
      IF (NTHETA.EQ.1) LL=1
      DELTH=PI/XL
      A=1.
      JJ5(1)=J1
      JJ5(2)=J2
      JJ5(3)=J3
      JJ5(4)=J4
      JJ5(5)=J5
C
C         COMPUTE S(THETA)
C
      DO 570 K=1,LL
C
      IF (J6.NE.1) GO TO 15
      IF (K-(LL+1)/2) 15,15,10
10    N=LL+1-K
      XXA(K)=XXA(N)
      XXB(K)=XXB(N)
      GO TO 570
15    CONTINUE
      IF (KOCYC.EQ.0) GO TO 19
C     IADD=38303+((K-1)*505)
      IADD=1+((K-1)*505)
      JM=IADD
      DO 1234 JK=1,5
      DO 1234 JL=1,101
      READ(9,REC=JM) S(JL,JK)
      JM=JM+1
1234  CONTINUE
      DO 16 I=1,101
16    S(I,2)=0.
      GO TO 21
19    CONTINUE
      DO 20 I=1,101
      DO 20 J=1,5
20    S(I,J)=0.
21    CONTINUE
      E=K-1
      THETA=-.5*PI+E*DELTH
      COSTH=COS(THETA)
      SINTH=SIN(THETA)
      B=-BETA*COSTH
      C=-BETA*SINTH
C
C          COMPUTE END-POINTS OF SEGMENT OF X-AXIS OUTSIDE OF WHICH
C          S(X,THETA) IS ZERO FOR CURRENT VALUE OF THETA
C
      IF (KOCYC.EQ.0) GO TO 24
      GO TO 40
24    CONTINUE
      DO 25 I=1,5
      XAC(K,I)=0.
25    XBC(K,I)=0.
      IF (J1.EQ.0) GO TO 40
C     READ(9,REC=1)BLOCK(1)
      DO 35 I=1,NWAF
      IF (I.NE.1) GO TO 30
      XA=WAFORG(1,1)+B*WAFORG(1,2)+C*(WAFORG(1,3)+TZORD(1,1))
      XB=WAFORG(1,1)+WAFORG(1,4)-B*WAFORG(1,2)+
     & C*(WAFORG(1,3)+TZORD(1,NWAFOR))
30    CONTINUE
      XA=MIN(XA,WAFORG(I,1)+B*WAFORG(I,2)+C*(WAFORG(I,3)+TZORD(I,1)))
      XB=MAX(XB,WAFORG(I,1)+WAFORG(I,4)-B*WAFORG(I,2)+
     & C*(WAFORG(I,3)+TZORD(I,NWAFOR)))
35    CONTINUE
      XAC(K,1)=XA
      XBC(K,1)=XB
 40   CONTINUE
      IF (J2.EQ.0) GO TO 65
C     READ(9,REC=7501)BLOCK(1)
      DO 55 I=1,NFUS
      NRAD=NRADX(I)
      NFUSOR=NFORX(I)
      IF (J2TEST.NE.3) GO TO 50
      LQ=1+2*(I-1)
      XAFUS(I)=XFUS(1,I)+B*SFUS(1,1,LQ)+C*SFUS(1,1,LQ+1)
      XBFUS(I)=XFUS(NFUSOR,I)-B*SFUS(1,NFUSOR,LQ)+C*SFUS(1,NFUSOR,LQ+1)
      DO 45 J=2,NRAD
      XAFUS(I)=MIN(XAFUS(I),XFUS(1,I)+B*SFUS(J,1,LQ)+C*SFUS(J,1,LQ+1))
      XBFUS(I)=MAX(XBFUS(I),XFUS(NFUSOR,I)-B*SFUS(J,NFUSOR,LQ)+
     &    C*SFUS(J,NFUSOR,LQ+1))
45    CONTINUE
      GO TO 55
50    CONTINUE
      XAFUS(I)=XFUS(1,I)+B*FUSRAD(1,I)*COSTH+
     & C*(ZFUS(1,I)+FUSRAD(1,I)*SINTH)
      XBFUS(I)=XFUS(NFUSOR,I)-B*FUSRAD(NFUSOR,I)*COSTH+
     & C*(ZFUS(NFUSOR,I)-FUSRAD(NFUSOR,I)*SINTH)
55    CONTINUE
      IF (KOCYC.NE.0) GO TO 115
      XAC(K,2)=XAFUS(1)
      XBC(K,2)=XBFUS(1)
      DO 60 I=1,NFUS
      XAC(K,2)=MIN(XAC(K,2),XAFUS(I))
60    XBC(K,2)=MAX(XBC(K,2),XBFUS(I))
 65   CONTINUE
      IF (J3.EQ.0) GO TO 80
C     READ(9,REC=15803)BLOCK(1)
      XA=PODORG(1,1)+XPOD(1,1)+B*(PODORG(1,2)+COSTH*PODORD(1,1))+
     & C*(PODORG(1,3)+SINTH*PODORD(1,1))
      XB=PODORG(1,1)+XPOD(1,1)-B*(PODORG(1,2)+COSTH*PODORD(1,1))+
     & C*(PODORG(1,3)-SINTH*PODORD(1,1))
      DO 75 I=1,NP
      DO 70 J=1,NPODOR
      XA=MIN(XA,PODORG(I,1)+XPOD(I,J)+B*(PODORG(I,2)+COSTH*PODORD(I,J))+
     & C*(PODORG(I,3)+SINTH*PODORD(I,J)))
      XB=MAX(XB,PODORG(I,1)+XPOD(I,J)-B*(PODORG(I,2)+COSTH*PODORD(I,J))+
     & C*(PODORG(I,3)-SINTH*PODORD(I,J)))
70    CONTINUE
75    CONTINUE
      XAC(K,3)=XA
      XBC(K,3)=XB
 80   CONTINUE
      IF (J4.EQ.0) GO TO 95
C     READ(9,REC=23303)BLOCK(1)
      DO 90 LQ=1,NF
      DO 90 I=1,2
      IF (LQ+I-2.NE.0) GO TO 85
      XA=FINORG(LQ,1,1)+B*FINORG(LQ,1,2)+C*FINORG(LQ,1,3)
      XB=FINORG(LQ,1,1)+FINORG(LQ,1,4)-B*FINORG(LQ,1,2)+C*FINORG(LQ,1,3)
      GO TO 90
85    XA=MIN(XA,FINORG(LQ,I,1)+B*FINORG(LQ,I,2)+C*FINORG(LQ,I,3))
      XB=MAX(XB,FINORG(LQ,I,1)+FINORG(LQ,I,4)-B*FINORG(LQ,I,2)+
     & C*FINORG(LQ,I,3))
90    CONTINUE
      XAC(K,4)=XA
      XBC(K,4)=XB
95    CONTINUE
      IF (J5.EQ.0) GO TO 115
C     READ(9,REC=30803)BLOCK(1)
      DO 110 NA=1,NCAN
      DO 105 I=1,2
      IF (NA+I-2.NE.0) GO TO 100
      XA=CANORG(NA,1,1)+B*CANORG(NA,1,2)+C*CANORG(NA,1,3)
      XB=CANORG(NA,1,1)+CANORG(NA,1,4)-B*CANORG(NA,1,2)+C*CANORG(NA,1,3)
      GO TO 105
100   XA=MIN(XA,CANORG(NA,I,1)+B*CANORG(NA,I,2)+C*CANORG(NA,I,3))
      XB=MAX(XB,CANORG(NA,I,1)+CANORG(NA,I,4)-B*CANORG(NA,I,2)+
     & C*CANORG(NA,I,3))
105   CONTINUE
110   CONTINUE
      XAC(K,5)=XA
      XBC(K,5)=XB
 115  CONTINUE
      DO 120 I=1,5
      IF (JJ5(I).EQ.0) GO TO 120
      JI=I
      GO TO 125
120   CONTINUE
125   CONTINUE
      XA=XAC(K,JI)
      XB=XBC(K,JI)
      DO 130 J=JI,5
      IF (JJ5(J).EQ.0) GO TO 130
      XA=MIN(XA,XAC(K,J))
      XB=MAX(XB,XBC(K,J))
130   CONTINUE
C
C         COMPUTE X ARRAY
C
      XXA(K)=XA
      XXB(K)=XB
      DELX=(XB-XA)/XN
      DDELX=.00001*DELX
      DO 135 J=1,NN
      E=J-1
      XARR(J)=XA+E*DELX
      IF (J.EQ.1) XARR(J)=XARR(J)+DDELX
      IF (J.EQ.NN) XARR(J)=XARR(J)-DDELX
135   CONTINUE
C
C         COMPUTE S(X,THETA) FOR WING
C
      IF (KOCYC.NE.0) GO TO 280
      IF (J1.EQ.0) GO TO 280
C     READ(9,REC=1)BLOCK(1)
      DO 270 M=1,2
      EE=(-1.0)**(M-1)
C
150   DO 265 L=2,NWAF
C
      DO 260 N=2,NWAFOR
      IF (N-2) 185,210,185
185   DO 205 INK=1,4
      PP(1,INK) = PP(3,INK)
      PP(2,INK) = PP(4,INK)
205   CONTINUE
210   PP(3,1)   = WAFORD(L-1,3,N)
      PP(4,1)   = WAFORD(L,3,N)
      PP(3,3)   = (WAFORD(L-1,1,N)+WAFORD(L-1,2,N))*0.5
      PP(4,3)   = (WAFORD(L,1,N)+WAFORD(L,2,N))*0.5
      PP(3,4)   = WAFORD(L-1,1,N)-WAFORD(L-1,2,N)
      PP(4,4)   = WAFORD(L,1,N)-WAFORD(L,2,N)
      IF (N-2) 220,215,220
215   PP(1,1)   = WAFORG(L-1,1)
      PP(1,2)   = WAFORG(L-1,2)*EE
      PP(1,3)   = (WAFORD(L-1,1,1)+WAFORD(L-1,2,1))*0.5
      PP(1,4)=WAFORD(L-1,1,1)-WAFORD(L-1,2,1)
      PP(2,1)   = WAFORG(L,1)
      PP(2,2)   = WAFORG(L,2)*EE
      PP(2,3)   = (WAFORD(L,1,1)+WAFORD(L,2,1))*0.5
      PP(2,4)   = WAFORD(L,1,1)-WAFORD(L,2,1)
220   PP(3,2)   = PP(1,2)
      PP(4,2)   = PP(2,2)
C
      CALL PANEL(NN,XARR,1,S,B,C,PP)
C
C     S(X,THETA) IS BEING SUMMED FOR EACH WING PANNEL
C
260   CONTINUE
265   CONTINUE
270   CONTINUE
C
C         COMPUTE S(X,THETA) FOR FUSELAGE
C
 280  CONTINUE
      IF (J2.EQ.0) GO TO 335
C     READ(9,REC=7501)BLOCK(1)
      N=NRICH
      E=0.0
      DO 320 NFU=1,NFUS
290   CONTINUE
      NRAD=NRADX(NFU)
      MQ=2*(NRAD-1)
      NFUSOR=NFORX(NFU)
! j2test=1 circular uncambered; =2 circular cambered; =3 arbitrary
      GO TO (295,300,305), J2TEST
295   CALL SPOD(BETA,THETA,NN,XARR,N,MQ,XI(1,NFU),RX(1,NFU),E,E,E,2,S)
      GO TO 310
300   CALL SPOD2(A,B,C,NN,XARR,N,MQ,XI(1,NFU),ZI(1,NFU),RX(1,NFU),
     & XAFUS(NFU),ARNO(NFU),XBFUS(NFU),ARBA(NFU),E,E,E,2,S)
      GO TO 310
305   KK=1+(NFU-1)*2
      CALL SPOD3(A,B,C,NN,XARR,NRAD,NFUSOR,XFUS(1,NFU),SFUS(1,1,KK),
     & XAFUS(NFU),ARNO(NFU),XBFUS(NFU),ARBA(NFU),E,E,E,2,S)
310   CONTINUE
C
320   CONTINUE
C
C
325   CONTINUE
      IF (.NOT.(NTHETA.EQ.1.AND.XMACH.LT.1.0000011)) GO TO 335
      NFUSOR=NFORX(NFUS)
      DO 330 NFU=1,NFUS
330   VSUM=VSUM+(ARBA(NFU)-ARNO(NFU))*(XB-XFUS(NFUSOR,NFUS))
C
C
C       COMPUTE S(X,THETA) FOR NACELLS
 335  CONTINUE
      IF (KOCYC.NE.0) GO TO 370
      IF (J3.EQ.0) GO TO 370
C     READ(9,REC=15803)BLOCK(1)
      MQ=NSECP
      DO 355 LP=1,NP
      DO 350 L=1,2
      IF (L.EQ.2.AND.PODORG(LP,2).EQ.0.) GO TO 350
      IF (L.EQ.2) GO TO 345
      XZERO=PODORG(LP,1)
      ZZERO=PODORG(LP,3)
      DO 340 N=1,NPODOR
      XP(N)=XPOD(LP,N)
340   RP(N)=PODORD(LP,N)
345   EE=(-1.0)**(L-1)                       ! L=1 -> EE=1; L=2 -> EE=-1
      YZERO=PODORG(LP,2)*EE
      CALL SPOD(BETA,THETA,NN,XARR,NPODOR,MQ,XP,RP,
     & XZERO,YZERO,ZZERO, 3,S)
350   CONTINUE
355   CONTINUE
360   CONTINUE
      IF (.NOT.(NTHETA.EQ.1.AND.XMACH.LT.1.0000011)) GO TO 370
      DO 365 LP=1,NP
      E=1.
      IF (PODORG(LP,2).NE.0.) E=2.
365   VSUM=VSUM+E*PI*(PODORD(LP,NPODOR)**2-PODORD(LP,1)**2)*
     &   (XB-PODORG(LP,1)-XPOD(LP,NPODOR))
C
  370 CONTINUE
      IF (KOCYC.NE.0) GO TO 460
C         COMPUTE S(X,THETA) FOR FINS
C
      IF (J4.EQ.0) GO TO 460
C     READ(9,REC=23303)BLOCK(1)
C
      DO 450 NNQ=1,NF
      LQ=NNQ
      DO 445 L=1,2
      IF (FINORG(LQ,1,2).EQ.0..AND.L.EQ.2) GO TO 445
      EE=(-1.0)**(L-1)
C
      DO 440 M=2,NFINOR
      IF (M-2) 390,415,390
390   DO 410 N=1,4
      PP(1,N)  = PP(3,N)
      PP(2,N)  = PP(4,N)
410   CONTINUE
415   PP(3,1)  = FINX3(LQ,1,M)
      PP(4,1)  = FINX3(LQ,2,M)
      PP(3,3) = FINORG(LQ,1,3)
      PP(4,3)  = FINORG(LQ,2,3)
      PP(3,4)  = FINORD(LQ,1,M)-FINX2(LQ,1,M)
      PP(4,4)  = FINORD(LQ,2,M)-FINX2(LQ,2,M)
      IF (M-2) 425,420,425
420   PP(1,1)  = FINORG(LQ,1,1)
      PP(1,2)  = FINORG(LQ,1,2)*EE
      PP(1,3)  = FINORG(LQ,1,3)
      PP(1,4)  = FINORD(LQ,1,1)-FINX2(LQ,1,1)
      PP(2,1)  = FINORG(LQ,2,1)
      PP(2,2)  = FINORG(LQ,2,2)*EE
      PP(2,3)  = FINORG(LQ,2,3)
      PP(2,4)  = FINORD(LQ,2,1)-FINX2(LQ,2,1)
425   PP(3,2)  = PP(1,2)
      PP(4,2)  = PP(2,2)
C
      CALL PANEL(NN,XARR,4,S,B,C,PP)
C
440   CONTINUE
445   CONTINUE
450   CONTINUE
C
  460 CONTINUE
      IF (KOCYC.NE.0) GO TO 565
C       COMPUTE S(X,THETA) FOR CANARDS
C
      IF (J5.EQ.0) GO TO 565
C     READ(9,REC=30803)BLOCK(1)
C
      DO 555 NCA=1,NCAN
      DO 550 L=1,2
      EE=(-1.0)**(L-1)
C
      DO 545 M=2,NCANOR
      IF (M-2) 495,520,495
495   DO 515 I=1,4
      PP(1,I)  = PP(3,I)
      PP(2,I)  = PP(4,I)
515   CONTINUE
520   PP(3,1)  = CANORX(NCA,1,M)
      PP(4,1)  = CANORX(NCA,2,M)
      PP(3,3)  = (CANOR1(NCA,1,M)+CANORD(NCA,1,M))*0.5
      PP(4,3)  = (CANOR1(NCA,2,M)+CANORD(NCA,2,M))*0.5
      PP(3,4)  = CANORD(NCA,1,M) -CANOR1(NCA,1,M)
      PP(4,4)  = CANORD(NCA,2,M) -CANOR1(NCA,2,M)
      IF (M-2) 530,525,530
525   PP(1,1)  = CANORG(NCA,1,1)
      PP(1,2)  = CANORG(NCA,1,2)*EE
      PP(1,3)  = (CANOR1(NCA,1,1)+CANORD(NCA,1,1))*0.5
      PP(1,4)  = CANORD(NCA,1,1)-CANOR1(NCA,1,1)
      PP(2,1)  = CANORG(NCA,2,1)
      PP(2,2)  = CANORG(NCA,2,2)*EE
      PP(2,3)  = (CANOR1(NCA,2,1)+CANORD(NCA,2,1))*0.5
      PP(2,4)  = CANORD(NCA,2,1) -CANOR1(NCA,2,1)
530   PP(3,2)  = PP(1,2)
      PP(4,2)  = PP(2,2)
C
      CALL PANEL(NN,XARR,5,S,B,C,PP)
C
545   CONTINUE
550   CONTINUE
555   CONTINUE
C
565   CONTINUE
      IF(KOCYC.NE.0) GO TO 571
C     IADD=38303+((K-1)*505)
      IADD=1+((K-1)*505)
      JM=IADD
      DO 568 JK=1,5
      DO 568 JL=1,101
      WRITE(9,REC=JM) S(JL,JK)
      JM=JM+1
568   CONTINUE
      GO TO 572
C 571 IADD=38404+((K-1)*505)
571   IADD=102+((K-1)*505)
      JM=IADD
      DO 1235 JL=1,101
      WRITE(9,REC=JM) S(JL,2)
      JM=JM+1
1235  CONTINUE
572   CONTINUE
570   CONTINUE
!
      WRITE(*,*) 'Leaving OVL50 (ADIST)'
      WRITE(2,*) 'Leaving OVL50 (ADIST)'
      END   ! -------------------------- End of Subroutine OVL50 (ADIST)
*+
      SUBROUTINE OVL60
*   --------------------------------------------------------------------
*     PURPOSE - (OUT) PRINTS AND PLOTS
*
*     NOTES-
*
 !!!   IMPLICIT NONE
*
!     BUG LIST -
!       declared, not referenced: dgth,in,nout,nym1,nym5,r1,the
!       set but not used: nocas
!       used before set: n2
!       may be used before set: dragth, web
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
      REAL PI
      INTEGER I401
      INTEGER GNU
      PARAMETER (PI=3.14159265, I401=401, GNU=7)
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
      CHARACTER*20 gnuName
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
      INTEGER KB(4)
      INTEGER KE(4)
!!!      INTEGER IN(2)
!!!      INTEGER NYM1(3)
!!!      INTEGER NOUT(10)
!!!      REAL DGTH(2)
!!!      REAL THE(2)
      REAL XARR(101)
      REAL THET(37)
      INTEGER JJ(5)
      REAL XI(101)
      REAL XF(99),SF(99),R(99)
      REAL SBARP(101,6)
      REAL XIP(101)
      REAL ZIP(101)
      REAL XII(101)
!!!      INTEGER NYM5(4)
      REAL RIP(101)
!!!      REAL R1(99)
      REAL SREST(10)
      REAL S(101,5)
      REAL SB2(101)
      REAL SOPT2(101)
!!!      INTEGER NYM7(3)
      REAL DRAGTH(37)
      REAL WEB(37)
************************************************************************
*     C O M M O N   B L O C K   D E F I N I T I O N S                  *
************************************************************************
      COMMON /TEXT/ ABC(20), NCASE
      COMMON J0,J1,J2,J3,J4,J5,J6,
     1NWAF,NWAFOR,NFUS,NRADX(4),NFORX(4),NP,NPODOR,
     2NF,NFINOR,NCAN,NCANOR,
     3J2TEST,LERR,NRICH,REFA,
     4 XMACH,NX,NTHETA,NREST,XREST(10)
     5,KKODE,JRST,KKKDE,IPLOT
!!!     5,KKODE,JRST,KKKDE         ! put IPLOT back in   14Nov94
!
      COMMON/BLK2/V,XFUS1,XFUSN
      COMMON/BLK4/XXA(37),XXB(37),
     1XAC(37,5),XBC(37,5),VSUM
      COMMON/BLK5/NFUSX,FUSAX(101),RFUS(101)
      COMMON/BLK6/ARNO(4),ARBA(4)
      COMMON/SAVE/SAVES(101,2),SAVEX(101,2),NSAVE
      COMMON/CYC/KOCYC,ICYC,ICY,CDW,CDWSV,KSTOP,
     1FOPX(30,4),FOPZ(30,4),FOPS(30,4)
      COMMON/ESEG/XBEG(4),XEND(4)
      COMMON/FILES/FDIR(35),DIRBUF(512)
      COMMON/LINXZ/XLINE(401),ZLINE(401)
C     COMMON/LAST/S(101,5)
*-----------------------------------------------------------------------
!!!      CHARACTER*5 NOCAS
!!!      DATA NOCAS/'CASE '/
      DATA N30/30/
      DATA N29/29/,N28/28/
      DATA N17/17/,EPS/.00001/
************************************************************************
*     A R I T H M E T I C   S T A T E M E N T   F U N C T I O N S      *
************************************************************************
      TERP(XB,XX,XE,FB,FE)=(FB*(XE-XX)+FE*(XX-XB))/(XE-XB)
*-----------------------------------------------------------------------
C
      WRITE(*,*) 'Entering OVL60 (OUT)'
      WRITE(2,*) 'Entering OVL60 (OUT)'
C     ITAPE=5LPTAPE
C     WRITE(2,15)NOCAS,NCASE
C15   FORMAT (A6,A4)
20    FORMAT (F7.3)
      BETA=SQRT(XMACH**2-1.)
      IF (J2.EQ.0) GO TO 30
C      READ(9,REC=15001)XLINE(1)
C      READ(9,REC=15402)ZLINE(1)
      NFUSPT=1
      DO 25 N=1,NFUS
      NN=NFORX(N)
25    NFUSPT=NFUSPT+NN-1
      IF (J2TEST.NE.3) NFUSPT=NFUS*(NRICH-1)+1
30    CONTINUE
      XN=NX
      NN=NX+1
      XL=NTHETA
      DELTH=PI/XL
      LL=NTHETA+1
      NU=NX-1
      JJ(1)=J2
      JJ(2)=J1
      JJ(3)=J3
      JJ(4)=J4
      JJ(5)=J5
      DRAG=0.
      CDW=0.
      VWING=0.
      CDLOWP=0.
      FDRP=0.
C
C         FIND 1ST COMPONENT
C
      DO 40 J=1,5
      IF (JJ(J).EQ.0) GO TO 40
      JK=J
      GO TO 45
40    CONTINUE
45    CONTINUE
      IF (NTHETA.NE.1) GO TO 50
      LL=1
      GO TO 135
50    CONTINUE
C
C         EXCHANGE WING AND BODY XA AND XB    (why?)
C
!!!      WRITE(*,*) 'Exchange wing and body'
      DO 55 L=1,LL                                  ! LL=ntheta+1
      E=XAC(L,1)
      XAC(L,1)=XAC(L,2)
      XAC(L,2)=E
      E=XBC(L,1)
      XBC(L,1)=XBC(L,2)
55    XBC(L,2)=E
C
C         FIND X(THETA) MIN AND MAX FOR BUILDUP
C
      JL=JK+1
      IF (JL.GT.5) GO TO 70
      DO 65 L=1,LL
      IF (J6.EQ.1.AND.L.GT.(LL+1)/2) GO TO 70
      DO 65 J=JL,5
      IF (JJ(J).NE.0) GO TO 60
      XAC(L,J)=XAC(L,J-1)
      XBC(L,J)=XBC(L,J-1)
      GO TO 65
60    XAC(L,J)=MIN(XAC(L,J),XAC(L,J-1))
      XBC(L,J)=MAX(XBC(L,J),XBC(L,J-1))
65    CONTINUE
70    CONTINUE
C
C
C         FIND  MIN AND MAX
C
      WRITE(*,*) 'Find max and min'
      XMIN=XXA(1)
      XMAX=XXB(1)
      KMIN=1
      KMAX=1
      DO 85 K=1,LL
      IF (J6.EQ.1.AND.K.GT.(LL+1)/2) GO TO 87
      IF (XMIN.LT.XXA(K)) GO TO 75
      XMIN=XXA(K)
      KMIN=K
75    IF (XMAX.GT.XXB(K)) GO TO 80
      XMAX=XXB(K)
      KMAX=K
80    CONTINUE
85    CONTINUE
87    CONTINUE
      DO 90 I=1,101
      SB2(I)=0.
      DO 90 J=1,6
      SBARP(I,J)=0.
90    CONTINUE
C
C         COMPUTE XI AND XIPRIME ARRAYS
C
      DELX=(XMAX-XMIN)/XN
      DO 95 N=1,NN                                             ! NN=NX+1
      E=N-1
95    XI(N)=XMIN+E*DELX
      IF (J2.NE.0) GO TO 105
      DO 100 N=1,NN
      XIP(N)=XI(N)
100   ZIP(N)=0.
      XAP=XMIN
      XBP=XMAX
      GO TO 125
105   CONTINUE
      TXA=-PI/2.+FLOAT(KMIN-1)*DELTH
      TXB=-PI/2.+FLOAT(KMAX-1)*DELTH
      XAP=XMIN+BETA*SIN(TXA)*ZLINE(1)
      XBP=XMAX+BETA*SIN(TXB)*ZLINE(NFUSPT)
      DELX=(XBP-XAP)/XN
      IPTQ=-1
      DO 120 N=1,NN
      E=N-1
      XIP(N)=XAP+E*DELX
      IF (XIP(N).GE.XLINE(1)) GO TO 110
      ZIP(N)=ZLINE(1)
      GO TO 120
110   IF (XIP(N).LE.XLINE(NFUSPT)) GO TO 115
      ZIP(N)=ZLINE(NFUSPT)
      GO TO 120
115   CALL IUNI(I401,NFUSPT,XLINE,1,ZLINE,1,XIP(N),ZIP(N),IPTQ,IERR)
120   CONTINUE
125   CONTINUE
      DELX=1./XN
      DO 130 I=1,NU
      E=I
130   XF(I)=E*DELX
135   CONTINUE
C
C         COMPUTE THETA
C
      WRITE(*,*) 'Fill theta array from -90 to 90 deg',LL, ' entries'
      DTHET=180./XL
      DO 140 K=1,LL
      E=K-1
140   THET(K)=-90.+E*DTHET
C
C         COMPUTE SBAR(THETA)*
C
      DO 270 K=1,LL                  ! start of BIG loop
      IF (J6.NE.1) GO TO 145                ! j6=1 if symmetrical z=0
      IF (K.LE.(LL+1)/2) GO TO 145
      N=LL+1-K
      DRAGTH(K)=DRAGTH(N)
      WEB(K)=WEB(N)
      GO TO 270
C145  IADD=38303+((K-1)*505)
145   IADD=1+((K-1)*505)
      JM=IADD
      DO 147 JN=1,5
      DO 147 JS=1,101
      READ(9,REC=JM) S(JS,JN)
      JM=JM+1
147   CONTINUE
      IF (NTHETA.EQ.1) GO TO 155
      ELL=XXB(K)-XXA(K)
C
C         COMPUTE VOLUME OF WING EQUIVALENT BODY
C         CORRESPONDING TO A PARTICULAR VALUE OF THETA
C
!!!      WRITE(*,*) 'Compute volume of wing-equivalent body for theta# ',k
      IF (J1.EQ.0) GO TO 155
      SUM=0.0
      DO 150 J=1,NN
      E=FLOAT(2*MOD(J-1,2)+2)
      IF (MOD(J-1,NX).EQ.0) E=1.
150   SUM=SUM+E*S(J,1)
      WEB(K)=(ELL*SUM)/(3.*XN)
155   CONTINUE
C
C         COMPUTE BUILDUP
C
      DO 160 N=1,NN
      E=S(N,1)
      S(N,1)=S(N,2)
160   S(N,2)=E
C
C         SUBTRACT CAPTURE AREA
C
      SCAPB=S(1,1)
      SCAPP=S(1,3)
      DO 165 N=1,NN
      S(N,1)=S(N,1)-SCAPB
      S(N,3)=S(N,3)-SCAPP
165   CONTINUE
      DO 175 N=1,NN
      DO 170 J=2,5
170   S(N,J)=S(N,J)+S(N,J-1)
175   CONTINUE
!        skips printing except for theta=-90,-45,0,45,90
      IF (LL.EQ.1) GO TO 180
      IF (MOD(K-1,(LL-1)/4).NE.0) GO TO 210
180   CONTINUE
C
C         COMPUTE X ARRAY
C
      DELX=(XXB(K)-XXA(K))/XN
      DO 185 N=1,NN
      E=N-1
      XARR(N)=XXA(K)+E*DELX
185   CONTINUE
C
C         PRINT
C
      WRITE(2,190) ABC,NCASE,ICY,XMACH,NX,NTHETA
190   FORMAT (2X,20A4//10X,'CASE NO. ',A4,4X,'CYCLE ',I3/
     & 10X,'MACH = ',F6.3,6X,'NX =',I3,6X,'NTHETA =',I3//)
!
      WRITE(2,191) THET(K),SCAPB,SCAPP
  191 FORMAT(10X,'S(X) COMPONENT BUILD UP AT THETA =',F8.3,//
     & 10X,'S(B),CAPTURE =',F9.4,6X,'S(P),CAPTURE =', F9.4//
     4 7X,'X',9X,'S(B)',7X,'S(BW)',5X,'S(BWP)',
     5 4X,'S(BWPF)',3X,'S(BWPFC)' )
!!!      WRITE(2,192) ICY
!!!192   FORMAT (//20X,'CYCLE ',I3//)
      WRITE(2,195) (XARR(N),(S(N,I),I=1,5),N=1,NN)
195   FORMAT (F11.4,5F11.3)
!
!..... Plot the component buildup at theta=-90,-45,0,45,90 .............
      WRITE(gnuName, '(A,I3.3,A)' ) 's', k, '.gnu'
      OPEN(UNIT=GNU,FILE=gnuName,STATUS='UNKNOWN')
      DO n=1,5
        WRITE(GNU, '(2F15.5)' ) (xarr(i), s(i,n),i=1,nx+1)
        WRITE(GNU,*)
      ENDDO
      CLOSE(UNIT=GNU)
!
      IF (NTHETA.NE.1) GO TO 210
      IF (XMACH.GT.1.0000011) GO TO 615
C
C         COMPUTE VOLUME OF ENTIRE AIRCRAFT
C
      WRITE(*,*) 'Compute volume after write'
      XMIN=XXA(1)
      XMAX=XXB(1)
      VTOT=0.
      DO 200 J=1,NN
      E=FLOAT(2*MOD(J-1,2)+2)
      IF (MOD(J-1,NX).EQ.0) E=1.
200   VTOT=VTOT+E*S(J,5)
      VTOT=((XMAX-XMIN)*VTOT)/(3.*XN)-VSUM
      V23=0.
      IF (J0.NE.0) V23=VTOT**(2./3.)/REFA
      WRITE(2,205) VTOT,V23
205   FORMAT (/10X,'VOLUME OF ENTIRE AIRCRAFT = ',E15.8//
     & 10X,'V**(2/3)/S',10X,'= ', E15.8)
      GO TO 615
210   L=K
C
C         COMPUTE DRAG OF AREA DISTRIBUTION CORRESPONDING
C         TO A PARTICULAR VALUE OF THETA
C
!!!      WRITE(*,*) 'Compute drag for theta# ', k
      SN=S(1,5)
      SB=S(NN,5)
      CALL EMLORD (ELL,SN,SB,NU,XF,S(2,5),E,R,2)
      DRAGTH(K)=E                             ! drag/q for this theta
C
C         COMPUTE XII(THETA)
C
      CON=BETA*SIN(-PI/2.+FLOAT(L-1)*DELTH)
      DO 215 I=1,NN
215   XII(I)=XIP(I)-CON*ZIP(I)
C
C         CALCULATE MINIMUM DRAG AVERAGE EQUIVALENT BODY
C
      IF (MOD((L-1),NTHETA).NE.0) GO TO 220
      EK=14.
      GO TO 230
220   IF (MOD((L-1),4).NE.0) GO TO 225
      EK=28.
      GO TO 230
225   EK=64.
      IF (MOD(L,2).NE.0) EK=24.
230   CONTINUE
      IF (J6.EQ.1.AND.K.LT.(LL+1)/2) EK=EK*2
!
      DO 265 JI=1,5
      IF (JI.LT.JK) GO TO 265
      SN=S(1,JI)
      SB=S(NN,JI)
      SBARP(1,JI)=SBARP(1,JI)+SN*EK
      SBARP(NN,JI)=SBARP(NN,JI)+SB*EK
      KL=2
      CALL EMLORD (ELL,SN,SB,NU,XF,S(2,JI),FDR,R,KL)
      DO 260 I=2,NX
      IF (XII(I).GT.XAC(L,JI)) GO TO 235
      SFIT=SN
      GO TO 255
235   IF (XII(I).LT.XBC(L,JI)) GO TO 240
      SFIT=SB
      GO TO 255
240   SUM=0.
      EX=(XII(I)-XXA(L))/ELL
      DO 250 J=1,NU
      Y=XF(J)
      E=(EX-Y)**2
      E1=EX+Y-2.*EX*Y
      E2=2.*SQRT(EX*Y*(1.-EX)*(1.-Y))
      IF (E.LE.1.E-7) GO TO 245
      E3=.5*E*ALOG((E1-E2)/(E1+E2))+E1*E2
      GO TO 250
245   E3=E1*E2
250   SUM=SUM+E3*R(J)
      E4=(ACOS(1.-2.*EX)-(2.-4.*EX)*SQRT(EX-EX**2))/PI
      SFIT=SN+(SB-SN)*E4+SUM
255   SBARP(I,JI)=SBARP(I,JI)+SFIT*EK
260   CONTINUE
265   CONTINUE
270   CONTINUE               ! end of BIG loop  1 to ntheta+1
      CON=1./(45.*XL)
      DO 275 J=1,5
      DO 275 I=1,NN
      SBARP(I,J)=SBARP(I,J)*CON
275   CONTINUE
      ELL=XIP(NN)-XIP(1)
      SN=SBARP(1,5)
      SB=SBARP(NN,5)
      CALL EMLORD (ELL,SN,SB,NU,XF,SBARP(2,5),FDRP,R,2)
C
C         COMPUTE DRAG OF ENTIRE AIRCRAFT
!   Uses Bode's Rule (see Numerical Recipes, eq 4.1.6, or Abramowitz &
!   Stegun, eq.25.4.14). This is why ntheta MUST be a multiple of 4
!   if drag is to be computed correctly. There does not seem to be a
!   test anywhere to check the input
C
      WRITE(*,*) 'Compute drag of entire aircraft'
      SUM=0.0
      DO 295 K=1,LL
      IF (MOD((K-1),NTHETA).NE.0) GO TO 280
      E=14.
      GO TO 290
280   IF (MOD((K-1),4).NE.0) GO TO 285
      E=28.
      GO TO 290
285   E=64.
      IF (MOD(K,2).NE.0) E=24.
290   SUM=SUM+E*DRAGTH(K)
295   CONTINUE
      DRAG=SUM/(45.*XL)                   ! remember, XL is REAL(NTHETA)
      IF (J0.NE.0) CDW=DRAG/REFA
C
C         COMPUTE VOLUME OF WING EQUIVALENT BODY
C
      WRITE(*,*) 'Volume of wing'
      IF (J1.EQ.0) GO TO 315
      SUM1=0.0
      DO 310 K=1,LL                 ! using Bode's rule again
      IF (MOD(K-1,NTHETA).NE.0) GO TO 300
      E=14.
      GO TO 310
300   IF (MOD(K-1,4).NE.0) GO TO 305
      E=28.
      GO TO 310
305   E=64.
      IF (MOD(K,2).NE.0) E=24.
310   SUM1=SUM1+E*WEB(K)
      VWING=SUM1/(45.*XL)
315   CONTINUE
C
C         PLOT D/Q vs. THETA  (original code has been commented out)
C
C     NOUT(1)=NXM1
C     DGTH(1)=DRAG
C     DGTH(2)=DRAG
C
C         FIND D/Q MAX
C
C     DMAX=DRAGTH(1)
C     DO 320 K=2,LL
C     IF (DMAX.GE.DRAGTH(K)) GO TO 320
C     DMAX=DRAGTH(K)
C320  CONTINUE
C     IF (DMAX.GT.1.) GO TO 325
C     DMAX=1.
C     GO TO 330
C325  IMAX=DMAX/10.
C     IMAX=IMAX+1
C     DMAX=IMAX*10
C330  CONTINUE
C     THE(1)=THET(1)
C     THE(2)=THET(LL)
C     TH1=THE(1)
C     TH2=THE(2)
C     CALL DDIPLT (0,IN,LL,THET,DRAGTH,TH1,TH2,0.,DMAX,10,NOUT,3,NYM1,14
C    1,ITAPE)
C     CALL DDIPLT (0,IN,LL,THET,DRAGTH,TH1,TH2,0.,DMAX,10,NOUT,3,NYM1,1,
C    1ITAPE)
C     CALL DDIPLT (1,IN,2,THE,DGTH,TH1,TH2,0.,DMAX,10,NOUT,3,NYM1,14,ITA
C    1PE)
!
!   Give each file a unique name .......................................
      WRITE(gnuName, '(A,I3.3,A)' ) 'WD', icy, '.gnu'
      OPEN(UNIT=GNU, FILE=gnuName, STATUS='UNKNOWN')
      WRITE(GNU,'(F8.2,F20.6)' ) (thet(i),dragth(i),i=1,ntheta+1)
      WRITE(GNU,*)                ! blank line
      WRITE(GNU,*) thet(1),drag
      WRITE(GNU,*) thet(ntheta+1),drag
      CLOSE(UNIT=GNU)
!
C         FIND S FOR INPUT RESTRAINT POINTS
C
      IF(JRST.NE.0) GO TO 536
      IF (NREST.EQ.0) GO TO 365   ! this test isn't really needed in F77
      DO 360 N=1,NREST
      EX=(XREST(N)-XIP(1))/ELL
      IF (ABS(EX).GT..000001) GO TO 335
      SREST(N)=SN
      GO TO 360
335   IF (EX.LT..999999) GO TO 340
      SREST(N)=SB
      GO TO 360
340   SUM=0.
      EINT=NX
      DO 355 J=1,NU
      Z=J
      Y=Z/EINT
      E=(EX-Y)**2
      E1=EX+Y-2.*EX*Y
      E2=2.*SQRT(EX*Y*(1.-EX)*(1.-Y))
      IF (E.LE.1.E-7) GO TO 345
      E3=.5*E*ALOG((E1-E2)/(E1+E2))+E1*E2
      GO TO 350
345   E3=E1*E2
350   CONTINUE
      SUM=SUM+E3*R(J)
355   CONTINUE
      E4=(ACOS(1.-2.*EX)-(2.-4.*EX)*SQRT(EX-EX**2))/PI
      S1=SN+(SB-SN)*E4+SUM
      SREST(N)=S1
360   CONTINUE
365   CONTINUE
C
C         CALCULATE MINIMIMUM DRAG CURVE WITH RESTRAINTS *
C
      WRITE(*,*) 'Minimum drag curve'
      KOUNT=0
      IF (J2.NE.0) GO TO 385
      IF (NREST.NE.0) GO TO 375
      KOUNT=1
      XF(1)=XIP(2)
      SF(1)=SBARP(2,5)
      DO 370 I=3,NX
      IF (SF(1).GE.SBARP(I,5)) GO TO 370
      SF(1)=SBARP(I,5)
      XF(1)=XIP(I)
      XREST(1)=XF(1)
370   CONTINUE
      GO TO 430
375   KOUNT=0
      DO 380 I=1,NREST
      KOUNT=KOUNT+1
      XF(KOUNT)=XREST(I)
380   SF(KOUNT)=SREST(I)
      GO TO 430
385   CONTINUE
      DO 390 I=2,NX
      II=I
      IF (XIP(I).GT.XFUS1) GO TO 395
      KOUNT=KOUNT+1
      XF(KOUNT)=XIP(I)
      SF(KOUNT)=SBARP(I,5)
390   CONTINUE
      GO TO 430
395   IF (NREST.EQ.0) GO TO 410
      DO 400 I=1,NREST
      KOUNT=KOUNT+1
      XF(KOUNT)=XREST(I)
400   SF(KOUNT)=SREST(I)
      DO 405 I=II,NX
      I2=I
      IF (XIP(I).GT.XFUSN) GO TO 420
405   CONTINUE
      GO TO 430
410   KOUNT=KOUNT+1
      XF(KOUNT)=XIP(II)
      SF(KOUNT)=SBARP(II,5)
      XREST(1)=XF(KOUNT)
      IF (II.EQ.NX) GO TO 430
      II=II+1
      DO 415 I=II,NX
      I2=I
      IF (XIP(I).GT.XFUSN) GO TO 420
      IF (SF(KOUNT).GE.SBARP(I,5)) GO TO 415
      SF(KOUNT)=SBARP(I,5)
      XF(KOUNT)=XIP(I)
      XREST(1)=XF(KOUNT)
415   CONTINUE
      GO TO 430
420   DO 425 I=I2,NX
      KOUNT=KOUNT+1
      XF(KOUNT)=XIP(I)
425   SF(KOUNT)=SBARP(I,5)
430   CONTINUE
      WRITE(2,435) SN,SB,ELL,(XF(K),SF(K),K=1,KOUNT)
435   FORMAT ('1',' INTERNAL RESTRAINT POINTS (XI*)'//3X,'SN=',
     1 F10.4,3X, 'SB=',F10.4,3X,'ELL=',F10.4/13X,'XF',12X,
     2 'SF'/(F18.4,F14.4))
      DO 440 K=1,KOUNT
440   XF(K)=(XF(K)-XIP(1))/ELL
      IF (XF(KOUNT).GT.1.) XF(KOUNT)=1.
      IF (KOUNT.LE.33) GO TO 450
      WRITE(2,445)
445   FORMAT (//' RESTRAINT POINTS EXCEED ALLOWABLE STORAGE OF 33,'/
     1' OPTIMIZATION CALCULATIONS WILL BE OMITTED')
      WRITE(*,*) 'Too many restraint points'
      GO TO 578
450   CONTINUE

C
C         FIT MINIMUM DRAG CURVE THROUGH RESTRAINT POINTS
C
      CALL EMLORD (ELL,SN,SB,KOUNT,XF,SF,CDLOWP,R,1)
      SBARP(1,6)=SN
      SBARP(NN,6)=SB
      EINT=NX
      DO 465 I=2,NX
      Z=I-1
      EX=Z/EINT
      SUM=0.0
      DO 460 J=1,KOUNT
      Y=XF(J)
      E=(EX-Y)**2
      E1=EX+Y-2.*EX*Y
      E2=2.*SQRT(EX*Y*(1.-EX)*(1.-Y))
      IF (E.LE.1.E-7) GO TO 455
      E3=.5*E*ALOG((E1-E2)/(E1+E2))+E1*E2
      GO TO 460
455   E3=E1*E2
460   SUM=SUM+E3*R(J)
      E4=(ACOS(1.-2.*EX)-(2.-4.*EX)*SQRT(EX-EX**2))/PI
      SBARP(I,6)=SN+(SB-SN)*E4+SUM
465   CONTINUE
C
C         FIT MINIMUM DRAG CURVE THROUGH INPUT BODY
C
      IF (J2.EQ.0) GO TO 505
      NK=NFUSX-2
      SN=0.
      G=ARNO(1)
      DO 475 NFU=1,NFUS
      IF (NFU.EQ.1) GO TO 475
      G=G+ARNO(NFU)-ARBA(NFU-1)
475   CONTINUE
      SB=ARBA(NFUS)-G
      ELL=XFUSN-XFUS1
      SB2(1)=SN
      SB2(NN)=SB
      DO 500 I=2,NX
      IF (XIP(I).GT.XFUS1) GO TO 480
      SB2(I)=SN
      GO TO 500
480   IF (XIP(I).LT.XFUSN) GO TO 485
      SB2(I)=SB
      GO TO 500
485   SUM=0.
      EX=(XIP(I)-XFUS1)/ELL
      DO 495 J=1,NK
      Y=FUSAX(J)
      E=(EX-Y)**2
      E1=EX+Y-2.*EX*Y
      E2=2.*SQRT(EX*Y*(1.-EX)*(1.-Y))
      IF (E.LE.1.E-7) GO TO 490
      E3=.5*E*ALOG((E1-E2)/(E1+E2))+E1*E2
      GO TO 495
490   E3=E1*E2
495   SUM=SUM+E3*RFUS(J)
      E4=(ACOS(1.-2.*EX)-(2.-4.*EX)*SQRT(EX-EX**2))/PI
      SB2(I)=SN+(SB-SN)*E4+SUM
500   CONTINUE
505   CONTINUE
C
C         COMPUTE OPTIMUM SBAR(B)*
C
      DO 510 N=1,NN
      SOPT2(N)=SB2(N)-SBARP(N,5)+SBARP(N,6)
510   CONTINUE
C
C         COMPUTE DELTA SBAR
C
      DO 535 N=1,NN
535   SB2(N)=SBARP(N,6)-SBARP(N,5)
  536 CONTINUE
C
C         PRINT  XI* VS SBAR   ( modified June 95   RLC )
C
      WRITE(2,190) ABC,NCASE,ICY,XMACH,NX,NTHETA
      WRITE(2,540)           !!! ******** FIX This **********
  540 FORMAT(10X,'SBAR(X*) AVERAGE EQUIVALENT BODY'//
     & 6X,'X*',6X,'SBAR',6X,'SBAR',6X,'SBAR',6X,'SBAR',6X,'SBAR',
     & 6X,'SBAR',5X,'DELTA'/
     & 16X,'B',9X,'BW',7X,'BWP',7X,'BWPF',5X,'BWPFC',
     & 5X,'REST.',6X,'SBAR')
!!!     4 2X,'X*',5X,'SBAR(B)',2X,'SBAR(BW)',1X,'SBAR(BWP)',1X,
!!!     5 'SBAR(BWPF)',1X,'SBAR(BWPFC)',4X,'SBAR(RESTRAINED)',2X,
!!!     6 'DELTA SBAR')
!!!      WRITE(2,542) ICY
!!!542   FORMAT (//61X,'CYCLE ',I3//)
      WRITE(2,545) (XIP(N),(SBARP(N,I),I=1,6),SB2(N),N=1,NN)
545   FORMAT (F9.4,5F10.3,2F10.4)
      IF(JRST.NE.0) GO TO 578
      DO 550 N=1,NN
550   RIP(N)=SIGN(SQRT(ABS(SOPT2(N))/PI),SOPT2(N))
C
C         PRINT OPTIMUM FUSELAGE AREA DISTRIBUTION
C
      WRITE(2,190) ABC,NCASE,ICY,XMACH,NX,NTHETA
      WRITE(2,555)
555   FORMAT (10X,
     & 'OPTIMUM FUSELAGE AREA DISTRIBUTION WITH RESTRAINTS AT'/)
      N1=1
      IF (NREST.NE.0) N1=NREST
      WRITE(2,560) (XREST(N),N=1,N1)
560   FORMAT (' X=',10F12.4)
!!!      WRITE(2,562) ICY
!!!562   FORMAT (//53X,'CYCLE ',I3//)
      WRITE(2,565)
565   FORMAT (//8X,'N',8X,'X',10X,'Z',10X,'R',10X,'S')
!      IJ2=(NN+1)/2
!      IJ3=NX/2
      DO 575 M=1,NN
!      N1=M-1
!      N2=N1+IJ3
!      N3=M+IJ3
      WRITE(2,570) M-1,XIP(M),ZIP(M),RIP(M),SOPT2(M)
570   FORMAT (I9,4F11.4)
575   CONTINUE
      IF(ICYC.NE.1) GO TO 2000
      WRITE(12) N2,(XIP(NN5),SOPT2(NN5),NN5=1,N2)
! the line above is strange. XIP is only defined to NX+1, not NX+NX/2
! However, unit 12 is never read by this program, so this isn't our
! problem here in d2500.

 2000 CONTINUE
578   CONTINUE
C
C         PRINT D/Q(THETA) AND AERODYNAMIC COEFFICIENTS
C
      WRITE(2,190) ABC,NCASE,ICY,XMACH,NX,NTHETA
!!!      WRITE(2,582) ICY
!!!582   FORMAT (//10X,'CYCLE ',I3//)
      WRITE(2,585)
585   FORMAT (/10X,'D/Q ASSOCIATED WITH VARIOUS VALUES OF THETA'//
     & 10X,'N', 14X,'THETA',18X,'D/Q'/)
      DO 595 K=1,LL
      N=K-1
      WRITE(2,590) K-1,THET(K),DRAGTH(K)
590   FORMAT (I12,F20.3,F23.5)
595   CONTINUE
      IF (J0.NE.0) GO TO 598
      CDLOWP=0.
      FDRP=0.
      GO TO 599
598   CDLOWP=CDLOWP/REFA
      FDRP=FDRP/REFA
599   CONTINUE
!
      POTCDP=CDLOWP-FDRP
      IF (KOUNT.GT.33) POTCDP=0.
      OPTCDP=CDW+POTCDP
!
      WRITE(2,*) ' WING VOLUME CHECK'
      WRITE(2,*) '    Exact Volume ', V
      WRITE(2,*) '    Equivalent body volume ', VWING
      WRITE(2,*) ' ENTIRE AIRCRAFT'
      WRITE(2,*) '    D/Q=', DRAG
      WRITE(2,*) '    CDW=', CDW
      WRITE(2,*) ' DRAG OF TRANSFERRED AREAS'
      WRITE(2,*) '    Opt.Eq. Body CDW=', CDLOWP
      WRITE(2,*) '    Average Eq. body CDW=', FDRP
      WRITE(2,*) '    Opt. CDW*=', OPTCDP
      WRITE(2,*) '    Potential CDW* change=', POTCDP
!!!      WRITE(2,600)
600   FORMAT (/5X, 'WING VOLUME CHECK',31X,'ENTIRE AIRCRAFT',
     & 16X,'DRAG OF TRANSFERRED AREA DISTRIBUTIONS'//)
!!!      WRITE(2,605) V,DRAG,CDLOWP,VWING,CDW,FDRP
605   FORMAT (5X,'EXACT VOLUME',11X,'=', F14.5,11X,'D/Q',6X,'=',
     1 F11.5,15X,'OPTIMUM EQ. BODY CDW*=',E16.8//
     2 5X,'EQUIVALENT BODY VOLUME =', F14.5, 11X, 'CDW', 6X,'=',
     3 E16.8,10X,'AVERAGE EQ. BODY CDW*=', E16.8)
!!!      WRITE(2,610) OPTCDP,POTCDP
!!!610   FORMAT (/10X,'OPT. CDW*=', E16.8, 10X,
!!!     &   'POTENTIAL CDW* CHANGE=', E16.8)
615   CONTINUE
C    AN EVEN NUMBERED CYCLE HAS A SUB OF 2,AN ODD A SUB OF 1
      ICSUB=1
      TEST=FLOAT(ICY)/2.
      IR=ICY/2
      IF(FLOAT(IR).EQ.TEST) ICSUB=2
      WRITE(*,619) ICYC
619   FORMAT(' ICYC=',I3)
      IF (ICYC.EQ.1) GO TO 625        ! big jump, 625 is almost at end
      IF (KOCYC.EQ.0) GO TO 616
      IF (CDW.LT.CDWSV) GO TO 616
      WRITE(*,618) KOCYC
618   FORMAT(' KOCYC=',I4)
      KSTOP=1        ! only place in program where KSTOP is changed 
      GO TO 625
616   KOCYC=1        ! only place in program where KOCYC is changed
      CDWSV=CDW
C
C         SEARCH FOR SEGMENT END POINT POSITION
C
      NFUS1=NFUS+1
      KK=1
      IF (ABS(XIP(1)-XBEG(1)).LE.EPS) XIP(1)=XBEG(1)
      IF (ABS(XIP(NN)-XEND(NFUS)).LE.EPS) XIP(NN)=XEND(NFUS)
      DO 920 N=1,NFUS1
      IF (KK.NE.1) GO TO 898
      IF (XIP(1).EQ.XBEG(1)) GO TO 896
      KK=KK+1
      GO TO 898
896   CONTINUE
      KB(1)=1
      KK=KK+1
      GO TO 920
898   CONTINUE
      IF(N.NE.NFUS1) GO TO 908
901   IF (KK.LT.NN) GO TO 904
      KE(N-1)=NN
      GO TO 920
904   IF (XIP(KK-1).LE.XEND(N-1).AND.
     1XEND(N-1).LT.XIP(KK)) GO TO 906
      KK=KK+1
      GO TO 901
906   KE(N-1)=KK-1
C
C     THE FOLLOWING STATEMENT WAS DELETED OCT. 81 - APPEARS
C     TO BE AN ERROR.   BO WALKLEY/HTC
C
C     IF (N.EQ.NFUS1) KE(N-1)=KK
C
      GO TO 920
908   IF (XIP(KK-1).LT.XBEG(N).AND.
     1XBEG(N).LE.XIP(KK)) GO TO 910
      KK=KK+1
      GO TO 908
910   KB(N)=KK
      IF (N.EQ.1) KB(N)=KK-1
      IF (N.NE.1) KE(N-1)=KK-1
      KK=KK+1
920   CONTINUE
C
C         ARRANGE NEW SEGMENTS
C
      IPT=-1
      DO 990 N=1,NFUS
      II=0
      K1=KB(N)
      K2=KE(N)
      NI=K2-K1+1
      IF (XBEG(N).EQ.XIP(K1).AND.XEND(N).EQ.XIP(K2).AND.NI.LE.N30)
     1  GO TO 924
      IF (XBEG(N).NE.XIP(K1).AND.XEND(N).NE.XIP(K2).AND.NI.LE.N28)
     1  GO TO 930
      IF (XBEG(N).EQ.XIP(K1).AND.XEND(N).NE.XIP(K2).AND.NI.LE.N29)
     1  GO TO 940
      IF (XBEG(N).NE.XIP(K1).AND.XEND(N).EQ.XIP(K2).AND.NI.LE.N29)
     1  GO TO 950
        GO TO 960
924   CONTINUE
      K3=K1-1
      DO 925 I=1,NI
      KK=K3+I
      FOPX(I,N)=XIP(KK)
      FOPZ(I,N)=ZIP(KK)
      FOPS(I,N)=SOPT2(KK)
925   CONTINUE
      NFORX(N)=NI
      NRADX(N)=N17
      GO TO 990
930   CONTINUE
      FOPX(1,N)=XBEG(N)
      FOPZ(1,N)=TERP(XIP(K1),XBEG(N),XIP(K1+1),ZIP(K1),ZIP(K1+1))
      CALL IUNI(101,NN,XIP,1,SOPT2,1,XBEG(N),FOPS(1,N),
     1IPT,IERR)
      FOPX(NI+2,N)=XEND(N)
      FOPZ(NI+2,N)=TERP(XIP(K2-1),XEND(N),XIP(K2),ZIP(K2-1),ZIP(K2))
      CALL IUNI(101,NN,XIP,1,SOPT2,1,XEND(N),FOPS(NI+2,N),
     1IPT,IERR)
      K3=K1-1
      DO 935 I=1,NI
      KK=K3+I
      FOPX(I+1,N)=XIP(KK)
      FOPZ(I+1,N)=ZIP(KK)
      FOPS(I+1,N)=SOPT2(KK)
935   CONTINUE
      NFORX(N)=NI+2
      NRADX(N)=N17
      GO TO 990
940   CONTINUE
      FOPX(NI+1,N)=XEND(N)
      FOPZ(NI+1,N)=TERP(XIP(K2-1),XEND(N),XIP(K2),ZIP(K2-1),ZIP(K2))
      CALL IUNI(101,NN,XIP,1,SOPT2,1,XEND(N),FOPS(NI+1,N),
     1IPT,IERR)
      K3=K1-1
      DO 945 I=1,NI
      KK=K3+I
      FOPX(I,N)=XIP(KK)
      FOPZ(I,N)=ZIP(KK)
      FOPS(I,N)=SOPT2(KK)
945   CONTINUE
      NFORX(N)=NI+1
      NRADX(N)=N17
      GO TO 990
950   CONTINUE
      FOPX(1,N)=XBEG(N)
      FOPZ(1,N)=TERP(XIP(K1),XBEG(N),XIP(K1+1),ZIP(K1),ZIP(K1+1))
      CALL IUNI(101,NN,XIP,1,SOPT2,1,XBEG(N),FOPS(1,N),
     1IPT,IERR)
      K3=K1-1
      DO 955 I=1,NI
      KK=K3+I
      FOPX(I+1,N)=XIP(KK)
      FOPZ(I+1,N)=ZIP(KK)
      FOPS(I+1,N)=SOPT2(KK)
955   CONTINUE
      NFORX(N)=NI+1
      NRADX(N)=N17
      GO TO 990
C
C         MORE THAN 30 POINTS
C
960   DDX=(XEND(N)-XBEG(N))/N29
      K1=KB(N)
      K2=KE(N)
      KK=K2-K1+1
      DO 965 I=1,N30
      E=I-1
      FOPX(I,N)=XBEG(N)+E*DDX
      CALL IUNI (101,KK,XIP(K1),1,ZIP(K1),1,FOPX(I,N),FOPZ(I,N),IPT,
     1 IERR)
      CALL IUNI (101,NN,XIP,1,SOPT2,1,FOPX(I,N),FOPS(I,N),IPT,
     1 IERR)
965   CONTINUE
      NFORX(N)=N30
      NRADX(N)=N17
990   CONTINUE
      N=NFORX(NFUS)
      FOPS(N,NFUS)=SOPT2(NN)
      WRITE(2,190) ABC,NCASE,ICY,XMACH,NX,NTHETA
!!!992   FORMAT('1',20A4//34X,'CASE NO. ',A4/
!!!     119X,'MACH = ',F6.3,6X,'NX =',I3,6X,'NTHETA =',I3)
!!!      WRITE(2,994) ICY
!!!994   FORMAT (//35X,'CYCLE ',I3//)
      WRITE(2,996)
996   FORMAT  (//28X,'BODY AREAS FOR NEXT CYCLE'//)
      NSAVE=0
      DO 1000 I=1,NFUS
      K=NFORX(I)
      
      WRITE(2,998) I
998   FORMAT (//23X,'BODY SEGMENT', I2//17X,'X',11X,'Z',11X,'R',11X,'S')
      
      WRITE(2,'(10X,4F12.4)') (FOPX(L,I),
     &   FOPZ(L,I), SQRT(FOPS(L,I)/3.14159),FOPS(L,I),L=1,K)

      DO 2002 L=1,K
      SAVEX(NSAVE+L,ICSUB)=FOPX(L,I)
      SAVES(NSAVE+L,ICSUB)=FOPS(L,I)
 2002 CONTINUE
      NSAVE=NSAVE+K
1000  CONTINUE
      IF( (KSTOP.EQ.1) .OR. (ICY.EQ.ICYC) ) WRITE(12)
     1 NSAVE,(SAVEX(NNSAVE,ICSUB),SAVES(NNSAVE,ICSUB),NNSAVE=1,NSAVE)
625   CONTINUE
C     IF (IPLOT.LT.0)CALL PLOTS(NN,XIP,SBARP,SOPT2,THET,
C    1DRAGTH,LL,DRAG)
C     IF (IPLOT.GT.0.AND.ICY.EQ.ICYC)CALL PLOTS(NN,XIP,SBARP,
C    1SOPT2,THET,DRAGTH,LL,DRAG)
!
      WRITE(*,*) 'Leaving OVL60 (OUT)'
      WRITE(2,*) 'Leaving OVL60 (OUT)'
      END   ! ---------------------------- End of Subroutine OVL60 (OUT)
*+
      SUBROUTINE EMLORD (ELL,SN,SB,NN,XX,SS,DRAG,R,K)
*   --------------------------------------------------------------------
*     PURPOSE - Compute drag of a slender body of revolution
*
*     NOTES-
*
 !!!   IMPLICIT NONE
*
*      EXTERNAL
************************************************************************
*     A R G U M E N T S                                                *
************************************************************************
      REAL ELL     ! length of the body                               IN
      REAL SN      ! nose area                                        IN
      REAL SB      ! base area                                        IN
      INTEGER NN   ! number of INTERIOR points where area is defined  IN
      REAL XX(*)   ! interior points (non-dimensional)                IN
      REAL SS(*)   ! corresponding areas                              IN
      REAL DRAG    ! drag/q                                          OUT
      REAL R(*)    ! used for something ??                           OUT
      INTEGER K    ! K=1, normal mode, compute matrix                 IN
!                    K=2, read matrix from unit 10
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
      REAL PI
      PARAMETER(PI=3.14159265)
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
      REAL E,E1,E2
      INTEGER M,N
      REAL X
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
      DIMENSION IPI(33),PQ(33,33),IND(33,2),C(99),Q(99),PQQ(99)
*-----------------------------------------------------------------------
      DRAG=0.0
      IF (K.GT.1) GO TO 50
      DO 30 N=1,NN
      X=XX(N)
      Q(N)=(ACOS(1.0-2.0*X)-(2.0-4.0*X)*SQRT(X-X**2))/PI
      DO 15 M=N,NN
      Y=XX(M)
      E=(X-Y)**2
      E1=X+Y-2.0*X*Y
      E2=2.0*SQRT(X*Y*(1.0-X)*(1.0-Y))
      IF (E) 5,10,5
5     PQ(M,N)=0.5*E*ALOG((E1-E2)/(E1+E2))+E1*E2
      GO TO 15
10    PQ(M,N)=E1*E2
15    CONTINUE
      NK=N-1
      IF (NK) 30,30,20
20    DO 25 M=1,NK
      E=PQ(N,M)
25    PQ(M,N)=E
30    CONTINUE
      CALL MATINV (33,NN,PQ,0,B,1,DET,IKK,IPI,IND)
      DO 35 N=1,NN
35    C(N)=SS(N)-SN-(SB-SN)*Q(N)
      DO 45 M=1,NN
      SUM=0.0
      DO 40 N=1,NN
40    SUM=SUM+PQ(M,N)*C(N)
45    R(M)=SUM
      GO TO 70
50    REWIND 10
      READ(10) (Q(I),I=1,NN)
      DO 55 N=1,NN
55    C(N)=SS(N)-SN-(SB-SN)*Q(N)
      DO 65 M=1,NN
      READ(10) (PQQ(I),I=1,NN)
      SUM=0.0
      DO 60 N=1,NN
60    SUM=SUM+PQQ(N)*C(N)
65    R(M)=SUM
70    SUM=0.0
      DO 75 M=1,NN
75    SUM=SUM+R(M)*C(M)
      DRAG=(4.0*(SB-SN)**2/PI+SUM*PI)/ELL**2
      END   ! --------------------------------- End of Subroutine EMLORD
*+
      INTEGER FUNCTION INLAP(A,B,C,D,P,P1,P2)
*   --------------------------------------------------------------------
*     PURPOSE - Find the point P where the line segment (P1,P2) cuts the
!        plane  Ax+By+Cz=D
*
*     NOTES- notice that P is modified in INLAP
*        This routine is called many,many,many times
!     RETURN VALUE FROM INLAP
C              =1---NORMAL RETURN. POINT COORDS. STORED IN P-ARRAY
C              =2---LINE LIES IN PLANE
C              =3---LINE IS PARALLEL TO PLANE
*
      IMPLICIT NONE
*
*      EXTERNAL
************************************************************************
*     A R G U M E N T S                                                *
************************************************************************
      REAL A            ! plane coefficient                           IN
      REAL B            ! plane coefficient                           IN
      REAL C            ! plane coefficient                           IN
      REAL D            ! plane coefficient                           IN
      REAL P(3)         ! (x,y,z) of the intersection                OUT
      REAL P1(3),P2(3)  ! endpoints of the line segment               IN
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
      REAL EPS
      PARAMETER (EPS=1.0E-6)
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
      REAL DX,DY,DZ
      REAL E1,E2,E3
      INTEGER I,L,MMM
      REAL T
*-----------------------------------------------------------------------
C
      L=1
      E1=A*P1(1)+B*P1(2)+C*P1(3)-D
      IF (ABS(E1)-EPS) 5,5,10
5     L=2
10    E2=A*P2(1)+B*P2(2)+C*P2(3)-D
      IF (ABS(E2)-EPS) 15,15,35
15    GO TO (20,30), L
20    DO 25 I=1,3
25    P(I)=P2(I)
      MMM=1
      GO TO 65
30    MMM=2
      GO TO 65
35    GO TO (50,40), L
40    DO 45 I=1,3
45    P(I)=P1(I)
      MMM=1
      GO TO 65
50    DX=P2(1)-P1(1)
      DY=P2(2)-P1(2)
      DZ=P2(3)-P1(3)
      E3=A*DX+B*DY+C*DZ
      IF (ABS(E3)-EPS) 55,55,60
55    MMM=3
      GO TO 65
60    T=-E1/E3
      P(1)=P1(1)+T*DX
      P(2)=P1(2)+T*DY
      P(3)=P1(3)+T*DZ
      MMM=1
65    INLAP=MMM
      END   ! ------------------------------------ End of Function INLAP
*+
      SUBROUTINE PANEL(N,XCUT,M,S,BCOS,BSIN,P)
*   --------------------------------------------------------------------
*     PURPOSE - PROJECTED AREA OF A WING PANEL
*
*     NOTES-
*
      IMPLICIT NONE
************************************************************************
*     A R G U M E N T S                                                *
************************************************************************
      INTEGER N                 !                                     IN
      REAL XCUT(101)            !                                     IN
      INTEGER M                 !                                     IN
      REAL S(101,5)   ! area distribution of 5 components         IN/OUT
      REAL BCOS,BSIN            !                                     IN
      REAL P(4,4)               !                                     IN
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
      INTEGER I,J,I1,I2,J1,J2,J3,K
      REAL X
      REAL XA,XB
      REAL XMIN,XMAX
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
      REAL PI(3,2), XP(4)
*-----------------------------------------------------------------------
!
      DO 20 I=1,4
20    XP(I)=P(I,1)+BCOS*P(I,2)+BSIN*P(I,3)
C
      XMIN = MIN(XP(1),XP(2))
      XMAX = MAX(XP(3),XP(4))
C
      DO 200 I=1,N
      X=XCUT(I)
C
      IF(X.LE.XMIN.OR.X.GE.XMAX) GO TO 200
C
      J=0
      DO 100 K=1,4
      GO TO (30,40,50,60), K
C
30    J1=1
      J2=2
      GO TO 70
40    J1=1
      J2=3
      GO TO 70
50    J1=2
      J2=4
      GO TO 70
60    J1=3
      J2=4
70    XA=MIN(XP(J1),XP(J2))
      XB=MAX(XP(J1),XP(J2))
      IF(XA.EQ.XP(J1)) GO TO 72
      J3=J1
      J1=J2
      J2=J3
72    CONTINUE
      IF(X.EQ.XB.AND.X.EQ.XA) GO TO 75
      IF(X.GT.XB.OR.X.LE.XA)  GO TO 100
75    J=J+1
      DO 80 I1=1,3
      I2 = I1+1
      PI(I1,J)=P(J1,I2)
80    IF(XB.NE.XA) PI(I1,J)=P(J1,I2)+(P(J2,I2)-P(J1,I2))*(X-XA)/(XB-XA)
      IF(J.GT.2) WRITE(2,90) J
90    FORMAT(I10, 5X, 'ERROR OCCURED IN SUBR. PANEL'//)
C
100   CONTINUE
C
      S(I,M)=0.5*(PI(3,1)+PI(3,2))*SQRT((PI(1,1)-PI(1,2))**2+
     &    (PI(2,1)-PI(2,2))**2)+S(I,M)
200   CONTINUE
      END   ! ---------------------------------- End of Subroutine PANEL
*+
      SUBROUTINE SPOD(BETA,THETA,NX,XCUT,N,M,X,R,XZERO,YZERO,ZZERO,MS,S)
*   --------------------------------------------------------------------
*     PURPOSE - PROJECTED AREA FOR CIRCULAR BODY
*
*     NOTES-
*
 !!!   IMPLICIT NONE
*
*      EXTERNAL
************************************************************************
*     A R G U M E N T S                                                *
************************************************************************
      REAL BETA    ! compressibility factor                           IN
      REAL THETA    ! angle (radians)                                 IN
      INTEGER NX            ! # of cutting stations                   IN
      REAL XCUT(101)           !                                      IN
      INTEGER N                !                                      IN
      INTEGER M                !                                      IN
      REAL X(101)              !                                      IN
      REAL R(101)              !                                      IN
      REAL XZERO,YZERO,ZZERO   !                                      IN
      INTEGER MS         ! column to put it in                        IN
      REAL S(101,5)     !                                            OUT
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
      REAL PI,EPS
      PARAMETER (PI=3.14159265, EPS=0.00001)
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
      REAL BC,BS
      INTEGER I,K
      REAL RHO   !
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
*-----------------------------------------------------------------------
C
      BC=BETA*COS(THETA)
      BS=BETA*SIN(THETA)
      XM=M
C
      DO 200 I=1,M
      K=0
      XI=I
      PHI=2.0*PI*XI/XM
!!!      DPHI=180.0*PHI/PI          ! never referenced
      T=BETA*COS(THETA-PHI)
      DO 150 IX=1,NX
      EX=XCUT(IX)
      A=EX+YZERO*BC+ZZERO*BS-XZERO
      IF (ABS(T)-EPS) 5,45,45
5     IF (A-X(1)) 10,10,15
10    RHO=R(1)
      GO TO 70
15    IF (A-X(N)) 25,20,20
20    RHO=R(N)
      GO TO 70
25    K= K+1
      IF (K.LT.2) K=2
      IF (A-X(K)) 40,35,30
30    IF (K.LT.N) GO TO 25
C
35    RHO=R(K)
      GO TO 70
40    RHO=R(K-1)+(R(K)-R(K-1))/(X(K)-X(K-1))*(A-X(K-1))
      GO TO 70
45    E=1.0/T
46    K=K+1
      XX=X(K)-T*R(K)
C
      IF (A-XX) 50,50,65
50    IF (K-1) 55,55,60
55    RHO=R(1)
      GO TO 70
60    D=(R(K)-R(K-1))/(X(K)-X(K-1))
      B1=R(K-1)-D*X(K-1)
      B2=-A*E
      RHO=(B2*D-B1*E)/(D-E)
      GO TO 70
65    IF(K.LT.N) GO TO 46
      RHO=R(N)
70    CONTINUE
100   B=1.0+AMOD(XI,2.0)
105   S(IX,MS)=S(IX,MS)+B*RHO**2*(2.0*PI)/(3.*XM)
      K=K-1
150   CONTINUE
200   CONTINUE
      END   ! ----------------------------------- End of Subroutine SPOD
*+
      SUBROUTINE SPOD2(A,B,C,NX,XCUT,N,NANG,XI,ZI,RI,XAFUS,ARNO,XBFUS,
     & ARBA,XZERO,YZERO,ZZERO,MS,S)
*   --------------------------------------------------------------------
*     PURPOSE - PROJECTED AREA FOR CAMBERED CIRCULAR BODY
*
*     NOTES-
*
 !!!   IMPLICIT NONE
************************************************************************
*     A R G U M E N T S                                                *
************************************************************************
      REAL A,B,C
      INTEGER NX
      REAL XCUT(101)
      INTEGER N
      INTEGER NANG
      REAL XI(101),ZI(101),RI(101)
      REAL XAFUS
      REAL ARNO
      REAL XBFUS
      REAL ARBA
      REAL XZERO,YZERO,ZZERO
      INTEGER MS
      REAL S(101,5)
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
      REAL PI2,EPS
      PARAMETER(PI2=6.2831853,EPS=0.000001)
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
      INTEGER I,K,M
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
      REAL P(3),P1(3),P2(3),P11(3),P22(3),SSS(101,5)
      REAL YCL(101),ZCL(101),RHO(101)
*-----------------------------------------------------------------------
      M=NANG
      XM=M
C
      DO 1 I=1,101
1     SSS(I,MS)=0.
      K=0
      DO 11 IX=1,NX
      EX=XCUT(IX)
      D=EX-YZERO*B-ZZERO*C-XZERO
4     K=K+1
      IF(K.GT.N) GO TO 9
      IF (K.LT.2) K=2
      IF (D-(XI(K)+ZI(K)*C)) 6,6,5
5     IF (K.LT.N) GO TO 4
6     CONTINUE
      P11(1)=XI(K-1)
      P11(2)=0.
      P11(3)=ZI(K-1)
      P22(1)=XI(K)
      P22(2)=0.
      P22(3)=ZI(K)
      D11=D-P11(1)-P11(3)*C
      IF (D11.LE.EPS) GO TO 7
      D22=D-P22(1)-P22(3)*C
      IF (-D22.LE.EPS) GO TO 8
      MI=INLAP(A,B,C,D,P,P11,P22)
      IF (MI.NE.1) WRITE(*,*) 'Return from INLAP of',mi, ' in SPOD2'

      YCL(IX)=P(2)
      ZCL(IX)=P(3)
      GO TO 10
7     YCL(IX)=P11(2)
      ZCL(IX)=P11(3)
      GO TO  10
8     CONTINUE
      YCL(IX)=P22(2)
      ZCL(IX)=P22(3)
      GO TO 10
9     CONTINUE
      YCL(IX)=0.
      ZCL(IX)=ZI(NX)
C
10    CONTINUE
      K=K-1
  11  CONTINUE
C
      DO 100 J=1,M
      K=0
      FJ=J
      PHI=(PI2*FJ)/XM
      CPHI=COS(PHI)
      SPHI=SIN(PHI)
      DO 80 IX=1,NX
      EX=XCUT(IX)
      IF (EX.GT.XAFUS) GO TO 12
      SSS(IX,MS)=ARNO/XM
      GO TO 55
12    IF (EX.LT.XBFUS) GO TO 13
      SSS(IX,MS)=ARBA/XM
      GO TO 55
13    CONTINUE
      D=EX-YZERO*B-ZZERO*C-XZERO
14    K=K+1
      IF(K.GT.N) GO TO 25
      IF (K.LT.2) K=2
      IF (D-(XI(K)+RI(K)*CPHI*B+(RI(K)*SPHI+ZI(K))*C)) 16,16,15
15    IF(K.LT.N) GO TO 14
16    CONTINUE
      P1(1)=XI(K-1)
      P1(2)=RI(K-1)*CPHI
      P1(3)=RI(K-1)*SPHI+ZI(K-1)
      P2(1)=XI(K)
      P2(2)=RI(K)*CPHI
      P2(3)=RI(K)*SPHI+ZI(K)
      D1=D-P1(2)*B-P1(3)*C-P1(1)
      IF(D1.LE.EPS) GO TO 20
      D2=D-P2(2)*B-P2(3)*C-P2(1)
      IF (-D2.LE.EPS) GO TO 25
      MI=INLAP(A,B,C,D,P,P1,P2)
      IF (mi.NE.1) WRITE(*,*) 'Return from INLAP of', mi, ' in SPOD2'
      RHO(IX)=SQRT((P(2)-YCL(IX))**2+(P(3)-ZCL(IX))**2)
      GO TO 30
20    CONTINUE
      RHO(IX)=SQRT((P1(2)-YCL(IX))**2+(P1(3)-ZCL(IX))**2)
      GO TO 30
25    CONTINUE
      RHO(IX)=SQRT((P2(2)-YCL(IX))**2+(P2(3)-ZCL(IX))**2)
30    CONTINUE
50    CON=1.0+AMOD(FJ,2.)
51    SSS(IX,MS)=CON*RHO(IX)**2*PI2/(3.*XM)
      K=K-1
55    CONTINUE
      S(IX,MS)=S(IX,MS)+SSS(IX,MS)
80    CONTINUE
100   CONTINUE
      END   ! ---------------------------------- End of Subroutinw SPOD2
*+
      SUBROUTINE SPOD3(A,B,C,NX,XCUT,NANG,N,XI,SURF,XAFUS,ARNO,XBFUS,
     & ARBA,XZERO,YZERO,ZZERO,MS,S)
*   --------------------------------------------------------------------
*     PURPOSE - PROJECTED AREA FOR ARBITRARY BODY
*
*     NOTES-
*
 !!!   IMPLICIT NONE
************************************************************************
*     A R G U M E N T S                                                *
************************************************************************
      REAL A,B,C
      INTEGER NX
      REAL XCUT(101)
      INTEGER NANG
      INTEGER N
      REAL XI(30)
      REAL SURF(30,30,2)
      REAL XAFUS
      REAL ARNO
      REAL XBFUS
      REAL ARBA
      REAL XZERO,YZERO,ZZERO
      INTEGER MS
      REAL S(101,5)
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
      REAL EPS
      PARAMETER (EPS=0.000001)
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
      REAL
     1 P(3),P1(3),P2(3),PSAV(2,101,2),PPP(101,3),YY2(101),ZZ2(101),
     2 YY3(101),ZZ3(101),SSS(101,5)
*-----------------------------------------------------------------------
!!!      DATA YCL/0./,ZCL/0./   leftover from something
      M=NANG
      XM=M
      DO 1 I=1,101
1     SSS(I,MS)=0.
      DO 100 I=1,2
      E=(-1.)**I
      DO 100 J=1,NANG
      K=0
10    DO 80 NN =1,NX
      DD=XCUT(NN)
      IF (DD.GT.XAFUS) GO TO 2
      SSS(NN,MS)=ARNO/(2.*XM)
      GO TO 70
2     IF (DD.LT.XBFUS) GO TO 3
      SSS(NN,MS)=ARBA/(2.*XM)
      GO TO 70
3     CONTINUE
      D=DD-YZERO*B-ZZERO*C-XZERO
12    K=K+1
      IF(K.GT.N.AND.J.GE.2) GO TO 50
      IF(K.GT.N) GO TO 25
      IF (K.LT.2) K=2
      IF (D-(XI(K)+SURF(J,K,2)*C+SURF(J,K,1)*B*E)) 14,14,13
13    IF (K.LT.N) GO TO 12
14    CONTINUE
      P1(1)=XI(K-1)
      P1(2)=SURF(J,K-1,1)*E
      P1(3)=SURF(J,K-1,2)
      P2(1)=XI(K)
      P2(2)=SURF(J,K,1)*E
      P2(3)=SURF(J,K,2)
      IF(J.GE.2) GO TO 40
      D1=D-P1(2)*B-P1(3)*C-P1(1)
      IF (D1.LE.EPS) GO TO 20
      D2=D-P2(2)*B-P2(3)*C-P2(1)
      IF (-D2.LE.EPS) GO TO 25
      MI=INLAP(A,B,C,D,P,P1,P2)
      PSAV(I,NN,1)=P(2)
      PSAV(I,NN,2)=P(3)
      GO TO 30
20    CONTINUE
      PSAV(I,NN,1)=P1(2)
      PSAV(I,NN,2)=P1(3)
      GO TO 30
25    CONTINUE
      PSAV(I,NN,1)=P2(2)
      PSAV(I,NN,2)=P2(3)
30    CONTINUE
      GO TO 75
40    D1=D-P1(2)*B-P1(3)*C-P1(1)
      IF (D1.LE.EPS) GO TO 45
      D2=D-P2(2)*B-P2(3)*C-P2(1)
      IF (-D2.LE.EPS) GO TO 50
      MI=INLAP (A,B,C,D,P,P1,P2)
      IF (mi.NE.1) WRITE(*,*) 'Return from INLAP of', mi, ' in SPOD3'
      PPP(NN,2)=P(2)
      PPP(NN,3)=P(3)
      GO TO 55
45    PPP(NN,2)=P1(2)
      PPP(NN,3)=P1(3)
      GO TO 55
50    PPP(NN,2)=P2(2)
      PPP(NN,3)=P2(3)
55    CONTINUE
      YY2(NN)=PSAV(I,NN,1)*E
      ZZ2(NN)=PSAV(I,NN,2)
      YY3(NN)=PPP(NN,2)*E
      ZZ3(NN)=PPP(NN,3)
      SSS(NN,MS)=.5*(YY2(NN)*ZZ3(NN)-YY3(NN)*ZZ2(NN))
65    CONTINUE
      PSAV(I,NN,1)=PPP(NN,2)
      PSAV(I,NN,2)=PPP(NN,3)
70    CONTINUE
      S(NN,MS)=S(NN,MS)+SSS(NN,MS)
75    CONTINUE
      K=K-1
80    CONTINUE
90    CONTINUE
100   CONTINUE
      END   ! ---------------------------------- End of Subroutine SPOD3
!
*+
      SUBROUTINE IUNI(NMAX,N,X,NTAB,Y,IORDER,X0,Y0,IPT,IERR)
*   --------------------------------------------------------------------
*     PURPOSE - SUBROUTINE IUNI USES FIRST OR SECOND ORDER LAGRANGIAN
*        INTERPOLATION TO ESTIMATE THE VALUES OF A SET OF A SET OF
*        FUNCTIONS AT A POINT X0.  IUNI USES ONE INDEPENDENT VARIABLE
*        TABLE AND A DEPENDENT VARIABLE TABLE FOR EACH FUNCTION TO BE
*        EVALUATED.   THE ROUTINE ACCEPTS THE INDEPENDENT VARIABLES
*        SPACED AT EQUAL OR UNEQUAL INTERVALS.  EACH DEPENDENT VARIABLE
*        TABLE MUST CONTAIN FUNCTION VALUES CORRESPONDING TO EACH X(I)
*        IN THE INDEPENDENT VARIABLE TABLE.  THE ESTIMATED VALUES ARE
*        RETURNED IN THE Y0 ARRAY WITH THE N-TH VALUE OF THE ARRAY
*        HOLDING THE VALUE OF THE N-TH FUNCTION VALUE EVALUATED AT X0.
*
*     AUTHORS - CMPB ROUTINE MTLUP MODIFIED BY COMPUTER SCIENCES CORPORATION
!               Ralph L. Carmichael, Public Domain Aeronautical Software
*
*     REVISION HISTORY
*   DATE  VERS PERSON  STATEMENT OF CHANGES
*  1Aug73  1.0   CSC   Original release; included in D2500 release
!  9Nov94  1.1   RLC   Added IMPLICIT NONE; declared variables
*
*     NOTES-
*
      IMPLICIT NONE
************************************************************************
*     A R G U M E N T S                                                *
************************************************************************
      INTEGER NMAX   ! the first dimension of the Y matrix
      INTEGER N      ! THE NUMBER OF POINTS IN THE INDEPENDENT ARRAY
                     !  N .LE. NMAX
C*
      REAL X(*)      ! A ONE-DIMENSIONAL ARRAY WHICH CONTAINS THE
*                      INDEPENDENT VARIABLES.
*                      THESE VALUES MUST BE STRICTLY MONOTONIC.
*
      INTEGER NTAB   ! THE NUMBER OF DEPENDENT VARIABLE TABLES
*
      REAL Y(NMAX,*) ! A TWO-DIMENSIONAL ARRAY DIMENSIONED (NMAX,NTAB) IN
C*                THE CALLING PROGRAM.  EACH COLUMN OF THE ARRAY
C*                CONTAINS A DEPENDENT VARIABLE TABLE
C*
      INTEGER IORDER !   INTERPOLATION PARAMETER SUPPLIED BY THE USER.
C*
C*                =0  ZERO ORDER INTERPOLATION: THE FIRST FUNCTION
C*                    VALUE IN EACH DEPENDENT VARIABLE TABLE IS
C*                    ASSIGNED TO THE CORRESPONDING MEMBER OF THE Y0
C*                    ARRAY.  THE FUNCTIONAL VALUE IS ESTIMATED TO
C*                    REMAIN CONSTANT AND EQUAL TO THE NEAREST KNOWN
C*                    FUNCTION VALUE.
C*
      REAL X0  !  THE INPUT POINT AT WHICH INTERPOLATION WILL BE
C*                PERFORMED.
C*
      REAL Y0(*)  !    A ONE-DIMENSIONAL ARRAY DIMENSIONED (NTAB) IN THE
C*                CALLING PEOGRAM.  UPON RETURN THE ARRAY CONTAINS THE
C*                ESTIMATED VALUE OF EACH FUNCTION AT X0.
C*
      INTEGER IPT !   ON THE FIRST CALL IPT MUST BE INITIALIZED TO -1 SO
C*                THAT MONOTONICITY WILL BE CHECKED. UPON LEAVING THE
C*                ROUTINE IPT EQUALS THE VALUE OF THE INDEX OF THE X
C*                VALUE PRECEDING X0 UNLESS EXTRAPOLATION WAS
C*                PERFORMED.  IN THAT CASE THE VALUE OF IPT IS
C*                RETURNED AS:
C*                =0  DENOTES X0 .LT. X(1) IF THE X ARRAY IS IN
C*                    INCREASING ORDER AND X(1) .GT. X0 IF THE X ARRAY
C*                    IS IN DECREASING ORDER.
C*                =N  DENOTES X0 .GT. X(N) IF THE X ARRAY IS IN
C*                    INCREASING ORDER AND X0 .LT. X(N) IF THE X ARRAY
C*                    IS IN DECREASING ORDER.
C*
C*                ON SUBSEQUENT CALLS, IPT IS USED AS A POINTER TO
C*                BEGIN THE SEARCH FOR X0.
C*
      INTEGER IERR  !  ERROR PARAMETER GENERATED BY THE ROUTINE
C*                =0  NORMAL RETURN
C*                =J  THE J-TH ELEMENT OF THE X ARRAY IS OUT OF ORDER
C*                =-1 ZERO ORDER INTERPOLATION PERFORMED BECAUSE
C*                    IORDER =0.
C*                =-2 ZERO ORDER INTERPOLATION PERFORMED BECAUSE ONLY
C*                    ONE POINT WAS IN X ARRAY.
C*                =-3 NO INTERPOLATION WAS PERFORMED BECAUSE
C*                    INSUFFICIENT POINTS WERE SUPPLIED FOR SECOND
C*                    ORDER INTERPOLATION.
C*                =-4 EXTRAPOLATION WAS PERFORMED
C*
C*                UPON RETURN THE PARAMETER IERR SHOULD BE TESTED IN
C*                THE CALLING PROGRAM.
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
      INTEGER IN,J,L,NM1,NT
      REAL DELX
      REAL P
      REAL V1,V2,V3
      REAL YY1,YY2
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
*-----------------------------------------------------------------------
      NM1=N-1
      IERR=0
      J=1
      DELX=X(2)-X(1)
C
C              TEST FOR ZERO ORDER INTERPOLATION
C
      IF (IORDER .EQ. 0) GO TO 10
      IF (N.LT. 2) GO TO 20
      GO TO 50
  10  IERR=-1
      GO TO 30
  20  IERR=-2
  30  DO 40 NT=1,NTAB
         Y0(NT)=Y(1,NT)
  40     CONTINUE
      RETURN
  50  IF (IPT .GT. -1) GO TO 65
C
C             CHECK FOR TABLE OF NODE POINTS BEING STRICTLY MONOTONIC
C             THE SIGN OF DELX SIGNIFIES WHETHER TABLE IS IN
C             INCREASING OR DECREASING ORDER.
C
      IF (DELX .EQ. 0) GO TO 190
      IF (N .EQ. 2) GO TO 65
C
C             CHECK FOR SIGN CONSISTENCY IN THE DIFFERENCES OF
C             SUBSEQUENT PAIRS
C
      DO 60 J=2,NM1
         IF (DELX * (X(J+1)-X(J))) 190,190,60
  60     CONTINUE
C
C             IPT IS INITIALIZED TO BE WITHIN THE INTERVAL
C
  65  IF (IPT .LT. 1) IPT=1
      IF (IPT .GT. NM1) IPT=NM1
      IN= SIGN (1.0,DELX *( X0-X(IPT)))
  70  P= X(IPT) - X0
      IF (P* (X(IPT +1)- X0)) 90,180,80
  80  IPT =IPT +IN
C
C             TEST TO SEE IF IT IS NECCESARY TO EXTRAPOLATE
C
      IF (IPT.GT.0 .AND. IPT .LT. N) GO TO 70
      IERR=-4
      IPT=IPT- IN
C
C             TEST FOR ORDER OF INTERPOLATION
C
C
  90  IF (IORDER .GT. 1) GO TO 120
C
C             FIRST ORDER INTERPOLATION
C
      DO 100 NT=1,NTAB
          Y0(NT)=Y(IPT,NT)+((Y(IPT+1,NT)- Y(IPT,NT))*(X0-X(IPT)))/
     1           (X(IPT+1)-X(IPT))
 100     CONTINUE
      IF (IERR .EQ. -4) IPT=IPT+IN
      RETURN
C
C             SECOND ORDER INTERPOLATION
C
 120  IF (N .EQ. 2) GO TO 200
C
C             CHOOSING A THIRD POINT SO AS TO MINIMIZE THE DISTANCE
C             BETWEEN THE THREE POINTS USED TO INTERPOLATE
C
      IF (IPT .EQ. NM1) GO TO  140
      IF (IPT .EQ. 1) GO TO 130
      IF (DELX *(X0-X(IPT-1)).LT.DELX* (X(IPT+2)-X0)) GO TO 140
 130  L=IPT
      GO TO 150
 140  L=IPT -1
 150  V1=X(L)-X0
      V2=X(L+1)-X0
      V3=X(L+2)-X0
      DO 160 NT=1,NTAB
         YY1=(Y(L,NT) * V2 - Y(L+1,NT) * V1)/(X(L+1) - X(L))
         YY2=(Y(L+1,NT)*V3-Y(L+2,NT) *V2)/(X(L+2)-X(L+1))
         Y0(NT)=(YY1*V3 -YY2*V1)/(X(L+2)-X(L))
 160     CONTINUE
*
      IF (IERR .EQ. -4) IPT=IPT + IN
      RETURN
 180  IF(P .NE. 0) IPT=IPT +1
      DO 185 NT=1,NTAB
         Y0(NT)=Y(IPT,NT)
 185     CONTINUE
      RETURN
C
C             IERR IS SET TO THE SUBSCRIPT OF THE MEMBER OF THE TABLE
C             WHICH IS OUT OF ORDER
C
 190  IERR=J +1
      RETURN
 200  IERR=-3
      RETURN
      END ! ------------------------------------- End of subroutine IUNI
*+
      SUBROUTINE MATINV(MAX,N,A,M,B,IOP,DETERM,ISCALE,IPIVOT,IWK)
*   --------------------------------------------------------------------
*     PURPOSE - INVERT A REAL SQUARE MATRIX A. IN ADDITION THE ROUTINE
*        SOLVES THE MATRIX EQUATION AX=B,WHERE B IS A MATRIX OF CONSTANT
*        VECTORS. THERE IS ALSO AN OPTION TO HAVE THE DETERMINANT
*        EVALUATED. IF THE INVERSE IS NOT NEEDED, USE GELIM TO SOLVE A
*        SYSTEM OF SIMULTANEOUS EQUATIONS AND DETFAC TO EVALUATE A
*        DETERMINANT FOR SAVING TIME AND STORAGE.
*
*     AUTHORS - COMPUTER SCIECES CORPORATION, HAMPTON, VA
*               Ralph L. Carmichael, Public Domain Aeronautical Software
*
*     REVISION HISTORY
*   DATE  VERS PERSON  STATEMENT OF CHANGES
*  July73  0.1   CSC   Original release
* 29Jul81  1.0?  CSC   Latest release (in release of D2500)
*  9Nov94  1.1   RLC   IMPLICIT NONE; declared variables
*
*     REFERENCE: FOX,L, AN INTRODUCTION TO NUMERICAL LINEAR ALGEBRA
*
      IMPLICIT NONE
*
*      EXTERNAL
************************************************************************
*     A R G U M E N T S                                                *
************************************************************************
      INTEGER MAX !  THE MAXIMUM ORDER OF A AS STATED IN THE
C                       DIMENSION STATEMENT OF THE CALLING PROGRAM.
C
      INTEGER N   ! - THE ORDER OF A, 1.LE.N.LE.MAX.
C
      REAL A(MAX,*) !    - A TWO-DIMENSIONAL ARRAY OF THE COEFFICIENTS.
C                       ON RETURN TO THE CALLING PROGRAM, A INVERSE
C                       IS STORED IN A.
C                       A MUST BE DIMENSIONED IN THE CALLING PROGRAM
C                       WITH FIRST DIMENSION MAX AND SECOND DIMENSION
C                       AT LEAST N.
C
      INTEGER M    ! - THE NUMBER OF COLUMN VECTORS IN B.
C                       M=0 SIGNALS THAT THE SUBROUTINE IS
C                       USED SOLELY FOR INVERSION,HOWEVER,
C                       IN THE CALL STATEMENT AN ENTRY CORRE-
C                       SPONDING TO B MUST BE PRESENT.
C
      REAL B(MAX,*) !   - A TWO-DIMENSIONAL ARRAY OF THE CONSTANT
C                       VECTOR B. ON RETURN TO CALLING PROGRAM,
C                       X IS STORED IN B. B SHOULD HAVE ITS FIRST
C                       DIMENSION MAX AND ITS SECOND AT LEAST M.
C
      INTEGER IOP  ! - COMPUTE DETERMINANT OPTION.
C                        IOP=0 COMPUTES THE MATRIX INVERSE AND
C                              DETERMINANT.
C                        IOP=1 COMPUTES THE MATRIX INVERSE ONLY.
C
      REAL DETERM  ! - FOR IOP=0-IN CONJUNCTION WITH ISCALE
C                       REPRESENTS THE VALUE OF THE DETERMINANT
C                       OF A, DET(A),AS FOLLOWS.
C                        DET(A)=(DETERM)(10**100(ISCALE))
C                       THE COMPUTATION DET(A) SHOULD NOT BE
C                       ATTEMPTED IN THE USER PROGRAM SINCE IF
C                       THE ORDER OF A IS LARGER AND/OR THE
C                       MAGNITUDE OF ITS ELEMENTS ARE LARGE(SMALL),
C                       THE DET(A) CALCULATION MAY CAUSE OVERFLOW
C                     (UNDERFLOW). DETERM SET TO ZERO FOR
C                     SINGULAR MATRIX CONDITION, FOR EITHER
C                     I0P=1,OR 0. SHOULD BE CHECKED BY PROGRAMER
C                     ON RETURN TO MAIN PROGRAM.
C
      INTEGER ISCALE  ! - A SCALE FACTOR COMPUTED BY THE
C                       SUBROUTINE TO AVOID OVERFLOW OR
C                       UNDERFLOW IN THE COMPUTATION OF
C                       THE QUANTITY,DETERM.
C
      INTEGER IPIVOT(*)  !  - A ONE DIMENSIONAL INTEGER ARRAY
C                       USED BY THE SUBPROGRAM TO STORE
C                       PIVOTOL INFORMATION. IT SHOULD BE
C                       DIMENSIONED AT LEAST N. IN GENERAL
C                       THE USER DOES NOT NEED TO MAKE USE
C                       OF THIS ARRAY.
C
      INTEGER IWK(MAX,*) !  - A TWO-DIMENSIONAL INTEGER ARRAY OF
C                       TEMPORARY STORAGE USED BY THE ROUTINE.
C                       IWK SHOULD HAVE ITS FIRST DIMENSION
C                       MAX, AND ITS SECOND 2.
C
C     REQUIRED ROUTINES-
C
C     STORAGE          - 542 OCTAL LOCATIONS
C
C     LANGUAGE         -FORTRAN
C     LIBRARY FUNCTIONS -ABS
C
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
      REAL AMAX,T,SWAP
      INTEGER IROW,JROW, ICOLUM,JCOLUM
      EQUIVALENCE (IROW,JROW), (ICOLUM,JCOLUM), (AMAX, T, SWAP)

      INTEGER I,J,K,L,L1
      REAL R1,R2,TMAX
      REAL PIVOT,PIVOTI
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
*-----------------------------------------------------------------------
C
C     INITIALIZATION
C
      ISCALE=0
      R1=1E37   ! changed by RLC from 100
      R2=1.0/R1
      DETERM=1.0
      DO 20 J=1,N
        IPIVOT(J)=0
 20   CONTINUE
      DO 550 I=1,N
C
C       SEARCH FOR PIVOT ELEMENT
C
        AMAX=0.0
        DO 105 J=1,N
          IF (IPIVOT(J)-1) 60, 105, 60
   60     DO 100 K=1,N
            IF (IPIVOT(K)-1) 80, 100, 740
   80       TMAX = ABS(A(J,K))
            IF(AMAX-TMAX) 85,100,100
   85       IROW=J
            ICOLUM=K
            AMAX=TMAX
  100     CONTINUE
  105   CONTINUE
        IF (AMAX) 740,106,110
  106   DETERM=0.0
        ISCALE=0
        GO TO 740
  110   IPIVOT(ICOLUM) = 1
C
C       INTERCHANGE ROWS TO PUT PIVOT ELEMENT ON DIAGONAL
C
        IF (IROW-ICOLUM) 140, 260, 140
  140   DETERM=-DETERM
        DO 200 L=1,N
          SWAP=A(IROW,L)
          A(IROW,L)=A(ICOLUM,L)
          A(ICOLUM,L)=SWAP
 200    CONTINUE
        IF(M) 260, 260, 210
  210   DO 250 L=1, M
          SWAP=B(IROW,L)
          B(IROW,L)=B(ICOLUM,L)
          B(ICOLUM,L)=SWAP
 250    CONTINUE
  260   IWK(I,1)=IROW
        IWK(I,2)=ICOLUM
        PIVOT=A(ICOLUM,ICOLUM)
        IF(IOP) 740,1000,321
C
C       SCALE THE DETERMINANT
C
 1000   PIVOTI=PIVOT
        IF(ABS(DETERM)-R1)1030,1010,1010
 1010   DETERM=DETERM/R1
        ISCALE=ISCALE+1
        IF(ABS(DETERM)-R1)1060,1020,1020
 1020   DETERM=DETERM/R1
        ISCALE=ISCALE+1
        GO TO 1060
 1030   IF(ABS(DETERM)-R2)1040,1040,1060
 1040   DETERM=DETERM*R1
        ISCALE=ISCALE-1
        IF(ABS(DETERM)-R2)1050,1050,1060
 1050   DETERM=DETERM*R1
        ISCALE=ISCALE-1
 1060   IF(ABS(PIVOTI)-R1)1090,1070,1070
 1070   PIVOTI=PIVOTI/R1
        ISCALE=ISCALE+1
        IF(ABS(PIVOTI)-R1)320,1080,1080
 1080   PIVOTI=PIVOTI/R1
        ISCALE=ISCALE+1
        GO TO 320
 1090   IF(ABS(PIVOTI)-R2)2000,2000,320
 2000   PIVOTI=PIVOTI*R1
        ISCALE=ISCALE-1
        IF(ABS(PIVOTI)-R2)2010,2010,320
 2010   PIVOTI=PIVOTI*R1
        ISCALE=ISCALE-1
  320   DETERM=DETERM*PIVOTI
C
C       DIVIDE PIVOT ROW BY PIVOT ELEMENT
C
  321   A(ICOLUM,ICOLUM)=1.0
        DO 350 L=1,N
  350     A(ICOLUM,L)=A(ICOLUM,L)/PIVOT
        IF(M) 380, 380, 360
  360   DO 370 L=1,M
  370     B(ICOLUM,L)=B(ICOLUM,L)/PIVOT
C
C       REDUCE NON-PIVOT ROWS
C
  380   DO 550 L1=1,N
          IF(L1-ICOLUM) 400, 550, 400
  400     T=A(L1,ICOLUM)
          A(L1,ICOLUM)=0.0
          DO 450 L=1,N
  450       A(L1,L)=A(L1,L)-A(ICOLUM,L)*T
          IF(M) 550, 550, 460
  460     DO 500 L=1,M
  500       B(L1,L)=B(L1,L)-B(ICOLUM,L)*T
  550 CONTINUE
C
C     INTERCHANGE COLUMNS
C
      DO 710 I=1,N
        L=N+1-I
        IF (IWK(L,1)-IWK(L,2))630,710,630
  630   JROW=IWK(L,1)
        JCOLUM=IWK(L,2)
        DO 705 K=1,N
          SWAP=A(K,JROW)
          A(K,JROW)=A(K,JCOLUM)
          A(K,JCOLUM)=SWAP
  705   CONTINUE
  710 CONTINUE
  740 RETURN

      END ! ----------------------------------- End of subroutine MATINV
