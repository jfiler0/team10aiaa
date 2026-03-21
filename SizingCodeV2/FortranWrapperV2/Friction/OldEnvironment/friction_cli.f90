!===============================================================================
! friction_cli.f90
! Non-interactive CLI wrapper for Mason FRICTION logic:
!   friction_cli <dataset.dat> <output.csv>
!
! Output CSV columns:
!   j, mach, alt_ft, rn_per_ft, cd_friction, cd_form, cd_total
!===============================================================================

module friction_types
  implicit none
  private
  public :: component_t

  type :: component_t
     character(len=16) :: name = ''
     real              :: swet_ft2 = 0.0
     real              :: refl_ft  = 0.0
     real              :: tc       = 0.0
     integer           :: icode    = 0
     real              :: trans    = 0.0
     real              :: ff       = 1.0
  end type component_t
end module friction_types

module friction_core
  use friction_types
  implicit none
  private
  public :: friction_compute_case, compute_form_factor

contains
  pure real function compute_form_factor(tc, icode) result(ff)
    real,    intent(in) :: tc
    integer, intent(in) :: icode
    if (icode == 0) then
      ff = 1.0 + 2.7*tc + 100.0*tc**4
    else
      ff = 1.0 + 1.5*tc**1.5 + 7.0*tc**3
    end if
  end function compute_form_factor

  subroutine friction_compute_case( &
      sref_ft2_in, scale, comps_in, ncomp, inmd, &
      mach, xinput, &
      cd_friction, cd_form, cd_total, rn_per_ft, alt_ft )

    real,              intent(in)  :: sref_ft2_in, scale
    type(component_t), intent(in)  :: comps_in(:)
    integer,           intent(in)  :: ncomp, inmd
    real,              intent(in)  :: mach, xinput

    real, intent(out) :: cd_friction, cd_form, cd_total, rn_per_ft, alt_ft

    type(component_t) :: comps(size(comps_in))
    real :: ascale, sref, sum_cfsw, sum_cfswff
    real :: twtaw, xme
    real :: t,p,rho,a,xmu,ts,rr,pp,rmr,qm
    integer :: kd, kk
    integer :: i
    real :: R_local, Rec, cflam, cfturbl, cfturbc, cfi

    comps = comps_in
    xme   = mach
    twtaw = 1.0

    ascale = scale*scale
    sref   = sref_ft2_in / ascale

    do i = 1, ncomp
      comps(i)%swet_ft2 = comps(i)%swet_ft2 / ascale
      comps(i)%refl_ft  = comps(i)%refl_ft  / scale
      comps(i)%ff       = compute_form_factor(comps(i)%tc, comps(i)%icode)
    end do

    alt_ft = 0.0
    if (inmd == 0) then
      alt_ft = 1000.0 * xinput
      kd = 1
      call stdatm(alt_ft, t, p, rho, a, xmu, ts, rr, pp, rmr, qm, kd, kk)
      if (kk /= 0) then
        rn_per_ft   = 0.0
        cd_friction = 0.0
        cd_form     = 0.0
        cd_total    = 0.0
        return
      end if
      rn_per_ft = rmr * xme
    else
      rn_per_ft = xinput * 1.0e6
    end if

    sum_cfsw   = 0.0
    sum_cfswff = 0.0

    do i = 1, ncomp
      R_local = rn_per_ft * comps(i)%refl_ft
      Rec     = R_local * comps(i)%trans

      cflam   = 0.0
      cfturbc = 0.0

      call turbcf(R_local, xme, twtaw, cfturbl)

      if (comps(i)%trans > 0.0) then
        call turbcf(Rec, xme, twtaw, cfturbc)
        call lamcf (Rec, xme, twtaw, cflam)
      end if

      cfi = cfturbl - comps(i)%trans * (cfturbc - cflam)

      sum_cfsw   = sum_cfsw   + cfi * comps(i)%swet_ft2
      sum_cfswff = sum_cfswff + cfi * comps(i)%swet_ft2 * comps(i)%ff
    end do

    cd_friction = sum_cfsw / sref
    cd_form     = (sum_cfswff - sum_cfsw) / sref
    cd_total    = cd_friction + cd_form
  end subroutine friction_compute_case

end module friction_core

module friction_io
  use friction_types
  implicit none
  private
  public :: read_friction_dataset

