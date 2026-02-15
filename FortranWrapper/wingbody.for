*+
      PROGRAM WingBody
*   --------------------------------------------------------------------
*     PURPOSE - Compute aerodynamic velocities, pressures, forces and
*        moments about a wing-body combination at subsonic or supersonic
*        speeds.
*
*     AUTHORS - Frank A. Woodward, Boeing Co, later Analytical Mechanics
*               Ralph L. Carmichael, Public Domain Aeronautical Software
*               Art Kawaguchi, Boeing Co.
*               Ed Tinoco, Boeing Co.
*               Jim Larsen, Boeing Co.
*               Richard Wallace, Boeing Co.
*
*     REVISION HISTORY
*   DATE  VERS PERSON  STATEMENT OF CHANGES
*   1959    -  FAW&RLC The really old original version. Source panels
*   1965    -    FAW   Developed the constant pressure panels (sub/super)
*                         (NASA Contract NAS2-xxxx)
*   1967    -    RLC   NAMELIST input, builtin geometry
*   1968    -    RLC   The NASA-AMES WINGBODY program (for IBM 7094)
*   1972    -    RLC   TSS/360 version. Namelist used & not $
*   1976    -    RLC   CDC7600 version. Back to $
*   1980    -    RLC   Made VAX versions (& of course). Few changes.
* 10Jan94  0.1   RLC   Resurrected from oblivion. Compiled with Lahey.
* 29Oct94  0.2   RLC   Added SAVE statement to subroutine BODY
* 15Jul95  0.3   RLC   Modified WRITE statements to fit 80 column screen
*                        Added more comments (in lower case)
* 31Aug95  0.4   RLC   Redefined /PARAMS/ and /WNGPMS/
*                        SECTIN has args, not COMMON. ISYM is gone                     
*                        Replaced Sommer&Short with simpler eq (Raymer)
*  8Sep95  0.5   RLC   Corrected dreadful error in eqns for VonKarman
* 16Oct95  0.6   RLC   "Final cleanup". Removed old equivalence stuff
* 17Oct95  0.7   RLC   Restructured /BDYBLK/
* 24Oct95  0.8   RLC   /COMPS/ all double precision
* 26Oct95  0.81  RLC   /SRCE/ all double precision
*  3Dec95  0.9   RLC   made names BODYCPEQ and WINGCPEQ to replace CPCALC
* 21Nov96  0.93  RLC   Namelist statements follow, not preceed COMMON
* 22Dec96  2.0   RLC   Release for version 2.0
* 26Apr09  0.95  RLC   Fixed bug in subroutine BODY
*
*     NOTES- The blank COMMON is used by each subroutine for temporary
*       storage. A number of features of this program appear strange
*       today, but you must remember, this program was developed and
*       used for years on a machine with 32K of memory.
*
*     BUG LIST -
*       What is unit 11 good for?
*       Is ARR initialized properly?
*
      IMPLICIT NONE
*
      REAL FRICT
************************************************************************
*     C O N S T A N T S                                                *
************************************************************************
      CHARACTER GREETING*40, VERSION*30, FAREWELL*60
      CHARACTER AUTHOR*63, MODIFIER*60
      PARAMETER (GREETING='NASA-AMES WingBody Aerodynamics Program')
      PARAMETER (AUTHOR=
     & 'Ralph L. Carmichael, Public Domain Aeronautical Software')
      PARAMETER (MODIFIER=' ')  ! add your name if you change anything
      PARAMETER (VERSION=' 0.95 (26Apr09)' )
      PARAMETER (FAREWELL=
     &   ' File wingbody.out has been added to your directory.')
      REAL PI,HALFPI,TWOPI
      PARAMETER(PI=3.14159265, HALFPI=PI/2, TWOPI=2*PI)
      INTEGER MAXPAN, MAX_NTAB
      PARAMETER(MAXPAN=200, MAX_NTAB=51)
************************************************************************
*     V A R I A B L E S                                                *
************************************************************************
      REAL BAREA
      INTEGER BCODE
      REAL BDF
      INTEGER BPCODE
      REAL BPFS(20)
      REAL C1,C2
      REAL CF
      REAL D1,D2
      INTEGER errCode
      CHARACTER fileName*80      
      INTEGER I,J,K  
      INTEGER NB2
      INTEGER NBTEMP   ! ???
      INTEGER NROWS
      INTEGER NTAB
      INTEGER OPT
      REAL PER
      REAL RAD
      REAL RESULT
      REAL RR
      REAL RX
      REAL S1,S2
      LOGICAL THK 
      REAL VOLUME
      REAL WDF
      REAL X1,X2
      REAL XNOSE
      REAL XSTART
      REAL XX
      REAL ZSTA

************************************************************************
*     A R R A Y S                                                      *
************************************************************************
      REAL X(MAX_NTAB),R(MAX_NTAB),RPRIME(MAX_NTAB),Z(MAX_NTAB)
************************************************************************
*     C O M M O N   B L O C K   D E F I N I T I O N S                  *
************************************************************************
      INTEGER NWING,NBODY,PANELS,OC
      REAL SREF,REFMOM,CBAR
      COMMON/PARAMS/NWING,NBODY,PANELS,SREF,REFMOM,CBAR,OC

      REAL ROOTLE,ROOTTE,ROOTY,ROOTZ, TIPLE,TIPTE,TIPY,TIPZ
      INTEGER COLS,ROWS,TYPE,SECT
      REAL F(51),G(51),P(51),SHEAR(51)
      REAL TCROOT,TCTIP
      COMMON/WNGPMS/ROOTLE,ROOTTE,ROOTY,ROOTZ, TIPLE,TIPTE,TIPY,TIPZ,
     & ROWS,COLS,TYPE, F,G,P,SHEAR,SECT,TCROOT,TCTIP
*
      REAL RNOSE,RADIUS,RBASE,LNOSE,LBODY,LTAIL,ZNOSE,ZBASE
      INTEGER NB,NXBODY
      REAL THETAB(23)
      REAL XBODY(101),RBODY(101),RPBODY(101),ZBODY(101)
      REAL DRDX(100),DZDX(101)
      COMMON/BDYBLK/RNOSE,RADIUS,RBASE,LNOSE,LBODY,LTAIL,ZNOSE,ZBASE,
     X NB,NXBODY,THETAB,XBODY,RBODY,RPBODY,ZBODY,DRDX,DZDX
*
      REAL XBAR(200),XC(200),YC(200),ZC(200),AREA(200)
      REAL SINTH(200),COSTH(200),XP(200,4),YP(200,2),ZP(200,2)
      COMMON/PANEL/XBAR,XC,YC,ZC,AREA,SINTH,COSTH,XP,YP,ZP

      REAL PW(200),ALPHAT(100)
      COMMON/PSINGS/PW,ALPHAT
      
      REAL MACH,MACHSQ,BETASQ,BETA,RNL
      COMMON/VEL/MACH,MACHSQ,BETASQ,BETA,RNL

      REAL DUMMY(10606)
      COMMON DUMMY                     ! blank common
************************************************************************
*     N A M E L I S T   D E F I N I T I O N S                          *
************************************************************************
      NAMELIST/WING/ROOTLE,ROOTTE,ROOTY,ROOTZ,
     2 TIPLE,TIPTE,TIPY,TIPZ,
     3 ROWS,COLS, TYPE, F,G,P,SHEAR,
     4 TCROOT,TCTIP, SECT,
     5 OC,MACH,SREF,REFMOM,CBAR, OPT, RNL, PER
*
      NAMELIST/BODY/NB,NXBODY,NROWS,BCODE,
     1 LNOSE,LBODY,LTAIL, XNOSE,RNOSE,RADIUS,RBASE,ZNOSE,ZBASE,
     2 NTAB,X,R,RPRIME,Z,
     4 XSTART,SREF,CBAR,REFMOM,
     3 MACH,OC,OPT,RNL, BPCODE,BPFS,PER

*-----------------------------------------------------------------------
*
*..... Give everything in namelist a default value .....................
      ROOTLE=0.0
      ROOTTE=1.0
      ROOTY=0.0
      ROOTZ=0.0
      TIPLE=0.0
      TIPTE=1.0
      TIPY=1.0
      TIPZ=0.0
      TCROOT=0.0
      TCTIP=0.0
      THK=.FALSE.
      RNL=0.0
      NB=0
      NROWS=0
      NXBODY=0
      NWING=0
      NBODY=0
      PANELS=0
      SREF=1.0
      REFMOM=0.0
      CBAR=1.0
      OC=1
      OPT=1
      ROWS=6
      COLS=8
      TYPE=4
      SECT=0
      
      PER=0.95
      WDF=0.0
      BDF=0.0
      MACH=0

!!!      DATA ARR/501*0./
*
      WRITE(*,*) GREETING
      WRITE(*,*) AUTHOR
      IF(MODIFIER .NE. ' ') WRITE(*,'(A,A)' ) ' Modified by ', MODIFIER
      WRITE(*,*) VERSION
*
    5 WRITE(*,*) 'Enter the name of the input file: '
      READ  (*, '(A)' ) fileName
      IF (fileName .EQ. ' ') STOP
      OPEN(UNIT=4, FILE=fileName, STATUS='OLD', IOSTAT=errCode)
      IF (errCode .NE. 0) THEN
        WRITE(*, '(A)' ) ' Unable to open this file. Try again.'
        GOTO 5
      END IF

      OPEN(UNIT=6, FILE='wingbody.out', STATUS='REPLACE',ACTION='WRITE')

*
*
! old style left them hanging around...
!              
!      OPEN(UNIT=3, FILE='OWBODY3.TMP', STATUS='UNKNOWN',
!     &                                              FORM='UNFORMATTED')
!      OPEN(UNIT=7, FILE='OWBODY7.TMP', STATUS='UNKNOWN',
!     &                                              FORM='UNFORMATTED')
!      OPEN(UNIT=8, FILE='OWBODY8.TMP', STATUS='UNKNOWN',
!     &                                              FORM='UNFORMATTED')
!      OPEN(UNIT=11, FILE='OWBODY11.TMP', STATUS='UNKNOWN',
!     &                                              FORM='UNFORMATTED')
      OPEN(UNIT=3,  STATUS='SCRATCH', FORM='UNFORMATTED',IOSTAT=errCode)
      IF (errCode .NE. 0) STOP 'Unable to open scratch unit 3'
      OPEN(UNIT=7,  STATUS='SCRATCH', FORM='UNFORMATTED',IOSTAT=errCode)
      IF (errCode .NE. 0) STOP 'Unable to open scratch unit 7'
      OPEN(UNIT=8,  STATUS='SCRATCH', FORM='UNFORMATTED',IOSTAT=errCode)
      IF (errCode .NE. 0) STOP 'Unable to open scratch unit 8'
      OPEN(UNIT=11, STATUS='SCRATCH', FORM='UNFORMATTED',IOSTAT=errCode)
      IF (errCode .NE. 0) STOP 'Unable to open scratch unit 11'
!!!      OPEN(UNIT=33,FILE='wingbody.dbg',STATUS='REPLACE',ACTION='WRITE')
*

      CALL CopyData(4)  ! 4 is the number of the input file
*
    9 CALL SELECT(K)
      IF (K .LT. 0) GOTO 99
      IF (K .EQ. 0) GOTO 9
      GO TO (11,12,13,99),K
*
   12 CONTINUE
      IF (NB .GT. 0) STOP 'Attempt to enter more than one BODY'
      IF (PANELS .GT. 0) STOP 'You must enter BODY first, then WING'
*
      NB=2                            ! default values for BODY namelist
      NXBODY=51
      NROWS=8
      XNOSE=0.0
      RNOSE=0.0
      RADIUS=1.0
      RBASE=0.0
      LNOSE=0.5
      LBODY=1.0
      LTAIL=0.0
      ZNOSE=0.0
      ZBASE=0.0
      BCODE=0
      BPCODE=0
      DO i=1,MAX_NTAB
        RPRIME(i)=0.0
      END DO
      
      READ(UNIT=4, NML=BODY)
      IF (NB .LT. 1) THEN
        WRITE(*,*) 'NB must be 1 or greater. Setting it to 2'
        WRITE(6,*) 'NB must be 1 or greater. Setting it to 2'
        NB=2
      ENDIF
      IF (NB .GT. 5) THEN
        WRITE(*,*) 'NB must be 5 or less. Setting it to 5'
        WRITE(6,*) 'NB must be 5 or less. Setting it to 5'
        NB=5
      ENDIF
      IF (NXBODY .LT. 2) THEN
        WRITE(*,*) 'NXBODY must be 2 or greater. Setting it to 21'
        WRITE(6,*) 'NXBODY must be 2 or greater. Setting it to 21'
        NXBODY=21
      ENDIF
      IF (NXBODY .GT. 101) THEN
        WRITE(*,*) 'NXBODY must be 101 or less. Setting it to 101'
        WRITE(6,*) 'NXBODY must be 101 or less. Setting it to 101'
        NXBODY=101
      ENDIF
*
      NB2=NB+NB
      NBODY=NROWS*NB2
      IF (BCODE .LT. 0) THEN
        XBODY(1)=X(1)
        XBODY(NXBODY)=X(NTAB)
        CALL FILL(XBODY, NXBODY-1)
        DO I=1,NXBODY   ! interpolate to fill tables
          CALL TAINT(X,R,      XBODY(I), RBODY(I),  NTAB,3)
          CALL TAINT(X,RPRIME, XBODY(I), RPBODY(I), NTAB,3)
          CALL TAINT(X,Z,      XBODY(I), ZBODY(I),  NTAB,3)
        END DO
        DO I=1,NXBODY-1
          DRDX(I)=(RBODY(I+1)-RBODY(I))/(XBODY(I+1)-XBODY(I))
          DZDX(I)=(ZBODY(I+1)-ZBODY(I))/(XBODY(I+1)-XBODY(I))
        END DO
        LBODY=XBODY(NXBODY)-XBODY(1)
!!!..... If all RPBODY are zero, compute by differencing .................
!!!      CALL DIFCHK(XBODY,RBODY,RPBODY,NXBODY)
      ELSE
        XBODY(1)=XNOSE
        XBODY(NXBODY)=XNOSE+LBODY
!!!        NN=NXBODY-1
        CALL FILL(XBODY,NXBODY-1)

        DO I=1,NXBODY  ! Define the body at the definition points
          xx=xbody(i)-xnose
          CALL BODYR(BCODE,xx,RBODY(I),RPBODY(I),ZBODY(I),rr)
        END DO
        DO I=1,NXBODY-1  ! define slopes at the control points
          xx=0.5*(XBODY(I+1)+XBODY(I)) - XNOSE
          CALL BODYR(BCODE,xx, rr, DRDX(I), rr,DZDX(I))
        END DO
      ENDIF
*..... Print the Physical dimensions of the body (if oc > 1) ...........
      IF (OC .GT. 1) THEN
        CALL PAGE
        WRITE(6,*) 'PHYSICAL DIMENSIONS OF BODY'
        WRITE(6,*)
     & '          x          r         dr/dx       z'
        WRITE(6, '(I3,4F11.5)' )
     & (I,XBODY(I),RBODY(I),RPBODY(I),ZBODY(I), I=1,NXBODY)
        CALL PAGE
        WRITE(6,*) 'CONTROL POINTS FOR BODY LINE SINGULARITIES'
        WRITE(6,*)
     & '          x          r         dr/dx       dz/dx'
        WRITE(6, '(I3,4F11.5)' )
     & (I, 0.5*(XBODY(I)+XBODY(I+1)), 0.5*(RBODY(I)+RBODY(I+1)),
     &  DRDX(I),DZDX(I), I=1,NXBODY-1)
      ENDIF

*
*  Compute body volume and skin friction...................................
      DO I=1,NXBODY
        DUMMY(I)=RBODY(I)*RBODY(I)
      END DO   
      CALL UTRAP(DUMMY,RESULT,NXBODY)
      VOLUME=PI*(XBODY(NXBODY)-XBODY(1))*RESULT

      DO i=1,nxbody
        DUMMY(I)=SQRT(1.+RPBODY(I)*RPBODY(I))*RBODY(I)
      END DO
      CALL UTRAP(DUMMY,RESULT,NXBODY)
      BAREA=TWOPI*(XBODY(NXBODY)-XBODY(1))*RESULT

      IF (RNL .LE. 0.0) THEN
        BDF=0.0
      ELSE
        RX=RNL*(XBODY(NXBODY)-XBODY(1))       ! Reynolds # based on body
        RX=MAX(RX, 1E4)                     ! don't let RX get too small
        CF=FRICT(RX,MACH)
        BDF=BAREA*CF
      ENDIF
      
      IF (OC.GT.1) THEN
        WRITE(6,42) VOLUME,BAREA
        IF (RNL .LE. 0.0) THEN
          WRITE(6,*) 'No skin friction calculations.'
        ELSE
          WRITE(6,43) RX,CF
        ENDIF
      ENDIF
*
      IF (XSTART .GE. XBODY(NXBODY)) NROWS=0
      IF (BPCODE.EQ.0) THEN
        BPFS(1)=XSTART
        BPFS(NROWS+1)=XBODY(NXBODY)
        CALL FILL(BPFS,NROWS)
      ENDIF
*
      THETAB(1)=0.
      THETAB(2)=HALFPI/NB2
      THETAB(NB2+1)=PI-THETAB(2)
      THETAB(NB2+2)=PI
      CALL FILL(THETAB(2),NB2-1)

      XX=PI/NB2
      X1=0.0
      X2=XX
      DO 30 J=1,NB2
        S1=SIN(X1)
        S2=SIN(X2)
        C1=COS(X1)
        C2=COS(X2)
        X1=X2
        X2=X2+XX
        DO 31 I=1,NROWS
          PANELS=PANELS+1
          IF (PANELS .GT. MAXPAN) STOP 'Too many panels'
          D1=BPFS(I)
          D2=BPFS(I+1)
          XP(PANELS,1)=D1
          XP(PANELS,2)=D1
          XP(PANELS,3)=D2
          XP(PANELS,4)=D2
          CALL TAINT(XBODY,RBODY, 0.5*(D1+D2), RAD,  NXBODY,1)
          CALL TAINT(XBODY,ZBODY, 0.5*(D1+D2), ZSTA, NXBODY,1)
          YP(PANELS,1)=RAD*S1
          YP(PANELS,2)=RAD*S2
          ZP(PANELS,1)=RAD*C1+ZSTA
          ZP(PANELS,2)=RAD*C2+ZSTA
   31   CONTINUE
   30 CONTINUE
      GO TO 9
*
   11 READ(4,WING)
      THK=THK .OR. TCROOT.GT.0.0 .OR. TCTIP.GT.0.0
      CALL WNGEOM(WDF)
      GO TO 9
