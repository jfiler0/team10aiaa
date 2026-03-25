!=============================================================================
! friction_mex.F90
! MATLAB MEX gateway for Mason/VT FRICTION skin-friction and form-drag code.
!
! Capital-F extension (.F90) tells the compiler to run the C preprocessor
! first so that  #include "fintrf.h"  is resolved before compilation.
!
! BUILD (run from MATLAB command window):
!   mex friction_mex.F90 -output friction_mex
!
! If gfortran is not yet selected as the Fortran compiler run:
!   mex -setup fortran
! and choose gfortran from the list, then rebuild.
!
! ---------------------------------------------------------------------------
! MATLAB interface
! ---------------------------------------------------------------------------
! results = friction_mex(sref, scale, inmd, swets, refls, tcs, icodes, trans, machs, xinputs)
!
! Inputs  (10 args, all double-precision scalars or 1-D row/column vectors):
!   1  sref    scalar   reference area, ft^2
!   2  scale   scalar   model scale factor  (1 = full size)
!   3  inmd    scalar   0 => xinputs are altitude in kft
!                       1 => xinputs are Re/ft * 1e-6
!   4  swets   1xncomp  wetted areas, ft^2
!   5  refls   1xncomp  reference lengths, ft
!   6  tcs     1xncomp  thickness ratios t/c
!   7  icodes  1xncomp  form-factor code: 0=wing/tail, 1=body/nacelle
!   8  trans   1xncomp  transition location (chord fraction, 0=fully turbulent)
!   9  machs   1xncases Mach numbers
!  10  xinputs 1xncases altitudes (kft) or Re/ft x 1e-6
!
! Output (1 arg):
!   results  ncases x 6
!     col 1  Mach
!     col 2  Alt_ft
!     col 3  Re_per_ft
!     col 4  Cd_friction
!     col 5  Cd_form
!     col 6  Cd_total
!=============================================================================


!-----------------------------------------------------------------------------
! Module: friction_types
!-----------------------------------------------------------------------------
module friction_types
  implicit none
  private
  public :: component_t

  type :: component_t
     character(len=16) :: name     = ''
     real              :: swet_ft2 = 0.0
     real              :: refl_ft  = 0.0
     real              :: tc       = 0.0
     integer           :: icode    = 0
     real              :: trans    = 0.0
     real              :: ff       = 1.0
  end type component_t
end module friction_types


!-----------------------------------------------------------------------------
! Module: friction_core
!-----------------------------------------------------------------------------
module friction_core
  use friction_types
  implicit none
  private
  public :: friction_compute_case, compute_form_factor

contains

  ! -------------------------------------------------------------------------
  pure real function compute_form_factor(tc, icode) result(ff)
    real,    intent(in) :: tc
    integer, intent(in) :: icode
    ! Torenbeek form factors (adopted Jan 2006 in Mason code)
    if (icode == 0) then
      ff = 1.0 + 2.7*tc + 100.0*tc**4        ! lifting surface
    else
      ff = 1.0 + 1.5*tc**1.5 + 7.0*tc**3     ! body / nacelle
    end if
  end function compute_form_factor

  ! -------------------------------------------------------------------------
  subroutine friction_compute_case( &
      sref_ft2_in, scale, comps_in, ncomp, inmd, &
      mach, xinput, &
      cd_friction, cd_form, cd_total, rn_per_ft, alt_ft )

    real,              intent(in)  :: sref_ft2_in, scale
    type(component_t), intent(in)  :: comps_in(:)
    integer,           intent(in)  :: ncomp, inmd
    real,              intent(in)  :: mach, xinput
    real,              intent(out) :: cd_friction, cd_form, cd_total, rn_per_ft, alt_ft

    type(component_t) :: comps(size(comps_in))
    real    :: ascale, sref, sum_cfsw, sum_cfswff, twtaw, xme
    real    :: t, p, rho, a, xmu, ts, rr, pp, rmr, qm
    real    :: R_local, Rec, cflam, cfturbl, cfturbc, cfi
    integer :: kd, kk, i

    comps  = comps_in
    xme    = mach
    twtaw  = 1.0
    ascale = scale * scale
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
      if (kk /= 0) then          ! altitude out of table
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
      R_local  = rn_per_ft * comps(i)%refl_ft
      Rec      = R_local   * comps(i)%trans
      cflam    = 0.0
      cfturbc  = 0.0

      call turbcf(R_local, xme, twtaw, cfturbl)

      if (comps(i)%trans > 0.0) then
        call turbcf(Rec, xme, twtaw, cfturbc)
        call lamcf (Rec, xme, twtaw, cflam)
      end if

      cfi = cfturbl - comps(i)%trans * (cfturbc - cflam)

      sum_cfsw   = sum_cfsw   + cfi * comps(i)%swet_ft2
      sum_cfswff = sum_cfswff + cfi * comps(i)%swet_ft2 * comps(i)%ff
    end do

    cd_friction = sum_cfsw   / sref
    cd_form     = (sum_cfswff - sum_cfsw) / sref
    cd_total    = cd_friction + cd_form

  end subroutine friction_compute_case

