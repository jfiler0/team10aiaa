! PROGRAM FLUTTER
! PURPOSE - A modified strip analysis has been developed for rapidly
! predicting flutter of finite-span, swept or unswept wings at subsonic
! to hypersonic speeds. The method employs distributions of aerodynamic
! parameters which may be evaluated from any suitable linear or nonlinear
! steady-flow theory or from measured steady-flow load distributions for
! the underformed wing. The method has been shown to give good flutter
! results for a broad range of wings at Mach number from 0 to as high
! as 15.3.

!     The principles of the modified strip analysis may be summarized as
! follows: Variable section lift-curve slope and aerodynamic center are
! substituted respectively, for the two-dimensional incompressible-flow
! values of 2 pi and quarter chord which were employed by Barmby,
! Cunningham, and Garrick. Spanwise distributions of these steady-flow
! section aerodynamic parameters, which are pertinent to the desired
! planform and Mach number, are used. Appropriate values of Mach
! number-dependent circulation functions are obtained from
! two-dimensional unsteady compressible-flow theory.

!     Use of the modified strip analysis avoids the necessity of
! reevaluating a number of loading parameters for each value of reduced
! frequency, since only the modified circulation functions, and of course
! the reduced frequency itself, vary with frequency. It is therefore
! practical to include in the digital computing program a very brief
! logical subroutine, which automatically selects reduced-frequency values
! that converge on a flutter solution. The problem of guessing suitable
! reduced-frequency values is thus eliminated, so that a large number of
! flutter points can be completely determined in a single brief run on
! the computing machine. If necessary, it is also practical to perform
! the calculations manually.

!     Flutter characteristics have been calculated by the modified strip
! analysis and compared with results of other calculations and with
! experiments for Mach numbers up to 15.3 and for wings with sweep angle
! from 0 degrees to 52.5 degrees, aspect ratios from 2.0 to 7.4, taper
! ratios from 0.2 to 1.0, and center-of-gravity positions between
! 34% chord and 59% chord.
! These ranges probably cover the great majority of wings that are of
! practical interest with the exception of very low-aspect-ratio
! surfaces such as delta wings and missile fins.

! PROGRAM NUMBER: LAR-10199,   also known as Langley Program R1542



MODULE FlutterProcedures

CONTAINS




!      SUBROUTINE ddiplt (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o)
!
!  DUMMY ROUTINE
!
!      RETURN
!      END


!+
      SUBROUTINE Egnc (a, p, nk, nn, nev, mp, nc, x, vec, ax, ck, vk, b,&
     & asave, cksave, vksave, seval, nsav, ans, nerror)
! ----------------------------------------------------------------------
      INTEGER,INTENT(IN):: nk   ! 1st dimensioned size of a,b,asave
      INTEGER,INTENT(IN):: nn   ! actual size of a
      INTEGER,INTENT(IN):: nev
      INTEGER,INTENT(IN):: mp
      INTEGER,INTENT(IN):: nc   ! 1st dimension size of 
      COMPLEX,INTENT(IN OUT):: a(nk,nk)
      COMPLEX,INTENT(IN):: p
      COMPLEX,INTENT(IN OUT):: x(nk)
      COMPLEX,INTENT(OUT):: vec(nk)
      COMPLEX,INTENT(IN OUT):: ax(nk)
      COMPLEX,INTENT(IN OUT):: ck(nk)
      COMPLEX,INTENT(IN OUT):: vk(nk)
      COMPLEX,INTENT(IN OUT):: b(nk,nk)
      COMPLEX,INTENT(OUT):: asave(nk,nk)
      COMPLEX,INTENT(OUT):: cksave(mp),vksave(mp),seval(nk)
      INTEGER,INTENT(OUT):: nsav(nk)
      COMPLEX,INTENT(OUT):: ans(nc,nk)
      INTEGER,INTENT(OUT):: nerror


      COMPLEX:: c,d
      COMPLEX:: peval
      COMPLEX:: xx,xvec
      COMPLEX:: amuip,vecmx,eval
      COMPLEX:: cval

!      COMPLEX ctemp   ! never used ???
!      COMPLEX cvec    ! never used ???
      COMPLEX denom
      COMPLEX diff
      COMPLEX e
      COMPLEX eigvl
      COMPLEX temp
!      COMPLEX vkeep   ! never used ???
!-----------------------------------------------------------------------
      write(6,*) 'Entering subroutine Engc, nk=', nk
      write(6,*) '  nn=',nn, '   nc=',nc,   'mp=',mp
      nerror=0
      knev=nev
      n=nn
      knn=n+2
      kc=0
      kev=0
      isav=0
!      DO 10 i=1,n
!        DO 10 j=1,n
!   10   asave(i,j)=a(i,j)
      asave(1:n,1:n)=a(1:n,1:n)

      num=1
      ndem=n+3
!     WILKINSON VARIATION OF THE POWER METHOD
   20 w=0.0
      kd=3
      kont2=0
      cval=(0.0,0.0)
      kdelta=0
      kont1=0
!!!      kontd=0   ! never used
!!!      IF (n-1) 30,770,30   
      IF (n==1) GO TO 770
   30 DO 40 i=1,n
        ck(i)=(0.0,0.0)
        x(i)=(1.0,0.0)
   40 END DO

      DO 50 i=1,n
        a(i,i)=a(i,i)-p
   50 END DO

   60 DO 70 i=1,n
        vec(i)=(0.0,0.0)
        DO 71 j=1,n
          vec(i)=a(i,j)*x(j)+vec(i)
   71   END DO
   70 END DO

      xvec=(0.0,0.0)
      xx=(0.0,0.0)
      testn=0.0
      testd=0.0
      DO 80 i=1,n
        xvec=x(i)*vec(i)+xvec
        xx=x(i)*x(i)+xx
   80 END DO

      amuip=xvec/xx
      CALL norm (vec, n, eigvl, ne)
      DO 90 i=1,n
        vecmx=vec(i)-x(i)
        testn=cabs(vecmx)+testn
        testd=cabs(x(i))+testd
   90 END DO

      eps=testn/testd
!!!      IF (w) 460,100,460
      IF (w /= 0.0) GO TO 460

  100 eval=amuip+p
      DO 110 i=1,n
        ax(i)=ck(i)
        ck(i)=x(i)
        vk(i)=vec(i)
        x(i)=vec(i)
  110 END DO

!!!      IF (eps-.1e-9) 230,230,120
      IF (eps <= 1E-10) GO TO 230

  120 IF (kd) 130,150,130

  130 kd=kd-1
  140 kont1=kont1+1
      kont2=kont2+1
      IF (kont2-150) 60,60,230

  150 IF (kdelta) 160,170,160

  160 IF (kont1-10) 140,140,200

  170 testd=cabs(eval)
      IF (testd-.1e-11) 230,230,180

  180 testn=cabs(eval-cval)
      test=testn/testd
      cval=eval
      IF (test-.00390625) 200,200,190

  190 IF (kont1-20) 140,140,200
!     AITKENS DELTA SQUARED ACCELERATION
  200 DO 220 i=1,n
        denom=ax(i)-2.0*ck(i)+vk(i)
        rtest=real(denom)
        IF (rtest) 210,220,210
  210   temp=ax(i)*vk(i)-(ck(i)**2)
        x(i)=temp/denom
  220 END DO

      kont1=0
      kdelta=1
      GO TO 60
  230 w=1.0
      kont1=0
!     WIELANDT METHOD

  240 DO 260 i=1,n
        DO 250 j=1,n
          b(i,j)=a(i,j)
  250   END DO
        b(i,i)=a(i,i)-eval
  260 END DO

      kn=n
      ip=1
      jp=1
!     FIND LARGEST MODULUS IN ITH COL.
  270 box=0.0
      DO 290 j=jp,n
        test=ABS(b(j,ip))   ! b is complex
!!!        IF (test-box) 290,280,280
!!!  280   box=test
!!!        k=j
        IF (test > box) THEN
          box=test
          k=j
        END IF
  290 END DO

      IF (box-.1e-12) 850,850,300

  300 IF (ip-k) 310,330,310
!     INTERCHANGE KTH AND ITH ROWS OF MATRIX

  310 DO 320 kcr=jp,n
        c=b(k,kcr)
        d=b(ip,kcr)
        b(ip,kcr)=c
        b(k,kcr)=d
  320 END DO

!     INTERCHANGE KTH AND ITH ELEMENTS OF VECTOR
      c=x(k)
      d=x(ip)
      x(k)=d
      x(ip)=c
!     REDUCE MATRIX TO TRIANGULAR FORM BY GAUSSIAN ELIMINATION
  330 jm=jp+1
      j=0
      DO 340 i=jm,n
        j=j+1
        ax(j)=b(i,jp)/b(jp,jp)
  340 END DO

      m=ip
      kn=kn-1
      DO 360 i=1,kn
        DO 350 j=jm,n
          b(m+1,j)=b(m+1,j)-ax(i)*b(jp,j)
  350   END DO
        m=m+1
  360 END DO

      jt=ip
      DO 370 i=1,kn
        jt=jt+1
        x(jt)=x(jt)-ax(i)*x(jp)
  370 END DO

      ip=ip+1
      jp=jp+1
!!!      IF (ip-n) 270,380,860
      IF (ip < n) GO TO 270
      IF (ip > n) GO TO 860
!     DO BACK SOLUTION FOR VECTOR

  380 k=0
      is=0
      temp=(0.0,0.0)

  390 k=k+1
      test=cabs(b(ip,ip))
      kp=n+1
      IF (test-.1e-13) 440,440,400

  400 IF (is.EQ.1) x(ip)=(0.0,0.0)
      x(ip)=(x(ip)-temp)/b(ip,ip)
  410 ip=ip-1
      IF (ip) 860,450,420

  420 temp=(0.0,0.0)
      DO 430 i=1,k
        kp=kp-1
        temp=b(ip,kp)*x(kp)+temp
  430 END DO

      GO TO 390
  440 is=1
      x(ip)=(1.0,0.0)
      GO TO 410
  450 CALL norm (x, n, eigvl, ne)
      GO TO 60
  460 eval=amuip+p
      IF (is) 520,470,520
  470 testd=cabs(eval)
      IF (testd-.1e-11) 510,510,480
  480 testn=cabs(eval-cval)
      test=testn/testd
      cval=eval
      IF (test-.1e-11) 520,520,490
  490 IF (eps-.1e-11) 520,520,500
  500 kont1=kont1+1
      IF (kont1-20) 240,840,840
  510 eval=(0.0,0.0)
!     MATRIX DEFLATION AND VECTOR INFLATION

  520 DO 530 i=1,n
        x(i)=vec(i)
        ck(i)=vec(i)
  530 END DO

      IF (n-ne) 860,570,540
  540 c=ck(ne)
      d=ck(n)
      ck(ne)=d
      ck(n)=c
!     INTERCHANGE COLUMNS
      DO 550 i=1,n
        c=a(i,ne)
        d=a(i,n)
        a(i,ne)=d
        a(i,n)=c
  550 END DO

