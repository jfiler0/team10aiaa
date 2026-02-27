c=======================================================================
c  idrag_mex.f  (FIXED-FORM Fortran MEX gateway)
c
c  MATLAB call (17 inputs):
c   cd = idrag_mex(input_mode, sym_flag, cl_design, cm_flag, cm_design,
c                  xcg, cp, sref, cavg, npanels,
c                  xc, yc, zc, nvortices, spacing_flag, load_flag, loads)
c
c  Outputs:
c    cd  (scalar) induced drag coefficient
c
c  Notes:
c   - This gateway hard-sets write_flag=0 and passes blank outfile/title.
c   - loads should be length sum(nvortices) in analysis mode; ignored in design mode.
c   - xc,yc,zc expected size (npanels x 4) from MATLAB.
c   - nvortices, spacing_flag expected length npanels (or length 5; extra ignored).
c=======================================================================

#include "fintrf.h"

      subroutine mexFunction(nlhs, plhs, nrhs, prhs)
      implicit none

c----- MEX API types
      mwPointer plhs(*), prhs(*)
      mwPointer mxGetPr, mxCreateDoubleMatrix
      mwPointer mxGetString
      double precision mxGetScalar
      integer mxGetM, mxGetN

      external mxGetPr, mxCreateDoubleMatrix, mxGetScalar
      external mxCopyPtrToReal8, mxGetM, mxGetN
      external mexErrMsgTxt

c----- idrag interface (from your core code)
      external idrag

c----- constants matching idrag.f parameters
      integer npanels_max, nvortices_max
      parameter (npanels_max=5, nvortices_max=200)

c----- locals
      integer nlhs, nrhs
      integer input_mode, sym_flag, cm_flag, npanels, load_flag
      integer write_flag
      double precision cl_design, cm_design, xcg, cp, sref, cavg
      double precision cd_induced

      character*72 outfile, title

c----- geometry arrays (idrag expects REAL, but passing double is ok if
c      your core is REAL*4; however best is to keep types consistent.
c      Here we will pass REAL*4 arrays, filled from MATLAB doubles.)
      real xc(npanels_max,4), yc(npanels_max,4), zc(npanels_max,4)
      integer nvortices(npanels_max), spacing_flag(npanels_max)

c----- loads array expected by idrag: size npanels_max*nvortices_max
      real loads(npanels_max*nvortices_max)

c----- temp buffers for copying MATLAB doubles
      double precision tmp(2000)
      integer i, j, n, m
      integer nv_tot, k

c----- pointers
      mwPointer p

c==================== argument checking ================================
      if (nrhs .ne. 17) then
         call mexErrMsgTxt(
     &   'idrag_mex: Expected 17 inputs. See header in idrag_mex.f')
      endif

      if (nlhs .gt. 1) then
         call mexErrMsgTxt('idrag_mex: One output only (cd_induced).')
      endif

c==================== scalars ==========================================
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
         call mexErrMsgTxt('idrag_mex: npanels must be 1..5.')
      endif

c==================== xc,yc,zc matrices ================================
c MATLAB is column-major; mxCopyPtrToReal8 gives column-major ordering.
c We copy into tmp then map into (i,j) as xc(i,j) with i=row, j=col.
c Expecting MATLAB sizes: [npanels x 4]
      m = mxGetM(prhs(11))
      n = mxGetN(prhs(11))
      if (m .ne. npanels .or. n .ne. 4) then
         call mexErrMsgTxt('idrag_mex: xc must be size npanels x 4.')
      endif
      p = mxGetPr(prhs(11))
      call mxCopyPtrToReal8(p, tmp, m*n)
      k = 0
      do j = 1, 4
         do i = 1, npanels
            k = k + 1
            xc(i,j) = real(tmp(k))
         enddo
      enddo

      m = mxGetM(prhs(12))
      n = mxGetN(prhs(12))
      if (m .ne. npanels .or. n .ne. 4) then
         call mexErrMsgTxt('idrag_mex: yc must be size npanels x 4.')
      endif
      p = mxGetPr(prhs(12))
      call mxCopyPtrToReal8(p, tmp, m*n)
      k = 0
      do j = 1, 4
         do i = 1, npanels
            k = k + 1
            yc(i,j) = real(tmp(k))
         enddo
      enddo

      m = mxGetM(prhs(13))
      n = mxGetN(prhs(13))
      if (m .ne. npanels .or. n .ne. 4) then
         call mexErrMsgTxt('idrag_mex: zc must be size npanels x 4.')
      endif
      p = mxGetPr(prhs(13))
      call mxCopyPtrToReal8(p, tmp, m*n)
      k = 0
      do j = 1, 4
         do i = 1, npanels
            k = k + 1
            zc(i,j) = real(tmp(k))
         enddo
      enddo