contains
  subroutine read_friction_dataset(filename, title_line, sref, scale, comps, ncomp, inmd, machs, xinputs, ncases)
    character(len=*), intent(in)  :: filename
    character(len=*), intent(out) :: title_line
    real,             intent(out) :: sref, scale
    type(component_t), allocatable, intent(out) :: comps(:)
    integer,          intent(out) :: ncomp, inmd
    real, allocatable, intent(out) :: machs(:), xinputs(:)
    integer,          intent(out) :: ncases

    integer :: iu, i, ios
    real :: fncomp, finmd
    character(len=256) :: line
    character(len=16)  :: nm
    real :: swet, refl, tc, ficode, ftrans
    real :: m, xin

    iu = 10
    open(unit=iu, file=filename, status='old', action='read', iostat=ios)
    if (ios /= 0) stop 'ERROR: could not open dataset file.'

    read(iu,'(A)',iostat=ios) title_line
    if (ios /= 0) stop 'ERROR: failed reading title line.'

    read(iu,*,iostat=ios) sref, scale, fncomp, finmd
    if (ios /= 0) stop 'ERROR: failed reading SREF/SCALE/NCOMP/INMD line.'

    ncomp = int(fncomp + 0.5)
    inmd  = int(finmd  + 0.5)

    allocate(comps(ncomp))

    do i = 1, ncomp
      read(iu,'(A)',iostat=ios) line
      if (ios /= 0) stop 'ERROR: failed reading a component line.'
      nm = line(1:min(16,len_trim(line)))
      comps(i)%name = adjustl(nm)

      swet=0.0; refl=0.0; tc=0.0; ficode=0.0; ftrans=0.0
      read(line(17:),*,iostat=ios) swet, refl, tc, ficode, ftrans
      if (ios /= 0) stop 'ERROR: failed parsing component numeric fields.'

      comps(i)%swet_ft2 = swet
      comps(i)%refl_ft  = refl
      comps(i)%tc       = tc
      comps(i)%icode    = int(ficode + 0.5)
      comps(i)%trans    = ftrans
    end do

    ncases = 0
    allocate(machs(0), xinputs(0))

    do
      read(iu,*,iostat=ios) m, xin
      if (ios /= 0) exit
      if (m <= 0.0) exit
      ncases = ncases + 1
      call append_real(machs,   m)
      call append_real(xinputs, xin)
    end do

    close(iu)

  contains
    subroutine append_real(arr, val)
      real, allocatable, intent(inout) :: arr(:)
      real, intent(in) :: val
      real, allocatable :: tmp(:)
      integer :: n
      n = size(arr)
      allocate(tmp(n+1))
      if (n > 0) tmp(1:n) = arr
      tmp(n+1) = val
      call move_alloc(tmp, arr)
    end subroutine append_real

  end subroutine read_friction_dataset

end module friction_io

program friction_cli
  use friction_types
  use friction_core
  use friction_io
  implicit none

  character(len=256) :: inFile, outFile, title
  integer :: nargs, ios
  real :: sref, scale
  type(component_t), allocatable :: comps(:)
  integer :: ncomp, inmd, ncases, j
  real, allocatable :: machs(:), xinputs(:)
  real :: cdf, cdform, cdtot, rn, alt

  nargs = command_argument_count()
  if (nargs < 2) then
    write(*,*) 'Usage: friction_cli <dataset.dat> <output.csv>'
    stop 2
  end if

  call get_command_argument(1, inFile)
  call get_command_argument(2, outFile)

  call read_friction_dataset(trim(inFile), title, sref, scale, comps, ncomp, inmd, machs, xinputs, ncases)

  open(unit=20, file=trim(outFile), status='replace', action='write', iostat=ios)
  if (ios /= 0) then
    write(*,*) 'ERROR: cannot open output file.'
    stop 3
  end if

  write(20,'(A)') 'j,mach,alt_ft,rn_per_ft,cd_friction,cd_form,cd_total'

  do j = 1, ncases
    call friction_compute_case(sref, scale, comps, ncomp, inmd, machs(j), xinputs(j), cdf, cdform, cdtot, rn, alt)
    write(20,'(I0,A,F10.6,A,F12.3,A,ES13.6,A,F12.8,A,F12.8,A,F12.8)') &
      j,',',machs(j),',',alt,',',rn,',',cdf,',',cdform,',',cdtot
  end do

  close(20)
end program friction_cli

!===============================================================================
! Original computational subroutines (kept compatible)
!===============================================================================

subroutine lamcf(Rex,Xme,TwTaw,CF)
  implicit none
  real, intent(in)  :: Rex, Xme, TwTaw
  real, intent(out) :: CF
  real :: G, Pr, R, TE, TK, TwTe, TstTe, Cstar

  G     = 1.4
  Pr    = 0.72
  R     = sqrt(Pr)
  TE    = 390.0
  TK    = 200.0

  TwTe  = TwTaw*(1.0 + R*(G - 1.0)/2.0*Xme**2)
  TstTe = 0.5 + 0.039*Xme**2 + 0.5*TwTe

  Cstar = sqrt(TstTe)*(1.0 + TK/TE)/(TstTe + TK/TE)
  CF    = 2.0*0.664*sqrt(Cstar)/sqrt(Rex)