!     INTERCHANGE ROWS
      DO 560 i=1,n
        c=a(ne,i)
        d=a(n,i)
        a(ne,i)=d
        a(n,i)=c
  560 END DO

  570 k=n-1
      DO 580 i=1,k
        vk(i)=a(n,i)
  580 END DO

      DO 590 i=1,k
        DO 590 j=1,k
        a(i,j)=a(i,j)-ck(i)*vk(j)
  590 END DO

      DO 600 i=1,k
        kc=kc+1
        cksave(kc)=ck(i)
        vksave(kc)=vk(i)
  600 END DO

  610 kev=kev+1
      seval(kev)=eval
      nsav(kev)=ne
      kont=n
      IF (nn-n) 860,780,620
  620 jev=kev
      knt=nn
      l=k+1
      IF (isav) 640,630,640
  630 kcu=1
      kcus=kcu
      kct=n
      kcts=kct
      isav=1
      GO TO 650

  640 inev=0
      kcu=kcus+n+1
      kcus=kcu
      kct=kcts+n
      kcts=kct

  650 jev=jev-1
      knt=knt-1
      jne=nsav(jev)
      j=0

      DO 660 i=kcu,kct
        j=j+1
        ck(j)=cksave(i)
        vk(j)=vksave(i)
  660 END DO

      peval=seval(jev)
!     INFLATION
      inf=0
      diff=eval-peval
      test=cabs(diff)
      IF (test-.1e-11) 670,670,680
  670 inf=1
  680 temp=(0.0,0.0)

      DO 690 i=1,l
        temp=vk(i)*x(i)+temp
  690 END DO

      test=cabs(temp)
      IF (test-.1e-11) 700,700,740

  700 inf=0
      e=(0.0,0.0)
  710 DO 720 i=1,kont
        x(i)=x(i)+e*ck(i)
  720 END DO

      kont=kont+1
      x(kont)=e
      c=x(kont)
      d=x(jne)
      x(kont)=d
      x(jne)=c
      CALL norm (x, kont, eigvl, ne)
      l=l+1
      IF (knt-n) 860,780,730
  730 inev=inev+1
      kcu=kcu-n-inev
      kct=kct-k-inev
      GO TO 650

  740 IF (inf) 750,760,750
  750 e=(1.0,0.0)
      GO TO 710
  760 e=temp/diff
      GO TO 710

  770 eval=a(1,1)
      k=n-1
      GO TO 610

!     TEST EIGENVECTOR IN ORIGINAL MATRIX
  780 DO 790 i=1,nn
        vec(i)=(0.0,0.0)
        DO 791 j=1,nn
          vec(i)=asave(i,j)*x(j)+vec(i)
  791   END DO
  790 END DO

      CALL norm (vec, nn, eigvl, ne)
      testn=0.0
      testd=0.0
      DO 800 i=1,nn
        vecmx=vec(i)-x(i)
        testn=cabs(vecmx)+testn
        testd=cabs(x(i))+testd
  800 END DO

      eps=testn/testd
      n=n-1
      j=0
      ans(1,num)=eval
      ans(2,num)=eigvl
      DO 810 i=3,knn
        j=j+1
        ans(i,num)=vec(j)
  810 END DO

      ans(ndem,num)=eps
      num=num+1
      nerror=1
      knev=knev-1

      IF (knev) 820,820,20

  820 DO 830 i=1,nn
        DO 831 j=1,nn
          a(i,j)=asave(i,j)
  831   END DO
  830 END DO


      WRITE(3,*) 'Dump of ans'
      DO j=1,num
        WRITE(3,'(6F13.5)' ) ans(:,j)
      END DO
      write(3,*)  'Return from Egnc, nerror=', nerror
      RETURN


  840 nerror=2
      GO TO 820
  850 nerror=3
      GO TO 820
  860 STOP
      END Subroutine Egnc   ! ------------------------------------------



!+
      SUBROUTINE Ftlup (x, y, m, n, vari, vard)
! ----------------------------------------------------------------------
      DIMENSION vari(1), vard(1), v(3), yy(2)
!-----------------------------------------------------------------------
      IF (m.EQ.0.and.n.EQ.0) GO TO 190
      IF (m.EQ.0.and.n.NE.0) GO TO 210
      IF (n.LE.iabs(m)) GO TO 210
      IF (m.GT.0) GO TO 80
!             M.LT.0
      DO 10 iyy=1,n
        i=iyy
        IF (vari(i)-x) 20,200,10
   10 END DO
      i=n+m
!          IF X.LT.X(N),EXTRAPOLATE
      IF (m.EQ.-1) GO TO 30
      GO TO 70
!          IF X.GT.X(1),EXTRAPOLATE
   20 IF (i.EQ.1.and.m.EQ.-1) GO TO 30
      IF (i.EQ.1.and.m.EQ.-2) GO TO 70
      IF (m.NE.-1) GO TO 40
!          M=-1
      i=i-1
   30 IF (vari(i).LE.vari(i+1)) GO TO 210
      GO TO 120
!          M=-2
   40 IF (i.NE.n) GO TO 50
      i=n-2
      GO TO 70
!          COMPARE WITH NEXT
   50 IF (vari(i+1)-x) 60,210,210
   60 i=i-1
      IF (i.EQ.1) GO TO 70
!          SEE WHICH THREE
      IF ((vari(i-1)-x).LT.(x-vari(i+2))) i=i-1
   70 IF (vari(i).LE.vari(i+1).or.vari(i+1).LE.vari(i+2)) GO TO 210
      GO TO 170
!             M.GT.0
   80 DO 90 iyy=1,n
        i=iyy
        IF (x-vari(i)) 100,200,90
   90 END DO
      i=n-m
!          IF X.GT.X(N),EXTRAPOLATE
      IF (m.EQ.1) GO TO 110
      GO TO 160
!          IF X.LT.X(1),EXTRAPOLATE
  100 IF (i.EQ.1.and.m.EQ.1) GO TO 110
      IF (i.EQ.1.and.m.EQ.2) GO TO 160
      IF (m.NE.1) GO TO 130
!          M=1
      i=i-1
  110 IF (vari(i+1).LE.vari(i)) GO TO 210
!          LINEAR
  120 y=(vard(i)*(vari(i+1)-x)-vard(i+1)*(vari(i)-x))/(vari(i+1)-vari(i)&
     &)
      RETURN
!          M=2
  130 IF (i.NE.n) GO TO 140
      i=n-2
      GO TO 160
!          COMPARE WITH NEXT
  140 IF (x-vari(i+1)) 150,210,210
  150 i=i-1
      IF (i.EQ.1) GO TO 160
!          SEE WHICH THREE
      IF ((x-vari(i-1)).LT.(vari(i+2)-x)) i=i-1
  160 IF (vari(i+1).LE.vari(i).or.vari(i+2).LE.vari(i+1)) GO TO 210
!          SECOND ORDER
  170 v(1)=vari(i)-x
      v(2)=vari(i+1)-x
      v(3)=vari(i+2)-x
      k=i
      DO 180 j=1,2
        yy(j)=(vard(k)*v(j+1)-vard(k+1)*v(j))/(vari(k+1)-vari(k))
  180   k=k+1
      y=(yy(1)*v(3)-yy(2)*v(1))/(vari(i+2)-vari(i))
      RETURN
!             ZERO ORDER(Y=Y(1))
  190 y=vard(1)
      RETURN
!             Y=Y(I)
  200 y=vard(i)
      RETURN
!
!          ERROR PRINT
  210 WRITE(*,220)
  220 FORMAT (/' ERROR WAS ENCOUNTERED IN FTLUP')
      WRITE(*,230) m,n,x
  230 FORMAT (' M=',I5,5X,'N=',I5,5X,'X=',ES20.8)
      IF (n.EQ.0) STOP
      IF (m.EQ.0) STOP
      WRITE(*,240)
  240 FORMAT (' TABLE OUT OF ORDER')
      STOP
      END Subroutine Ftlup   ! -----------------------------------------



!+
      SUBROUTINE Hessen (a, m, max)
! ----------------------------------------------------------------------
!     Subroutine to put matrix in upper Hessenberg form.
      DIMENSION a(max,max), b(99)
      DOUBLE PRECISION sum
!-----------------------------------------------------------------------
      WRITE(3,*) 'Entering Hessen, m=', m
      IF (m-2) 170,170,10
   10 DO 160 lc=3,m
        n=m-lc+3
        n1=n-1
        n2=n-2
        ni=n1
        div=abs(a(n,n-1))

        DO 30 j=1,n2
          IF (abs(a(n,j))-div) 30,30,20
   20     ni=j
          div=abs(a(n,j))
   30   END DO

        IF (div) 40,160,40
   40   IF (ni-n1) 50,80,50

   50   DO 60 j=1,n
          ia=n-2
          div=a(j,ni)
          a(j,ni)=a(j,n1)
          a(j,n1)=div
   60   END DO

        DO 70 j=1,m
          div=a(ni,j)
          a(ni,j)=a(n1,j)
          a(n1,j)=div
   70   END DO

   80   DO 90 k=1,n1
          b(k)=a(n,k)/a(n,n-1)
   90   END DO

        DO 150 j=1,m
          sum=0.0
          IF (j-n1) 100,130,130
  100     IF (b(j)) 110,130,110
  110     a(n,j)=0.0
          DO 120 k=1,n1
            a(k,j)=a(k,j)-a(k,n1)*b(j)
            sum=sum+a(k,j)*b(k)
  120     END DO

          GO TO 150

  130     DO 140 k=1,n1
            sum=sum+a(k,j)*b(k)
  140     END DO

          a(n1,j)=sum
  150   END DO
  160 END DO

  170 WRITE(3,*) 'Leaving Hessen'
      RETURN
      END Subroutine Hessen

!+
      SUBROUTINE PrintInput()
! ----------------------------------------------------------------------
      INCLUDE 'blk.inc'
!      COMMON wingno,calcno,mach,brl,ur,tanlea,msubn,eps,k1,d1k,d2k,d3k,
!     &nu,nv,wh(6),wa(6),gh(6),ga(6)
!-----------------------------------------------------------------------
      WRITE(3,*) 'Entering PrintInput'
      WRITE(6,10) wingno,mach,nu,nv,ur,eps,msubn,brl,tanlea
   10 FORMAT(/' WING NO. =', f10.3, 10x, 'Mach=', F8.3/                &
     & 7x,'NU =',i4, 5X, 'NV=',I4/                                     &
     & 5x,'UR =',ES12.4,3X,'E =',ES12.4,6x,'MN =',ES12.4/              &
     & '  BR/L =',ES12.4,9x,'TANLEA =',ES12.4)

      WRITE(6,20)
   20 FORMAT(/'MODAL FREQUENCIES AND DAMPING COEFFICIENTS')

      WRITE(6,30)
   30 FORMAT(6x,'I =',5x,'1',5x,'2',5x,'3',5x,'4',5x,'5',5x,'6')

      WRITE(6,40) (wh(i),i=1,nu)
   40 FORMAT(/'WHI/WR =',6ES12.4)

      WRITE(6,50) (gh(i),i=1,nu)
   50 FORMAT(4x,'GHI =',6ES12.4)

      WRITE(6,60) (wa(i),i=1,nv)
   60 FORMAT(/'WAI/WR =',6ES12.4)

      WRITE(6,70) (ga(i),i=1,nv)
   70 FORMAT(/4x,'GAI =',6ES12.4)

      WRITE(6,80) k1,d1k,d2k,d3k
   80 FORMAT(/6x,'K =',ES12.4/'  DELK1 =',ES12.4,'  DELK2 =',ES12.4,'  DELK3 =', e15.5)

      WRITE(3,*) 'Leaving PrintInput'
      RETURN
      END Subroutine PrintInput   ! ------------------------------------------------