*
!..... Jumps here when an AERO namelist is found.
!      No more geometry; proceed to calculate the matrix, etc.
   13 CONTINUE
      WRITE(*,*) 'Geometry input complete. Computing matrix'
      NWING=PANELS-NBODY
      MACHSQ=MACH*MACH
      BETASQ=1.0-MACHSQ
      BETA=SQRT(ABS(BETASQ))
!      CALL FILL(XFTAB,NFTAB-1)          ! commented out  14Apr94
      IF (NWING .GT. 0) CALL EVAL(THK,PER)
      WRITE(*,*) 'Matrix computed. Reduction under way.'
      NBTEMP=MAX(1, NBODY)   ! what is this for ??????????
      IF(NWING.GT.0)CALL REDUCE(OPT,NWING,NBTEMP,NWING+1,NWING+2,
     X   DUMMY,DUMMY,DUMMY,DUMMY)
      WRITE(*,*) 'Reduction complete. Evaluate line singularities'
      CALL KMSET(XNOSE)
      WRITE(*,*) 'Line singularities computed. Do cases.'
      CALL FORCE(BDF/SREF,WDF/SREF)
*
   99 WRITE(6,*) 'Normal termination in main program'
      WRITE(*,*) FAREWELL
      STOP 'Normal termination in main program'
42    FORMAT('BODY VOLUME=',F15.5,10X,'BODY SURFACE AREA=',F15.5)
43    FORMAT('REYNOLDS NUMBER=',F12.0,'     CF=',F8.4)
      END   ! --------------------------- End of main module of WingBody

      SUBROUTINE CopyData(efu)
      INTEGER efu
      CHARACTER A*132
      INTEGER I
      REWIND efu
      I=0
      WRITE(6,*)
     &   'SUMMARY OF DATA CARDS FOR NASA/AMES WING-BODY PROGRAM'
100   READ(efu, '(A)', END=10) A
      I=I+1
      WRITE(6, '(I3,2X,A)' ) I,A
      GO TO 100

10    WRITE(6,*) 'END OF DATA CARDS '
      REWIND efu
      END   ! ------------------------------- End of Subroutine CopyData

      SUBROUTINE SELECT(K)
      IMPLICIT NONE
      INTEGER K
!    Peeks ahead at the next input recors to see if it is a valid
!      namelist record, and if so, what the namelist name is ...........
!... modified to use internal files   10Oct94   RLC
!... see if first 6 char match a DICT entry. If so, K holds the index.
!... If not, K=0
!... If EOF encountered, K=-1
!... if k==0 and line is not blank, make it the title (TGEN)
!
      CHARACTER TGEN*80, DUMMY*80
      INTEGER I
      INTEGER NDICT,NOPAGE
      PARAMETER (NDICT=4)
      COMMON/GENERAL/NOPAGE,TGEN
      CHARACTER*6 DICT(NDICT)
      DATA DICT/' &WING', ' &BODY', ' &AERO', ' &INCR' /
*
      READ (4, '(A)', END=18) DUMMY
      K=0
      DO I=1,NDICT
         IF(DUMMY(1:6) .EQ. DICT(I) ) THEN
            K=I
            BACKSPACE 4
            RETURN
         ENDIF
      ENDDO
      IF ( (K .EQ. 0) .AND. (DUMMY .NE. ' ') ) TGEN=DUMMY
      RETURN

   18 WRITE(6,*) 'NORMAL TERMINATION FROM SELECT'
      K=-1
      END   ! --------------------------------- End of Subroutine Select

      SUBROUTINE PAGE
      CHARACTER TGEN*80, HEADER*70
      PARAMETER (HEADER = 'NASA/AMES WING-BODY PROGRAM')
      COMMON/GENERAL/NOPAGE,TGEN
      INTEGER NOPAGE
!
      NOPAGE=NOPAGE+1
      WRITE(6, '(///A,A,I4)' ) HEADER, 'PAGE', NOPAGE
      WRITE(6,*) TGEN
      END

!..... Assumes AFILL(1) and AFILL(NFILL+1) are already set. Computes
!      AFILL(2) thru AFILL(NFILL) with uniform spacing .................
      SUBROUTINE FILL(AFILL,NFILL)
      REAL AFILL(*)
      INTEGER NFILL
      REAL DEL
      INTEGER I

      IF(NFILL .LE. 1)RETURN
      DEL=(AFILL(NFILL+1)-AFILL(1))/FLOAT(NFILL)
      DO 20 I=2,NFILL
         AFILL(I)=AFILL(I-1)+DEL
   20 CONTINUE
      END

!..... Integrate the function tabulated at unequal intervals with
!      the trapezoidal rule. ZTRAP is the result.
!      Why isn't this a function???
      SUBROUTINE TRAP(XTRAP,YTRAP,ZTRAP,NTRAP)
      IMPLICIT NONE
      REAL XTRAP(*),YTRAP(*),ZTRAP
      INTEGER NTRAP
      REAL SUM
      INTEGER I
*
      SUM=0.0
      DO 10 I=2,NTRAP
         SUM=SUM+(XTRAP(I)-XTRAP(I-1))*(YTRAP(I)+YTRAP(I-1))
   10 CONTINUE
      ZTRAP=0.5*SUM
      END

!..... Integrate the function tabulated at equal intervals. Back in
!      the calling program, multiply by the length of the integration
!      interval to get the answer.
!      Why isn't this a function???
      SUBROUTINE UTRAP(YTP,RESULT,NU)
      REAL YTP(*), RESULT
      INTEGER NU
      REAL SUM
      INTEGER I
*
      SUM=0.0
      DO 10 I=1,NU
         SUM=SUM+YTP(I)
   10 CONTINUE
      DO 20 I=2,NU-1
         SUM=SUM+YTP(I)
   20 CONTINUE
      IF (NU.GT.1) SUM=SUM/REAL(2*NU-2)
      RESULT=SUM
      END


!..... Average flat plate skin turbulent skin friction coeff.
      REAL FUNCTION FRICT(RN,MACH)
      IMPLICIT NONE
      REAL RN,MACH
      REAL XX,CFI,Z
      XX=LOG10(RN)-1.5
      CFI=.088/(XX*XX)                      ! Eqn. of Sievells and Payne
      Z=1.0+0.144*MACH*MACH
      FRICT=CFI/(Z**0.65)                   ! Correction for Mach number
      RETURN
      END   ! ------------------------------------ End of Function Frict

      REAL FUNCTION AMACHF(X) 
      IMPLICIT NONE              ! Why not make mach an arg? no /VEL/
      REAL x ! square of local velocity
      COMMON/VEL/MACH,MACHSQ,BETASQ,BETA,RNL
      REAL MACH,MACHSQ,BETASQ,BETA,RNL
      REAL XX
      IF (MACH .EQ. 0.0) THEN
        AMACHF=0.0
      ELSE
        XX=1.0/MACH**2 + 0.2*(1.-X)
        AMACHF=SQRT(MAX(X/XX, 0.))
      ENDIF
      END   ! ----------------------------------- End of Function Amachf

!..... Fill fprime with estimate using difference formulas of the
!      derivative of f vs. x
!      If any entries in fprime are non-zero, then do NOTHING
      SUBROUTINE DIFCHK(X,F,FPRIME,N)
      IMPLICIT NONE
      REAL X(*),F(*),FPRIME(*)
      INTEGER N
      INTEGER I

      DO 10 I=1,N
        IF (FPRIME(I) .NE. 0.0) RETURN
   10 CONTINUE
*
      FPRIME(1)=(F(2)-F(1))/(X(2)-X(1))             ! forward difference 
      FPRIME(N)=(F(N)-F(N-1))/(X(N)-X(N-1))        ! backward difference
      DO 20 I=2,N-1                                 ! central difference 
        FPRIME(I)=(F(I+1)-F(I-1))/(X(I+1)-X(I-1))
   20 CONTINUE
      END   ! --------------------------------- End of Subroutine DIFCHK

!
      SUBROUTINE CCP(ICP,U,V,W,C)
      IMPLICIT NONE
      INTEGER ICP
      REAL U,V,W,C
      COMMON/VEL/MACH,MACHSQ,BETASQ,BETA,RNL
      REAL MACH,MACHSQ,BETASQ,BETA,RNL
      REAL XX,X3
      
      IF (ICP .EQ. 1) THEN
        C=-2.*U-V*V-W*W     ! slender-body theory
      ELSEIF (ICP .EQ. 2) THEN
        C=-2.*U + BETASQ*U*U - V*V - W*W   ! 2nd order
      ELSEIF (ICP .EQ. 3) THEN
        XX=1.-.2*MACHSQ*(2.*U + U*U + V*V + W*W)     ! isentropic
        X3=XX*XX*XX
        C=(SQRT(XX*X3*X3)-1.)/MACHSQ /.7
      ELSEIF (ICP .EQ. 4) THEN
        C=-2.*U-V*V   ! ???, slender-body if v means radial.
      ELSE
        C=-2.*U                     ! linear
      ENDIF
      RETURN
      END   ! ------------------------------------ End of Subroutine CCP

      SUBROUTINE RUNTRP(XRTP,YRTP,BARRAY,NT)
      IMPLICIT NONE
      REAL XRTP(*),YRTP(*),BARRAY(*)
      INTEGER NT
      INTEGER I

      BARRAY(1)=0.0
      DO 10 I=2,NT
        BARRAY(I)=BARRAY(I-1)+(YRTP(I)+YRTP(I-1))*(XRTP(I)-XRTP(I-1))/2.
   10 CONTINUE
      RETURN
      END
*
*     TAble INTerpolation. Originally written by Virginia Sorensen
*        One of the old war-horse routines from NASA Ames
!     Interpolate in a table of N points using K-order polynomial
!       fitting.
      SUBROUTINE TAINT(XTAB,FTAB,X,FX,N,K)
      IMPLICIT NONE
      REAL XTAB(*),FTAB(*)
      REAL X,FX
      INTEGER N,K

      REAL C(10),T(10)    ! 10 is max order; no defense
      INTEGER I,J,L,M
      IF(N.LE.1)GO TO 60
      DO 13 I=1,N
        IF(X.GT.XTAB(I))GO TO 13    ! sequential search, tsk,tsk!
        J=I
        GO TO 18
13    CONTINUE
      J=N
18    J=J-(K+1)/2
      IF (J.LE.0) J=1
20    M=J+K
      IF (M.LE.N) GO TO 21
      J=J-1
      GO TO 20

21    DO 23 L=1,K+1           ! Lagrange polynomial of order K
        C(L)=X-XTAB(J)
        T(L)=FTAB(J)
        J=J+1
   23 CONTINUE
!..... In Fortran90, the 23 loop would be written as
!          c(1:k+1)=x-xtab(j:j+k); t(1:k+1)=ftab(j:j+k)
!..... The k+1 points used for interpolation are now in C and T
!
!..... The next loop is just a coding of Lagrange's Equation
      DO 24 J=1,K
        I=J+1
25      T(I)=(C(J)*T(I)-C(I)*T(J))/(C(J)-C(I))
        I=I+1
        IF(I .LE. K+1)GO TO 25
24    CONTINUE
      FX=T(K+1)
      RETURN
60    FX=FTAB(1)
      RETURN
      END   ! ---------------------------------- End of Subroutine TAINT


*     LU decomposition of matrix for Gaussian elimination
*     ACM Algorithm 423, April 1972, by Cleve Moler
*     Thanks to the Office of Naval Research, Contract NR 044-377.
      SUBROUTINE DECOMP(N,A,IP,NDIM)
      INTEGER N,NDIM
      INTEGER IP(N)
      REAL A(NDIM,N)
      REAL T

      IP(N)=1
      DO 6 K=1,N
        IF(K.EQ.N)GO TO 5
!!!        KP1=K+1
        M=K
        DO 1 I=K+1,N
          IF(ABS(A(I,K)) .GT. ABS(A(M,K)) ) M=I
1       CONTINUE
        IP(K)=M
        IF (M.NE.K) IP(N)=-IP(N)
        T=A(M,K)
        A(M,K)=A(K,K)
        A(K,K)=T
        IF(T.EQ.0.)GO TO 5
        DO 2 I=K+1,N
          A(I,K)=-A(I,K)/T   ! original. Most folks do T=1/T outside loop
    2   CONTINUE
        DO 4 J=K+1,N
          T=A(M,J)
          A(M,J)=A(K,J)
          A(K,J)=T
          IF (T.EQ.0.) GO TO 4
          DO 3 I=K+1,N
            A(I,J)=A(I,J)+A(I,K)*T
    3     CONTINUE
4       CONTINUE
5       IF(A(K,K).EQ.0.)IP(N)=0
6     CONTINUE
      RETURN
      END   ! --------------------------------- End of Subroutine Decomp

*     Part of Algorithm 423. Used after DECOMP
      SUBROUTINE SOLVE(N,A,IP,B,NDIM)
      DIMENSION B(*),IP(*),A(NDIM,*)
      IF (N.EQ.1) GO TO 9
      NM1=N-1
      DO 7 K=1,N-1
        KP1=K+1
        M=IP(K)
        T=B(M)
        B(M)=B(K)
        B(K)=T
        DO 7 I=KP1,N
          B(I)=B(I)+A(I,K)*T
    7   CONTINUE
      DO 8 KB=1,NM1                 ! today we would do K=N,2,-1
        KM1=N-KB
        K=KM1+1
        B(K)=B(K)/A(K,K)
        T=-B(K)
        DO 8 I=1,KM1
          B(I)=B(I)+A(I,K)*T
    8 CONTINUE
9     B(1)=B(1)/A(1,1)
      RETURN
      END   ! ---------------------------------- End of Subroutine Solve

*     This was part of the 1965 program from Boeing
*     Invert matrix by Gaussian elimination. Assume pivot on diagonal
      SUBROUTINE INVERT(AA,NN)
      REAL AA(NN,*)
!!!      write(6,*) 'starting invert, nn=', nn
      DO 10 I=1,NN
         PIVOT=AA(I,I)
!!!         write(6,*) 'pivot', i, pivot
         AA(I,I)=1.
         DO 31 L=1,NN
            AA(I,L)=AA(I,L)/PIVOT
31       continue
         DO 30 M=1,NN
            IF(M.EQ.I) GO TO 30
            TT=AA(M,I)
            AA(M,I)=0.
            DO 32 L=1,NN
               AA(M,L)=AA(M,L)-AA(I,L)*TT
   32       continue
30       CONTINUE
   10 continue
!!!      write(6,*) 'ending invert'
      END

      SUBROUTINE WNGEOM(DF)
      IMPLICIT NONE
      REAL FRICT
!!! note blank commom
      REAL XCPT(51),SLOPE(51),CHROOT(101),CHTIP(101)
      REAL ZUROOT(51),ZUTIP(51),ZLROOT(51),ZLTIP(51),SCF(51),ZY1(10047)
      COMMON XCPT,SLOPE,CHROOT,CHTIP,ZUROOT,ZUTIP,ZLROOT,ZLTIP,SCF,ZY1
      
      REAL ROOTLE,ROOTTE,ROOTY,ROOTZ, TIPLE,TIPTE,TIPY,TIPZ
      INTEGER ROWS,COLS,TYPE,SECT
      REAL F(51),G(51),P(51),SHEAR(51),TCROOT,TCTIP
      COMMON/WNGPMS/ROOTLE,ROOTTE,ROOTY,ROOTZ, TIPLE,TIPTE,TIPY,TIPZ,
     & ROWS,COLS,TYPE,F,G,P,SHEAR,SECT,TCROOT,TCTIP

      INTEGER NWING,NBODY,PANELS,OC
      REAL SREF,REFMOM,CBAR
      COMMON/PARAMS/NWING,NBODY,PANELS,SREF,REFMOM,CBAR,OC
*
      REAL XBAR(200),XC(200),YC(200),ZC(200),AREA(200)
      REAL SINTH(200),COSTH(200),X(200,4),Y(200,2),Z(200,2)
      COMMON/PANEL/XBAR,XC,YC,ZC,AREA,SINTH,COSTH,X,Y,Z

      REAL PW(200),ALPHAT(100)
      COMMON/PSINGS/PW,ALPHAT
      
      REAL MACH,MACHSQ,BETASQ,BETA,RNL
      COMMON/VEL/MACH,MACHSQ,BETASQ,BETA,RNL
      
      INTEGER PANMAX
      INTEGER I,J

      REAL DR,DT
      REAL DOVERQ
      REAL S1,S2,SSPAN
      REAL SC1,SC2
      REAL PAREA,SAREA
      REAL Y1,Y2,YPER
      REAL PERCHD
      REAL RTMAX,TIPMAX
      REAL VOLUME
      REAL DVTERM
      REAL DX1,DX2
      REAL ZP1,ZP2,ZPP1,DZ1,DZ2
      REAL DS1,DS2
      REAL THCK
      REAL ZT
      REAL DZDX
      REAL ZPP2
      REAL ZZ
      REAL DF
      REAL TH
      REAL SC
      REAL S,C
      REAL RX
      REAL CF

      DATA PANMAX/200/
*
      IF(COLS.LE.0 .OR. ROWS.LE.0)RETURN
!!!      M1=M+1
!!!      N1=N+1
      DR=ROOTTE-ROOTLE
      DT=TIPTE-TIPLE
      S1=DR
      S2=DT
      SSPAN=TIPY-ROOTY
      PAREA=(DR+DT)*SSPAN   ! planform area
      SC1=1.
      SC2=1.
!..... Changed the old convoluted logic to logical IF statements 17Jul95 RLC
      IF (TYPE.EQ.3 .OR. TYPE.EQ.4) THEN
        F(1)=ROOTLE
        G(1)=TIPLE
        F(ROWS+1)=ROOTTE
        G(ROWS+1)=TIPTE
        CALL FILL(F,ROWS)
        CALL FILL(G,ROWS)
      ENDIF
      IF (TYPE.EQ.2 .OR. TYPE.EQ.4) THEN
        P(1)=ROOTY
        P(COLS+1)=TIPY
        SHEAR(1)=ROOTZ
        SHEAR(COLS+1)=TIPZ
        CALL FILL(P,COLS)
        CALL FILL(SHEAR,COLS)
      ENDIF
*
      DO 25 I=1,ROWS+1
        CHROOT(I)=0.0
        CHTIP(I)=0.0
        SLOPE(I)=(G(I)-F(I))/(TIPY-ROOTY)
        XCPT(I)=F(I)-ROOTY*SLOPE(I)
   25 CONTINUE
      DO 26 I=1,ROWS
        IF(DR.GT.0.0) CHROOT(I)=((F(I)+F(I+1))/2.-F(1))/DR
        IF(DT.GT.0.0) CHTIP(I)=((G(I)+G(I+1))/2.-G(1))/DT