end subroutine lamcf

subroutine turbcf(Rex,xme,TwTaw,CF)
  implicit none
  real, intent(in)  :: Rex, xme, TwTaw
  real, intent(out) :: CF

  real :: epsmax, G, r, Te
  real :: xm, TawTe, F, Tw, A, B, denom, Alpha, Beta, Fc
  real :: Xnum, Denom2, Ftheta, Fx, RexBar, Cfb, Cfo, eps
  integer :: iter

  epsmax = 0.2e-8
  G      = 1.4
  r      = 0.88
  Te     = 222.0

  xm    = (G - 1.0)/2.0*xme**2
  TawTe = 1.0 + r*xm
  F     = TwTaw*TawTe
  Tw    = F * Te
  A     = sqrt(r*xm/F)
  B     = (1.0 + r*xm - F)/F
  denom = sqrt(4.0*A**2 + B**2)
  Alpha = (2.0*A**2 - B)/denom
  Beta  = B/denom
  Fc    = ((1.0 + sqrt(F))/2.0)**2
  if (xme > 0.1) Fc = r*xm/(asin(Alpha) + asin(Beta))**2

  Xnum   = (1.0 + 122.0/Tw*10.0**(-5.0/Tw))
  Denom2 = (1.0 + 122.0/Te*10.0**(-5.0/Te))
  Ftheta = sqrt(1.0/F)*(Xnum/Denom2)
  Fx     = Ftheta/Fc

  RexBar = Fx * Rex
  Cfb    = 0.074/RexBar**0.20

  iter = 0
  do
    iter = iter + 1
    Cfo  = Cfb
    Xnum   = 0.242 - sqrt(Cfb)*log10(RexBar*Cfb)
    Denom2 = 0.121 + sqrt(Cfb)/log(10.0)
    Cfb    = Cfb*(1.0 + Xnum/Denom2)
    eps    = abs(Cfb - Cfo)
    if (eps <= epsmax) exit
    if (iter > 200) exit
  end do

  CF = Cfb/Fc
end subroutine turbcf

subroutine stdatm(z,t,p,r,a,mu,ts,rr,pp,rm,qm,kd,kk)
  implicit none
  real,    intent(in)  :: z
  integer, intent(in)  :: kd
  integer, intent(out) :: kk
  real, intent(out) :: t,p,r,a,mu,ts,rr,pp,rm,qm

  real :: k, C1, TL, PL, RL, AL, BT, ml
  real :: Hkm

  KK = 0
  K  = 34.163195
  C1 = 3.048E-04

  if (KD /= 0) then
    TL = 518.67
    PL = 2116.22
    RL = 0.0023769
    AL = 1116.45
    ML = 3.7373E-07
    BT = 3.0450963E-08
  else
    TL = 288.15
    PL = 101325.0
    RL = 1.225
    C1 = 0.001
    AL = 340.294
    ML = 1.7894E-05
    BT = 1.458E-06
  end if

  Hkm = C1 * Z / (1.0 + C1 * Z / 6356.766)

  if (Hkm <= 11.0) then
    T  = 288.15 - 6.5 * Hkm
    PP = (288.15 / T) ** ( - K / 6.5)
  else if (Hkm <= 20.0) then
    T  = 216.65
    PP = 0.22336 * exp ( - K * (Hkm - 11.0) / 216.65)
  else if (Hkm <= 32.0) then
    T  = 216.65 + (Hkm - 20.0)
    PP = 0.054032 * (216.65 / T) ** K
  else if (Hkm <= 47.0) then
    T  = 228.65 + 2.8 * (Hkm - 32.0)
    PP = 0.0085666 * (228.65 / T) ** (K / 2.8)
  else if (Hkm <= 51.0) then
    T  = 270.65
    PP = 0.0010945 * exp ( - K * (Hkm - 47.0) / 270.65)
  else if (Hkm <= 71.0) then
    T  = 270.65 - 2.8 * (Hkm - 51.0)
    PP = 0.00066063 * (270.65 / T) ** ( - K / 2.8)
  else if (Hkm <= 84.852) then
    T  = 214.65 - 2.0 * (Hkm - 71.0)
    PP = 3.9046E-05 * (214.65 / T) ** ( - K / 2.0)
  else
    KK = 1
    return
  end if

  RR = PP / (T / 288.15)
  MU = BT * T**1.5 / (T + 110.4)
  TS = T / 288.15
  A  = AL * sqrt(TS)
  T  = TL * TS
  R  = RL * RR
  P  = PL * PP
  RM = R * A / MU
  QM = 0.7 * P
end subroutine stdatm
