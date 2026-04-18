      subroutine sgefs(a, lda, n, b, ldb, nb, ipvt, info)
c
c  Simple replacement for legacy SGEFS:
c    Solves A * X = B for general matrix A using Gaussian elimination
c    with partial pivoting (LU factorization in-place).
c
c  Inputs:
c    a(lda,*)   coefficient matrix (overwritten)
c    lda        leading dimension of a
c    n          order of system
c    b(ldb,*)   right-hand side(s) (overwritten with solution)
c    ldb        leading dimension of b
c    nb         number of RHS columns
c
c  Outputs:
c    ipvt(*)    pivot indices (1..n)
c    info       0 if OK; k if zero pivot encountered at step k
c
      integer lda, ldb, n, nb, ipvt(*), info
      real a(lda,*), b(ldb,*)
      integer i, j, k, p, col
      real maxa, tmp, piv, factor

      info = 0

c --- LU factorization with partial pivoting ---
      do 200 k = 1, n-1

c Find pivot row p in k..n
         p = k
         maxa = abs(a(k,k))
         do 50 i = k+1, n
            if (abs(a(i,k)) .gt. maxa) then
               maxa = abs(a(i,k))
               p = i
            end if
   50    continue
         ipvt(k) = p

c Check for near-zero pivot
         if (maxa .eq. 0.0) then
            info = k
            return
         end if

c Swap rows in A if needed
         if (p .ne. k) then
            do 60 j = k, n
               tmp = a(k,j)
               a(k,j) = a(p,j)
               a(p,j) = tmp
   60       continue

c Swap corresponding rows in B for all RHS columns
            do 70 col = 1, nb
               tmp = b(k,col)
               b(k,col) = b(p,col)
               b(p,col) = tmp
   70       continue
         end if

c Eliminate entries below pivot
         piv = a(k,k)
         do 120 i = k+1, n
            factor = a(i,k) / piv
            a(i,k) = factor
            do 100 j = k+1, n
               a(i,j) = a(i,j) - factor * a(k,j)
  100       continue
            do 110 col = 1, nb
               b(i,col) = b(i,col) - factor * b(k,col)
  110       continue
  120    continue

  200 continue

      ipvt(n) = n
      if (a(n,n) .eq. 0.0) then
         info = n
         return
      end if

c --- Back substitution: U * X = Y (Y is stored in B) ---
      do 400 col = 1, nb
         b(n,col) = b(n,col) / a(n,n)
         do 350 i = n-1, 1, -1
            tmp = b(i,col)
            do 300 j = i+1, n
               tmp = tmp - a(i,j) * b(j,col)
  300       continue
            b(i,col) = tmp / a(i,i)
  350    continue
  400 continue

      return
      end