26    CONTINUE
      IF(DT.EQ.0.) THEN
        DO 28 I=1,ROWS
          CHTIP(I)=CHROOT(I)
   28   CONTINUE
      ENDIF

      DO 30 J=1,COLS
        Y1=P(J)
        Y2=P(J+1)
        YPER=((Y1+Y2)/2.-P(1))/(TIPY-ROOTY)
        THCK=TCTIP*YPER + TCROOT*(1.0-YPER)
        DO 29 I=1,ROWS
          PANELS=PANELS+1
          IF(PANELS.GT.PANMAX) STOP 'Too many panels'
          X(PANELS,1)=XCPT(I)+Y1*SLOPE(I)
          X(PANELS,2)=XCPT(I)+Y2*SLOPE(I)
          X(PANELS,3)=XCPT(I+1)+Y1*SLOPE(I+1)
          X(PANELS,4)=XCPT(I+1)+Y2*SLOPE(I+1)
          Y(PANELS,1)=Y1
          Y(PANELS,2)=Y2
          Z(PANELS,1)=SHEAR(J)
          Z(PANELS,2)=SHEAR(J+1)
          IF(THCK.NE.0.0) THEN
            PERCHD=CHTIP(I)*YPER + CHROOT(I)*(1.0-YPER)
            CALL SECTIN(SECT, PERCHD, ZT, DZDX)
          ENDIF
          ALPHAT(PANELS-NBODY)=THCK*DZDX
   29   CONTINUE
30    CONTINUE

      RTMAX=TCROOT*DR
      TIPMAX=TCTIP*DT
      DO 36 I=1,ROWS+1
      IF(RTMAX.EQ.0..OR.DR.EQ.0.)GO TO 37
      PERCHD=(F(I)-F(1))/DR
      CALL SECTIN(SECT, PERCHD, ZT, DZDX)
      ZUROOT(I)=ROOTZ+ZT*RTMAX
      ZLROOT(I)=ROOTZ-ZT*RTMAX
      GO TO 38
37    ZUROOT(I)=ROOTZ
      ZLROOT(I)=ROOTZ
38    IF(TIPMAX.EQ.0..OR.DT.EQ.0.)GO TO 39
      PERCHD=(G(I)-G(1))/DT
      CALL SECTIN(SECT, PERCHD, ZT, DZDX)
      ZUTIP(I)=TIPZ+ZT*TIPMAX
      ZLTIP(I)=TIPZ-ZT*TIPMAX
      GO TO 36
39    ZUTIP(I)=TIPZ
      ZLTIP(I)=TIPZ
36    CONTINUE

*..... Compute wing surface area and volume ............................
      IF (TCROOT.EQ.0.  .AND.  TCTIP.EQ.0.) THEN
        VOLUME=0.
        SAREA=2.*PAREA
      ELSE
        DVTERM=0.
        S1=0.
        S2=0.
        DO 70 I=1,ROWS
          DX1=F(I+1)-F(I)
          DX2=G(I+1)-G(I)
          ZP1=ZUROOT(I)-ZLROOT(I)
          ZPP1=ZUROOT(I+1)-ZLROOT(I+1)
          DZ1=ZP1+ZPP1
          ZP2=ZUTIP(I)-ZLTIP(I)
          ZPP2=ZUTIP(I+1)-ZLTIP(I+1)
          DZ2=ZP2+ZPP2
          DVTERM=DVTERM+DX1*(DZ1+DZ2/2.)+DX2*(DZ1/2.+DZ2)
          ZZ=(ZP1-ZPP1)/2.
          DS1=SQRT(DX1*DX1+ZZ*ZZ)
          ZZ=(ZP2-ZPP2)/2.
          DS2=SQRT(DX2*DX2+ZZ*ZZ)
          S1=S1+DS1
          S2=S2+DS2
   70   CONTINUE
        VOLUME=SSPAN*DVTERM/3.    ! 3 not 6 to get the left wing
        SAREA=2.0*(S1+S2)*SSPAN
      ENDIF
*
*..... Compute skin friction on this wing (if RNL > 0) .................
      IF (RNL .EQ. 0.0) THEN
        DF=0.0
      ELSE
        IF(DR.NE.0.)SC1=S1/DR
        IF(DT.NE.0.)SC2=S2/DT
        DO 80 J=1,COLS+1
          TH=(P(J)-P(1))/SSPAN
          SC=TH*SC2 + (1.0-TH)*SC1  ! surface length/chord length
          C=TH*DT + (1.0-TH)*DR    ! local chord
          S=SC*C
          RX=MAX(RNL*S, 1E4)   ! don't let Reynolds get small
          CF=FRICT(RX, MACH)
          SCF(J)=S*CF
   80   CONTINUE
        CALL TRAP(P, SCF, DOVERQ, COLS+1)
        DOVERQ=4.0*DOVERQ   ! 4 from top,bottom left,right
        DF=DF+DOVERQ 
      ENDIF
      IF(OC.LE.1)RETURN
*
      CALL PAGE
      WRITE(6,*) 'WING PANEL GEOMETRY'
      WRITE(6,*) '                ROOT           TIP'
      WRITE(6,35) ROOTLE,ROOTTE,ROOTY,ROOTZ, TIPLE,TIPTE,TIPY,TIPZ
35    FORMAT(' LEADING EDGE  ',2G15.5/' TRAILING EDGE ',2G15.5/
     Y ' Y',G28.5,G15.5/' Z',G28.5,G15.5)
      WRITE(6,51) PAREA,SAREA,VOLUME
51    FORMAT('PLANFORM AREA OF THIS WING REGION=',G12.4/
     & 'TOTAL SURFACE AREA OF THIS WING REGION=',G12.4/
     & 'VOLUME OF THIS WING REGION=', G12.4)
*
      IF (RNL.GT.0.) WRITE(6,52)MACH,RNL,DOVERQ,DF
52    FORMAT('TURBULENT SKIN FRICTION AT MACH=',F6.3,
     X  '    UNIT REYNOLDS NO=', E12.4/
     Y 10X,'D/Q OF THIS PANEL=',E10.3,'  D/Q (CUMULATIVE)=',E10.3)
C
      WRITE(6,*) '   ROOT DIVISION POINTS           TIP DIVISION POINTS'
      WRITE(6,40)(F(I),ZUROOT(I),ZLROOT(I),G(I),ZUTIP(I),ZLTIP(I),
     X  SLOPE(I),XCPT(I),I=1,ROWS+1)
40    FORMAT(
     X 5X,'X',5X,'Z(UPPER)',1X, 'Z(LOWER)',5X,
     &    'X',5X,'Z(UPPER)',1X,'Z(LOWER)',
     & 2X,'SLOPE', 2X,'XCPT'/(3F9.4,2X,3F9.4,2X,2F9.4))
      WRITE(6,41)(P(I),SHEAR(I),I=1,COLS+1)
41    FORMAT(5X,'SPAN DIVISIONS'/5X,'Y',10X,'Z'/(2F10.4))
      END
*+
      SUBROUTINE SECTIN (ISECT, X, Z, DZDX)
*   --------------------------------------------------------------------
*     PURPOSE - Compute wing section
*
      IMPLICIT NONE
************************************************************************
*     A R G U M E N T S                                                *
************************************************************************
      INTEGER ISECT
      REAL X,Z,DZDX
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
      REAL XTAB(19)               ! common x-table fro all sections
      REAL ZTAB1(19),ZPTAB1(19)   ! z and dz/dx for 000x
      REAL ZTAB2(19),ZPTAB2(19)   ! z and dz/dx for 6400x
      REAL ZTAB3(19),ZPTAB3(19)   ! z and dz/dx for 6500x
      REAL ZTAB4(19),ZPTAB4(19)   ! z and dz/dx for RAE 101
!
      DATA XTAB    /0.,.005,.0125,.0250,.05,.075,.1,.15,.2,.25,.3,.4,
     X  .5,.6,.7,.8,.9,.95,1./
      DATA ZTAB1    /0.,.0923,.1578,.2178,.2962,.35,.3902,.4455,.4782,
     X.4952,.5002,.4837,.4412,.3803,.3053,.2187,.1207,.0672,.0105/
      DATA ZPTAB1    /18.46,12.624,6.275,3.69,2.644,1.88,1.273,.88,.497,
     X .22,-.0767,-.295,-.517,-.6795,-.808,-.923,-1.01,-1.102,-1.134/
      DATA ZTAB2    /0.,.082,.125,.1701,.2343,.2826,.3221,.3842,.4302,
     X.4639,.4864,.4988,.4586,.3820,.2827,.1722,.0671,.0248,0./
      DATA ZPTAB2    /16.4,10.,4.405,2.915,2.25,1.756,1.354,1.081,.797,
     X .562,.2327,-.139,-.584,-.8795,-1.049,-1.078,-.983,-.671,-.496/
      DATA ZTAB3    /0.,.0772,.1169,.1574,.2177,.2647,.3040,.3666,.4143,
     X  .4503,.4760,.4996,.4812,.4146,.3156,.1987,.0810,.0306,0./
      DATA ZPTAB3    /15.44,9.352,4.01,2.688,2.146,1.726,1.359,1.103,
     X  .837,.617,.329,.026,-.425,-.828,-1.079,-1.173,-1.121,-.81,-.612/
      DATA ZTAB4    /0.,.087,.1335,.1915,.2659,.3191,.3607,.4220,.4630,
     X .4885,.4997,.4801,.4267,.3531,.2681,.1789,.0894,.0447,0./
      DATA ZPTAB4    /22.,10.5,5.32,3.71,2.446,1.863,1.465,1.000,.6589,
     X .3725,.0464,-.3966,-.6529,-.8073,-.8837,4*-.894/
*-----------------------------------------------------------------------
*
      IF(X.LT.0. .OR. X.GT.1.) THEN
        Z=0.0                                                
        DZDX=0.
        RETURN
      ENDIF
*
      IF (ISECT .EQ. 1) THEN
        IF (X .LE. 0.5) THEN                              ! double-wedge
          Z=X
          DZDX=1.0
        ELSE
          Z=1.-X
          DZDX=-1.
        ENDIF
      ELSEIF (ISECT .EQ. 2) THEN
        IF (X .LT. 0.3) THEN                                 ! 30-70 hex
          Z=1.666667*X
          DZDX=1.666667
        ELSEIF (X .GT. 0.7) THEN
          Z=1.666667*(1.-X)
          DZDX=-1.666667
        ELSE
          Z=.5
          DZDX=0.
        ENDIF
      ELSEIF(ISECT .EQ. 3) THEN
        Z=X/2.                                      ! wedge (blunt base)
        DZDX=.5
      ELSEIF (ISECT .EQ. -1) THEN
        CALL TAINT(XTAB,ZTAB1,X,Z,19,2)                           ! 000x
        CALL TAINT(XTAB,ZPTAB1,X,DZDX,19,2)
      ELSEIF (ISECT .EQ. -2) THEN
        CALL TAINT(XTAB,ZTAB2,X,Z,19,2)                          ! 6400x
        CALL TAINT(XTAB,ZPTAB2,X,DZDX,19,2)
      ELSEIF (ISECT .EQ. -3) THEN
        CALL TAINT(XTAB,ZTAB3,X,Z,19,2)                          ! 6500x
        CALL TAINT(XTAB,ZPTAB3,X,DZDX,19,2)
      ELSEIF (ISECT .EQ. -4) THEN
        CALL TAINT(XTAB,ZTAB4,X,Z,19,2)                        ! RAE 101
        CALL TAINT(XTAB,ZPTAB4,X,DZDX,19,2)
      ELSE
        Z=2.0*X*(1.0-X)                              ! parabolic section
        DZDX=2.0*(1.0-2.0*X)
      ENDIF
      END ! ----------------------------------- End of subroutine Sectin

      REAL FUNCTION Parabolic(x)
      IMPLICIT NONE
      REAL x
      Parabolic=x*(2.0-x)
      END   ! -------------------------------- End of function Parabolic

      REAL FUNCTION ParabolicSlope(x)
      IMPLICIT NONE
      REAL x
      ParabolicSlope=2.0*(1.0-x)
      END   ! --------------------------- End of Function ParabolicSlope

      REAL FUNCTION SearsHaack(x)
      IMPLICIT NONE
      REAL x
      SearsHaack=(x*(2.0-x))**0.75
      END   ! ------------------------------- End of function SearsHaack

      REAL FUNCTION SearsHaackSlope(x)
      IMPLICIT NONE
      REAL x
      IF (x .LE. 0.0 .OR. x .GE. 1.0) THEN
        SearsHaackSlope=0.0
      ELSE
        SearsHaackSlope=1.5*(1.0-x)*(x*(2.0-x))**(-0.25)
      ENDIF
      END   ! -------------------------- End of Function SearsHaackSlope

      REAL FUNCTION VonKarmanOgive(x)
      IMPLICIT NONE
      REAL x
      REAL PI
      PARAMETER(PI=3.14159265)
      REAL area

      area=2.0*(ASIN(SQRT(x)) - (1.0-x-x)*SQRT(x*(1.0-x)))
      VonKarmanOgive=SQRT(area/PI)
      END   ! --------------------------- End of function VonKarmanOgive

      REAL FUNCTION VonKarmanOgiveSlope(x)
      IMPLICIT NONE
      REAL x
      REAL PI
      PARAMETER(PI=3.14159265)
      REAL area,r

      IF (x .LE. 0.0  .OR.  x .GE. 1.0) THEN
        VonKarmanOgiveSlope=0.0
      ELSE
        area =2.0*(ASIN(SQRT(x)) - (1.0-x-x)*SQRT(x*(1.0-x)))
        r =Sqrt(area/PI)
        VonKarmanOgiveSlope=(4.0/PI)*Sqrt(x*(1.0-x))/r
      ENDIF
      END   ! ---------------------- End of Function VonKarmanOgiveSlope

      REAL FUNCTION Ellipsoid(x)
      IMPLICIT NONE
      REAL x
      Ellipsoid=Sqrt(x*(2.0-x))
      END   ! -------------------------------- End of function Ellipsoid

      REAL FUNCTION EllipsoidSlope(x)
      IMPLICIT NONE
      REAL x

      IF (x .LE. 0.0  .OR.  x .GE. 1.0) THEN
        EllipsoidSlope =0.0
      ELSE
        EllipsoidSlope =(1.0-x)/SQRT(x*(2.0-x))
      ENDIF
      END   ! --------------------------- End of Function EllipsoidSlope
*+
      SUBROUTINE BodyR(BCODE, X,R,RPRIME,Z,DZDX)
*   --------------------------------------------------------------------
*     PURPOSE - Calculate body radius and slope for a body of the type
*        forbody-cylinder-afterbody
*
*     NOTES-
*
      IMPLICIT NONE
*
      REAL Parabolic,SearsHaack,VonKarmanOgive,Ellipsoid
      REAL ParabolicSlope,SearsHaackSlope
      REAL VonKarmanOgiveSlope,EllipsoidSlope
************************************************************************
*     A R G U M E N T S                                                *
************************************************************************
      INTEGER BCODE   ! =0 for parabolic body
                      ! =1 for Sears-Haack body
                      ! =2 for VonKarman ogive
                      ! =3 for ellipsoid
                      ! =4 for cone
      REAL X,R,RPRIME,Z,DZDX
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
      REAL xx,rr
************************************************************************
*     L O C A L   A R R A Y S                                          *
************************************************************************
      REAL RNOSE,RADIUS,RBASE,LNOSE,LBODY,LTAIL,ZNOSE,ZBASE
      INTEGER NB,NXBODY
      REAL THETAB(23),XRB(605)
      COMMON/BDYBLK/RNOSE,RADIUS,RBASE,LNOSE,LBODY,LTAIL,ZNOSE,ZBASE,
     X NB,NXBODY,THETAB,XRB
