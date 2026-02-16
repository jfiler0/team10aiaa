

WAVE DRAG BY AREA RULE  - NASA LANGLEY PROGRAM D2500        /wavedrag/readme.txt

The files for this program are in the directory /wavedrag 
  readme.txt      this file - general description
  cases.txt       description of the sample cases supplied
  lar13223.txt    original COSMIC description file
  d2500.for       the complete source code
                   (D2500 was the internal NASA Langley name of the program)
  input.txt       Instructions for preparing input
  output.txt      How to interpret the output files

  case1.inp       input for sample case1
  case1.out       output for sample case1
  case2.inp       input for sample case2
  case2.out       output for sample case2
  case3.inp       input for sample case3
  case3.out       output for sample case3
  case4.inp       input for sample case4
  case4.out       output for sample case4
  caseslnx.zip    4 cases above with Unix end-of-line


The reference documents for this program may be accessed
from the web page https://www.pdas.com/wavedragrefs.html. 

To compile this program for your computer, use the command
   gfortran  d2500.f90 -o 2500.exe
Linux and Macintosh users may prefer to omit the .exe on the file name.

The program asks for the name of the input file. This file must be
formatted according to the instructions in input.txt. The output from
the program is described in the file output.txt.

              

              DESCRIPTION

The concept known as the area rule is one of the great success stories
of airplane design. The area rule says very simply that the transonic wave 
drag of an aircraft is essentially the same as the wave drag of an equivalent
body of revolution having the same cross-sectional area distribution as the 
aircraft. Since the rule was formulated and verified experimentally, attempts
have been made to estimate aircraft wave drag by a theoretical analysis of 
the equivalent-body area distributions.  It is known that reasonably good 
wave drag estimates can be made near a Mach Number of 1 if the slender-body-
theory is applied to the aircraft area distribution. Numerous theoretical and
experimental investigations show that the fuselage and other components of 
an airplane can be reshaped in a way that will reduce the wave drag of the 
total configuration. A typical configuration will frequently have a fuselage 
with a local minimum of area near the middle of its length, sometimes 
referred to as "coke-bottling".

The transonic area rule was considered so valuable that attempts were
made to extend the results to higher Mach numbers. This theoretical effort 
culminated in the development of the so-called Supersonic Area Rule, which 
is more complicated than the transonic rule.

The procedure can be extended to higher Mach numbers with good accuracy 
by using the supersonic area rule to determine the equivalent-body area
distributions.

Not many textbooks on aerodynamics give an explanation of supersonic area 
rule, but "Aerodynamics of Wings and Bodies" by Ashley and Landahl has a 
good introduction in section 9-7. This book is available in a low cost 
student edition and is highly recommended. Jack Nielsen's book "Missile 
Aerodynamics" also has a good treatment.  It is distributed by AIAA.

The development of the area rule concept was largely reported in NACA reports
that are not easily accessible for everyone. 
There are links to additional references at the web site at
   https://www.pdas.com/wavedragrefs.html
