program run_idrag
  implicit none

  integer, parameter :: npanels_max=5, nvortices_max=200
  character(len=72) :: outfile, title
  integer :: input_mode, write_flag, sym_flag, cm_flag
  integer :: npanels, load_flag
  real :: cl_design, cm_design, xcg, cp, sref, cavg
  integer :: nvortices(npanels_max), spacing_flag(npanels_max)
  real :: xc(npanels_max,4), yc(npanels_max,4), zc(npanels_max,4)
  real :: loads(npanels_max*nvortices_max)
  real :: cd_induced

  character(len=256) :: inname
  integer :: i, j, nloads

  ! --- Get input file from command line ---
  call get_command_argument(1, inname)
  if (len_trim(inname) == 0) then
     print *, "Usage: run_idrag <input_file>"
     stop 1
  end if

  ! --- Defaults (important if npanels < npanels_max) ---
  nvortices = 0
  spacing_flag = 0
  xc = 0.0
  yc = 0.0
  zc = 0.0
  loads = 0.0

  open(10, file=trim(inname), status='old', action='read')

  ! ===== INPUT FILE FORMAT (fixed order) =====
  read(10,'(A)') outfile
  read(10,'(A)') title
  read(10,*) input_mode, write_flag, sym_flag
  read(10,*) cl_design
  read(10,*) cm_flag, cm_design, xcg, cp
  read(10,*) sref, cavg
  read(10,*) npanels

  do i=1,npanels
     read(10,*) nvortices(i), spacing_flag(i)
     do j=1,4
        read(10,*) xc(i,j), yc(i,j), zc(i,j)
     end do
  end do

  read(10,*) load_flag

  if (input_mode == 1) then
     nloads = 0
     do i=1,npanels
        nloads = nloads + nvortices(i)
     end do
     do i=1,nloads
        read(10,*) loads(i)
     end do
  end if

  close(10)

  ! --- Call your legacy routine ---
  call idrag(outfile, title, input_mode, write_flag, sym_flag, &
             cl_design, cm_flag, cm_design, xcg, cp, sref, cavg, npanels, &
             xc, yc, zc, nvortices, spacing_flag, load_flag, loads, cd_induced)

  ! --- Write a simple output file MATLAB can parse ---
  open(20, file="idrag_result.txt", status="replace", action="write")
  write(20,'(A,1X,F15.8)') "cd_induced", cd_induced
  close(20)

end program run_idrag