!+
      SUBROUTINE Norm (y, nn, vkeep, ne)
! ----------------------------------------------------------------------
!     Subroutine to normalize a complex vector. Used in Eqnc.
      COMPLEX,INTENT(IN OUT),DIMENSION(*):: y
      INTEGER,INTENT(IN):: nn   ! size of y    ( was l. Changed by RLC )
      COMPLEX,INTENT(OUT):: vkeep  ! element of y with largest ABS
      INTEGER,INTENT(OUT):: ne   ! index of largest element

      INTEGER:: i
      REAL:: sb   ! largest element (in ABS) in y
      REAL:: stest
!-----------------------------------------------------------------------
      WRITE(3,*) 'Entering Norm'
      sb=0.0
      DO 20 i=1,nn
        stest=ABS(y(i))
        IF (stest-sb) 20,10,10
   10   sb=stest
        vkeep=y(i)
        ne=i
   20 END DO

      DO 30 j=1,nn
        y(j)=y(j)/vkeep   !
   30 END DO
      
      WRITE(3,*) 'Leaving Norm'
      RETURN
      END Subroutine Norm

!+
      SUBROUTINE Print (k, a, nu, nv)
! ----------------------------------------------------------------------
! PURPOSE
      IMPLICIT NONE

                  !
      INTEGER k
      REAL a(6,6)
      INTEGER nu
      INTEGER nv

      INTEGER i,j
!-----------------------------------------------------------------------
      WRITE(3,*) 'Entering Print, k,nu,nv=', k,nu,nv
      WRITE(6,'(A,I3)') ' INTEGRAL ', k
      DO i=1,nu
        WRITE(6,'(6E15.6)') (a(i,j),j=1,nv)
      END DO
      WRITE(3,*) 'Leaving Print'
      RETURN
      END Subroutine Print



!+
      SUBROUTINE Qrt (a, n, r, sig, d, max)
! ----------------------------------------------------------------------
      INTEGER max
      REAL,INTENT(IN OUT):: a(max,max)
      INTEGER,INTENT(IN):: n
      REAL,INTENT(IN):: r
      REAL,INTENT(IN):: sig
      REAL,INTENT(IN):: d


      REAL psi(2), g(3)
!-----------------------------------------------------------------------
      WRITE(3,*) 'Entering Qrt, n=', n
      n1=n-1
      ia=n-2 ! just guessing  RLC  4Nov99
      ip=ia

      IF (n-3) 350,50,10

   10 DO 40 j=3,n1
        j1=n-j
        IF (abs(a(j1+1,j1))-d) 50,50,20
   20   den=a(j1+1,j1+1)*(a(j1+1,j1+1)-sig)+a(j1+1,j1+2)*a(j1+2,j1+1)+r
        IF (den) 30,40,30
   30   IF (abs(a(j1+1,j1)*a(j1+2,j1+1)*(abs(a(j1+1,j1+1)+a(j1+2,j1+2)- &
     &   sig)+abs(a(j1+3,j1+2)))/den)-d) 50,50,40
   40   ip=j1

   50 DO 60 j=1,ip
        j1=ip-j+1
        IF (abs(a(j1+1,j1))-d) 70,70,60
   60   iq=j1

   70 DO 340 i=ip,n1
!!!        IF (i-ip) 90,80,90
        IF (i /= ip) GO TO 90

   80   g(1)=a(ip,ip)*(a(ip,ip)-sig)+a(ip,ip+1)*a(ip+1,ip)+r
        g(2)=a(ip+1,ip)*(a(ip,ip)+a(ip+1,ip+1)-sig)
        g(3)=a(ip+1,ip)*a(ip+2,ip+1)
        a(ip+2,ip)=0.0
        GO TO 120

   90   g(1)=a(i,i-1)
        g(2)=a(i+1,i-1)
!!!        IF (i-ia) 100,100,110
        IF (i > ia) GO TO 110

  100   g(3)=a(i+2,i-1)
        GO TO 120

  110   g(3)=0.0

  120   xk=SIGN(SQRT(g(1)**2+g(2)**2+g(3)**2),g(1))
        IF (xk) 130,140,130
  130   al=g(1)/xk+1.0
        psi(1)=g(2)/(g(1)+xk)
        psi(2)=g(3)/(g(1)+xk)
        GO TO 150

  140   al=2.0
        psi(1)=0.0
        psi(2)=0.0

  150   IF (i-iq) 160,190,160

  160   IF (i-ip) 180,170,180

  170   a(i,i-1)=-a(i,i-1)
        GO TO 190

  180   a(i,i-1)=-xk

  190   DO 240 j=i,n
          IF (i-ia) 200,200,210

  200     c=psi(2)*a(i+2,j)
          GO TO 220

  210     c=0.0

  220     e=al*(a(i,j)+psi(1)*a(i+1,j)+c)
          a(i,j)=a(i,j)-e
          a(i+1,j)=a(i+1,j)-psi(1)*e
          IF (i-ia) 230,230,240

  230     a(i+2,j)=a(i+2,j)-psi(2)*e

  240   CONTINUE

        IF (i-ia) 250,250,260

  250   l=i+2
        GO TO 270

  260   l=n

  270   DO 320 j=iq,l
          IF (i-ia) 280,280,290

  280     c=psi(2)*a(j,i+2)
          GO TO 300

  290     c=0.0

  300     e=al*(a(j,i)+psi(1)*a(j,i+1)+c)
          a(j,i)=a(j,i)-e
          a(j,i+1)=a(j,i+1)-psi(1)*e
          IF (i-ia) 310,310,320

  310     a(j,i+2)=a(j,i+2)-psi(2)*e
  320   END DO

        IF (i-n+3) 330,330,340

  330   e=al*psi(2)*a(i+3,i+2)
        a(i+3,i)=-e
        a(i+3,i+1)=-psi(1)*e
        a(i+3,i+2)=a(i+3,i+2)-psi(2)*e

  340 END DO

  350 WRITE(3,*) 'Leaving Qrt'
      RETURN
      END Subroutine Qrt   ! ------------------------------------------------

!+
      SUBROUTINE Reig (a, m, nval, nvec, rootr, rooti, vec, max, idx,   &
     &irn, p, np, save)
! ----------------------------------------------------------------------
!        program to call qr transformation, variable dimension
!        maximum iter is 50
  REAL,INTENT(IN OUT),DIMENSION(:,:):: a
  INTEGER,INTENT(IN):: m
  INTEGER,INTENT(IN):: nval,nvec
  REAL,INTENT(OUT),DIMENSION(:):: rootr,rooti
  REAL,INTENT(OUT),DIMENSION(:,:):: vec
  INTEGER,INTENT(IN):: max
  REAL,INTENT(OUT),DIMENSION(:):: idx
  REAL,INTENT(OUT),DIMENSION(:):: irn
  REAL,INTENT(IN OUT),DIMENSION(:):: p
  INTEGER,INTENT(IN):: np
  REAL,INTENT(OUT),DIMENSION(:,:):: save

!!!      DIMENSION a(max,max), rootr(max), rooti(max), vec(max,max),       &
!!!     &idx(max), irn(max), p(max), save(max,np)
!!!      REAL idx,irn
  INTEGER:: n
!-----------------------------------------------------------------------
      WRITE(3,*) 'Entering Reig, m=', m
      n=m

!        SAVE ORIGINAL MATRIX,  RESTORE AT 200
      DO i=1,m
        DO j=1,m
          save(j,i)=a(j,i)
        END DO
      END DO

!        REDUCE MATRIX TO HESSENBERG FORM
        CALL hessen (a, m, max)
!        zero=0.0   ! never used
        jj=1
   10   xnn=0.0
        xn2=0.0
        aa=0.0
        b=0.0
        c=0.0
        dd=0.0
        r=0.0
        sig=0.0
        iter=0
        IF (n-2) 20,30,40
   20   rootr(1)=a(1,1)
        rooti(1)=0.0
        GO TO 320

   30   jj=-1

   40   x=(a(n-1,n-1)-a(n,n))**2
        s=4.0*a(n,n-1)*a(n-1,n)
        iter=iter+1
        IF (x.EQ.0.0) GO TO 80
        IF (abs(s/x).GT.1.0e-8) GO TO 80
        IF (abs(a(n-1,n-1))-abs(a(n,n))) 60,60,50

   50   e=a(n-1,n-1)
        g=a(n,n)
        GO TO 70

   60   g=a(n-1,n-1)
        e=a(n,n)

   70   f=0.0
        h=0.0
        GO TO 130

   80   s=x+s
        x=a(n-1,n-1)+a(n,n)
        sq=sqrt(abs(s))
        IF (s) 120,90,90

   90   f=0.0
        h=0.0
        IF (x) 100,100,110

  100   e=(x-sq)/2.0
        g=(x+sq)/2.0
        GO TO 130

  110   g=(x-sq)/2.0
        e=(x+sq)/2.0
        GO TO 130

  120   f=sq/2.0
        e=x/2.0
        g=e
        h=-f

  130   IF (jj.LT.0) GO TO 140
        d=1.0e-10*(abs(g)+f)
        IF (abs(a(n-1,n-2)).GT.d) GO TO 150

  140   rootr(n)=e
        rooti(n)=f
        rootr(n-1)=g
        rooti(n-1)=h
        n=n-2
        IF (jj) 320,10,10

  150   IF (abs(a(n,n-1)).GT.1.0e-10*abs(a(n,n))) GO TO 170

  160   rootr(n)=a(n,n)
        rooti(n)=0.0
        n=n-1
        GO TO 10

  170   IF (abs(abs(xnn/a(n,n-1))-1.0)-1.0e-6) 190,190,180

  180   IF (abs(abs(xn2/a(n-1,n-2))-1.0)-1.0e-6) 190,190,240

  190   vq=abs(a(n,n-1))-abs(a(n-1,n-2))
        IF (iter-15) 260,200,230

  200   IF (vq) 210,210,220

  210   r=a(n-1,n-2)**2
        sig=2.0*a(n-1,n-2)
        GO TO 310

  220   r=a(n,n-1)**2
        sig=2.0*a(n,n-1)
        GO TO 310

  230   IF (vq) 160,160,140

  240   IF (iter.GT.50) GO TO 190
        IF (iter.GT.5) GO TO 260
        z1=((e-aa)**2+(f-b)**2)/(e*e+f*f)
        z2=((g-c)**2+(h-dd)**2)/(g*g+h*h)
        IF (z1-0.25) 250,250,280

  250   IF (z2-0.25) 260,260,270

  260   r=e*g-f*h
        sig=e+g
        GO TO 310

  270   r=e*e
        sig=e+e
        GO TO 310

  280   IF (z2-0.25) 290,290,300

  290   r=g*g
        sig=g+g
        GO TO 310

  300   r=0.0
        sig=0.0

  310   xnn=a(n,n-1)
        xn2=a(n-1,n-2)
        CALL qrt (a, n, r, sig, d, max)
        aa=e
        b=f
        c=g
        dd=h
        GO TO 40
!        RESTORE MATRIX

!!!  320   DO 330 j=1,m
!!!          DO 330 i=1,m
!!!  330     a(i,j)=save(i,j)
   320 a(1:m,1:m)=save(1:m,1:m)