*-----------------------------------------------------------------------
*
      IF (x .LT. lnose) THEN
        xx=x/lnose                     ! non-dimensional nose coordinate
        rr=radius-rnose
        z=znose*(1.0-xx)**2                         ! camber, all shapes
        dzdx=-2.*znose/lnose*xx
        IF (bcode .EQ. 0) THEN
          r=rnose+(radius-rnose)*Parabolic(xx)          ! parabolic nose
          rprime=(rr/lnose)*ParabolicSlope(xx)
        ELSEIF (bcode .EQ. 1) THEN
          r=rnose+(radius-rnose)*SearsHaack(xx)        ! SearsHaack nose
          rprime=(rr/lnose)*SearsHaackSlope(xx)
        ELSEIF (bcode .EQ. 2) THEN
          r=rnose+(radius-rnose)*VonKarmanOgive(xx)    ! VonKarman ogive
          rprime=(rr/lnose)*VonKarmanOgiveSlope(xx)
        ELSEIF (bcode .EQ. 3) THEN
          r=rnose+(radius-rnose)*Ellipsoid(xx)        ! ellipsoidal nose
          rprime=(rr/lnose)*EllipsoidSlope(xx)
        ELSE
          r=rnose+(radius-rnose)*xx                       ! conical nose
          rprime=rr/lnose
        ENDIF
      ELSEIF (x .GT. lbody-ltail) THEN
        XX=(lbody-x)/ltail                            ! afterbody region
        rr=radius-rbase
        z=zbase*(1.0-xx)**2                         ! camber, all shapes
        dzdx=2.*XX*zbase/ltail
        IF (bcode .EQ. 0) THEN
          r=rbase+(radius-rbase)*Parabolic(xx)          ! parabolic tail
          rprime=(-rr/ltail)*ParabolicSlope(xx)
        ELSEIF (bcode .EQ. 1) THEN
          r=rbase+(radius-rbase)*SearsHaack(xx)        ! SearsHaack tail
          rprime=(-rr/ltail)*SearsHaackSlope(xx)
        ELSEIF (bcode .EQ. 2) THEN
          r=rbase+(radius-rbase)*VonKarmanOgive(xx)    ! VonKarman ogive
          rprime=(-rr/ltail)*VonKarmanOgiveSlope(xx)
        ELSEIF (bcode .EQ. 3) THEN
          r=rbase+(radius-rbase)*Ellipsoid(xx)        ! ellipsoidal tail
          rprime=(-rr/ltail)*EllipsoidSlope(xx)
        ELSE
          r=rbase+(radius-rbase)*xx                       ! conical tail
          rprime=-rr/ltail
        ENDIF
      ELSE
        r=radius                                    ! cylindrical region
        rprime=0.0
        z=0.0
        dzdx=0.0
      ENDIF
      RETURN
      END   ! ---------------------------------- End of Subroutine BodyR


      SUBROUTINE EVAL(THICK,PER)
      IMPLICIT NONE
      LOGICAL THICK      
      REAL PER

      REAL DUMX(1200),UWP(200),ZDUM1(400)
      REAL UWT(200),VWT(200),WWT(200),A(200)
      REAL BTEST(200),VTEST(200),WTEST(200),DUMMY(7406)
      COMMON DUMX,UWP,ZDUM1,UWT,VWT,WWT,A,BTEST,VTEST,WTEST,DUMMY

      REAL MACH,MACHSQ,BETASQ,BETA,RNL
      COMMON/VEL/MACH,MACHSQ,BETASQ,BETA,RNL
      
      INTEGER NWING,NBODY,PANELS,OC
      REAL SREF,REFMOM,CBAR
      COMMON/PARAMS/NWING,NBODY,PANELS,SREF,REFMOM,CBAR,OC
      
      REAL XBARS(200),XCS(200),YC(200),ZC(200),AREA(200)
      REAL SINTH(200),COSTH(200),X(200,4),Y(200,2),Z(200,2)
      COMMON/PANEL/XBARS,XCS,YC,ZC,AREA,SINTH,COSTH,X,Y,Z
      
      DOUBLE PRECISION XPRIME,YPRIME,ZPRIME,U,V,W,B,BTERM,EPS,XPMT
      LOGICAL SUB,BPOS
      COMMON/COMPS/XPRIME,YPRIME,ZPRIME,U,V,W,B,BTERM,EPS,XPMT,SUB,BPOS

      REAL XCRNRS(200,4),YCRNRS(200,2),ZCRNRS(200,2)
      COMMON/CRNRS/XCRNRS,YCRNRS,ZCRNRS
      
      REAL XBAR(200),XC(200)
      REAL ANT(200),BNT(200)
      LOGICAL ASYM,B1NEG,B2NEG,DIAG,WING,TWING
      DOUBLE PRECISION AAVL,AAVLT,AAVR,AAVRT
      DOUBLE PRECISION AAWL,AAWLT,AAWR,AAWRT
      DOUBLE PRECISION ABN
      DOUBLE PRECISION B1,B2, BTERM1,BTERM2
      DOUBLE PRECISION COST,COSTL,COSTR
      DOUBLE PRECISION CR,CT
      DOUBLE PRECISION DELTAY,DELTAZ
      DOUBLE PRECISION DELY,DELZ
      INTEGER I,J
      DOUBLE PRECISION LE
      DOUBLE PRECISION SINT,SINTL,SINTR
      DOUBLE PRECISION SPN
      DOUBLE PRECISION STOTAL
      DOUBLE PRECISION TE
      DOUBLE PRECISION UCON,UT,UTCON,UU,VWCON,VWTCON
      DOUBLE PRECISION X1,X2,X3,X4
      DOUBLE PRECISION XBTERM
      DOUBLE PRECISION XW,XX,XY,XZ
      DOUBLE PRECISION Y1,Y2
      REAL YPER,YPER1
      DOUBLE PRECISION YP3,YP3N, YP4,YP4N
      DOUBLE PRECISION Z1,Z2
      DOUBLE PRECISION ZP3,ZP3N, ZP4,ZP4N
      

      DOUBLE PRECISION PI,PI1,PI2,PI4,PI8
      PARAMETER (PI=3.14159265)
      PARAMETER (PI1=1/PI, PI2=1/(2*PI), PI4=1/(4*PI), PI8=1/(8*PI))
      
      DATA ANT,BNT/400*0./
      AAVL=0.
      AAWL=0.
      AAVLT=0.
      AAWLT=0.
!!!      HYP=.FALSE.
      DO 4 J=1,4
      DO 4 I=1,PANELS
4     XCRNRS(I,J)=X(I,J)
      DO 6 J=1,2
      DO 6 I=1,PANELS
      YCRNRS(I,J)=Y(I,J)
6     ZCRNRS(I,J)=Z(I,J)
      REWIND 3

5     STOTAL=0.
      DO 10 I=1,PANELS
      CR=X(I,3)-X(I,1)
      DELY=Y(I,2)-Y(I,1)
      DELZ=Z(I,2)-Z(I,1)
      SPN=SQRT(DELY*DELY+DELZ*DELZ)
      CT=X(I,4)-X(I,2)
      AREA(I)=(CR+CT)*SPN/2.
      IF(I.GT.NBODY)STOTAL=STOTAL+AREA(I)
      YPER=(1.+CT/(CR+CT))/3.
      YPER1=1.-YPER
      LE=YPER*X(I,2)+YPER1*X(I,1)
      TE=YPER*X(I,4)+YPER1*X(I,3)
      XCS(I)=PER*TE + (1.0-PER)*LE
      XC(I)=XCS(I)/BETA
      XBARS(I)=(LE+TE)/2.
      XBAR(I)=XBARS(I)/BETA
      YC (I)=Y(I,1)*YPER1+Y(I,2)*YPER
      ZC (I)=Z(I,1)*YPER1+Z(I,2)*YPER
      SINTH (I)=DELZ/SPN
10    COSTH (I)=DELY/SPN
      STOTAL=STOTAL+STOTAL
      IF(OC.LE.1)GO TO 12
      CALL PAGE
      WRITE(6,1)(I,X(I,1),X(I,2),X(I,3),X(I,4),Y(I,1),Y(I,2),Z(I,1),
     X Z(I,2),I=1,PANELS)
1     FORMAT('PANEL CORNER POINTS',1X,'1-L.E.(LEFT)',1X,
     & '2-L.E.(RIGHT)',1X, '3-T.E.(LEFT)',1X, '4-T.E.(RIGHT)'/
     &  9X, 'X1', 7X, 'X2', 7X, 'X3', 7X, 'X4', 
     &  7X, 'Y1', 7X, 'Y2', 7X, 'Z1', 7X, 'Z2'/(I4,8F9.4))
      CALL PAGE
      WRITE(6,2)(I,XBARS(I),XCS(I),YC (I),ZC (I),AREA(I),
     X       SINTH(I),COSTH(I),I=1,PANELS)
2     FORMAT('SUMMARY OF PANEL CENTROIDS AND AREAS'/9X,'XBAR',6X,'XC',
     & 8X, 'YC', 8X, 'ZC', 8X, 'AREA  SIN(THETA) COS(THETA)'/
     X (I4,7F10.5))
      WRITE(6,3)STOTAL
3     FORMAT(' TOTAL EXPOSED WING AREA=',G15.6)
12    IF(SREF.LE.0.) SREF=STOTAL
      IF(CBAR.LE.0.) CBAR=SQRT(SREF)
!!!      IF(HYP)RETURN
      EPS=CBAR/10000.0
      IF (BETASQ.LE.0.) GO TO 8
      SUB=.TRUE.
      XBTERM=1.
      UCON=PI8
      UTCON=PI2/BETA
      VWCON=BETA*PI8
      VWTCON=PI2
      GO TO 9
8     SUB=.FALSE.
      XBTERM=-1.
      UCON=PI4
      UTCON=PI1/BETA
      VWCON=BETA*PI4
      VWTCON=PI1

9     DO 900 I=1,PANELS     ! begin big loop
!!!!!!!!!!!!!!!!      ASYM=.NOT.ISYM
      asym=.false.
      COST=COSTH(I)
      SINT=SINTH(I)
      WING=I.GT.NBODY
      TWING=THICK.AND.WING
      X1=X(I,1)/BETA
      X2=X(I,2)/BETA
      X3=X(I,3)/BETA
      X4=X(I,4)/BETA
      Y1=Y(I,1)
      Y2=Y(I,2)
      Z1=Z(I,1)
      Z2=Z(I,2)
      DELTAY=(Y2-Y1)*COST+(Z2-Z1)*SINT
      B1=(X2-X1)/DELTAY
      B2=(X4-X3)/DELTAY
      B1NEG=B1.LT.0.
      B2NEG=B2.LT.0.
      B1= ABS(B1)
      B2= ABS(B2)
      BTERM1= SQRT( ABS(B1*B1+XBTERM))
      BTERM2= SQRT( ABS(B2*B2+XBTERM))
      DO 850 J=1,PANELS
      DIAG=I.EQ.J.AND.WING
      XW=SINT*COSTH(J)
      XX=COST*SINTH(J)
      XY=COST*COSTH(J)
      XZ=SINT*SINTH(J)
      SINTR=XW-XX
      COSTR=XY+XZ
      SINTL=XW+XX
      COSTL=XY-XZ
      BPOS=.NOT.B1NEG
      B=B1
      BTERM=BTERM1
      DELTAY=YC(J)-Y1
      DELTAZ=ZC(J)-Z1
      XPRIME=XC(J)-X1
      YPRIME=DELTAY*COST+DELTAZ*SINT
      YP3=YPRIME
      IF(B1NEG)YPRIME=-YPRIME
      ZPRIME=DELTAZ*COST-DELTAY*SINT
      ZP3=ZPRIME
      CALL COMP
      AAVR=V
      AAWR=W
      IF(DIAG)GO TO 30
      UU=U
      GO TO 31
30    UU=0.
31    IF(.NOT.TWING)GO TO 40
      XPMT=XBAR(J)-X1
      CALL TCOMP
      UT=U
      IF(DIAG)GO TO 39
      AAVRT=V
      AAWRT=W
      GO TO 40
39    AAVRT=0.
      AAWRT=0.
      ABN=V
40    IF(ASYM)GO TO 50
      DELTAY=-YC(J)-Y1
      YPRIME=DELTAY*COST+DELTAZ*SINT
      YP3N=YPRIME
      IF(B1NEG)YPRIME=-YPRIME
      ZPRIME=DELTAZ*COST-DELTAY*SINT
      ZP3N=ZPRIME
      CALL COMP
      AAVL=V
      AAWL=W
      UU=UU+U
      IF(.NOT.TWING)GO TO 50
      CALL TCOMP
      UT=UT+U
      AAVLT=V
      AAWLT=W
50    DELTAY=YC(J)-Y2
      DELTAZ=ZC(J)-Z2
      XPRIME=XC(J)-X2
      YPRIME=DELTAY*COST+DELTAZ*SINT
      YP4=YPRIME
      IF(B1NEG)YPRIME=-YPRIME
      ZPRIME=DELTAZ*COST-DELTAY*SINT
      ZP4=ZPRIME
      CALL COMP
      AAVR=AAVR-V
      AAWR=AAWR-W
      IF(DIAG)GO TO 33
      UU=UU-U
33    IF(.NOT.TWING)GO TO 60
      XPMT=XBAR(J)-X2
      CALL TCOMP
      UT=UT-U
      IF(DIAG)GO TO 55
      AAVRT=AAVRT-V
      AAWRT=AAWRT-W
      GO TO 60
55    ABN=ABN-V
60    IF(ASYM) GO TO 70
      DELTAY=-YC(J)-Y2
      YPRIME=DELTAY*COST+DELTAZ*SINT
      YP4N=YPRIME
      IF(B1NEG)YPRIME=-YPRIME
      ZPRIME=DELTAZ*COST-DELTAY*SINT
      ZP4N=ZPRIME
      CALL COMP
      AAVL=AAVL-V
      AAWL=AAWL-W
      UU=UU-U
      IF(.NOT.TWING)GO TO 70
      CALL TCOMP
      UT=UT-U
      AAVLT=AAVLT-V
      AAWLT=AAWLT-W
70    BPOS=.NOT.B2NEG
      B=B2
      BTERM=BTERM2
      XPRIME=XC(J)-X3
      YPRIME=YP3
      IF(B2NEG)YPRIME=-YPRIME
      ZPRIME=ZP3
      CALL COMP
      AAVR=AAVR-V
      AAWR=AAWR-W
      IF(DIAG)GO TO 35
      UU=UU-U
35    IF(.NOT.TWING)GO TO 80
      XPMT=XBAR(J)-X3
      CALL TCOMP
      UT=UT-U
      IF(DIAG)GO TO 75
      AAVRT=AAVRT-V
      AAWRT=AAWRT-W
      GO TO 80
75    ABN=ABN-V
80    IF(ASYM) GO TO 90
      YPRIME=YP3N
      IF(B2NEG)YPRIME=-YPRIME
      ZPRIME=ZP3N
      CALL COMP
      AAVL=AAVL-V
      AAWL=AAWL-W
      UU=UU-U
      IF(.NOT.TWING)GO TO 90
      CALL TCOMP
      UT=UT-U
      AAVLT=AAVLT-V
      AAWLT=AAWLT-W
90    YPRIME=YP4
      XPRIME=XC(J)-X4
      IF(B2NEG)YPRIME=-YPRIME
      ZPRIME=ZP4
      CALL COMP
      AAVR=AAVR+V
      AAWR=AAWR+W
      IF(DIAG)GO TO 37
      UU=UU+U
37    IF(.NOT.TWING)GO TO 100
      XPMT=XBAR(J)-X4
      CALL TCOMP
      UT=UT+U
      IF(DIAG)GO TO 95
      AAVRT=AAVRT+V
      AAWRT=AAWRT+W
      GO TO 100
95    ABN=ABN+V
100   IF(ASYM) GO TO 110
      YPRIME=YP4N
      IF(B2NEG)YPRIME=-YPRIME
      ZPRIME=ZP4N
      CALL COMP
      AAVL=AAVL+V
      AAWL=AAWL+W
      UU=UU+U
      IF(.NOT.TWING)GO TO 110
      CALL TCOMP
      UT=UT+U
      AAVLT=AAVLT+V
      AAWLT=AAWLT+W
110   CONTINUE
      A(J)=(AAVR*SINTR+AAVL*SINTL+AAWR*COSTR+AAWL*COSTL)*VWCON
      BTEST(J)=(AAVR*COSTR-AAWR*SINTR-AAVL*COSTL+AAWL*SINTL)*VWCON
      VTEST(J)=BTEST(J)*COSTH(J)-A(J)*SINTH(J)
      WTEST(J)=A(J)*COSTH(J)+BTEST(J)*SINTH(J)
      UWP(J)=UU*UCON
      IF(.NOT.TWING)GO TO 840
      UWT(J)=UT*UTCON
      IF(DIAG)GO TO 115
      BNT(J)=(AAVRT*COSTR-AAWRT*SINTR-AAVLT*COSTL+AAWLT*SINTL)*VWTCON
      ANT(J)=(AAVRT*SINTR+AAVLT*SINTL+AAWRT*COSTR+AAWLT*COSTL)*VWTCON
      GO TO 850
115   BNT(J)=(ABN+AAWLT*SINTL-AAVLT*COSTL)*VWTCON
      ANT(J)=(AAVLT*SINTL+AAWLT*COSTL)*VWTCON
      GO TO 850
840   UWT(J)=0.
      VWT(J)=0.
      WWT(J)=0.
850   CONTINUE
      WRITE(3)(A(J),J=1,PANELS),(UWP(J),VTEST(J),WTEST(J),UWT(J),
     X   BNT(J),ANT(J),J=1,PANELS)
      IF(OC.LE.4)GO TO 900
      WRITE(6,904)I,(A(J),J=1,PANELS)
904   FORMAT(
     & 'NORMAL COMPONENT OF VELOCITY INDUCED BY DELTA-CP=1 ON PANEL',
     &  I4/(1X,5G13.5))
      WRITE(6,901)I,(UWP(J),J=1,PANELS)
901   FORMAT('X-COMPONENT OF VELOCITY INDUCED BY DELTA-CP=1 ON PANEL',
     X  I4/(1X,5G13.5))
      WRITE(6,905)I,(BTEST(J),J=1,PANELS)
905   FORMAT(
     & 'BINORMAL COMPONENT OF VELOCITY INDUCED BY DELTA-CP=1 ON PANEL',
     &  I4/(1X,5G13.5))
      IF(.NOT.TWING) GO TO 900
      WRITE(6,910)I,(UWT(J),J=1,PANELS)
910   FORMAT(
     & 'X-COMPONENT OF VELOCITY INDUCED BY ALPHA(THICKNESS)=1 ONPANEL',
     &  I4/(1X,5G13.5))
      WRITE(6,911)I,(BNT(J),J=1,PANELS)
911   FORMAT('BINORMAL COMPONENT OF VELOCITY INDUCED',
     & ' BY ALPHA(THICKNESS)=1 ON PANEL',I4/(1X,5G13.5))
      WRITE(6,912)I,(ANT(J),J=1,PANELS)
912   FORMAT('NORMAL COMPONENT OF VELOCITY INDUCED',
     & ' BY ALPHA(THICKNESS)=1 ON PANEL',I4/(1X,5G13.5))
900   CONTINUE
      REWIND 3
      IF(.NOT.THICK) WRITE(6,903)
903   FORMAT('WING THICKNESS MATRIX CALCULATION WAS SUPPRESSED')
      END

      SUBROUTINE COMP
      IMPLICIT NONE
      DOUBLE PRECISION X,Y,Z,U,V,W,B,BTERM,EPS,XT
      LOGICAL SUB,BPOS
      COMMON/COMPS/X,Y,Z,U,V,W,B,BTERM,EPS,XT,SUB,BPOS
      
      DOUBLE PRECISION A,AA,BR2,DR2,D, F2,F3,F6
      DOUBLE PRECISION X2,Y2,Z2,R2,R,RPRIME

      DOUBLE PRECISION PI,HALFPI,PI32,ZERO,ONE
      PARAMETER(PI=3.14159265)
      PARAMETER(HALFPI=PI/2, PI32=3*PI/2, ZERO=0, ONE=1)

      IF(SUB)GO TO 200
      IF(X .LE. ZERO) GO TO 350
      X2=X*X
      Y2=Y*Y
      IF(B .EQ. ZERO) GO TO 150
      IF (ABS(Z) .LT. EPS) GO TO 125
      Z2=Z*Z
      R2=Y2+Z2
      IF(B .GE. ONE) GO TO 120
      IF(X2.GT.R2)GO TO 116
      IF(Y.LE.B*X)GO TO 350
      A=X-B*Y
      IF(A .LE. ZERO) GO TO 350
      IF(A*A.LE.BTERM*BTERM*Z2)GO TO 350
      U=PI
      V=-B*U
      W=-BTERM*PI
      IF(Z .GT. ZERO) GO TO 300
      V=-V
      U=-U
      GO TO 300
116   D= SQRT(X2-Y2-Z2)
      DR2=D/R2
      U= ATAN2(Z*D,B*R2-X*Y)
      V=Z*DR2-B*U
      W=-BTERM* ATAN2(BTERM*D,B*X-Y)-B*LOG((X+D)/ SQRT(R2))-Y*DR2
      GO TO 300