end module friction_core


!-----------------------------------------------------------------------------
! Laminar skin-friction (Eckert Reference Temperature, White 1974)
!-----------------------------------------------------------------------------
subroutine lamcf(Rex, Xme, TwTaw, CF)
  implicit none
  real, intent(in)  :: Rex, Xme, TwTaw
  real, intent(out) :: CF
  real :: G, Pr, R, TE, TK, TwTe, TstTe, Cstar

  G     = 1.4
  Pr    = 0.72
  R     = sqrt(Pr)
  TE    = 390.0
  TK    = 200.0

  TwTe  = TwTaw * (1.0 + R*(G - 1.0)/2.0*Xme**2)
  TstTe = 0.5 + 0.039*Xme**2 + 0.5*TwTe
  Cstar = sqrt(TstTe) * (1.0 + TK/TE) / (TstTe + TK/TE)
  CF    = 2.0 * 0.664 * sqrt(Cstar) / sqrt(Rex)
end subroutine lamcf


!-----------------------------------------------------------------------------
! Turbulent skin-friction (Van Driest II, NASA TN D-6945)
!-----------------------------------------------------------------------------
subroutine turbcf(Rex, xme, TwTaw, CF)
  implicit none
  real, intent(in)  :: Rex, xme, TwTaw
  real, intent(out) :: CF

  real    :: epsmax, G, r, Te
  real    :: xm, TawTe, F, Tw, A, B, denom, Alpha, Beta, Fc
  real    :: Xnum, Denom2, Ftheta, Fx, RexBar, Cfb, Cfo, eps
  integer :: iter

  epsmax = 0.2e-8
  G      = 1.4
  r      = 0.88
  Te     = 222.0

  xm    = (G - 1.0)/2.0 * xme**2
  TawTe = 1.0 + r*xm
  F     = TwTaw * TawTe
  Tw    = F * Te
  A     = sqrt(r*xm/F)
  B     = (1.0 + r*xm - F)/F
  denom = sqrt(4.0*A**2 + B**2)
  Alpha = (2.0*A**2 - B) / denom
  Beta  = B / denom
  Fc    = ((1.0 + sqrt(F))/2.0)**2
  if (xme > 0.1) Fc = r*xm / (asin(Alpha) + asin(Beta))**2

  Xnum   = 1.0 + 122.0/Tw * 10.0**(-5.0/Tw)
  Denom2 = 1.0 + 122.0/Te * 10.0**(-5.0/Te)
  Ftheta = sqrt(1.0/F) * (Xnum/Denom2)
  Fx     = Ftheta / Fc

  RexBar = Fx * Rex
  Cfb    = 0.074 / RexBar**0.20

  iter = 0
  do
    iter   = iter + 1
    Cfo    = Cfb
    Xnum   = 0.242 - sqrt(Cfb)*log10(RexBar*Cfb)
    Denom2 = 0.121 + sqrt(Cfb)/log(10.0)
    Cfb    = Cfb * (1.0 + Xnum/Denom2)
    eps    = abs(Cfb - Cfo)
    if (eps  <= epsmax) exit
    if (iter >  200)    exit
  end do

  CF = Cfb / Fc
end subroutine turbcf