!        TEST FOR COMPLEX ROOTS
        n=0
        nc=m+1
        DO 380 i=1,m
          IF (rootr(i).EQ.0.) GO TO 340
          IF (abs(rooti(i)/rootr(i)).GE.1.e-12) GO TO 350
  340     IF (abs(rooti(i)).LT.1.e-12) GO TO 360

!        INDEX FOR COMPLEX (END OF ARRAYS)
  350     nc=nc-1
          jm=nc
          GO TO 370
!        INDEX FOR REAL ROOTS SAME, N = NO. REAL ROOTS
  360     n=n+1
          jm=n

  370     irn(jm)=rootr(i)
          idx(jm)=rooti(i)
  380    END DO
!        REAL ROOTS IN DESCENDING ORDER BY MAGNITUDE
        DO 410 i=1,m
          IF (i.GE.n) GO TO 400
          k=i+1
          DO 390 j=k,n
            IF (abs(irn(i)).GE.abs(irn(j))) GO TO 390
            sig=irn(j)
            irn(j)=irn(i)
            irn(i)=sig
  390     END DO
  400     rootr(i)=irn(i)
          rooti(i)=idx(i)
!        STORE ZERO IN VECTOR
          DO 411 j=1,m
            vec(j,i)=0.0
  411     END DO
  410   END DO

        IF (nvec.LT.n) n=nvec
        IF (n.LE.0) GO TO 440
        DO 420 i=1,n
          k=n+1-i
          IF (abs(rootr(k)/rootr(1)).GT.1.e-14) GO TO 430
          rootr(k)=0.
  420  END DO

  430   CONTINUE
!        CALL ROUTINE FOR N VECTORS
        CALL Vector (idx, irn, rootr, a, vec, m, save, p, np, max, n)

  440 WRITE(3,*) 'Leaving Reig'
      RETURN
      END Subroutine Reig   ! -----------------------------------------------


!+
      SUBROUTINE Subpr()
! ----------------------------------------------------------------------
!      COMMON wingno,calcno,mach,brl,ur,tanlea,msubn,eps,k1,d1k,d2k,d3k,
!     &nu,nv,wh(6),wa(6),gh(6),ga(6)
      INCLUDE 'blk.inc'
      INCLUDE 'wws.inc'
!      COMMON /wws/ one(6,6),two(6,6),three(6,6),four(6,6),five(6,6),
!     &six(6,6),seven(6,6),eight(6,6),nine(6,6),ten(6,6),eleven(6,6),
!     &twelve(6,6),thirt(6,6),fourt(6,6),fift(6,6),sixt(6,6),sevent(6,6)
!     &eightt(6,6),ninet(6,6),twenty(6,6),twent1(6,6),twent2(6,6),
!     &twent3(6,6)
!-----------------------------------------------------------------------
      WRITE(3,*) 'Entering Subpr'
      kpr=1
      CALL Print (kpr, one, nu, nu)
      kpr=kpr+1
      CALL Print (kpr, two, nu, nu)
      kpr=kpr+1
      CALL Print (kpr, three, nu, nu)
      kpr=kpr+1
      CALL Print (kpr, four, nu, nu)
      kpr=kpr+1
      CALL Print (kpr, five, nu, nu)
      kpr=kpr+1
      CALL Print (kpr, six, nu, nv)
      kpr=kpr+1
      CALL Print (kpr, seven, nu, nv)
      kpr=kpr+1
      CALL Print (kpr, eight, nu, nv)
      kpr=kpr+1
      CALL Print (kpr, nine, nu, nv)
      kpr=kpr+1
      CALL Print (kpr, ten, nu, nv)
      kpr=kpr+1
      CALL Print (kpr, eleven, nu, nv)
      kpr=kpr+1
      CALL Print (kpr, twelve, nu, nv)
      kpr=kpr+1
      CALL Print (kpr, thirt, nu, nv)
      kpr=kpr+1
      CALL Print (kpr, fourt, nu, nv)
      kpr=kpr+1
      CALL Print (kpr, fift, nu, nv)
      kpr=kpr+1
      CALL Print (kpr, sixt, nv, nv)
      kpr=kpr+1
      CALL Print (kpr, sevent, nv, nv)
      kpr=kpr+1
      CALL Print (kpr, eightt, nv, nv)
      kpr=kpr+1
      CALL Print (kpr, ninet, nv, nv)
      kpr=kpr+1
      CALL Print (kpr, twenty, nv, nv)
      kpr=kpr+1
      CALL Print (kpr, twent1, nv, nv)
      kpr=kpr+1
      CALL Print (kpr, twent2, nv, nv)
      kpr=kpr+1
      CALL Print (kpr, twent3, nv, nv)

      WRITE(3,*) 'Leaving Subpr'
      RETURN
      END Subroutine Subpr   !----------------------------------------------


!+
      SUBROUTINE Ucb (n, y, z, dz, bn)
! ----------------------------------------------------------------------
      INTEGER,INTENT(IN):: n
      REAL,INTENT(IN):: y
      REAL,INTENT(OUT):: z
      REAL,INTENT(OUT):: dz
      REAL,INTENT(OUT):: bn

      REAL,PARAMETER,DIMENSION(6):: B = (/ &
     & 1.8751041,4.69409113,7.85475743,10.995541,14.1371684,17.27876/)
!!!      DIMENSION b(6)
!!!      DATA (b(i),i=1,6)/1.8751041,4.69409113,7.85475743,10.995541,      &
!!!     &14.1371684,17.27876/
!-----------------------------------------------------------------------
      WRITE(3,*) 'Entering Ucb, n=', n
      u=2.*y-1.
      IF (n <= 6) THEN
        bn=b(n)
      ELSE
        bn=REAL(2*n-1)*1.57079633
      END IF
      p=bn/2.
      a=p*u
      s=((exp(a)-exp(-a))/(exp(p)-exp(-p))+cos(a)/cos(p))/2.
      t=((exp(a)+exp(-a))/(exp(p)+exp(-p))+sin(a)/sin(p))/2.

      IF (n > (n/2)*2) THEN
        z=t                        ! n is odd
        dz=bn*s*cos(p)/sin(p)
      ELSE
        z=s                        ! n is even
        dz=-bn*t*sin(p)/cos(p)
      END IF

      WRITE(3,*) 'Leaving Ucb'
      RETURN
      END Subroutine Ucb



!+
      SUBROUTINE Vector (x, xx, lamba, a, igvect, n, aprime, bum, nx,   &
     &nmax, nv)
! ----------------------------------------------------------------------
      INTEGER,INTENT(IN):: nmax
      INTEGER,INTENT(IN):: n
      INTEGER,INTENT(IN):: nx
      INTEGER,INTENT(IN):: nv
      REAL,INTENT(OUT),DIMENSION(nmax):: x
      REAL,INTENT(OUT),DIMENSION(nmax):: xx
      REAL,INTENT(IN),DIMENSION(nmax):: lamba
      REAL,INTENT(IN OUT),DIMENSION(nmax,nmax):: a
      REAL,INTENT(OUT),DIMENSION(nmax,nmax):: igvect
      REAL,INTENT(OUT),DIMENSION(nmax,nx):: aprime
      REAL,INTENT(OUT),DIMENSION(nmax):: bum
!!!      REAL igvect,lamba
!!!      DIMENSION x(nmax), xx(nmax), a(nmax,nmax), igvect(nmax,nmax),     &
!!!     &aprime(nmax,nx), lamba(nmax), bum(nmax)
!-----------------------------------------------------------------------

      WRITE(3,*) 'Entering Vector, n,nx,nv=', n,nx,nv
      ny=n-1
      zt=abs(lamba(1))
      bum(n)=1.0
      maxit=50
      const=1.e-12
!
      DO 330 ii=1,nv
        iconst=0
        jon=1
!        STORE 0 IN XX.  APRIME = A - LAMBA I.  LAST COL = 1.0
        DO 10 j=1,n
          igvect(j,ii)=REAL(j)
   10   END DO
        DO 30 k=1,n
          xx(k)=0.0
          aprime(k,nx)=1.0
          DO 20 i=1,n
            aprime(i,k)=a(i,k)
   20     END DO
          aprime(k,k)=a(k,k)-lamba(ii)
   30   END DO

!        JPIV = ROW INDEX,  KPIV = COL. INDEX FOR PIVOTAL STRATEGY
        DO 150 i=1,ny
          piv=0.0
          jpiv=i
          kpiv=i
          i2=i
          DO 40 jx=i2,n
            DO 41 ik=i2,n
              IF (abs(piv).GT.abs(aprime(jx,ik))) GO TO 40
              jpiv=jx
              kpiv=ik
              piv=aprime(jx,ik)
   41       END DO
   40     END DO

          IF (jpiv.EQ.i2) GO TO 60
          DO 50 jx=i2,nx
            swap=aprime(i2,jx)
            aprime(i2,jx)=aprime(jpiv,jx)
            aprime(jpiv,jx)=swap
   50     END DO

   60     IF (kpiv.EQ.i2) GO TO 80
          DO 70 jx=1,n
            swap=aprime(jx,i2)
            aprime(jx,i2)=aprime(jx,kpiv)
            aprime(jx,kpiv)=swap
   70     END DO

          swap=igvect(i2,ii)
          igvect(i2,ii)=igvect(kpiv,ii)
          igvect(kpiv,ii)=swap
!        TEST FOR MULTIPLE ROOTS

   80     piz=abs(piv/zt)
          IF (piz.GT.const) GO TO 120
          jon=2
          mult=n-i2
          DO 90 ik=1,n
            x(ik)=0.0
   90     END DO

          x(i2)=1.0
          IF (i2.EQ.1) GO TO 220
          nnn=ny-mult
          DO 110 jx=1,nnn
            nn=i2-jx
            DO 100 ix=1,i2
              jo=ix+nn
              x(nn)=x(nn)-x(jo)*aprime(nn,jo)
              IF (jo.EQ.i2) GO TO 110
  100       END DO
  110     END DO

          GO TO 220
!        GAUSSIAN ELIMINATION
  120     sum=1./aprime(i,i)
          bum(i)=sum
          DO 130 j=i,nx
            aprime(i,j)=aprime(i,j)*sum
  130     END DO

          nn=i+1
          DO 151 jj=nn,n
          DO 140 iz=nn,nx
            aprime(jj,iz)=aprime(jj,iz)-aprime(jj,i)*aprime(i,iz)
  140     END DO
  151     END DO
  150   END DO

        IF (lamba(ii).EQ.0.) GO TO 160
        IF (abs(aprime(n,n)/zt).GE.const) GO TO 180
  160   DO 170 ik=1,n
          aprime(ik,nx)=0.0
  170   END DO

        jon=2
!        BACK SUBSTITUTION
  180   x(n)=1.0
        IF (jon.NE.2) x(n)=aprime(n,nx)/aprime(n,n)
        DO 190 jx=1,ny
          x(jx)=aprime(jx,nx)
  190   END DO

        DO 210 jx=1,ny
          nn=n-jx
          DO 200 ik=1,n
            jo=ik+nn
            x(nn)=x(nn)-x(jo)*aprime(nn,jo)
            IF (jo.EQ.n) GO TO 210
  200     END DO
  210   END DO