120   IF(X2.LE.R2)GO TO 350
      D= SQRT(X2-R2)
      A=X-B*Y
      F2=LOG((B*X-Y+BTERM*D)/ SQRT(A*A+BTERM*BTERM*Z2))
      F3= ATAN2(Z*D,B*R2-X*Y)
      F6=D/R2
      U=F3
      V=Z*F6-B*F3
      W=BTERM*F2-Y*F6-B*LOG((X+D)/ SQRT(R2))
      GO TO 300
125   IF(B .GT. ONE) GO TO 140
      IF(Y.LE.EPS.OR.X.LT.B*Y)GO TO 350
      IF(X2.GT.Y2)GO TO 135
      U=PI
      V=-B*U
      W=-BTERM*PI
      GO TO 300
135   U=ZERO
      IF (Y .GT. ZERO) U=PI
      V=-B*U
      D= SQRT(X2-Y2)
      W=-BTERM* ATAN2(BTERM*D,B*X-Y)-B*LOG((X+D)/ ABS(Y))-D/Y
      GO TO 300
140   IF(X2.LE.Y2)GO TO 350
      D= SQRT(X2-Y2)
      R= ABS(Y)
      U=ZERO
      IF (Y.GT.ZERO .AND. B*Y.LT.X) U=PI
      V=-B*U
      W=BTERM*LOG((B*X-Y+BTERM*D)/ ABS(X-B*Y))-D/Y-B*LOG((X+D)/R)
      GO TO 300
150   IF( ABS(Z).LT.EPS)GO TO 175
      Z2=Z*Z
      R2=Y2+Z2
      IF (X2.GE.R2)GO TO 165
      IF (Y.LE.ZERO  .OR. X2.LE.Z2) GO TO 350
      U=PI
      V=ZERO
      W=-PI
      IF(Z .LT. ZERO) U=-PI
      GO TO 300
165   D= SQRT(X2-R2)
      A=Z*D
      U= ATAN2(A,-X*Y)
      V=A/R2
      W=- ATAN2(D,-Y)-Y*D/R2
      GO TO 300
175   IF(X2.GT.Y2)GO TO 190
      IF(Y.LT.EPS)GO TO 350
      W=-PI
      V=ZERO
      U=PI
      GO TO 300
190   U=ZERO
      IF (Y .GT. ZERO) U=PI
      V=ZERO
      D= SQRT(X2-Y2)
      W= -ATAN2(D,-Y)-D/Y
      GO TO 300
200   IF (B .EQ. ZERO) GO TO 250
      X2=X*X
      Y2=Y*Y
      IF( ABS(Z).LT.EPS)GO TO 225
      Z2=Z*Z
      R2=Y2+Z2
      BR2=B*R2
      D= SQRT(X2+R2)
      A=X-B*Y
      RPRIME= SQRT(A*A+BTERM*BTERM*Z2)
      F6=(X+D)/R2
      F2=LOG((B*X+Y+BTERM*D)/RPRIME)
      U= ATAN2(Z*D,BR2-X*Y)+ ATAN(Y/Z)
      V=Z*F6-B*U
      W=BTERM*F2-Y*F6-B*LOG((X+D)*RPRIME/BR2)
      GO TO 300
225   A=X-B*Y
      AA= ABS(A)
      D= SQRT(X2+Y2)
      F2=LOG((B*X+Y+BTERM*D)/AA)
      U=HALFPI
      IF (A .LE. ZERO) GO TO 235
      IF (Y .GE. ZERO) GO TO 230
      U=-HALFPI
      GO TO 235
230   U=PI32
235   V=-B*U
      W=BTERM*F2-(X+D)/Y-B*LOG((X+D)*AA/B/Y2)
      GO TO 300
250   IF( ABS(Z).LT.EPS)GO TO 275
      X2=X*X
      Y2=Y*Y
      Z2=Z*Z
      R2=Y2+Z2
      D= SQRT(X2+R2)
      U= ATAN2(Z*D,-X*Y)+ ATAN(Y/Z)
      F6=(X+D)/R2
      V=Z*F6
      W=LOG((Y+D)/ SQRT(X2+Z2))-Y*F6
      GO TO 300
275   D= SQRT(X*X+Y*Y)
      U=HALFPI
      IF(X.LE. ZERO) GO TO 285
      IF(Y.GE. ZERO) GO TO 280
      U=-HALFPI
      GO TO 285
280   U=PI32
285   V=ZERO
      W=LOG((Y+D)/ ABS(X))-(X+D)/Y
300   IF(BPOS)RETURN
      U=-U
      W=-W
      RETURN
350   U=ZERO
      V=ZERO
      W=ZERO
      RETURN
      ENTRY TCOMP
      IF(SUB)GO TO 400
      IF(XT.LE. ZERO) GO TO 350
      X2=XT*XT
      Y2=Y*Y
      IF( ABS(Z).LT.EPS) GO TO 525
      Z2=Z*Z
      R2=Y2+Z2
      IF (B .GT. ONE) GO TO 520
      IF(X2.GT.R2) GO TO 516
      IF(Y.LE.B*XT)GO TO 350
      A=XT-B*Y
      IF(A.LE. ZERO) GO TO 350
      IF(A*A.LE.BTERM*BTERM*Z2) GO TO 350
      U=-PI/BTERM
      V=-B*U
      W=PI
      IF(Z.LT. ZERO) W=-W
      GO TO 300
516   D= SQRT(X2-R2)
      U=- ATAN2(BTERM*D,B*XT-Y)/BTERM
      V=-B*U-LOG((XT+D)/ SQRT(R2))
      W= ATAN2(Z*D,B*R2-XT*Y)
      GO TO 300
520   IF(X2.LE.R2) GO TO 350
      D= SQRT(X2-R2)
      A=XT-B*Y
      F2=LOG((B*XT-Y+BTERM*D)/ SQRT(A*A+BTERM*BTERM*Z2))/BTERM
      W= ATAN2(Z*D,B*R2-XT*Y)
      U=-F2
      V=B*F2-LOG((XT+D)/ SQRT(R2))
      GO TO 300
525   IF (B .GT. ONE) GO TO 560
      IF(X2.GT.Y2)GO TO 550
      IF(Y.LE.EPS.OR.XT.LE.B*Y)GO TO 350
      U=-PI/BTERM
      V=-B*U
      W=PI
      GO TO 300
550   D= SQRT(X2-Y2)
      U=- ATAN2(BTERM*D,B*XT-Y)/BTERM
      V=-B*U-LOG((XT+D)/ ABS(Y))
      W=ZERO
      IF(Y.GT.ZERO  .AND. XT.GT.B*Y) W=PI
      GO TO 300
560   IF(X2.LE.Y2)GO TO 350
      D= SQRT(X2-Y2)
      F2=LOG((B*XT-Y+BTERM*D)/ ABS(XT-B*Y))/BTERM
      W=ZERO
      IF(Y.GT.ZERO  .AND.XT.GT.B*Y)W=PI
      U=-F2
      V=B*F2-LOG((XT+D)/ ABS(Y))
      GO TO 300
400   X2=XT*XT
      Y2=Y*Y
      A=XT-B*Y
      IF( ABS(Z).LT.EPS) GO TO 425
      Z2=Z*Z
      R2=Y2+Z2
      R= SQRT(R2)
      D= SQRT(X2+R2)
      RPRIME= SQRT(A*A+BTERM*BTERM*Z2)
      F2=LOG((B*XT+Y+BTERM*D)/RPRIME)/BTERM
      U=-F2
      V=B*F2-LOG((XT+D)/R)
      W= ATAN2(Z*D,B*R2-XT*Y)
      GO TO 300
425   D= SQRT(X2+Y2)
      AA=(B*XT+Y+BTERM*D)/ ABS(A)
      IF(AA.LE.ZERO) GO TO 350
      F2=LOG(AA)/BTERM
      W=ZERO
      IF(A*Y.GT. ZERO) W=PI
      U=-F2
      V=B*F2-LOG((XT+D)/ ABS(Y))
      GO TO 300
      END

      SUBROUTINE REDUCE(OPT,NW,NB,N1,N2,AW,AB,AN1,AN2)
C     SUBROUTINE TO COMPUTE THE REDUCED AERODYNAMIC MATRICES AND THE
C        AUXILIARY MATRICES D AND E. ALSO COMPUTES THE DRAG MINIMIZATION
C        MATRICES. THIS INFORMATION IS PLACED ON DATA SET 7.
      REAL AW(NW,*),AB(NB,*),AN1(N1,*),AN2(N2,*)
      INTEGER OPT
      COMMON/PANEL/XBAR(200),XC(200),YC(200),ZC(200),AREA(200),
     & SINTH(200),COSTH(200), XP(200,4),YP(200,2),ZP(200,2)
      INTEGER NWING,NBODY,PANELS,OC
      REAL SREF,REFMOM,CBAR
      COMMON/PARAMS/NWING,NBODY,PANELS,SREF,REFMOM,CBAR,OC
      COMMON/PSINGS/PW(100),PB(100),ALPHAT(100)
      COMMON/OPTARR/AWT(100),R   (100),S(100),T(100) ,F(100),CLBWT
      COMMON       A(102,102),E(102),B(100)
      REAL DMMY(3000),UWT(200),VWT(200),WWT(200)
      EQUIVALENCE (A(1,1),DMMY(1)),(DMMY(1709),UWT(1)),(DMMY(1909),
     X  VWT(1)),(DMMY(2109),WWT(1))
      REWIND 7
      REWIND 8
      REWIND 3
C     CALL SETTIM(1,0)
      IF(NBODY.EQ.0)GO TO 115
      DO 1 I=1,100
        PB(I)=0.
        PW(I)=0.
    1 CONTINUE
950   CALL VELCOM
*
C         READ AWB FROM 3 INTO A AND WRITE ON 7 BY ROWS
      DO 10 J=1,NBODY
        READ(3)(E(I),I=1,NBODY),(A(I,J),I=1,NWING)
   10 CONTINUE
      DO 15 I=1,NWING
        WRITE(7)(A(I,J),J=1,NBODY)
   15 CONTINUE
      REWIND 3
C     NOW READ ABB INTO CORE FROM 3
      DO 20 J=1,NBODY
        READ(3)(AB(I,J),I=1,NBODY)
   20 CONTINUE
*
C     NOW INVERT ABB
      CALL INVERT(AB,NBODY)
      REWIND 7
C     NOW COMPUTE R=ABB-INVERSE*ALPHAY   (solve ABB*R=alphay)
      CLBWT=0.
      DO 25 I=1,NBODY
        XX=0.0
        DO 26 J=1,NBODY
          XX=XX+AB(I,J)*AWT(J)
   26   CONTINUE
        R(I)=-XX
        CLBWT=CLBWT+XX*AREA(I)*COSTH(I)
   25 CONTINUE
      CLBWT=2.0*CLBWT/SREF
*
C     NOW COMPUTE D=AWB*(ABB-INVERSE) AND S=D*AWT   . STORE D ON 8 BY RO
      DO 30 I=1,NWING
        READ(7)(E(J),J=1,NBODY)
        XX=0.
        DO 31 J=1,NBODY
          XY=0.
          DO 32 K=1,NBODY
            XY=XY+E(K)*AB(K,J)
   32     CONTINUE
          XX=XX+XY*AWT(J)
          B(J)=XY
   31   CONTINUE
        S(I)=XX
        WRITE(8)(B(J),J=1,NBODY)
   30 CONTINUE
*
C         THIS IS ROW I OF D=AWB*(ABB-INVERSE)
      REWIND 7
C         NOW COMPUTE E=-(ABB-INVERSE)*ABW BY COLUMNS
C         AT THE SAME TIME COMPUTE F
C         DATASET 3 IS POSITIONED AT THE END OF RECORD NO. NBODY
      DO 80 J=1,NWING
        READ(3)(E(I),I=1,NBODY)   !      THIS IS COLUMN J OF ABW
        XX=0.
        DO 81 I=1,NBODY
          XY=0.0
          DO 82 K=1,NBODY
            XY=XY-AB(I,K)*E(K)
   82     CONTINUE
          XX=XX+XY*AREA(I)*COSTH(I)
          B(I)=XY
   81   CONTINUE
        F(J)=XX
        WRITE(8)(B(I),I=1,NBODY)
   80 CONTINUE
*
      REWIND 8
C     NOW TO COMPUTE THE REDUCED AERODYNAMIC MATRIX A=AWW-D*ABW
C     FIRST RELOAD D INTO A FROM DATA SET 8 (FIRST NWING RECORDS)
      DO 90 I=1,NWING
90    READ(8)(A(I,J),J=1,NBODY)
C     NOW ADVANCE DATA SET 3 TO THE END OF RECORD NO.NBODY
      REWIND 3
      DO 100 I=1,NBODY
        READ(3)
  100 CONTINUE
C     NOW COMPUTE A AND WRITE ON DATA SET 7 (BY COLUMNS)
      DO 110 J=1,NWING
        READ(3)(B(I),I=1,NBODY),(E(I),I=1,NWING)
        DO 112 I=1,NWING
          XX=E(I)
          DO 111 K=1,NBODY
            XX=XX-A(I,K)*B(K)
  111     CONTINUE
          E(I)=XX
  112   CONTINUE
        IF(OC.GT.5)WRITE(6,401)J,(E(I),I=1,NWING)
401   FORMAT('COLUMN',I4,'  OF REDUCED AERO MATRIX'/(1X,5F13.6))
        WRITE(7)(E(I),I=1,NWING)
  110 CONTINUE
      REWIND 7
      GO TO 119
C     NEXT STATEMENTS ARE SPECIAL CASES FOR THE WING-ALONE PROBLEM
115   DO 116 J=1,NWING
        READ(3) (AW(I,J),I=1,NWING)
        F(J)=0.
        S(J)=0.
        T(J)=0.
        IF(OC.GT.5)WRITE(6,401)J,(AW(I,J),I=1,NWING)
        WRITE(7)(AW(I,J),I=1,NWING)
  116 CONTINUE
      write(6,*) 'calling invert, nw, nwing  ', nw, nwing
      GO TO 122
119   DO 120 J=1,NWING
        READ(7)(AW(I,J),I=1,NWING)
  120 CONTINUE
      REWIND 7
      DO 121 J=1,NWING
        WRITE(7)(AW(I,J),I=1,NWING)
  121 CONTINUE
C   THIS MAY SEEM UNNECCESARY TO WRITE THE INFO ON THE DATA SET AGAIN
C   BUT WHEN USING BLOCKED RECORDS IT CAUSES TROUBLE TO ATTEMPT TO
C    WRITE AFTER READING ONLY A PORTION OF A BLOCK
122   CALL INVERT(AW,NWING)
      DO 125 J=1,NWING
        IF(OC.GT.5)WRITE(6,402)J,(AW(I,J),I=1,NWING)
402   FORMAT('COLUMN',I4,'  OF INVERSE AERO MATRIX'/(1X,5F13.6))
        WRITE(7)(AW(I,J),I=1,NWING)
  125 CONTINUE
      IF(NBODY.GT.0)GO TO 131
      REWIND 7
      GO TO 137
C         NOW TRANSFER MATRIX E FROM DATA SET 8 TO DATA SET 7
C         DATA SET 8 SHOULD BE PROPERLY POSITIONED
131   DO 130 J=1,NWING
      READ(8)(E(I),I=1,NBODY)
130   WRITE(7)(E(I),I=1,NBODY)
      REWIND 7
C         COMPUTE T=(A-INVERSE)*S
      DO 135 I=1,NWING
      XX=0.
      DO 136 J=1,NWING
136   XX=XX+AW(I,J)*S(J)
135   T(I)=XX
137   CONTINUE
165   REWIND 3
*
      IF (OC.GT.5) WRITE(6,403) (AWT(I),I=1,100)
      IF (OC.GT.5) WRITE(6,404) (R(I),I=1,100)
      IF (OC.GT.5) WRITE(6,405) (S(I),I=1,100)
      IF (OC.GT.5) WRITE(6,406) (T(I),I=1,100)
  403 FORMAT('AWT-VECTOR'/(5F12.5))
  404 FORMAT('R-VECTOR'/(5F12.5))
  405 FORMAT('S-VECTOR'/(5F12.5))
  406 FORMAT('T-VECTOR'/(5F12.5))
      IF(OPT.EQ.0)RETURN
C     NOW PREPARE THE MATRICES REQUIRED FOR THE DRAG MINIMIZATION
C     READ REDUCED AERO MATRIX INTO AN1
      REWIND 8
      DO 160 J=1,NWING
160   READ(7)(AN1(I,J),I=1,NWING)
      DO 180 I=1,NWING
      I1=I+NBODY
      XX=AREA(I1)
      AN1(I,N1)=-XX*COSTH(I1)-F(I)
      AN1(N1,I)=AN1(I,N1)
      DO 180 J=1,I
      J1=J+NBODY
      AN1(I,J)=AN1(I,J)*XX+AN1(J,I)*AREA(J1)
180   AN1(J,I)=AN1(I,J)
      AN1(N1,N1)=0.
      CALL INVERT(AN1,N1)
      DO 185 J=1,N1
185   WRITE(8)(AN1(I,J),I=1,N1)
C         NOW THE DRAG MINIMIZATION MATRIX FOR MOMENT CONSTRAINT MUST
C         BE COMPUTED
C                   (LATER)
!!!      IF(OC.GT.0)WRITE(6,976)NCPU
!!!      RETURN
!!!975   FORMAT('TIME TO COMPUTE REDUCED  AERO. MATRIX=',I5, ' SEC.')
!!!976   FORMAT('TIME TO COMPUTE MINIMIZATION MATRICES=',I5, ' SEC.')
      END   ! --------------------------------- End of Subroutine Reduce

      SUBROUTINE KMSET(XNOSE)
      INTEGER NWING,NBODY,PANELS,OC
      REAL SREF,REFMOM,CBAR
      COMMON/PARAMS/NWING,NBODY,PANELS,SREF,REFMOM,CBAR,OC
      
      REAL RNOSE,RADIUS,RBASE,LNOSE,LBODY,LTAIL,ZNOSE,ZBASE
      COMMON/BDYBLK/RNOSE,RADIUS,RBASE,LNOSE,LBODY,LTAIL,ZNOSE,ZBASE,
     X NB,NXBODY,THETAB(23),
     X XBODY(101),RBODY(101),RPBODY(101),ZBODY(101),DRDX(100),DZDX(101)

      DOUBLE PRECISION XFIELD,RFIELD,BSQ,X2,D2SQ,U,V,VT
      COMMON/SRCE/XFIELD,RFIELD,BSQ,X2,D2SQ,U,V,VT

      COMMON/PANEL/XBAR(200),XC(200),YC(200),ZC(200),AREA(200),
     & SINTH(200),COSTH(200), XP(200,4),YP(200,2),ZP(200,2)
      COMMON UBS(101),VBS(101),UBD(101),VBD(101),VTBD(101),
     1UBC(101),VBC(101),VTBC(101),UWBS(100),VWBS(100),WWBS(100),
     2UWBD(100),VWBD(100),WWBD(100),UWBC(100),VWBC(100),WWBC(100),
     3UWT(200),VWT(200),WWT(200),UWBT(100),VWBT(100),WWBT(100),
     4ALPHAX(100),UB(200),VB(200),WB(200),UW(200),VW(200),WW(200)

      REAL MACH,MACHSQ,BETASQ,BETA,RNL
      COMMON/VEL/MACH,MACHSQ,BETASQ,BETA,RNL

      COMMON/BSINGS/T(100),TC(100),TCC(100),TX(101)
      REAL A(100,100), AFILL(10606)
      INTEGER IP(100)
      LOGICAL cambered
      EQUIVALENCE(A(1,1),UBS(1),AFILL(1))