c==================== nvortices & spacing_flag =========================
c Expect MATLAB vectors length npanels (row or col). We read min(length,npanels).
      m = mxGetM(prhs(14))
      n = mxGetN(prhs(14))
      if (m*n .lt. npanels) then
         call mexErrMsgTxt('idrag_mex: nvortices length < npanels.')
      endif
      p = mxGetPr(prhs(14))
      call mxCopyPtrToReal8(p, tmp, m*n)
      do i = 1, npanels
         nvortices(i) = int(tmp(i))
         if (nvortices(i) .lt. 1 .or. nvortices(i) .gt. nvortices_max)
     &   then
            call mexErrMsgTxt(
     &      'idrag_mex: each nvortices(i) must be 1..200.')
         endif
      enddo
      do i = npanels+1, npanels_max
         nvortices(i) = 1
      enddo

      m = mxGetM(prhs(15))
      n = mxGetN(prhs(15))
      if (m*n .lt. npanels) then
         call mexErrMsgTxt('idrag_mex: spacing_flag length < npanels.')
      endif
      p = mxGetPr(prhs(15))
      call mxCopyPtrToReal8(p, tmp, m*n)
      do i = 1, npanels
         spacing_flag(i) = int(tmp(i))
      enddo
      do i = npanels+1, npanels_max
         spacing_flag(i) = 0
      enddo

c==================== load_flag & loads ================================
      load_flag = int(mxGetScalar(prhs(16)))

c total vortices expected
      nv_tot = 0
      do i = 1, npanels
         nv_tot = nv_tot + nvortices(i)
      enddo
      if (nv_tot .gt. npanels_max*nvortices_max) then
         call mexErrMsgTxt('idrag_mex: total vortices > 1000.')
      endif

c initialize loads
      do i = 1, npanels_max*nvortices_max
         loads(i) = 0.0
      enddo

c loads input should have at least nv_tot elements (analysis mode)
      m = mxGetM(prhs(17))
      n = mxGetN(prhs(17))
      if (m*n .lt. nv_tot) then
c If in design mode, loads can be empty-ish, but we still require length.
c If you want to allow empty loads in design mode, loosen this check.
         if (input_mode .ne. 0) then
            call mexErrMsgTxt(
     &      'idrag_mex: loads length must be >= sum(nvortices).')
         endif
      endif
      p = mxGetPr(prhs(17))
      call mxCopyPtrToReal8(p, tmp, m*n)
      do i = 1, min(nv_tot, m*n)
         loads(i) = real(tmp(i))
      enddo

c==================== call idrag =======================================
      outfile   = ' '
      title     = 'MATLAB MEX call'
      write_flag = 0

c idrag expects REAL scalars; passing double scalars may downcast depending
c on compiler. We pass doubles for scalars; Intel will convert as needed.
      call idrag_cores(outfile, title, input_mode, write_flag, sym_flag,
     &     real(cl_design), cm_flag, real(cm_design), real(xcg),
     &     real(cp), real(sref), real(cavg), npanels, xc, yc, zc,
     &     nvortices, spacing_flag, load_flag, loads, cd_induced)

c==================== output ===========================================
      plhs(1) = mxCreateDoubleMatrix(1, 1, 0)
      p = mxGetPr(plhs(1))
      tmp(1) = cd_induced
      call mxCopyReal8ToPtr(tmp, p, 1)

      return
      end