!        NORMALIZE VECTOR
  220   sum=0.0
        DO 230 ik=1,n
          sum=x(ik)**2+sum
  230   END DO

        sum=sqrt(sum)
        DO 240 jx=1,n
          x(jx)=x(jx)/sum
  240   END DO

        IF (jon.EQ.2) GO TO 290
        rdiff=0.0
        DO 250 ik=1,n
          rdiff=(abs(x(ik))-abs(xx(ik)))**2+rdiff
          xx(ik)=x(ik)
  250   END DO

        rdiff=sqrt(rdiff)
        IF (rdiff.LT.const) GO TO 290
        IF (iconst.EQ.maxit) GO TO 340
        iconst=iconst+1
        DO 260 ik=1,n
          aprime(ik,nx)=x(ik)
  260   END DO

        DO 280 iz=1,n
          aprime(iz,nx)=bum(iz)*aprime(iz,nx)
          jx=iz+1
          IF (jx.GT.n) GO TO 280
          DO 270 ik=jx,n
            aprime(ik,nx)=aprime(ik,nx)-aprime(iz,nx)*aprime(ik,iz)
  270     END DO
  280   END DO

        GO TO 180


!        REARRANGE ELEMENTS IN X
  290   DO 310 j=1,n
  300     i2=ifix(igvect(j,ii))
          IF (i2.EQ.j) GO TO 310
          swap=x(i2)
          x(i2)=x(j)
          x(j)=swap
          swap=igvect(i2,ii)
          igvect(i2,ii)=igvect(j,ii)
          igvect(j,ii)=swap
          GO TO 300
  310   END DO

!        COLUMN VECTOR
        DO 320 j=1,n
          igvect(j,ii)=x(j)
  320   END DO

  330 END DO
      WRITE(3,*) 'Leaving Vector (converged)'
      RETURN