*
      IF(NB.LE.0 .OR. NXBODY.LE.0) RETURN

      N=NXBODY-1
      
      DO 10 I=1,NXBODY
        TX(I)=XBODY(I)
        IF(MACH .GT. 1.0) TX(I)=TX(I)-BETA*RBODY(I)
   10 CONTINUE
*
*..... DETERMINATION OF SOURCE STRENGTHS ...............................
200   DO 210 I=1,NXBODY-1
      XFIELD=(XBODY(I+1)+XBODY(I))/2.
      RFIELD=(RBODY(I+1)+RBODY(I))/2.
      SLOPE=DRDX(I)
      BSQ=BETASQ*RFIELD*RFIELD
      X2=XFIELD-XBODY(NXBODY)
      D2SQ=X2*X2+BSQ
      T(I)=DRDX(I)
      DO 211 J=1,N
      CALL SOURCE(J)
      A(I,J)=V-SLOPE*U
  211 CONTINUE
  210 CONTINUE
      CALL DECOMP(N,A,IP,100)
      CALL SOLVE(N,A,IP,T,100)
      WRITE(*,*) 'Source strengths computed.'
*
*..... DETERMINATION OF DOUBLET STRENGTHS...............................
      cambered=.FALSE.
      DO i=1,nxbody-1
        IF (dzdx(i) .NE. 0.0) cambered=.TRUE.
      ENDDO
      DO 215 I=1,N
        XFIELD=(XBODY(I+1)+XBODY(I))/2.
        RFIELD=(RBODY(I+1)+RBODY(I))/2.
        SLOPE=DRDX(I)
        BSQ=BETASQ*RFIELD*RFIELD
        X2=XFIELD-XBODY(NXBODY)
        D2SQ=X2*X2+BSQ
        TC(I)=1.
        TCC(I)=DZDX(I)
        DO 216 J=1,N
          CALL DOUBLT(J)
          A(I,J)=SLOPE*U-V
  216   CONTINUE
  215 CONTINUE
      CALL DECOMP(N,A,IP,100)
      CALL SOLVE(N,A,IP,TC,100)
      CALL SOLVE(N,A,IP,TCC,100)
      WRITE(*,*) 'Normalized doublet strengths computed.'
      
*
*..... PRINT OUT OF BODY CHARACTERISTICS
*      Modified to fit screen   17Jul95   RLC
*
      IF (OC .GT. 1) THEN
        WRITE(6,799)MACH
799   FORMAT(///'SINGULARITY STRENGTHS REPRESENTING THE BODY AT MACH=',
     & F7.4/9X,'TX',5X,'SOURCE',6X, 'R*DR/DX',
     & 5X, 'DOUBLET', 5X, 'R*R/2', 6X, 'CAMBER')
        DO 800 I=1,NXBODY
          SUM1=0.
          SUM2=0.
          SUM3=0.
          DO 802 J=1,N
            XX=XBODY(I)-TX(J)
            IF(XX.LE.0.)GO TO 803
            SUM1=SUM1+XX*T(J)
            SUM2=SUM2+XX*TC(J)
            SUM3=SUM3+XX*TCC(J)
  802     CONTINUE
803       XX=RBODY(I)*RPBODY(I)
          XY=RBODY(I)*RBODY(I)/2.
          WRITE(6,801) I, TX(I), SUM1,XX,SUM2,XY,SUM3
  800   CONTINUE
801   FORMAT(I4,F9.4,5G12.5)
        WRITE(6,*) 'DOUBLET STRENGTH IS AT ALPHA=1 RADIAN'
      ENDIF
C
C     VELOCITIES INDUCED ON BODY BY BODY SOURCES & DOUBLETS
      DO 225 I=1,NXBODY
        XFIELD=XBODY(I)
        RFIELD=RBODY(I)
        IF (RFIELD .GT. 0.0) GO TO 214
C  IF THE FIELD POINT IS ON THE AXIS, THEN WE SHIFT OUT TO AVOID THE
C   SINGULARITY IN THE VELOCITY FUNCTION ON THE AXIS.
        IF(I.EQ.NXBODY)GO TO 221
        RFIELD=RBODY(I+1)/10.
        XFIELD=XFIELD+(XBODY(I+1)-XBODY(I))/10.
        GO TO 214
221     RFIELD=RBODY(I-1)/10.
        XFIELD=XFIELD-(XBODY(I)-XBODY(I-1))/10.
214     BSQ=BETASQ*RFIELD*RFIELD
        X2=XFIELD-XBODY(NXBODY)
        D2SQ=X2*X2+BSQ
        US=0.0
        VS=0.0
        UD=0.0
        VD=0.0
        VTD=0.0
        UC=0.0
        VC=0.0
        VTC=0.0
        DO 218 J=1,N
          CALL SOURCE(J)
          US=US+T(J)*U
          VS=VS+T(J)*V
          CALL DOUBLT(J)
          UC=UC+U*TCC(J)
          VC=VC+V*TCC(J)
          VTC=VTC-VT*TCC(J)
          UD=UD+U*TC(J)
          VD=VD+V*TC(J)
          VTD=VTD-VT*TC(J)
  218   CONTINUE
        UBS(I)=US
        VBS(I)=VS
        UBD(I)=UD
        VBD(I)=VD
        VTBD(I)=VTD
        UBC(I)=UC
        VBC(I)=VC
        VTBC(I)=VTC
  225 CONTINUE

        IF(OC.LE.2)GO TO 226
*
*..... Print the velocities
*      Revised to fit screen   17Jul95   RLC
      CALL PAGE
      WRITE(6,*) 'VELOCITIES INDUCED BY LINE SINGULARITIES',
     & '     MACH=', MACH
!!!      WRITE(6,227)MACH
!!!227   FORMAT(5X,
!!!&'VELOCITIES INDUCED ON BODY BY BODY LINE SINGULARITIES AT MACH=',
!!!     & F7.4//10X,'BODY SOURCES',20X,'BODY DOUBLETS',20X,'BODY CAMBER'/
!!!     & 40X,'(ALPHA=1 RADIAN)'/ 9X,'X', 7X,'U',10X,'V',11X,'U',
!!!     X 10X,'V', 9X,'VT', 9X,'U',10X,'V',10X,'VT')
!!!      DO 5 I=1,NXBODY
!!!5     WRITE(6,6) I,XBODY(I),UBS(I),VBS(I),UBD(I),VBD(I),VTBD(I),
!!!     X  UBC(I),VBC(I),VTBC(I)
!!!6     FORMAT(I4,F9.4,10G7.3)
*
      WRITE(6,*) 'VELOCITIES INDUCED ON BODY BY LINE SOURCES'
      WRITE(6,*) '   i       x           u          v'
      WRITE(6,'(I4,3F12.6)' ) (I,XBODY(I),UBS(I),VBS(I),I=1,NXBODY)
*
      WRITE(6,*) 'VELOCITIES INDUCED ON BODY BY LINE DOUBLETS'
      WRITE(6,*) '   i       x           u          v          vt'
      WRITE(6,'(I4,4F12.6)' )
     &   (I,XBODY(I), UBD(I),VBD(I),VTBD(I),I=1,NXBODY)
*
      IF (cambered) THEN
        WRITE(6,*) 'VELOCITIES INDUCED ON BODY BY BODY CAMBER'
        WRITE(6,*) '   i       x           u          v          vt'
        WRITE(6,'(I4,4F12.6)' )
     &     (I,XBODY(I), UBC(I),VBC(I),VTBC(I),I=1,NXBODY)
      ELSE
        WRITE(6,*) 'NO VELOCITIES INDUCED BY BODY CAMBER'
      ENDIF


C     VELOCITIES INDUCED ON WING BY BODY LINE SINGULARITIES
226   IF(NWING.LE.0)RETURN
      DO 240 J=1,NWING
      I=J+NBODY
      US=0.0
      VS=0.0
      UD=0.0
      VD=0.0
      VTD=0.0
      UC=0.0
      VC=0.0
      VTC=0.0
      DELY=YC(I)
      DELZ=ZC(I)
      IF(DELZ.EQ.0.)GO TO 241
      RFIELD=SQRT(DELY*DELY+DELZ*DELZ)
      COSTHA=DELZ/RFIELD
      SINTHA=DELY/RFIELD
      GO TO 245
241   RFIELD=DELY
      COSTHA=0.
      SINTHA=1.
245   XFIELD=XC(I)-XNOSE
      BSQ=BETASQ*RFIELD*RFIELD
      X2=XFIELD-XBODY(NXBODY)
      D2SQ=X2*X2+BSQ
      DO 248 K=1,N
      CALL SOURCE(K)
      US=US+U*T(K)
      VS=VS+V*T(K)
      CALL DOUBLT(K)
      UC=UC+U*TCC(K)
      VC=VC+V*TCC(K)
      VTC=VTC+VT*TCC(K)
      UD=UD+U*TC(K)
      VD=VD+V*TC(K)
248   VTD=VTD+VT*TC(K)
      UD=UD*COSTHA
      VD=VD*COSTHA
      VTD=VTD*SINTHA
      UC=UC*COSTHA
      VC=VC*COSTHA
      VTC=VTC*SINTHA
      UWBS(J)=US
      VWBS(J)=VS*SINTHA
      WWBS(J)=VS*COSTHA
      UWBD(J)=UD
      VWBD(J)=VD*SINTHA-VTD*COSTHA
      WWBD(J)=VD*COSTHA+VTD*SINTHA
      UWBC(J)=UC
      VWBC(J)=VC*SINTHA-VTC*COSTHA
240   WWBC(J)=VC*COSTHA+VTC*SINTHA
250   IF(OC.LE.2)RETURN
*
*..... Print velocities induced on wing ................................
*      Revised to fit screen   17Jul95   RLC
      CALL PAGE
      WRITE(6,256)MACH
256   FORMAT(/5X,
     & 'VELOCITIES INDUCED ON WING PANELS BY BODY LINE SINGULARITIES',
     & ' AT MACH=',F7.4//10X,'BODY SOURCES',15X,'BODY DOUBLETS',
     2 15X,'BODY CAMBER'/40X,'(ALPHA=1 RADIAN)'/10X,'U',10X,'V',10X,'W',
     X   10X,'U',10X,'V',10X,'W',10X,'U',10X,'V',10X,'W')
!!!      DO 255 I=1,NWING
!!!255   WRITE(6,7)I,UWBS(I),VWBS(I),WWBS(I),UWBD(I),VWBD(I),WWBD(I),
!!!   X   UWBC(I),VWBC(I),WWBC(I)
      WRITE(6,*) 'VELOCITIES INDUCED ON WING PANELS BY LINE SOURCES'
      WRITE(6,*) '  i         u           v           w'
      WRITE(6,'(I4,3F12.6)' ) (I,UWBS(I),VWBS(I),WWBS(I),I=1,NWING)
      WRITE(6,*) 'VELOCITIES INDUCED ON WING PANELS BY LINE DOUBLETS'
      WRITE(6,*) '  i         u           v           w'
      WRITE(6,'(I4,3F12.6)' ) (I,UWBD(I),VWBD(I),WWBD(I),I=1,NWING)
      WRITE(6,*) 'VELOCITIES INDUCED ON WING PANELS BY BODY CAMBER'
      WRITE(6,*) '  i         u           v           w'
      WRITE(6,'(I4,3F12.6)' ) (I,UWBC(I),VWBC(I),WWBC(I),I=1,NWING)
7     FORMAT(I4,1P9E8.3E1)
      END

      SUBROUTINE SOURCE(J)
      INTEGER J

      DOUBLE PRECISION X1,XL,D1SQ,BR,D1,D2

      REAL RNOSE,RADIUS,RBASE,LNOSE,LBODY,LTAIL,ZNOSE,ZBASE
      INTEGER NB,NXBODY
      COMMON/BDYBLK/RNOSE,RADIUS,RBASE,LNOSE,LBODY,LTAIL,ZNOSE,ZBASE,
     X NB,NXBODY,THETAB(23),
     X XBODY(101),RBODY(101),RPBODY(101),ZBODY(101),DRDX(100),DZDX(101)
      COMMON/BSINGS/T(100),TC(100),TCC(100),TX(101)
      
      DOUBLE PRECISION XFIELD,RFIELD,BSQ,X2,D2SQ,U,V,VT
      COMMON/SRCE/XFIELD,RFIELD,BSQ,X2,D2SQ,U,V,VT
      
      REAL MACH,MACHSQ,BETASQ,BETA,RNL
      COMMON/VEL/MACH,MACHSQ,BETASQ,BETA,RNL
      
C  UPON ENTRY TO EITHER SUBROUTINE SOURCE OR DOUBLT, THE QUANTITIES 
C  XFIELD,RFIELD,BSQ,X2, AND D2SQ MUST BE ENTERED IN /SRCE/.   
C  UPON EXIT, THE QUANTITIES U,V, AND VT ARE UPDATED IN /SRCE/

      XL=XBODY(NXBODY)-TX(J)
      X1=XFIELD-TX(J)
      D1SQ=X1*X1+BSQ
      IF(BETASQ)12,9,9
12    BR=BETA*RFIELD
      IF(X1.LE.BR) GO TO 10
      IF(X2.LE.BR)GO TO 11
9     D1=SQRT(D1SQ)
      D2=SQRT(D2SQ)
      U=LOG((X2+D2)/(X1+D1))+XL/D2
      V=(D1-(D1SQ-X1*XL)/D2)/RFIELD
      RETURN
11    XL=X1/BR
      D23=SQRT(XL*XL-1.0)
      U=-LOG(XL+D23)
      V=BETA*D23
      RETURN
10    U=0.0
      V=0.0
      RETURN
      END

      SUBROUTINE DOUBLT(J)
      INTEGER J

      DOUBLE PRECISION ZERO
      PARAMETER(ZERO=0.0)

      DOUBLE PRECISION X1,XL,RSQ,D1SQ,BR,D1,D2,XLD23,X1D1,X2D2

      REAL RNOSE,RADIUS,RBASE,LNOSE,LBODY,LTAIL,ZNOSE,ZBASE
      INTEGER NB,NXBODY
      COMMON/BDYBLK/RNOSE,RADIUS,RBASE,LNOSE,LBODY,LTAIL,ZNOSE,ZBASE,
     X NB,NXBODY,THETAB(23),
     X XBODY(101),RBODY(101),RPBODY(101),ZBODY(101),DRDX(100),DZDX(101)

      COMMON/BSINGS/T(100),TC(100),TCC(100),TX(101)

      DOUBLE PRECISION XFIELD,RFIELD,BSQ,X2,D2SQ,U,V,VT
      COMMON/SRCE/XFIELD,RFIELD,BSQ,X2,D2SQ,U,V,VT
      
      REAL MACH,MACHSQ,BETASQ,BETA,RNL
      COMMON/VEL/MACH,MACHSQ,BETASQ,BETA,RNL
      
      XL=XBODY(NXBODY)-TX(J)
      X1=XFIELD-TX(J)
      IF(BETASQ)23,22,22
23    BR=BETA*RFIELD
      BRTEST=1.0010*BR
      IF(X1.LE.BRTEST)GO TO 40
      IF(X2.LE.BRTEST)GO TO 21
22    D1SQ=X1*X1+BSQ
      D1=SQRT(D1SQ)
      RSQ=RFIELD*RFIELD
      D2=SQRT(D2SQ)
      XLD23=XL/(D2*D2*D2)
      X1D1=X1/D1
      X2D2=X2/D2
      U=(X1D1-X2D2-BSQ*XLD23)/RFIELD
      V=(X2*X2D2-X1*X1D1+X2*XLD23*(X2*X2+2.0*BSQ))/RSQ
      VT=(D1-D2-XL*X2D2)/RSQ
      IF(BETASQ)25,30,30
21    D1SQ=X1*X1+BSQ
      D1=SQRT(D1SQ)
      RSQ=RFIELD*RFIELD
      U=X1/(RFIELD*D1)
      V=-X1*X1/(RSQ*D1)
      VT=D1/RSQ
25    U=U*2.0
      V=V*2.0
      VT=VT*2.0
30    RETURN
40    U=ZERO
      V=ZERO
      VT=ZERO
      RETURN
      END

      SUBROUTINE KARMOR(ICP,ANGLE,BBCZ,BBCX,BBCM)
C CALLED BY SUBROUTINE FORCES
      
      REAL RNOSE,RADIUS,RBASE,LNOSE,LBODY,LTAIL,ZNOSE,ZBASE
      COMMON/BDYBLK/RNOSE,RADIUS,RBASE,LNOSE,LBODY,LTAIL,ZNOSE,ZBASE,
     X NB,NXBODY,THETAB(23),
     X XBODY(101),RBODY(101),RPBODY(101),ZBODY(101),DRDX(100),DZDX(101)
      
      INTEGER NWING,NBODY,PANELS,OC
      REAL SREF,REFMOM,CBAR
      COMMON/PARAMS/NWING,NBODY,PANELS,SREF,REFMOM,CBAR,OC
      
      COMMON/PANEL/XBAR(200),XC(200),YC(200),ZC(200),AREA(200),
     & SINTH(200),COSTH(200),XP(200,4),YP(200,2),ZP(200,2)
      
C..... blank common allocation      
      COMMON   UBS(101),VBS(101),UBD(101),VBD(101),VTBD(101),
     1 UBC(101),VBC(101),VTBC(101),  UWBS(100),VWBS(100),WWBS(100),
     2 UWBD(100),VWBD(100),WWBD(100),UWBC(100),VWBC(100),WWBC(100),
     3 UWT(200),VWT(200),WWT(200),UWBT(100),VWBT(100),WWBT(100),
     4 ALPHAX(100),UB(200),VB(200),WB(200),UW(200),VW(200),WW(200),
     5 U(101,12),V(101,12),W(101,12),CPBB(101,12)
      REAL AFILL(10606)
      EQUIVALENCE(UBS(1),AFILL(1))
      INTEGER I,J