!-----------------------------------------------------------------------------
! 1976 Standard Atmosphere
!   kd /= 0  =>  English units (ft, R, slug/ft^3, ft/s)
!   kd  = 0  =>  SI units
!   kk  = 0  =>  good return
!   kk  = 1  =>  altitude out of table (> 84.852 km)
!-----------------------------------------------------------------------------
subroutine stdatm(z, t, p, r, a, mu, ts, rr, pp, rm, qm, kd, kk)
  implicit none
  real,    intent(in)  :: z
  integer, intent(in)  :: kd
  integer, intent(out) :: kk
  real,    intent(out) :: t, p, r, a, mu, ts, rr, pp, rm, qm

  real :: kval, C1, TL, PL, RL, AL, BT, ML, Hkm

  kk   = 0
  kval = 34.163195
  C1   = 3.048e-4

  if (kd /= 0) then              ! English units
    TL = 518.67
    PL = 2116.22
    RL = 0.0023769
    AL = 1116.45
    ML = 3.7373e-7
    BT = 3.0450963e-8
  else                           ! SI units
    TL = 288.15
    PL = 101325.0
    RL = 1.225
    C1 = 0.001
    AL = 340.294
    ML = 1.7894e-5
    BT = 1.458e-6
  end if

  Hkm = C1 * z / (1.0 + C1 * z / 6356.766)

  if (Hkm <= 11.0) then
    t  = 288.15 - 6.5*Hkm
    pp = (288.15/t)**(-kval/6.5)
  else if (Hkm <= 20.0) then
    t  = 216.65
    pp = 0.22336 * exp(-kval*(Hkm - 11.0)/216.65)
  else if (Hkm <= 32.0) then
    t  = 216.65 + (Hkm - 20.0)
    pp = 0.054032 * (216.65/t)**kval
  else if (Hkm <= 47.0) then
    t  = 228.65 + 2.8*(Hkm - 32.0)
    pp = 0.0085666 * (228.65/t)**(kval/2.8)
  else if (Hkm <= 51.0) then
    t  = 270.65
    pp = 0.0010945 * exp(-kval*(Hkm - 47.0)/270.65)
  else if (Hkm <= 71.0) then
    t  = 270.65 - 2.8*(Hkm - 51.0)
    pp = 0.00066063 * (270.65/t)**(-kval/2.8)
  else if (Hkm <= 84.852) then
    t  = 214.65 - 2.0*(Hkm - 71.0)
    pp = 3.9046e-5 * (214.65/t)**(-kval/2.0)
  else
    kk = 1
    return
  end if

  rr = pp / (t/288.15)
  mu = BT * t**1.5 / (t + 110.4)
  ts = t / 288.15
  a  = AL * sqrt(ts)
  t  = TL * ts
  r  = RL * rr
  p  = PL * pp
  rm = r * a / mu
  qm = 0.7 * p
end subroutine stdatm


