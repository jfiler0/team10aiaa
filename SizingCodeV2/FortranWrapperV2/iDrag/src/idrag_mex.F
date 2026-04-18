c=======================================================================
c  idrag_mex.F  (fixed-form Fortran MEX gateway)
c  Capital .F extension => C preprocessor runs first for fintrf.h
c
c  MATLAB call (17 inputs):
c   cd = idrag_mex(input_mode, sym_flag, cl_design, cm_flag, cm_design,
c                  xcg, cp, sref, cavg, npanels,
c                  xc, yc, zc, nvortices, spacing_flag, load_flag, loads)
c
c  Output:
c   cd  (scalar double)  induced drag coefficient
c
c  Notes:
c   - xc, yc, zc  must be  npanels x 4  from MATLAB (double).
c   - nvortices, spacing_flag  vectors length >= npanels.
c   - loads  vector length >= sum(nvortices); ignored in design mode (input_mode=0).
c   - write_flag is hard-set to 0 (no file output from inside MEX).
c=======================================================================

#include "fintrf.h"

      subroutine mexFunction(nlhs, plhs, nrhs, prhs)
      implicit none

c----- standard MEX argument types (fintrf.h sets mwPointer/mwSize)
      integer nlhs, nrhs
      mwPointer plhs(*), prhs(*)

c----- MX API declarations
      mwPointer mxGetPr, mxCreateDoubleMatrix
      double precision mxGetScalar
      mwSize mxGetM, mxGetN

      external mxGetPr, mxCreateDoubleMatrix
      external mxGetScalar
      external mxGetM, mxGetN
      external mxCopyPtrToReal8, mxCopyReal8ToPtr
      external mexErrMsgTxt

c----- idrag_core is the computation engine (no file I/O)
      external idrag_core

c----- hard limits (must match idrag_core.f parameter statements)
      integer npanels_max, nvortices_max
      parameter (npanels_max=20, nvortices_max=200)

c----- scalar inputs
      integer input_mode, sym_flag, cm_flag, npanels, load_flag
      double precision cl_design, cm_design, xcg, cp, sref, cavg

c----- geometry arrays (idrag_core uses REAL*4 internally)
      real xc(npanels_max,4), yc(npanels_max,4), zc(npanels_max,4)
      integer nvortices(npanels_max), spacing_flag(npanels_max)

c----- loads vector
      real loads(npanels_max*nvortices_max)

c----- output
      real cd_induced

c----- workspace for mxCopyPtrToReal8 (copies MATLAB doubles into tmp)
      double precision tmp(npanels_max*nvortices_max)

c----- locals
      mwPointer ptr
      mwSize m, n, total
      integer i, j, k, nv_tot

c======================================================================
c  Argument count check
c======================================================================
      if (nrhs .ne. 17) then
         call mexErrMsgTxt(
     &   'idrag_mex: Expected 17 inputs.'//char(10)//
     &   '  cd = idrag_mex(input_mode, sym_flag, cl_design,'//
     &   ' cm_flag, cm_design,'//char(10)//
     &   '                 xcg, cp, sref, cavg, npanels,'//char(10)//
     &   '                 xc, yc, zc, nvortices,'//
     &   ' spacing_flag, load_flag, loads)')
      endif

      if (nlhs .gt. 1) then
         call mexErrMsgTxt('idrag_mex: At most 1 output (cd_induced).')
      endif

c======================================================================
c  Scalar inputs  (args 1-10)
c======================================================================
      input_mode = int(mxGetScalar(prhs(1)))
      sym_flag   = int(mxGetScalar(prhs(2)))
      cl_design  =     mxGetScalar(prhs(3))
      cm_flag    = int(mxGetScalar(prhs(4)))
      cm_design  =     mxGetScalar(prhs(5))
      xcg        =     mxGetScalar(prhs(6))
      cp         =     mxGetScalar(prhs(7))
      sref       =     mxGetScalar(prhs(8))
      cavg       =     mxGetScalar(prhs(9))
      npanels    = int(mxGetScalar(prhs(10)))

      if (npanels .lt. 1 .or. npanels .gt. npanels_max) then
         call mexErrMsgTxt('idrag_mex: npanels must be 1..20.')
      endif

c======================================================================
c  Geometry matrices xc, yc, zc  (args 11-13)
c  MATLAB is column-major so mxCopyPtrToReal8 returns column-major data.
c  Expected size from MATLAB: [npanels x 4].
c======================================================================
c--- xc ---
      m = mxGetM(prhs(11))
      n = mxGetN(prhs(11))
      if (int(m) .ne. npanels .or. int(n) .ne. 4) then
         call mexErrMsgTxt('idrag_mex: xc must be npanels x 4.')
      endif
      ptr = mxGetPr(prhs(11))
      call mxCopyPtrToReal8(ptr, tmp, m*n)
      k = 0
      do j = 1, 4
         do i = 1, npanels
            k = k + 1
            xc(i,j) = real(tmp(k))
         enddo
      enddo