*
      IF (NB.EQ.0) GO TO 888
C     COMPUTE VELOCITY COMPONENTS ON BODY DUE TO BODY LINE SINGULARITIES
      NN=MIN(NB+NB+2, 12)
      USINA=SIN(ANGLE)
      DO 10 J=1,NN
        S=SIN(THETAB(J))
        C=COS(THETAB(J))
        DO 11 I=1,NXBODY
          VR=VBS(I)+(VBD(I)*ANGLE+VBC(I))*C  +USINA*C
          VT=(VTBD(I)*ANGLE+VTBC(I))*S-USINA*S
          V(I,J)=VR*S+VT*C
          W(I,J)=VR*C-VT*S
          U(I,J)=UBS(I)+(UBD(I)*ANGLE+UBC(I))*C
   11   CONTINUE
   10 CONTINUE
*
C     COMPUTE VELOCITY COMPONENTS ON WING DUE TO BODY LINE SINGULARITIES
      DO 20 J=1,NWING
        I=J+NBODY
        UWBT(J)=UWBS(J)+UWBD(J)*ANGLE+UWBC(J)
        VWBT(J)=VWBS(J)+VWBD(J)*ANGLE+VWBC(J)
        WWBT(J)=WWBS(J)+WWBD(J)*ANGLE+WWBC(J)
        ALPHAX(J)=WWBT(J)*COSTH(I)-VWBT(J)*SINTH(I)
   20 CONTINUE
*
C     CALCULATE PRESSURES,FORCES,AND MOMENTS ON ISOLATED BODY
25    CALL BODY1(BBCZ,BBCX,BBCM,ICP,ANGLE)
      RETURN
888   BBCZ=0.
      BBCX=0.
      BBCM=0.
      DO 889 I=1,100
         ALPHAX(I)=0.
         UWBT(I)=0.
         VWBT(I)=0.
         WWBT(I)=0.
  889 CONTINUE
      END   ! --------------------------------- End of Subroutine Karmor

      SUBROUTINE FORCE(BCXF,WCXF)
      REAL BCXF,WCXF

      REAL EPS
      PARAMETER (EPS=0.00001)

      COMMON       DUMMY(1708),UWT(200),VWT(200),WWT(200),UWBT(100),
     1VWBT(100),WWBT(100),ALPHAX(100),UB(200),VB(200),WB(200),
     X  UW(200),VW(200),WW(200),DUMN(6698)
      INTEGER NWING,NBODY,PANELS,OC
      REAL SREF,REFMOM,CBAR
      COMMON/PARAMS/NWING,NBODY,PANELS,SREF,REFMOM,CBAR,OC
      
      REAL MACH,MACHSQ,BETASQ,BETA,RNL
      COMMON/VEL/MACH,MACHSQ,BETASQ,BETA,RNL
      COMMON/PSINGS/PW(100),PB(100),ALPHAT(100)
      COMMON/OPTARR/ZDM(200),          S(100),T(100),F(100),CLBWT
      COMMON/THKCAM/ITHCK,ICMBR,THF(100),CAMF(100)
      REAL  A(200),B(200),CPU(100),CPL(100),DELCP(100)
      COMMON/PANEL/XBAR(200),XC(200),YC(200),ZC(200),AREA(200),
     & SINTH(200),COSTH(200),XP(200,4),YP(200,2),ZP(200,2)
      COMMON/CNT/CASE,CAMBER(100),CP(100)
      INTEGER CASE
!!!      integer CPCALC(2)
      INTEGER BODYCPEQ,WINGCPEQ
!!!      EQUIVALENCE(DEL,DELTA,DELALP)
      NAMELIST/AERO/CASE,BDYALP,CP,CLBAR,CMBAR,SREF,CBAR,
     X REFMOM,OC,CAMBER,BODYCPEQ,WINGCPEQ
      NAMELIST/INCR/DELTA,OC

!!!      DATA CPCALC/0,1/
      DATA BODYCPEQ/1/, WINGCPEQ/0/
      DATA RAD/57.2957795/,BDYALP/0./

      REWIND 7
      REWIND 8
*
9999  CALL SELECT(K)
      IF (K .LT. 0) THEN
        WRITE(6,*) 'Normal termination of WINGBODY in Subroutine FORCE'
        WRITE(*,*) 'File wingbody.out added to your directory.'
        STOP 'Normal termination in Subroutine FORCE'
      ENDIF

      IF (K .EQ. 4) THEN
        READ(UNIT=4, NML=INCR)
        ANGLE=ANGLE+DELTA/RAD
!!!       ARADEG=ANGLE*RAD        ! set but never used ???
        CALL KARMOR(BODYCPEQ, ANGLE,BBCZ,BBCX,BBCM)
        GOTO 200
      ENDIF

      IF(K .NE. 3) GOTO 9999

      READ(UNIT=4, NML=AERO)
      ANGLE=BDYALP
!!!      ARADEG=ANGLE*RAD
      CALL KARMOR(BODYCPEQ, ANGLE,BBCZ,BBCX,BBCM)
*
      IF(CASE.EQ.2.OR.CASE.LE.0.OR.CASE.GT.4)GO TO 200
      GO TO(100,200,300,700),CASE
*
100   CONTINUE                     ! CASE 1 - Given CP, find alpha
      DO 101 J=1,NWING
        PW(J)=CP(J)
  101 CONTINUE
      CALL CAMBWB(CAMBER)
      CALL GETPB(NBODY,NWING)
      DO 105 I=1,NWING
        CAMBER(I)=CAMBER(I)+ALPHAX(I)+S(I)
  105 CONTINUE
      GO TO 700
*
200   CONTINUE                 ! CASE 2 - Given alpha, find CP
      IF(NWING.EQ.0)GO TO 220
      DO 205 I=1,NWING
        READ(7)
        PW(I)=T(I)
  205 CONTINUE
      DO 210 J=1,NWING
        READ(7)(A(I),I=1,NWING)
        JJ=J+NBODY
        AXX=-CAMBER(J)-ANGLE*COSTH(JJ)-ALPHAX(J)
        DO 211 I=1,NWING
          PW(I)=PW(I)+A(I)*AXX
  211   CONTINUE
  210 CONTINUE
      CALL GETPBX(NBODY,NWING)
220   REWIND 7
      GO TO 700
*
300   NN=NWING+1        ! Given CL, compute shape of minimum drag
      DO 305 I=1,NWING
        J=I+NBODY
        B(I)=F(I)*BDYALP+AREA(J)*(S(I)-ALPHAX(I))
        PW(I)=0.
  305 CONTINUE
      B(NN)=(CLBAR-BBCL-CLBWT)*SREF/2.
      DO 310 J=1,NWING+1
        READ(8)(A(I),I=1,NWING+1)
        DO 311 I=1,NWING
          PW(I)=PW(I)-A(I)*B(J)
  311   CONTINUE
  310 CONTINUE
      REWIND 8
      CALL CAMBWB(CAMBER)
      CALL GETPB(NBODY,NWING)
      DO 315 I=1,NWING
        CAMBER(I)=CAMBER(I)+ALPHAX(I)
  315 CONTINUE
*
  700 CONTINUE                                ! code common to all cases
      IF (ABS(BBCZ) .LE. EPS) THEN
        BBCP=REFMOM
      ELSE
        BBCP=REFMOM-CBAR*BBCM/BBCZ
      ENDIF
      BBCX=BBCX+BCXF
      COSA=COS(ANGLE)
      SINA=SIN(ANGLE)
      BBCL=BBCZ*COSA-BBCX*SINA
      BBCD=BBCZ*SINA+BBCX*COSA
      IF(NWING.EQ.0)GO TO 30
      CALL VELCOM
704   CALL BODY(BCZ,BCX,BCM,BODYCPEQ,ANGLE)
      BCX=BCX+BCXF
      BCL=BCZ*COSA-BCX*SINA
      BCD=BCZ*SINA+BCX*COSA
      IF (ABS(BCZ) .LE. EPS) THEN
        BCP=REFMOM
      ELSE
        BCP=REFMOM-CBAR*BCM/BCZ
      ENDIF

C.....COMPUTE PRESSURES ON WING......
      write(6,*) ' starting 705 loop'
      DO 705 I=1,NWING
        J=I+NBODY
        UX=UB(J)+UW(J)+UWBT(I)+UWT(J)+PW(I)/4.
        VX=VB(J)+VW(J)+VWBT(I)+VWT(J)-ALPHAT(I)*SINTH(J)
        WX=WB(J)+WW(J)+WWBT(I)+WWT(J)+ALPHAT(I)*COSTH(J)
        A(I)=AMACHF((1.+UX)*(1.+UX)+VX*VX+WX*WX)
        CALL CCP(WINGCPEQ, UX,VX,WX,CPU(I))
        UX=UB(J)+UW(J)+UWBT(I)+UWT(J)-PW(I)/4.
        VX=VB(J)+VW(J)+VWBT(I)+VWT(J)+ALPHAT(I)*SINTH(J)
        WX=WB(J)+WW(J)+WWBT(I)+WWT(J)-ALPHAT(I)*COSTH(J)
        B(I)=AMACHF((1.+UX)*(1.+UX)+VX*VX+WX*WX)
        CALL CCP(WINGCPEQ, UX,VX,WX,CPL(I))
  705 CONTINUE
      CALL WING(WCZ,WCX,WCM,CAMBER,CPU,CPL,DELCP)
      WCX=WCX+WCXF
      WCL=WCZ*COSA-WCX*SINA
      WCD=WCZ*SINA+WCX*COSA
      IF (ABS(WCZ) .LE. EPS) THEN
        WCP=REFMOM
      ELSE
        WCP=REFMOM-CBAR*WCM/WCZ
      ENDIF

      WBCXF=BCXF+WCXF
      WBCZ=WCZ+BCZ
      WBCX=WCX+BCX
      WBCL=WCL+BCL
      WBCD=WCD+BCD
      WBCM=WCM+BCM
      IF (ABS(WBCZ) .LE. EPS) THEN
        WBCP=REFMOM
      ELSE
        WBCP=REFMOM-CBAR*WBCM/WBCZ
      ENDIF

795   IF (OC.LE.0) GO TO 30
      CALL PAGE
      WRITE(6,1) CASE,WINGCPEQ,BODYCPEQ,SREF,CBAR,REFMOM,MACH
      WRITE(6,*) NWING, ' WING PANELS', NBODY, ' BODY PANELS'
      IF(CASE.EQ.3)WRITE(6,2)CLBAR
      IF(CASE.EQ.4)WRITE(6,2)CLBAR,CMBAR
      WRITE(6,25) ANGLE*RAD
      WRITE(6,*) 'WING CAMBER SLOPE'
      WRITE(6,'(5F13.6)' )(CAMBER(I),I=1,NWING)
      WRITE(6,36)(ALPHAT(I),I=1,NWING)
      WRITE(6,27)(CPU(I),I=1,NWING)
      WRITE(6,28)(CPL(I),I=1,NWING)
      WRITE(6,29)(DELCP(I),I=1,NWING)
      WRITE(6,38)(A(I),I=1,NWING)
      WRITE(6,39)(B(I),I=1,NWING)
      WRITE(6,40)(PW(I),I=1,NWING)
      IF (NBODY .GT. 0) THEN
        WRITE(6,*) 'PB ARRAY'
        WRITE(6, '(5F13.6)' ) (PB(I),I=1,NBODY)
      ENDIF
*
30    CALL PAGE
!!!      WRITE(6,31)MACH, ARADEG
      WRITE(6,*) 'Mach=', MACH, '    angle of attack=', ANGLE*RAD
      WRITE(6,*) 'SREF=', SREF, 'CBAR=',CBAR, 'REFMOM=',REFMOM
!!!
!..... Rewrote summary to fit on screen   17July95   RLC
      IF (NWING .EQ. 0) THEN
        WRITE(6,'(25X,A)' ) 'Isolated'
        WRITE(6,'(25X,A)' ) '  body'
        WRITE(6,'(A,F10.5)' ) 'Lift coeff..............', BBCL
        WRITE(6,'(A,F10.5)' ) 'Drag coeff..............', BBCD
        WRITE(6,'(A,F10.5)' ) 'Friction drag coeff.....', BCXF
        WRITE(6,'(A,F10.5)' ) 'Pitching moment coeff...', BBCM
        WRITE(6,'(A,F10.5)' ) 'Normal coeff............', BBCZ
        WRITE(6,'(A,F10.5)' ) 'Axial coeff.............', BBCX
        WRITE(6,'(A,F10.3)' ) 'Center of pressure......', BBCP
      ELSEIF (NBODY .EQ. 0) THEN
        WRITE(6,'(25X,A)' ) '  wing'
        WRITE(6,'(A,F10.5)' ) 'Lift coeff..............', WCL
        WRITE(6,'(A,F10.5)' ) 'Drag coeff..............', WCD
        WRITE(6,'(A,F10.5)' ) 'Friction drag coeff.....', WCXF
        WRITE(6,'(A,F10.5)' ) 'Pitching moment coeff...', WCM
        WRITE(6,'(A,F10.5)' ) 'Normal coeff............', WCZ
        WRITE(6,'(A,F10.5)' ) 'Axial coeff.............', WCX
        WRITE(6,'(A,F10.3)' ) 'Center of pressure......', WCP
      ELSE
        WRITE(6,'(25X,A)' ) 'Isolated'
        WRITE(6,'(25X,A)' ) '  body      body      wing      wing-body'
        WRITE(6,'(A,4F10.5)' ) 'Lift coeff..............',
     &    BBCL,BCL,WCL,WBCL
        WRITE(6,'(A,4F10.5)' ) 'Drag coeff..............',
     &    BBCD,BCD,WCD,WBCD
        WRITE(6,'(A,4F10.5)' ) 'Friction drag coeff.....',
     &    BCXF,BCXF,WCXF,WBCXF
        WRITE(6,'(A,4F10.5)' ) 'Pitching moment coeff...',
     &    BBCM,BCM,WCM,WBCM
        WRITE(6,'(A,4F10.5)' ) 'Normal coeff............',
     &    BBCZ,BCZ,WCZ,WBCZ
        WRITE(6,'(A,4F10.5)' ) 'Axial coeff.............',
     &    BBCX,BCX,WCX,WBCX
        WRITE(6,'(A,4F10.3)' ) 'Center of pressure......',
     &    BBCP,BCP,WCP,WBCP
      ENDIF
      
      GO TO 9999
      
1     FORMAT(' CASE=',I2,5X,'CP METHOD=',I2, ' ON WING AND ', I2,
     & ' ON BODY'/
     & 'SREF=', F15.6/'CBAR=',F10.6/'MOMENT REFERENCE=',
     & F10.6/'MACH=', F7.4)
2     FORMAT(' WING OPTIMIZED FOR CL=',F8.4,F20.4, ' =CM')
25    FORMAT('CONFIGURATION ANGLE OF ATTACK=',F7.3,' DEGREES')
31    FORMAT('SUMMARY OF INTEGRATED FORCES & MOMENTS ON CONFIGURATION',
     X '  AT MACH=',F8.3,5X,'ALPHA=',F8.3///
     X 42X,'LIFT',9X,'DRAG',9X,'MOMENT',7X,'NORMAL',8X,'AXIAL',8X,
     X  'C.P.', 7X,'FRICTION')
32    FORMAT(' ISOLATED BODY',21X,7F13.6)
931   FORMAT(' ISOLATED WING',21X,7F13.6)
33    FORMAT('BODY IN PRESENCE OF WING',10X,6F13.6/'BODY DUE TO WING',
     118X,6F13.6/'WING IN PRESENCE OF BODY',10X,7F13.6/
     2'WING-BODY COMBINATION',13X,7F13.6)
36    FORMAT('WING THICKNESS SLOPES'/(1X,5F13.6))
26    FORMAT('WING CAMBER SLOPE'/(1X,5F13.6))
27    FORMAT('WING UPPER SURFACE CP'/(1X,5F13.6))
28    FORMAT('WING LOWER SURFACE CP'/(1X,5F13.6))
29    FORMAT('WING DELTA-CP'/(1X,5F13.6))
38    FORMAT('UPPER MACH NOS.'/(1X,5F13.5))
39    FORMAT('LOWER MACH NOS.'/(1X,5F13.5))
40    FORMAT('PW ARRAY'/(1X,5F13.6))
41    FORMAT('PB ARRAY'/(1X,5F13.6))
      END

      SUBROUTINE CAMBWB(AWX)
      INTEGER NWING,NBODY,PANELS,OC
      REAL SREF,REFMOM,CBAR
      COMMON/PARAMS/NWING,NBODY,PANELS,SREF,REFMOM,CBAR,OC
      COMMON/PSINGS/PW(100),ZDUM2(200)
      REAL A(200),AWX(*)
      INTEGER I,J
      REWIND 7
      DO 10 I=1,NWING
        AWX(I)=0.0
   10 CONTINUE

      DO 20 J=1,NWING
        READ(7)(A(I),I=1,NWING)
        DO 21 I=1,NWING
          AWX(I)=AWX(I)-A(I)*PW(J)
   21   CONTINUE
   20 CONTINUE

      END   ! --------------------------------- End of Subroutine CAMBWB

!..... Compute PB vector ...............................................
      SUBROUTINE GETPB(NBODY,NWING)
      INTEGER NBODY,NWING
      INTEGER I
      
      IF (NBODY .GT. 0) THEN
        DO 10 I=1,NWING   ! advance dataset 7 by NWING records
          READ(7)
   10   CONTINUE
        CALL GETPBX(NBODY,NWING)
      ENDIF
      REWIND 7
      RETURN
      END   ! ---------------------------------- End of Subroutine GetPB

!..... Called by GETPB to actually load PB (in /BSINGS/ )
      SUBROUTINE GETPBX(NBODY,NWING)
      INTEGER NBODY,NWING
      COMMON/PSINGS/PW(100),PB(100),PWT(100)
      COMMON/OPTARR/AWT(100),RMAT(100),S(100),T(201)
      INTEGER I,J
      REAL A(100)
      
      IF(NBODY .EQ.0)GO TO 70
      DO 50 J=1,NBODY
        PB(J)=RMAT(J)
   50 CONTINUE
      DO 60  J=1,NWING
        READ(7)(A(I),I=1,NBODY)
        DO 61 I=1,NBODY
          PB(I)=PB(I)+A(I)*PW(J)   ! use dummy array A to hold E
   61   CONTINUE
   60 CONTINUE

70    REWIND 7
      RETURN
      END

