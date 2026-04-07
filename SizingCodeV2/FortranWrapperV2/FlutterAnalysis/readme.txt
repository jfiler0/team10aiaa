

MODIFIED STRIP ANALYSIS METHOD FOR PREDICTING WING        /flutter/readme.txt
 FLUTTER AT SUBSONIC TO HYPERSONIC SPEEDS


The files for this program are in the directory flutter 
  readme.txt      this file of general description
  input.txt       guide to writing the input file
  flutter.f90     the complete source code
  blk.inc         the code for common /BLK/
  wws.inc         the code for common /WWS/ 
  lar10199.txt    the original program description from COSMIC
  original.src    the original copy of the source code (from COSMIC)
  case1.inp       input data for a sample case
  case1.out       output data for case1.inp

To compile this program for your computer, use the command
   gfortran flutter.f90 -o flutter.exe
Linux and Macintosh users may prefer to omit the .exe on the file name.

This program first asks for the name of the input file. This must
be a file written to conform to input.txt.  After calculating 
the solution, the program produces a file called flutter.out that contains a 
wealth of information concerning the flow problem to be solved.