c--- yc ---
      m = mxGetM(prhs(12))
      n = mxGetN(prhs(12))
      if (int(m) .ne. npanels .or. int(n) .ne. 4) then
         call mexErrMsgTxt('idrag_mex: yc must be npanels x 4.')
      endif
      ptr = mxGetPr(prhs(12))
      call mxCopyPtrToReal8(ptr, tmp, m*n)
      k = 0
      do j = 1, 4
         do i = 1, npanels
            k = k + 1
            yc(i,j) = real(tmp(k))
         enddo
      enddo

c--- zc ---
      m = mxGetM(prhs(13))
      n = mxGetN(prhs(13))
      if (int(m) .ne. npanels .or. int(n) .ne. 4) then
         call mexErrMsgTxt('idrag_mex: zc must be npanels x 4.')
      endif
      ptr = mxGetPr(prhs(13))
      call mxCopyPtrToReal8(ptr, tmp, m*n)
      k = 0
      do j = 1, 4
         do i = 1, npanels
            k = k + 1
            zc(i,j) = real(tmp(k))
         enddo
      enddo

c======================================================================
c  nvortices  (arg 14)  -- vector length >= npanels
c======================================================================
      m = mxGetM(prhs(14))
      n = mxGetN(prhs(14))
      total = m*n
      if (int(total) .lt. npanels) then
         call mexErrMsgTxt('idrag_mex: nvortices length < npanels.')
      endif
      ptr = mxGetPr(prhs(14))
      call mxCopyPtrToReal8(ptr, tmp, total)
      do i = 1, npanels
         nvortices(i) = int(tmp(i))
         if (nvortices(i).lt.1 .or. nvortices(i).gt.nvortices_max) then
            call mexErrMsgTxt(
     &      'idrag_mex: each nvortices(i) must be 1..200.')
         endif
      enddo
      do i = npanels+1, npanels_max
         nvortices(i) = 1
      enddo

c======================================================================
c  spacing_flag  (arg 15)  -- vector length >= npanels
c======================================================================
      m = mxGetM(prhs(15))
      n = mxGetN(prhs(15))
      total = m*n
      if (int(total) .lt. npanels) then
         call mexErrMsgTxt('idrag_mex: spacing_flag length < npanels.')
      endif
      ptr = mxGetPr(prhs(15))
      call mxCopyPtrToReal8(ptr, tmp, total)
      do i = 1, npanels
         spacing_flag(i) = int(tmp(i))
      enddo
      do i = npanels+1, npanels_max
         spacing_flag(i) = 0
      enddo

c======================================================================
c  load_flag  (arg 16)  and  loads  (arg 17)
c======================================================================
      load_flag = int(mxGetScalar(prhs(16)))

      nv_tot = 0
      do i = 1, npanels
         nv_tot = nv_tot + nvortices(i)
      enddo

c  Initialise loads to zero (safe default for design mode)
      do i = 1, npanels_max*nvortices_max
         loads(i) = 0.0
      enddo

      m = mxGetM(prhs(17))
      n = mxGetN(prhs(17))
      total = m*n
c  In analysis mode (input_mode=1) we need at least nv_tot loads.
      if (input_mode .ne. 0 .and. int(total) .lt. nv_tot) then
         call mexErrMsgTxt(
     &   'idrag_mex: loads length must be >= sum(nvortices)'//
     &   ' in analysis mode (input_mode=1).')
      endif
      if (int(total) .gt. 0) then
         ptr = mxGetPr(prhs(17))
         call mxCopyPtrToReal8(ptr, tmp, total)
         do i = 1, min(nv_tot, int(total))
            loads(i) = real(tmp(i))
         enddo
      endif

c======================================================================
c  Call idrag_core
c  Signature:
c    idrag_core(input_mode, sym_flag,
c               cl_design, cm_flag, cm_design, xcg, cp, sref, cavg,
c               npanels, xc, yc, zc, nvortices, spacing_flag,
c               load_flag, loads, cd_induced)
c
c  NOTE: idrag_core does NOT take outfile/title/write_flag.
c        Those belong to the full idrag.f wrapper (used by the old EXE).
c======================================================================
      call idrag_core(
     &     input_mode, sym_flag,
     &     real(cl_design), cm_flag, real(cm_design),
     &     real(xcg), real(cp), real(sref), real(cavg),
     &     npanels, xc, yc, zc,
     &     nvortices, spacing_flag,
     &     load_flag, loads, cd_induced)

c======================================================================
c  Return cd_induced as a scalar double
c======================================================================
      plhs(1) = mxCreateDoubleMatrix(1, 1, 0)
      ptr = mxGetPr(plhs(1))
      tmp(1) = dble(cd_induced)
      call mxCopyReal8ToPtr(tmp, ptr, 1)

      return
      end