!=============================================================================
! MEX gateway
! Must be a top-level (non-module) subroutine named mexFunction.
!=============================================================================
subroutine mexFunction(nlhs, plhs, nrhs, prhs)
#include "fintrf.h"
  use friction_core
  use friction_types
  use iso_c_binding, only: c_ptr, c_f_pointer, c_null_ptr, c_double, c_intptr_t
  implicit none

  ! ----- Standard MEX arguments -------------------------------------------
  integer    :: nlhs, nrhs
  mwPointer  :: plhs(*), prhs(*)

  ! ----- MX API function declarations (return types set by fintrf.h macros) -
  mwPointer  :: mxGetPr              ! pointer to real data of an mxArray
  mwPointer  :: mxCreateDoubleMatrix ! create new real double mxArray
  mwSize     :: mxGetM, mxGetN       ! row / column count
  real(8)    :: mxGetScalar          ! first element as scalar double

  external   :: mxGetPr, mxCreateDoubleMatrix
  external   :: mxGetM,  mxGetN
  external   :: mxGetScalar
  external   :: mexErrMsgIdAndTxt

  ! ----- Local variables ---------------------------------------------------
  ! NOTE: mwSize / mwPointer expand to "integer*8" via fintrf.h #define, so
  ! they cannot be used as kind-parameters in int() or kind-suffixed literals.
  ! Use integer(8) explicitly wherever a kind value is needed.
  integer, parameter          :: mwKind = 8   ! same numeric kind as mwSize

  mwPointer                   :: mxptr
  type(c_ptr)                 :: cptr
  integer(c_intptr_t)         :: iaddr
  integer(mwKind)             :: inr, inc     ! typed args for mxCreateDoubleMatrix

  real(c_double), pointer     :: p_swets(:),  p_refls(:), p_tcs(:)
  real(c_double), pointer     :: p_icode(:),  p_trans(:)
  real(c_double), pointer     :: p_machs(:),  p_xin(:)
  real(c_double), pointer     :: p_out(:)

  real(8)                     :: sref_d, scale_d, inmd_d
  integer                     :: ncomp, ncases, inmd_i, i, j
  type(component_t), allocatable :: comps(:)
  real :: cdf_f, cdform_f, cdtot_f, rn_f, alt_f

  ! ----- Validate argument counts -----------------------------------------
  if (nrhs /= 10) &
    call mexErrMsgIdAndTxt('friction_mex:nrhs', &
      'friction_mex requires exactly 10 input arguments')
  if (nlhs > 1) &
    call mexErrMsgIdAndTxt('friction_mex:nlhs', &
      'friction_mex returns at most 1 output argument')

  ! ----- Scalar inputs (args 1-3) -----------------------------------------
  sref_d  = mxGetScalar(prhs(1))
  scale_d = mxGetScalar(prhs(2))
  inmd_d  = mxGetScalar(prhs(3))
  inmd_i  = nint(inmd_d)

  ! ----- Component arrays (args 4-8) --------------------------------------
  ! Accept both row and column vectors by taking the larger dimension.
  ncomp = int(max(mxGetM(prhs(4)), mxGetN(prhs(4))))

  ! Helper: get Fortran pointer into an mxArray's data buffer (no copy).
  !   mxGetPr  -> mwPointer  (opaque integer)
  !   transfer to integer(c_intptr_t) then to c_ptr for c_f_pointer
  mxptr = mxGetPr(prhs(4))
  iaddr = int(mxptr, c_intptr_t)
  cptr  = transfer(iaddr, c_null_ptr)
  call c_f_pointer(cptr, p_swets, [ncomp])

  mxptr = mxGetPr(prhs(5))
  iaddr = int(mxptr, c_intptr_t)
  cptr  = transfer(iaddr, c_null_ptr)
  call c_f_pointer(cptr, p_refls, [ncomp])

  mxptr = mxGetPr(prhs(6))
  iaddr = int(mxptr, c_intptr_t)
  cptr  = transfer(iaddr, c_null_ptr)
  call c_f_pointer(cptr, p_tcs, [ncomp])

  mxptr = mxGetPr(prhs(7))
  iaddr = int(mxptr, c_intptr_t)
  cptr  = transfer(iaddr, c_null_ptr)
  call c_f_pointer(cptr, p_icode, [ncomp])

  mxptr = mxGetPr(prhs(8))
  iaddr = int(mxptr, c_intptr_t)
  cptr  = transfer(iaddr, c_null_ptr)
  call c_f_pointer(cptr, p_trans, [ncomp])

  ! ----- Condition arrays (args 9-10) -------------------------------------
  ncases = int(max(mxGetM(prhs(9)), mxGetN(prhs(9))))

  mxptr = mxGetPr(prhs(9))
  iaddr = int(mxptr, c_intptr_t)
  cptr  = transfer(iaddr, c_null_ptr)
  call c_f_pointer(cptr, p_machs, [ncases])

  mxptr = mxGetPr(prhs(10))
  iaddr = int(mxptr, c_intptr_t)
  cptr  = transfer(iaddr, c_null_ptr)
  call c_f_pointer(cptr, p_xin, [ncases])

  ! ----- Build Fortran component array ------------------------------------
  allocate(comps(ncomp))
  do i = 1, ncomp
    comps(i)%swet_ft2 = real(p_swets(i))
    comps(i)%refl_ft  = real(p_refls(i))
    comps(i)%tc       = real(p_tcs(i))
    comps(i)%icode    = nint(p_icode(i))
    comps(i)%trans    = real(p_trans(i))
  end do

  ! ----- Create output matrix: ncases × 6 ---------------------------------
  ! MATLAB matrices are stored column-major:
  !   element (row, col) => linear index  row + ncases*(col-1)
  !
  !  col 1  Mach       col 4  Cd_friction
  !  col 2  Alt_ft     col 5  Cd_form
  !  col 3  Re_per_ft  col 6  Cd_total
  !
  ! mxCreateDoubleMatrix(nrows, ncols, complexity)  complexity=0 => real
  ! Args must be mwSize (integer*8); use the typed local variables inr, inc.
  inr = int(ncases, mwKind)
  inc = int(6,      mwKind)
  plhs(1) = mxCreateDoubleMatrix(inr, inc, 0)

  mxptr = mxGetPr(plhs(1))
  iaddr = int(mxptr, c_intptr_t)
  cptr  = transfer(iaddr, c_null_ptr)
  call c_f_pointer(cptr, p_out, [ncases*6])

  ! ----- Compute and fill output ------------------------------------------
  do j = 1, ncases
    call friction_compute_case( &
        real(sref_d), real(scale_d), comps, ncomp, inmd_i, &
        real(p_machs(j)), real(p_xin(j)), &
        cdf_f, cdform_f, cdtot_f, rn_f, alt_f)

    p_out(j)              = p_machs(j)               ! col 1: Mach
    p_out(j + ncases)     = real(alt_f,    c_double)  ! col 2: Alt_ft
    p_out(j + ncases*2)   = real(rn_f,     c_double)  ! col 3: Re_per_ft
    p_out(j + ncases*3)   = real(cdf_f,    c_double)  ! col 4: Cd_friction
    p_out(j + ncases*4)   = real(cdform_f, c_double)  ! col 5: Cd_form
    p_out(j + ncases*5)   = real(cdtot_f,  c_double)  ! col 6: Cd_total
  end do

  deallocate(comps)

end subroutine mexFunction