!        NON-CONVERGENCE
  340 WRITE(6,350)
  350 FORMAT (//10x,' NON CONVERGENCE VECTOR IN 50 ITERATIONS')
      WRITE(3,*) 'Leaving Vector (non-converged)'
      RETURN
      END Subroutine Vector   ! --------------------------------------------




END Module FlutterProcedures






!+
      PROGRAM flutter
! ----------------------------------------------------------------------

USE FlutterProcedures

      INTEGER gtest
!      COMMON wingno,calcno,mach,brl,ur,tanlea,msubn,eps,k1,d1k,d2k,d3k,
!     &nu,nv,wh(6),wa(6),gh(6),ga(6)
      INCLUDE 'blk.inc'
      COMMON mr,ra,xa,a,b,clan,acn,ent,jmax,h,dh,alph,dalph,            &
     &nc,upper,lower,eta
      COMMON nopt1,nopt2,n,etac(6),uc(6),xc(6),ac(6),bc(6),hc(6,6),     &
     &alphc(6,6),us,ws,gs,etas,xs,hs(6),alphs(6),as,bs,npr1,npr2,npr3,  &
     &nplot
      COMMON nopts,tabk(100),tabfg(100)
      COMMON xm1(10),xm2(10),iden1,iden2
!      COMMON /wws/ one(6,6),two(6,6),three(6,6),four(6,6),five(6,6),
!     &six(6,6),seven(6,6),eight(6,6),nine(6,6),ten(6,6),eleven(6,6),
!     &twelve(6,6),thirt(6,6),fourt(6,6),fift(6,6),sixt(6,6),sevent(6,6)
!     &eightt(6,6),ninet(6,6),twenty(6,6),twent1(6,6),twent2(6,6),
!     &twent3(6,6)

      INCLUDE 'wws.inc'

      DIMENSION h(51,6), dh(51,6), alph(51,6), dalph(51,6), eta(51),    &
     &bsq(51), bcube(51), bf8a(51), clb(51), clbb(51), mrb(51), ca(51), &
     &caa(51), ama(51), caaa(51), mr(51), ra(51), xa(51), a(51), b(51), &
     &clan(51), acn(51), ent(51)
      DIMENSION whsq(6), wasq(6), bdiv(6,6), br(6,6), bi(6,6), ddiv(6,6)&
     &, dr(6,6), di(6,6), aiz(6), arz(6), adivz(6), ar(6,6), ai(6,6),   &
     &adiv(6,6), erz(6), eiz(6), er(6,6), ediv(6,6), ei(6,6), bpsq(6),  &
     &bpar(6), atotr(13,13), atoti(13,13), divt(12,12),                 &
     &adiagr(13), adiagi(13), divg(12,12)

!!!      DIMENSION plot1(1000), plot2(1000), plot3(1000)

                                    ! , date(2)
      DIMENSION rtr(12), rti(12)

      DIMENSION delta(3), wwr(13), vbw(13), lg(13)
      EQUIVALENCE (d1k,delta)

      DIMENSION irun(12)
      dimension ddiag(12)
      EQUIVALENCE (irun,ddiag)


!!!      REAL nine,ninet
!!!      REAL msubn,mach
!      INTEGER calcno
!      DATA ym/'G'/

      REAL aj(6,1)
      REAL ak(1,6)
      COMPLEX ans(16,13)
      COMPLEX ans1D(208)
      REAL ansi(13)
      REAL ansr(13)
      COMPLEX asave(13,13)
      COMPLEX cca(13,13)
      COMPLEX cksave(208)
      COMPLEX denom
      COMPLEX eax(13)
      COMPLEX eb(13,13)
      REAL ebReal(13,13)   ! added by RLC
      COMPLEX eck(13)
      REAL edivz(6)


      INTEGER errCode
      COMPLEX evk(13)
      COMPLEX ex(13)
      REAL f(6,1)
      CHARACTER*80 fileName
      REAL g(1,6)
      INTEGER indat
      REAL ksq,kcube
      REAL lower,lg
      INTEGER nsav(13)
      REAL nsavDummy(13)   ! added by RLC
      COMPLEX numer
      DATA numer/(1.0,0.0)/
      REAL mr,mrb
!      CHARACTER*80 xm1,xm2,method,iden1,iden2
      COMPLEX p
      REAL r(13)
      COMPLEX seval(13)
      REAL theta(13)
      COMPLEX vbrwr(12)
      COMPLEX vec(13)
      COMPLEX vksave(208)
      REAL x(12), y(12)

      NAMELIST /NAM1/ a,ac,acn,alph,alphc,alphs,as,b,bc,brl,bs,clan,    &
     & d1k,d2k,d3k,dalph,dh,ent,eps,eta,etac,etas,ga,gh,gs,h,hc,hs,     &
     & jmax,k1,lower,mach,mr,msubn,n,nc,nev,nn,nopt1,nopt2,nopts,nplot, &
     & npr1,npr2,npr3,nu,nv,ra,tabfg,tabk,tanlea,uc,upper,ur,us,wa,wh,  &
     & wingno,ws,xa,xc,xs

!!!      NAMELIST/NAM1/wingno,mach,brl,ur,tanlea,msubn,eps,k1,d1k,d2k,
!!!     &d3k,nu,nv,wh,wa,gh,ga,mr,ra,xa,a,b,clan,acn,ent,jmax,h,dh,alph,
!!!     &dalph,nc,upper,lower,eta,nopt1,nopt2,n,etac,uc,xc,ac,bc,hc,alph
!!!     &us,ws,gs,etas,xs,hs,alphs,as,bs,npr1,npr2,npr3,nplot,nopts,tabk
!!!     &tabfg,nev,nn
!-----------------------------------------------------------------------
      INDAT=1
      DO
        WRITE(*,*) "Enter the name of the input file:"
        READ(*,'(A)') fileName
        IF (fileName .EQ. ' ') STOP
        OPEN(UNIT=INDAT,FILE=fileName,STATUS='OLD',IOSTAT=errCode,ACTION='READ')
        IF (errCode .EQ. 0) EXIT
        WRITE(*,*) "Unable to open this file for input. Try again."
      END DO

      OPEN(UNIT=6, FILE='flutter.out', STATUS='REPLACE',ACTION='WRITE')
      OPEN(UNIT=3, FILE='flutter.dbg', STATUS='REPLACE',ACTION='WRITE')

   10 READ(INDAT,NAM1,IOSTAT=errCode)
      IF (errCode .LT. 0) THEN
        WRITE(*,*) "No more input records"
        WRITE(6,*) "No more input records"
        STOP
      END IF

!      IF (eof,5) 20,30
!   20 STOP
!   30 READ(5,'(A)') xm1
!      READ(5,'(A)') xm2
!      READ(5,'(A)') iden1,iden2
!      READ(5,'(A)') method
!      READ(5,'(A)') calcno
!   40 FORMAT (a6)
!   50 FORMAT (10a6)
!   60 FORMAT (2a6)
!
!***********************************************************************
!   IF NC IS NOT EQUAL TO ZERO, COMPUTE VIBRATION MODES
!   IF NC IS EQUAL TO ZERO, VIBRATION MODES GIVEN AS INPUT
!
      IF (nc .NE. 0) THEN
        DO i=1,nv
          cof=1.5707963*float(2*i-1)
          DO j=1,jmax
            alph(j,i)=(-1.)**(i-1)*SIN(cof*eta(j))
            dalph(j,i)=(-1.)**(i-1)*cof*COS(cof*eta(j))
          END DO
        END DO

        DO i=1,nu
          DO j=1,jmax
            CALL Ucb (i, eta(j), h(j,i), dh(j,i), eig)
          END DO
        END DO
      END IF
!***********************************************************************

!!!   90 CALL inp1()
      CALL PrintInput()

      WRITE(6,100) upper,lower
  100 FORMAT ("upperlimitfork=",ES15.6,"    lowerlimitfork=",ES15.6)

      WRITE(6,110) jmax
  110 FORMAT (6x,'JMAX =',i4)

      WRITE(6,120) nev
  120 FORMAT (" nev=",i3)

      IF (nev.EQ.0) GO TO 140
      WRITE(6,130) nn
  130 FORMAT (" nn=",i3)
  140 CONTINUE

      WRITE(6,*) 'WING STRUCTURE AND INTEGRATING FACTORS'
      WRITE(6,150)
  150 FORMAT (//3x,'ETA', 8x, &
     & 'MR', 8x,'RASQ',8x,'XA',8x,'A',8x,'B',8x,'I. F.')

      DO 160 i=1,jmax
        WRITE(6,170) eta(i),mr(i),ra(i),xa(i),a(i),b(i),ent(i)
  160 END DO
  170 FORMAT (F6.3,6ES13.5)

      WRITE(6,*) ' '
      WRITE(6,*) 'VIBRATION MODES'
      WRITE(6,180)
  180 FORMAT (//8x,'ETA',8x,'H1',8x,'H2',8x,'H3',   &
     & 8x,'H4', 8x,'H5',8x,'H6')

      DO 190 i=1,jmax
        WRITE(6,170) eta(i),(h(i,j),j=1,nu)
  190 END DO

!      WRITE(6,200)
  200 FORMAT ('0')

      WRITE(6,210)
  210 FORMAT (/3x,'ETA',7X,'DH1',7X,'DH2',7X,'DH3',7X,              &
     &  'DH4',7X,'DH5',7X,'DH6')

      DO 220 i=1,jmax
        WRITE(6,170) eta(i),(dh(i,j),j=1,nu)
  220 END DO

!      WRITE(6,200)

      WRITE(6,230)
  230 FORMAT (/3x,'ETA',5X,'ALPHA1',5X,'ALPHA2',5X,'ALPHA3',5X,         &
     & 'ALPHA4',5X,'ALPHA5',5X,'ALPHA6')

      DO 240 i=1,jmax
        WRITE(6,170) eta(i),(alph(i,j),j=1,nv)
  240 END DO

!      WRITE(6,200)

      WRITE(6,250)
  250 FORMAT (/5x,'ETA',8X,'DALPHA1',8X,'DALPHA2',8X,'DALPHA3',8X,      &
     &  'DALPHA4',8X,'DALPHA5',8X,'DALPHA6')

      DO 260 i=1,jmax
        WRITE(6,170) eta(i),(dalph(i,j),j=1,nv)
  260 END DO

      WRITE(6,270)
  270 FORMAT (/'AERODYNAMIC COEFFICIENTS'/3x,'ETA',8X,'CLAN',8X,'ACN')

      DO 280 i=1,jmax
        WRITE(6,170) eta(i),clan(i),acn(i)
  280 END DO

!      WRITE(6,200)

      IF (nopt1 .EQ. 0) GO TO 400

      WRITE(6,290) n
  290 FORMAT (/' OPTION 1',10X,'N=',I4/6X,'K =',10X,'1',19X,'2',19X,    &
     & '3',19X,'4', 19X,'5',19X,'6')

      WRITE(6,300) (etac(i),i=1,n)
  300 FORMAT (2x,'ETACK =', 6e20.8)

      WRITE(6,310) (uc(i),i=1,n)
  310 FORMAT (4x,'UCK =', 6e20.8)

      WRITE(6,320) (xc(i),i=1,n)
  320 FORMAT (4x,'XCK =', 6e20.8)

      WRITE(6,330) (ac(i),i=1,n)
  330 FORMAT (4x,'ACK =', 6e20.8)

      WRITE(6,340) (bc(i),i=1,n)
  340 FORMAT (4x,'BCK =', 6e20.8)

      DO 350 i=1,nu
        WRITE(6,360) (hc(k,i),k=1,n)
  350 END DO
  360 FORMAT (4x,'HCK =', 6e20.8)

      DO 370 i=1,nv
        WRITE(6,380) (alphc(k,i),k=1,n)
  370 END DO
  380 FORMAT (' ALPHCK =', 6e20.8)

  390 FORMAT (6ES14.5)
  400 IF (nopt2.EQ.0) GO TO 440

      WRITE(6,410) etas,xs,us,ws,gs,as,bs
  410 FORMAT (/'OPTION 2'/3x,'ETAS =',e20.8,10x,'XS =',e20.8,6x,        &
     & 'US =', e20.8,6x,'WS/WR =', e20.8/5x,'GS =', e20.8,10x,'AS =',   &
     & e20.8,6x,'BS =', e20.8/6x,'I =',10x,'1',19x,'2',19x,'3',19x,     &
     & '4',19x,'5',19x,'6')

      WRITE(6,420) (hs(i),i=1,nu)
  420 FORMAT (5x,'HS =',6ES20.8)

      WRITE(6,430) (alphs(i),i=1,nv)
  430 FORMAT ('  ALPHS =',6ES20.8)
!
!***********************************************************************
!
  440 DO 450 i=1,nu
        whsq(i)=wh(i)**2
  450 END DO

      DO 460 i=1,nv
        wasq(i)=wa(i)**2
  460 END DO

!
!***********************************************************************
!
      ij=1
      kount=0
!
!***********************************************************************
!  COMPUTE INTEGRALS
!
      DO 470 i=1,jmax
        bsq(i)=b(i)**2
        bcube(i)=b(i)*bsq(i)
        bf8a(i)=bsq(i)**2*(.125+a(i)**2)
        clb(i)=clan(i)*eps*b(i)
        clbb(i)=clan(i)*eps*bsq(i)
        mrb(i)=mr(i)*b(i)
        ca(i)=(clan(i)*eps)/6.2831853+acn(i)
        caa(i)=ca(i)-a(i)
        ama(i)=a(i)-acn(i)
        caaa(i)=caa(i)*ama(i)
  470 END DO

      DO 480 i=1,nu
        DO 481 j=1,nu
          one(i,j)=0.0
          two(i,j)=0.0
          three(i,j)=0.0
          four(i,j)=0.0
          five(i,j)=0.0
          DO 482 k=1,jmax
            one(i,j)=one(i,j)+mr(k)*h(k,i)*h(k,j)*ent(k)
            two(i,j)=two(i,j)+bsq(k)*h(k,i)*h(k,j)*ent(k)
            three(i,j)=three(i,j)+clb(k)*h(k,i)*h(k,j)*ent(k)
            four(i,j)=four(i,j)+clb(k)*dh(k,j)*h(k,i)*ent(k)
            five(i,j)=five(i,j)+bsq(k)*dh(k,j)*h(k,i)*ent(k)
  482     END DO
  481   END DO
  480 END DO

      DO 490 i=1,nu
        DO 491 j=1,nv
          six(i,j)=0.0
          seven(i,j)=0.0
          eight(i,j)=0.0
          nine(i,j)=0.0
          ten(i,j)=0.0
          eleven(i,j)=0.0
          twelve(i,j)=0.0
          thirt(i,j)=0.0
          fourt(i,j)=0.0
          fift(i,j)=0.0
          DO 492 k=1,jmax
            six(i,j)=mrb(k)*xa(k)*h(k,i)*alph(k,j)*ent(k)+six(i,j)
            seven(i,j)=clb(k)*h(k,i)*alph(k,j)*ent(k)+seven(i,j)
            eight(i,j)=                                                 &
     &        clbb(k)*caa(k)*h(k,i)*alph(k,j)*ent(k)+eight(i,j)
            nine(i,j)=bcube(k)*a(k)*h(k,i)*alph(k,j)*ent(k)+nine(i,j)
            ten(i,j)=bsq(k)*h(k,i)*alph(k,j)*ent(k)+ten(i,j)
            eleven(i,j)=                                                &
     &        clbb(k)*caa(k)*dalph(k,j)*h(k,i)*ent(k)+eleven(i,j)
            twelve(i,j)=                                                &
     &        bcube(k)*dalph(k,j)*h(k,i)*a(k)*ent(k)+twelve(i,j)
            thirt(i,j)=                                                 &
     &        clbb(k)*ama(k)*h(k,i)*alph(k,j)*ent(k)+thirt(i,j)
            fourt(i,j)=                                                 &
     &        clbb(k)*ama(k)*dh(k,i)*alph(k,j)*ent(k)+fourt(i,j)
            fift(i,j)=bcube(k)*a(k)*dh(k,i)*alph(k,j)*ent(k)+fift(i,j)
  492     END DO
  491   END DO
  490 END DO

      DO 500 i=1,nv
        DO 501 j=1,nv
          sixt(i,j)=0.0
          sevent(i,j)=0.0
          eightt(i,j)=0.0
          ninet(i,j)=0.0
          twenty(i,j)=0.0
          twent1(i,j)=0.0
          twent2(i,j)=0.0
          twent3(i,j)=0.0
          DO 502 k=1,jmax
            sixt(i,j)=                                                  &
     &       mr(k)*bsq(k)*ra(k)*alph(k,i)*alph(k,j)*ent(k)+sixt(i,j)
            sevent(i,j)=                                                &
     &       clbb(k)*ama(k)*alph(k,i)*alph(k,j)*ent(k)+sevent(i,j)
            eightt(i,j)=bf8a(k)*alph(k,i)*alph(k,j)*ent(k)+eightt(i,j)
            ninet(i,j)=                                                 &
     &       clb(k)*bsq(k)*caaa(k)*alph(k,i)*alph(k,j)*ent(k)+ninet(i,j)
            twenty(i,j)=bcube(k)*                                       &
     &       caa(k)*alph(k,i)*alph(k,j)*ent(k)+twenty(i,j)
            twent1(i,j)=clb(k)*                                         &
     &       bsq(k)*caaa(k)*dalph(k,j)*alph(k,i)*ent(k)+twent1(i,j)
            twent2(i,j)=                                                &
     &       bcube(k)*ca(k)*dalph(k,j)*alph(k,i)*ent(k)+twent2(i,j)
            twent3(i,j)=bf8a(k)*dalph(k,j)*alph(k,i)*ent(k)+twent3(i,j)
  502     END DO
  501   END DO
  500 END DO

      WRITE(3,*) 'Integrals have been computed.'
!
!***********************************************************************
!
!   IF NPR1 IS NOT EQUAL TO ZERO, PRINT INTEGRALS
!
      IF (npr1.NE.0) CALL Subpr()

  510 rpi=1.0/3.1415926
      blrpi=brl*rpi
      brltan=brl*tanlea
      blptan=blrpi*tanlea
      fsubi=1.0
      gsubi=0.0
      nf1=1

  520 trig=-1.0
      ij=1
      WRITE(6,1440) ij
  530 ksq=k1*k1
      kcube=ksq*k1
      IF (msubn.GT.2.0) GO TO 560
!
!***********************************************************************
!
!  COMPUTE REGULAR F AND G
      fsubi=(1.0+8.65538*k1-.271169*ksq)/(1.98936+24.7807*k1+103.774*   &
     &ksq+107.048*kcube)+.5
      gsubi=-(1.0+247.242*k1+855.885*ksq)/(61.8236+930.649*k1+3791.55*  &
     &ksq+6167.5*kcube)
!
!***********************************************************************
!
! IF  MSUBN =0, FC/FI = 1.0
! IF  MSUBN NOT EQUAL TO ZERO, GO TO TABLES FOR FC/FI
!
      IF (msubn .EQ. 0.0) THEN
        corr=1.0
      ELSE
        CALL Ftlup (k1, corr, 1, nopts, tabk, tabfg)
      END IF

  550 fsubi=fsubi*corr
      gsubi=gsubi*corr
!
!***********************************************************************
!
!  COMPUTE A,B,D AND E MATRICES
  560 CONTINUE
      gok=gsubi/k1
      fok=fsubi/k1
      foksq=fsubi/ksq
      goksq=gsubi/ksq
      DO 570 i=1,nu
        DO 571 j=1,nv
          tem1=(brltan*eleven(i,j)+seven(i,j))*rpi
          tem2=rpi*eight(i,j)
          br(i,j)=(-ur*six(i,j)+nine(i,j))-tem2*gok+tem1*foksq
          bi(i,j)=((ten(i,j)-brltan*twelve(i,j))/k1)+tem2*fok+tem1*goksq
  571   END DO
  570 END DO

      DO 580 i=1,nv
        DO 581 j=1,nu
          tem1=rpi*thirt(j,i)
          tem2=blptan*fourt(j,i)
          dr(i,j)=(-ur*six(j,i)+nine(j,i))+tem1*gok-tem2*foksq
          di(i,j)=(-brltan*fift(j,i))/k1-tem1*fok-tem2*goksq
  581   END DO
  580 END DO

      DO 600 i=1,nu
        DO 601 j=1,nu
          temp=0.0
          tem1=rpi*three(i,j)
          tem2=blptan*four(i,j)
          IF (i.NE.j) GO TO 590
          temp=ur*one(i,j)
          arz(i)=temp*whsq(i)
          aiz(i)=arz(i)*gh(i)
  590     ar(i,j)=-temp-two(i,j)-tem1*gok+tem2*foksq
          adiv(i,j)=tem2
          ai(i,j)=(brltan*five(i,j))/k1+tem1*fok+tem2*goksq
  601   END DO
  600 END DO

      DO 620 i=1,nv
        DO 621 j=1,nv
          temp=0.0
          tem1=rpi*ninet(i,j)
          tem2=(sevent(i,j)+brltan*twent1(i,j))*rpi
          IF (i.NE.j) GO TO 610
          temp=ur*sixt(i,j)
          erz(i)=temp*wasq(i)
          eiz(i)=erz(i)*ga(i)
  610     er(i,j)=-temp-eightt(i,j)+                                    &
     &      tem1*gok-tem2*foksq+(brltan*twent2(i,j))/ksq
          ei(i,j)=(twenty(i,j)+brltan*twent3(i,j))/k1-                  &
     &      tem1*fok-tem2*goksq
  621   END DO
  620 END DO

      ntot=nu+nv

      WRITE(3,*) 'A,B,D,E matrices have been computed'

      WRITE(3,*) 'Making option choice, nopt1=', nopt1
      IF (nopt1.EQ.0) GO TO 720
!
! OPTION 1
!
      DO 630 k=1,n
        bpar(k)=bc(k)*(1.0+ac(k)+xc(k))
        bpsq(k)=bpar(k)**2
  630 END DO

      DO 650 i=1,nu
        DO 651 j=1,nu
          sum=0.0
          DO 640 k=1,n
            sum=uc(k)*hc(k,i)*hc(k,j)+sum
  640     END DO
          ar(i,j)=ar(i,j)-sum
          IF (i.NE.j) GO TO 651    ! check this   RLC
          temp=sum*whsq(i)
          arz(i)=arz(i)+temp
          adivz(i)=adivz(i)+temp
          aiz(i)=aiz(i)+temp*gh(i)
  651   END DO
  650 END DO

      DO 670 i=1,nu
        DO 670 j=1,nv
        sum=0.0
        DO 660 k=1,n
          sum=uc(k)*bpar(k)*hc(k,i)*alphc(k,j)+sum
  660   END DO
        br(i,j)=br(i,j)+sum
  670 END DO

      DO 690 i=1,nv
        DO 690 j=1,nu
        sum=0.0
        DO 680 k=1,n
          sum=uc(k)*bpar(k)*hc(k,j)*alphc(k,i)+sum
  680   END DO
        dr(i,j)=dr(i,j)+sum
  690 END DO

      DO 710 i=1,nv
        DO 710 j=1,nv
        sum=0.0
        DO 700 k=1,n
          sum=uc(k)*bpsq(k)*alphc(k,i)*alphc(k,j)+sum
  700   END DO
        er(i,j)=er(i,j)-sum
        IF (i.NE.j) GO TO 710
        temp=sum*wasq(i)
        erz(i)=erz(i)+temp
        edivz(i)=edivz(i)+temp
        eiz(i)=eiz(i)+temp*ga(i)
  710 END DO

  720 IF (nopt2.EQ.0) GO TO 810
!
! OPTION 2
!
      DO 730 i=1,nu
        DO 731 j=1,nu
          tem1=us*hs(i)*hs(j)
          ar(i,j)=ar(i,j)-tem1
          IF (i.NE.j) GO TO 730
          tem2=tem1*whsq(i)
          arz(i)=arz(i)+tem2
          adivz(i)=adivz(i)+tem2
          aiz(i)=aiz(i)+tem2*gh(i)
  731   END DO
  730 END DO

      bprod=bs*(1.0+as+xs)
      DO 740 i=1,nu
        DO 741 j=1,nv
        br(i,j)=br(i,j)+us*bprod*hs(i)*alphs(j)
  741 END DO
  740 END DO

      DO 750 i=1,nv
        DO 751 j=1,nu
          dr(i,j)=dr(i,j)+us*bprod*hs(j)*alphs(i)
  751   END DO
  750 END DO

      DO 760 i=1,nv
        DO 761 j=1,nv
        tem1=us*bprod**2*alphs(i)*alphs(j)
        er(i,j)=er(i,j)-tem1
        IF (i.NE.j) GO TO 761
        tem2=tem1*wasq(i)
        erz(i)=erz(i)+tem2
        edivz(i)=edivz(i)+tem2
        eiz(i)=eiz(i)+tem2*ga(i)
  761   END DO
  760 END DO

      DO 770 i=1,nu
        f(i,1)=-us*hs(i)
  770 END DO

      DO 780 j=1,nv
        aj(j,1)=us*bprod*alphs(j)
  780 END DO

      h11r=-us
      h11rz=us*ws**2
      h11iz=h11rz*gs
      DO 790 j=1,nu
        g(1,j)=f(j,1)
  790 END DO

      DO 800 j=1,nv
        ak(1,j)=aj(j,1)
  800 END DO

      WRITE(3,*) 'Completed options'
!
!***********************************************************************
!
!   IF NPR2 IS NOT EQUAL TO ZERO, PRINT ELEMENTS OF DETERMINANT
!
!
  810 IF (npr2.EQ.0) GO TO 1030
      WRITE(6,820)
  820 FORMAT (/'ELEMENTS OF FLUTTER DETERMINANT'/)

      WRITE(6,830)
  830 FORMAT ('  A(I,J)')

      WRITE(6,840)
  840 FORMAT ('   REAL')

      DO 850 i=1,nu
        WRITE(6,390) (ar(i,j),j=1,nu)
  850 END DO

      WRITE(6,860)
  860 FORMAT ('   IMAGINARY')

      DO 870 i=1,nu
        WRITE(6,390) (ai(i,j),j=1,nu)
  870 END DO

      WRITE(6,880)
  880 FORMAT ('   COEFFICIENT OF UNKNOWN')

      WRITE(6,840)
      WRITE(6,390) (arz(i),i=1,nu)
      WRITE(6,860)
      WRITE(6,390) (aiz(i),i=1,nu)
      WRITE(6,890)
  890 FORMAT ('  B(I,J)')

      WRITE(6,840)
      DO 900 i=1,nu
        WRITE(6,390) (br(i,j),j=1,nv)
  900 END DO

      WRITE(6,860)
      DO 910 i=1,nu
        WRITE(6,390) (bi(i,j),j=1,nv)
  910 END DO

      WRITE(6,920)
  920 FORMAT ('  D(I,J)')

      WRITE(6,840)
      DO 930 i=1,nv
        WRITE(6,390) (dr(i,j),j=1,nu)
  930 END DO

      WRITE(6,860)
      DO 940 i=1,nv
        WRITE(6,390) (di(i,j),j=1,nu)
  940 END DO

      WRITE(6,950)
  950 FORMAT ('  E(I,J)')

      WRITE(6,840)
      DO 960 i=1,nv
        WRITE(6,390) (er(i,j),j=1,nv)
  960 END DO

      WRITE(6,860)
      DO 970 i=1,nv
        WRITE(6,390) (ei(i,j),j=1,nv)
  970 END DO

      WRITE(6,880)
      WRITE(6,840)
      WRITE(6,390) (erz(i),i=1,nv)
      WRITE(6,860)
      WRITE(6,390) (eiz(i),i=1,nv)
      IF (nopt2.EQ.0) GO TO 1030
      WRITE(6,980) (f(i,1),i=1,nu)
  980 FORMAT('  F(I,1)'/6e20.8)

      WRITE(6,990) (g(1,i),i=1,nu)
  990 FORMAT ('  G(1,J)'/6e20.8)

      WRITE(6,1000) (aj(i,1),i=1,nv)
 1000 FORMAT ('  J(I,1)'/6e20.8)

      WRITE(6,1010) (ak(1,i),i=1,nv)
 1010 FORMAT ('  K(1,I)'/6e20.8)

      WRITE(6,1020) h11r
 1020 FORMAT ('  H11'/e20.8)

      WRITE(6,880)
      WRITE(6,840)
      WRITE(6,390) h11rz
      WRITE(6,860)
      WRITE(6,390) h11iz


! SET UP TOTAL FLUTTER  DETERMINANT
      WRITE(3,*) 'Setting up total flutter determinant, nu,nv,nopt2=', nu,nv,nopt2
 1030 DO 1040 i=1,nu
        DO 1041 j=1,nu
        atotr(i,j)=ar(i,j)
        atoti(i,j)=ai(i,j)
 1041   END DO
 1040 END DO

      DO 1050 i=1,nv
        nuv=nu+i
        DO 1051 j=1,nu
          atotr(nuv,j)=dr(i,j)
          atoti(nuv,j)=di(i,j)
 1051   END DO
 1050 END DO

      DO 1060 i=1,nu
        DO 1061 j=1,nv
          nuv=nu+j
          atotr(i,nuv)=br(i,j)
          atoti(i,nuv)=bi(i,j)
 1061   END DO
 1060 END DO

      DO 1070 i=1,nv
        nuv1=nu+i
        DO 1071 j=1,nv
          nuv2=nu+j
          atotr(nuv1,nuv2)=er(i,j)
          atoti(nuv1,nuv2)=ei(i,j)
 1071   END DO
 1070 END DO

      DO 1080 i=1,nu
        adiagr(i)=arz(i)
        adiagi(i)=aiz(i)
 1080 END DO

      DO 1090 j=1,nv
        nuv=nu+j
        adiagr(nuv)=erz(j)
        adiagi(nuv)=eiz(j)
 1090 END DO

      IF (nopt2.EQ.0) GO TO 1120
      ntot=ntot+1
      DO 1100 i=1,nu
        atotr(i,ntot)=f(i,1)
        atoti(i,ntot)=0.0
        atotr(ntot,i)=g(1,i)
        atoti(ntot,i)=0.0
 1100 END DO

      DO 1110 j=1,nv
        nuv=nu+1
        atotr(nuv,ntot)=aj(j,1)
        atoti(nuv,ntot)=0.0
        atotr(ntot,nuv)=ak(1,j)
        atoti(ntot,nuv)=0.0
 1110 END DO

      atotr(ntot,ntot)=h11r
      atoti(ntot,ntot)=0.0
      adiagr(ntot)=h11rz
      adiagi(ntot)=h11iz

 1120 DO 1130 i=1,ntot
        denom=-cmplx(adiagr(i),adiagi(i))
        DO 1131 j=1,ntot
          cca(i,j)=cmplx(atotr(i,j),atoti(i,j))/denom
 1131   END DO
 1130 END DO

      p=(0.0,0.0)
      nk3=ntot+3
      mp=ntot*nk3
      kct=1-nk3

      write(3,*) ' 1130 completed!'
      write(3,*) ' ntot=', ntot
      write(3,*) ' mp=', mp
      write(3,*) ' nk3=', nk3
      write(3,*) ' npr3=', npr3


      IF (npr3.NE.0) THEN
        WRITE(6,*) 'NORMALIZED DETERMINANT BY ROWS'
        DO i=1,ntot
          WRITE(6,'(6ES13.5)') (cca(i,j),j=1,ntot)
        END DO
      END IF


      CALL Egnc (cca, p, 13, ntot, ntot, mp, nk3, ex, vec, eax, eck,    &
     &evk, eb, asave, cksave, vksave, seval, nsav, ans, nerr)
      WRITE(3,*) 'In main program, return from Eqnc, nerr=', nerr

      k=0
      DO j=1,13
        DO i=1,16
          k=k+1
          ans1D(k)=ans(i,j)
        END DO
      END DO

      GO TO (1200,1160,1180),nerr
 1160 WRITE(6,1170)
 1170 FORMAT (/' NON CONVERGENCE RETURN FROM LF-EGNC')
      GO TO 1780

 1180 WRITE(6,1190)
 1190 FORMAT (/' SINGULARITY RETURN FROM LF-EGNC')
      GO TO 1780

 1200 DO 1230 j=1,ntot
        kct=kct+nk3
        if=kct+2
        il=if+ntot-1
        ik=il+1
        l=0
        DO 1210 i=if,il
          l=l+1
          cca(l,j)=ans1D(i) ! RLC
 1210   END DO
        cca(l+1,j)=ans1D(ik) ! RLC
        ansr(j)=real(ans1D(kct))       ! RLC
        ansi(j)=aimag(ans1D(kct))   ! RLC
        tem1=real(ans1D(kct+1))    ! RLC
        tem2=aimag(ans1D(kct+1))    ! RLC
        temp=abs(ansr(j))+abs(ansi(j))
        IF (abs((temp-(abs(tem1)+abs(tem2)))/temp).LT..001) GO TO 1230
        WRITE(6,1220) ans1D(kct),ans1D(kct+1)        ! RLC
 1220   FORMAT (/' ROOT=',2ES20.8,' CHECK ROOT=',2ES20.8)
 1230 END DO

      IF (npr3.EQ.0) GO TO 1250
      WRITE(6,1240) (ansr(i),ansi(i),i=1,ntot)
 1240 FORMAT (/' X + IY'/(2e20.8))
!
!***********************************************************************
!    K GUESSER
! NCT1 = COUNT OF REAL, POSITIVE G
! NCT2 = COUNT OF REAL, MINUS G
!
 1250 CONTINUE
      WRITE(3,*) 'Start of K Guesser'
      
!!!      nlg=0     ! never used
      nct1=0
      nct2=0
!!!      enk=1.0/k1  ! never used
      WRITE(6,1260)
 1260 FORMAT (/7x,'K',10X,'G',11X,'W/WR',8X,'VN/(BR*WR)',6X,'FSUBI',    &
     & 6X,'GSUBI', 6X,'FC/FI')
      DO 1330 i=1,ntot
        IF (ansr(i) .GT. 0.0) GO TO 1280
 1270   wwr(i)=-1.0
        vbw(i)=0.0
        lg(i)=ansi(i)/ansr(i)
        GO TO 1320
 1280   wwr(i)=1.0/sqrt(ansr(i))
        vbw(i)=wwr(i)/k1
        lg(i)=ansi(i)/ansr(i)
        IF (lg(i)) 1290,1310,1300
 1290   nct2=nct2+1
        GO TO 1320
 1300   nct1=nct1+1
        GO TO 1320
 1310   CONTINUE
!!!        nlg=1   ! never used
 1320   WRITE(6,1400) k1,lg(i),wwr(i),vbw(i),fsubi,gsubi,corr
        IF (nplot.EQ.0) GO TO 1330
        IF (kount.GE.999) GO TO 1330
        kount=kount+1
!        plot1(kount)=enk
!        plot2(kount)=lg(i)
!        plot3(kount)=wwr(i)
 1330 END DO

      IF (nev.EQ.0) GO TO 1380
      nsum=ntot-1
      gmin=abs(lg(1))
      kg=1
      DO 1340 i=1,nsum
        absg=abs(lg(i+1))
        IF (absg.GT.gmin) GO TO 1340
        gmin=absg
        kg=i+1
 1340 END DO

      DO 1350 i=1,ntot
        r(i)=cabs(cca(i,kg))
        theta(i)=atan2(aimag(cca(i,kg)),real(cca(i,kg)))
 1350 END DO

      rnorm=r(nn)
      thetan=theta(nn)
      DO 1360 i=1,ntot
        r(i)=r(i)/rnorm
        theta(i)=theta(i)-thetan
        x(i)=r(i)*cos(theta(i))
        y(i)=r(i)*sin(theta(i))
 1360 END DO

      WRITE(6,1370) (r(i), theta(i), x(i), y(i),i=1,ntot)
 1370 FORMAT (/'rtheta r1 r2'/(4ES15.6))

 1380 WRITE(6,1390)
 1390 FORMAT ('0')

 1400 FORMAT (7ES13.6)   ! RLC
      GO TO (1410,1420),nf1
 1410 gtest=nct1
      nf1=2
      GO TO 1470

 1420 IF (nct1.NE.gtest) GO TO 1430
      GO TO 1470
 1430 trig=-trig
      gtest=nct1
      ij=ij+1
      IF (ij.GT.3) GO TO 1450
      WRITE(6,1440) ij
 1440 FORMAT (/'delta=delk',i1//)
      GO TO 1470

 1450 WRITE(6,1460)
 1460 FORMAT (/' ******************************************************')
      k1=k1-delta(1)
      write(3,*) ' at 1459', k1, lower, upper
      IF (k1.LT.lower .or. k1.GT.upper) GO TO 1480
      GO TO 520

 1470 k1=k1+trig*delta(ij)
      write(3,*) ' at 1470', k1, lower, upper

      IF (k1.GE.lower.and.k1.LE.upper) GO TO 530
!
!***********************************************************************
!
!   DIVERGENCE CALCULATION
!
      WRITE(3,*) 'Start divergence calculations'
 1480 WRITE(6,1490)
 1490 FORMAT (///'DIVERGENCE CALCULATION'/)

      DO 1500 i=1,nu
        DO 1501 j=1,nv
          bdiv(i,j)=(brltan*eleven(i,j)+seven(i,j))*rpi
 1501   END DO
 1500 END DO

      DO 1510 i=1,nv
        DO 1511 j=1,nu
          ddiv(i,j)=-blptan*fourt(j,i)
 1511   END DO
 1510 END DO

      DO 1520 i=1,nu
        DO 1521 j=1,nu
        IF (i.NE.j) GO TO 1520
        adivz(i)=ur*one(i,j)*whsq(i)
        adiv(i,j)=blptan*four(i,j)
 1521   END DO
 1520 END DO

      DO 1530 i=1,nv
        DO 1531 j=1,nv
        IF (i.NE.j) GO TO 1530
        edivz(i)=ur*sixt(i,j)*wasq(i)
        ediv(i,j)=-(sevent(i,j)+brltan*(twent1(i,j)-3.1415926*twent2(i,j)))*rpi
 1531   END DO
 1530 END DO

      IF (nopt1.EQ.0) GO TO 1580
      DO 1550 i=1,nu
        sum=0.0
        DO 1540 k=1,n
 1540     sum=sum+uc(k)*hc(k,i)**2
 1550   adivz(i)=adivz(i)+sum*whsq(i)

      DO 1570 i=1,nv
        sum=0.0
        DO 1560 k=1,n
 1560     sum=sum+uc(k)*bpsq(k)*alphc(k,i)**2
 1570   edivz(i)=edivz(i)+sum*wasq(i)

 1580 IF (nopt2.EQ.0) GO TO 1610
      DO 1590 i=1,nu
        adivz(i)=adivz(i)+us*hs(i)**2
 1590 END DO

      DO 1600 i=1,nv
        edivz(i)=us*bprod**2*alphs(i)**2*wasq(i)+edivz(i)
 1600 END DO

 1610 IF (npr2.EQ.0) GO TO 1660
      WRITE(6,820)
      DO 1620 i=1,nu
        WRITE(6,390) (adiv(i,j),j=1,nu)
 1620 END DO

      WRITE(6,880)
      WRITE(6,390) (adivz(i),i=1,nu)
      WRITE(6,890)
      DO 1630 i=1,nu
        WRITE(6,390) (bdiv(i,j),j=1,nv)
 1630 END DO

      WRITE(6,920)
      DO 1640 i=1,nv
        WRITE(6,390) (ddiv(i,j),j=1,nu)
 1640 END DO

      WRITE(6,950)
      DO 1650 i=1,nv
        WRITE(6,390) (ediv(i,j),j=1,nv)
 1650 END DO

      WRITE(6,880)
      WRITE(6,390) (edivz(i),i=1,nv)

 1660 DO 1670 i=1,nu
        ddiag(i)=adivz(i)
        DO 1671 j=1,nu
          divt(i,j)=adiv(i,j)
 1671   END DO
 1670 END DO

      DO 1680 i=1,nv
        nuv=nu+i
        DO 1681 j=1,nu
          divt(nuv,j)=ddiv(i,j)
 1681   END DO
 1680 END DO

      DO 1690 i=1,nu
        DO 1691 j=1,nv
          nuv=nu+j
          divt(i,nuv)=bdiv(i,j)
 1691 END DO
 1690 END DO

      DO 1700 i=1,nv
        nuv1=nu+i
        ddiag(nuv1)=edivz(i)
        DO 1701 j=1,nv
          nuv2=nu+j
          divt(nuv1,nuv2)=ediv(i,j)
 1701   END DO
 1700 END DO

      nuv=nu+nv
      nuvpl1=nuv+1
      DO 1710 i=1,nuv
        DO 1711 j=1,nuv
          divg(i,j)=-divt(i,j)/ddiag(i)
 1711   END DO
 1710 END DO

      WRITE(3,*) 'Preparing to call Reig, nuv=', nuv
!!! in following CALL, args 7,9,10 have different types that  that of
!!! the called subroutine.  eb  nsav  irun
!!! eb is COMPLEX, but 7th arg in Reig is REAL   (??)
!!!      CALL reig (divg, nuv, nuv, 0, rtr, rti, eb, 12, nsav, irun, ansr, &
!!!     &nuvpl1, divt)
      CALL Reig (divg, nuv, nuv, 0, rtr, rti, ebreal, 12,                  &
     &  nsavDummy, ddiag, ansr, nuvpl1, divt)
      WRITE(3,*) 'In main program, returned from Reig'

      WRITE(6,1720)
 1720 FORMAT (18X,'ZETA',33X,'VN/(BR*WR)'/9X,'REAL',14X,'IMAGINARY'/)

      DO 1750 i=1,nuv
        IF (rtr(i)) 1730,1730,1740
 1730   vbrwr(i)=(-1.0,0.0)
        GO TO 1750
 1740   denom=cmplx(rtr(i),rti(i))
        vbrwr(i)=csqrt(numer/denom)
 1750 END DO

      DO 1760 i=1,nuv
        WRITE(6,1770) rtr(i),rti(i),vbrwr(i)
 1760 END DO
 1770 FORMAT (2e20.8,10x,2e20.8)

      WRITE(3,*) 'END OF THIS CASE'
      WRITE(6,*) 'END OF THIS CASE'
!
!***********************************************************************
!
 1780 WRITE(6,1790)
 1790 FORMAT ('1')

      IF (nplot.EQ.0) GO TO 10
!      kount=kount+1
!      plot1(kount)=0.0
!      plot2(kount)=0.0
!      plot3(kount)=0.0

!!!      CALL ddiplt (1, iden1, kount, plot1, plot2, 0, 0, 0, 0, 10, xm1
!!!     &1, ym, 13, itape)
!!!      CALL ddiplt (1, iden1, kount, plot3, plot2, 0, 0, 0, 0, 10, xm2
!!!     &1, ym, 13, itape)
      GO TO 10  ! go back and look for more cases
      END Program Flutter   ! ===============================================