!..... Compute the velocity components at each panel induced by 
!        pressure panels and by wing thickness .........................
      SUBROUTINE VELCOM
      COMMON/PSINGS/PW(100),PB(100),PWT(100)
      COMMON DMY1(1708),UWT(200),VWT(200),WWT(200),
     X  UWBT(100),VWBT(100),WWBT(100),ALPHAX(100),
     1            UB(200),VB(200),WB(200),UW(200),VW(200),WW(200)
      COMMON/PANEL/XBAR(200),XC(200),YC(200),ZC(200),AREA(200),
     & SINTH(200),COSTH(200),X(200,4),Y(200,2),Z(200,2)
      INTEGER NWING,NBODY,PANELS,OC
      REAL SREF,REFMOM,CBAR
      COMMON/PARAMS/NWING,NBODY,PANELS,SREF,REFMOM,CBAR,OC
      COMMON/OPTARR/AWT(501)
      REAL AT(200),BT(200),CT(200)    ,A(200),B(200),C(200),AFILL(10606)
      EQUIVALENCE(DMY1(1),AFILL(1))
      CHARACTER*1 UA,VA,WA
      CHARACTER*4 BDY,WNG
      PARAMETER (UA='U', VA='V', WA='W', BDY='BODY', WNG='WING')


C  PUT THESE IN SCRAT WHEN WE CAN FIND A PLACE
      DO 9 I=1,200
         UWT(I)=0.
         VWT(I)=0.
         WWT(I)=0.
         UB(I)=0.
         VB(I)=0.
         WB(I)=0.
         UW(I)=0.
         VW(I)=0.
         WW(I)=0.
    9 CONTINUE
      REWIND 3
!..... Compute UB,VB,WB, the velocities induced by the body delta-Cp....
      DO 10 J=1,NBODY
        CLJ=PB(J)
        READ(3)(A(I),I=1,PANELS),    (A(I),B(I),C(I),AT(I),BT(I),CT(I),
     X     I=1,PANELS)
        DO 11 I=1,PANELS
          UB(I)=UB(I)+A(I)*CLJ
          VB(I)=VB(I)+B(I)*CLJ
          WB(I)=WB(I)+C(I)*CLJ
   11   CONTINUE
   10 CONTINUE
      
!..... Compute UWT,VWT,WWT, the velocities induced by wing thickness
!        and UW,VW,WW, the velocities induced by wing delta-Cp .........
      DO 20 J=1,NWING
      PWTJ=PWT(J)
      CLJ=PW(J)
17    READ(3)(A(I),I=1,PANELS),      (A(I),B(I),C(I),AT(I),BT(I),CT(I),
     X     I=1,PANELS)
      DO 20 I=1,PANELS
      UWT(I)=UWT(I)+AT(I)*PWTJ
      VWT(I)=VWT(I)+BT(I)*PWTJ
      WWT(I)=WWT(I)+CT(I)*PWTJ
21    UW(I)=UW(I)+A(I)*CLJ
22    VW(I)=VW(I)+B(I)*CLJ
20    WW(I)=WW(I)+C(I)*CLJ

!..... The VWT and WWT components computed above were actually the
!        normal and binormal components. Convert to Y and Z ............
      DO 23 I=1,PANELS
        IF (I .LE. NBODY) AWT(I)=WWT(I)
        XX=VWT(I)*COSTH(I)-WWT(I)*SINTH(I)
        WWT(I)=VWT(I)*SINTH(I)+WWT(I)*COSTH(I)
        VWT(I)=XX
   23 CONTINUE
      REWIND 3
      IF(OC.LE.3) RETURN
      WRITE(6,71)(UWBT(I),I=1,NWING)
      WRITE(6,72)(VWBT(I),I=1,NWING)
      WRITE(6,73)(WWBT(I),I=1,NWING)
      WRITE(6,74)(ALPHAX(I),I=1,NWING)
71    FORMAT('U VELOCITY INDUCED BY ISOLATED BODY ON WING'/(5F13.6))
72    FORMAT('V VELOCITY INDUCED BY ISOLATED BODY ON WING'/(5F13.6))
73    FORMAT('W VELOCITY INDUCED BY ISOLATED BODY ON WING'/(5F13.6))
74    FORMAT('INDUCED ALPHA'/(5F13.6))
1     FORMAT(/1X,A1,' VELOCITY COMPONENTS INDUCED BY ',A4,
     X   '  PRESSURE PANELS'/(1X,5F13.6))

      IF(NBODY.EQ.0)GO TO 25
      WRITE(6,1)UA,BDY,(UB(I),I=1,PANELS)
      WRITE(6,1)VA,BDY,(VB(I),I=1,PANELS)
      WRITE(6,1)WA,BDY,(WB(I),I=1,PANELS)
25    WRITE(6,1)UA,WNG,(UW(I),I=1,PANELS)
      WRITE(6,1)VA,WNG,(VW(I),I=1,PANELS)
      WRITE(6,1)WA,WNG,(WW(I),I=1,PANELS)
      WRITE(6,2)UA,(AWT(I),I=1,NBODY)
      WRITE(6,2)UA,(UWT(I),I=1,PANELS)
      WRITE(6,2)VA,(VWT(I),I=1,PANELS)
      WRITE(6,2)WA,(WWT(I),I=1,PANELS)
2     FORMAT(1X,A1,' VELOCITY COMPONENTS INDUCED BY WING THICKNESS'/
     X  (5F13.6))
      RETURN
      END

*+
      SUBROUTINE WING(CL,CD,CM,ALPHA,CPU,CPL,DELCP)
*   --------------------------------------------------------------------
*     PURPOSE - Compute the pressures, forces, and moments on the wing
*
      IMPLICIT NONE
*
************************************************************************
*     A R G U M E N T S                                                *
************************************************************************
      REAL CL,CD,CM
      REAL ALPHA(*)
      REAL CPU(*),CPL(*),DELCP(*)
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
      INTEGER i,k
      REAL LIFT,DRAG,MOMENT
      REAL XL,CDU,CDL
************************************************************************
*     C O M M O N   B L O C K S                                        *
************************************************************************
      INTEGER NWING,NBODY,PANELS,OC
      REAL SREF,REFMOM,CBAR
      COMMON/PARAMS/NWING,NBODY,PANELS,SREF,REFMOM,CBAR,OC
*
      REAL XBAR(200),XC(200),YC(200),ZC(200),AREA(200),
     & SINTH(200),COSTH(200),XP(200,4),YP(200,2),ZP(200,2)
      COMMON/PANEL/XBAR,XC,YC,ZC,AREA,SINTH,COSTH,XP,YP,ZP
*
      REAL ZDUM(200),ALPHAT(100)
      COMMON/PSINGS/ZDUM,ALPHAT
*-----------------------------------------------------------------------
      LIFT=0
      DRAG=0
      MOMENT=0
*
      DO 10 I=1,NWING
        K=I+NBODY
        DELCP(I)=CPL(I)-CPU(I)
        XL=DELCP(I)*AREA(K)*COSTH(K)
        CDL=CPL(I)*(ALPHAT(I)+ALPHA(I))
        CDU=CPU(I)*(ALPHAT(I)-ALPHA(I))
        DRAG = DRAG + AREA(K)*(CDU+CDL)
        MOMENT=MOMENT+XL*XBAR(K)
        LIFT=LIFT+XL
   10 CONTINUE

      CL=2.0*LIFT/SREF
      CD=2.0*DRAG/SREF
      MOMENT=REFMOM*LIFT-MOMENT
      CM=2.0*MOMENT/(SREF*CBAR)
      RETURN
      END ! ------------------------------------- End of subroutine WING

*+
      SUBROUTINE BODY(CZ,CX,CM,ICP,ANGLE)
*   --------------------------------------------------------------------
*     PURPOSE - COMPUTE THE NET PRESSURE DISTRIBUTION ON THE BODY
*       AND TO INTEGRATE THIS PRESSURE TO GET THE FORCES AND MOMENTS
!       To do this, one takes the velocities due to the line
!       singularities and adds the velocities from the panels.
!
!     NOTES - A special entry point BODY1 is for the isolated body
*
!!!      IMPLICIT NONE
************************************************************************
*     A R G U M E N T S                                                *
************************************************************************
      REAL CZ      !                                                 OUT
      REAL CX      !                                                 OUT
      REAL CM      !                                                 OUT
      INTEGER ICP  !                                                  IN
      REAL ANGLE   !                                                  IN
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
************************************************************************
*     C O M M O N   B L O C K S                                        *
************************************************************************
      COMMON/PANEL/XBAR(200),XC(200),YC(200),ZC(200),AREA(200),
     & SINTH(200),COSTH(200),XP(200,4),YP(200,2),ZP(200,2)
      REAL LNOSE,LBODY,LTAIL
      COMMON/BDYBLK/RNOSE,RADIUS,RBASE,LNOSE,LBODY,LTAIL,ZNOSE,ZBASE,
     X NB,NXBODY,THETAB(23),
     X XBODY(101),RBODY(101),RPBODY(101),ZBODY(101),DRDX(100),DZDX(101)
      INTEGER NWING,NBODY,PANELS,OC
      REAL SREF,REFMOM,CBAR
      COMMON/PARAMS/NWING,NBODY,PANELS,SREF,REFMOM,CBAR,OC
      REAL MACH,MACHSQ,BETASQ,BETA,RNL
      COMMON/VEL/MACH,MACHSQ,BETASQ,BETA,RNL
      LOGICAL SKIP
      COMMON   DMY1(1708),UWT(200),VWT(200),WWT(200),DMY2(400),
     1 UB(200),VB(200),WB(200),UW(200),VW(200),WW(200),
     2 U(101,12),V(101,12),W(101,12),CPBB(101,12),
     3 A(200),B(200),C(200),F(101),G(101),  DMY3(1048)  ! added 31Oct94
*-----------------------------------------------------------------------
!!!      SAVE NN,NB2,NROWS                               ! added 29Oct94
      IF(NB.EQ.0)GO TO 777                          ! NB=0 means no body

      NB2=NB+NB
      NN=NB2+2
      NROWS=NBODY/NB2
      DENOM=0.5*SREF/(XBODY(NXBODY)-XBODY(1))
      ANGDEG=ANGLE*57.29578
      SKIP=.FALSE.


*  NB=0 WILL DENOTE NO BODY  (ALL SPEED REGIMES)
*  NBODY=0 MERELY INDICATES NO PANELS
      IF(OC.LE.0) GO TO 4
      CALL PAGE
      WRITE(6,1)MACH,ANGDEG
1     FORMAT('CHARACTERISTICS OF BODY IN PRESENCE OF WING AT MACH=',
     X  F7.3/'   ANGLE OF ATTACK=',F7.3,'  DEGREES')
*
4     K=0
      DO 5 J=1,NB2
      DO 6 I=1,NROWS
      K=K+1
      A(I)=UB(K)+UW(K)+UWT(K)
      B(I)=VB(K)+VW(K)+VWT(K)
      C(I)=WB(K)+WW(K)+WWT(K)
6     F(I)=XBAR(K)
*     NOW INTERPOLATE IN THESE TABLES TO GET THE INDUCED
*       VELOCITIES AT THE LATTICE POINTS
      DO 7 I=1,NXBODY
      IF(XBODY(I).LT.F(1)) GO TO 7
      CALL TAINT(F,A,XBODY(I),UX,NROWS,2)
      CALL TAINT(F,B,XBODY(I),VX,NROWS,2)
      CALL TAINT(F,C,XBODY(I),WX,NROWS,2)
      U(I,J+1)=U(I,J+1)+UX
      V(I,J+1)=V(I,J+1)+VX
      W(I,J+1)=W(I,J+1)+WX
      IF(J.NE.1)GO TO 8
      U(I,1)=U(I,1)+UX
      V(I,1)=V(I,1)+VX
      W(I,1)=W(I,1)+WX
      GO TO 7
8     IF(J.NE.NB2)GO TO 7
      U(I,NN)=U(I,NN)+UX
      V(I,NN)=V(I,NN)+VX
      W(I,NN)=W(I,NN)+WX
7     CONTINUE
5     CONTINUE
      GO TO 9



      ENTRY BODY1(CZ,CX,CM,ICP,ANGLE)
      SKIP=.FALSE.
      GO TO 12

12    NB2=NB+NB       ! were done at the top, but isolated body...
      NN=NB2+2
11    NROWS=NBODY/NB2
      DENOM=0.5*SREF/(XBODY(NXBODY)-XBODY(1))
      ANGDEG=ANGLE*57.29578
      IF(OC.LE.0)GO TO 9
      CALL PAGE
      WRITE(6,2)MACH,ANGDEG


*..... FIRST INTEGRATE FOR AXIAL FORCE..................................
9     DO 10 I=1,NXBODY
        IF(SKIP)GO TO 16     ! looks as if SKIP is always FALSE now
        DO 15 J=1,NN
          CALL CCP(ICP,U(I,J),V(I,J),W(I,J),G(J))         ! strange
          CPBB(I,J)=G(J)
   15   CONTINUE
        GO TO 18
16      DO 17 J=1,NN
17      G(J)=CPBB(I,J)
18      IF(RPBODY(I).NE.0.)CALL TRAP(THETAB,G,RESULT,NN)
        A(I)=RBODY(I)*RPBODY(I)*RESULT
   10 CONTINUE
      CALL UTRAP(A,RESULT,NXBODY)
      CX=RESULT/DENOM
*
*..... NEXT INTEGRATE FOR NORMAL FORCE..................................
      DO 20 I=1,NXBODY
        DO 21 J=1,NN
          B(J)=CPBB(I,J)*COS(THETAB(J))
   21   CONTINUE
        CALL TRAP(THETAB,B,RESULT,NN)
        A(I)=-RBODY(I)*RESULT
   20 CONTINUE
      CALL UTRAP(A,RESULT,NXBODY)
      CZ=RESULT/DENOM
*
*..... Next integrate for pitching moment ..............................
      DO 30 I=1,NXBODY
        B(I)=A(I)*(REFMOM-XBODY(I)+RBODY(I)*RPBODY(I))
   30 CONTINUE
      CALL UTRAP(B,RESULT,NXBODY)
      CM=RESULT/(DENOM*CBAR)
*
*..... Following gives running lift load on the body. We were going to
*      combine this with running load on wing and use to result to
*      compute sonic boom by Whitham's F-function method.
*      Looks unfinished...
      CALL RUNTRP(XBODY,A,B,NXBODY)   ! B never gets used
*
      IF(OC.LE.0)RETURN
!
      CALL PrintBodyData(6, 101,
     &  nxbody, nb+nb+2, xbody, thetab, cpbb, 'Cp')
*
      IF (OC.GT.1) WRITE(11)((CPBB(I,J),I=1,NXBODY),J=1,NN)
64    IF(SKIP.OR.OC.LE.3)RETURN
      CALL PrintBodyData(6, 101,
     &  nxbody, nb+nb+2, xbody, thetab, u, 'X-PERTURB-VELOCITY')
      CALL PrintBodyData(6, 101,
     &  nxbody, nb+nb+2, xbody, thetab, v, 'Y-VELOCITY')
      CALL PrintBodyData(6, 101,
     &  nxbody, nb+nb+2, xbody, thetab, w, 'Z-VELOCITY')

*
      DO 50 J=1,NN
        B(J)=SIN(THETAB(J))
        C(J)=COS(THETAB(J))
   50 CONTINUE
*
!
!..... Now we very cleverly replace V and W with the radial and
!      tangential components of velocity
      DO i=1,nxbody
        DO j=1,nb+nb+2
          radial=V(I,J)*B(J)+W(I,J)*C(J)
          tangential=V(I,J)*C(J)-W(I,J)*B(J)
          v(i,j)=radial
          w(i,j)=tangential
        END DO
      END DO
      CALL PrintBodyData(6, 101,                                        &
     &  nxbody, nb+nb+2, xbody, thetab, v, 'RADIAL VELOCITY')
      CALL PrintBodyData(6, 101,                                        &
     &  nxbody, nb+nb+2, xbody, thetab, w, 'TANGENTIAL VELOCITY')


      RETURN
777   CZ=0.
      CX=0.
      CM=0.
      RETURN
2     FORMAT('CHARACTERISTICS OF ISOLATED BODY AT MACH=',F7.3/
     X  '   ANGLE OF ATTACK=',F7.3,'  DEGREES')
      END ! ------------------------------------- End of subroutine Body
*+
      SUBROUTINE PrintBodyData(efn, ndim, nx, ntheta, x, theta, a, s)
*   --------------------------------------------------------------------
*     PURPOSE - Print pressures or velocities along meridians of the
*       body, either isolated or in presence of wing.
*
      IMPLICIT NONE
************************************************************************
*     A R G U M E N T S                                                *
************************************************************************
      INTEGER efn                      ! external file number for output
      INTEGER ndim                          ! first dimension of array a
      INTEGER nx                                       ! # of x-stations 
      INTEGER ntheta       ! # of theta stations (always an even number)
      REAL x(nx)                                 ! longitudinal stations
      REAL theta(ntheta)     ! angular stations (0 at top, pi at bottom)
      REAL a(ndim,*)                            ! variable to be printed
      CHARACTER*(*) s                           ! string printed with it
************************************************************************
*     L O C A L   C O N S T A N T S                                    *
************************************************************************
      REAL PI
      PARAMETER (PI=3.14159265)
************************************************************************
*     L O C A L   V A R I A B L E S                                    *
************************************************************************
      INTEGER i,j,k
*-----------------------------------------------------------------------
      IF (ntheta .LE. 6) THEN
        WRITE(efn,*) s//' ALONG MERIDIANS OF BODY'
        WRITE(efn, '(/35X,A)' ) 'theta'
        WRITE(efn,99) ((180/PI)*theta(i),i=1,ntheta)
        DO i=1,nx
          WRITE(efn,'(7F11.5)' ) x(i), (a(i,j), j=1,ntheta)
        END DO
      ELSE
        k=ntheta/2
        WRITE(efn,*) s//' ALONG MERIDIANS ON UPPER HALF OF BODY'
        WRITE(efn, '(/35X,A)' ) 'theta'
        WRITE(efn,99) ((180/PI)*theta(i),i=1,k)
        DO i=1,nx
          WRITE(efn,'(7F11.5)' ) x(i), (a(i,j), j=1,k)
        END DO
        WRITE(efn,*) s//' ALONG MERIDIANS ON LOWER HALF OF BODY'
        WRITE(efn, '(/35X,A)' ) 'theta'
        WRITE(efn,99) ((180/PI)*theta(i),i=k+1,ntheta)
        DO i=1,nx
          WRITE(efn,'(7F11.5)' ) x(i), (a(i,j), j=k+1,ntheta)
        END DO
      END IF
   99 FORMAT(5X,'x',5X,6F11.2)
      END ! ---------------------------- End of subroutine PrintBodyData
       

