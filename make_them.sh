#!/bin/sh
make || exit

echo GIT
(cd ../git-1.2.6; rm git; make)

echo NITFOL
(cd ../nitfol-0.5 ; rm newnitfol ; make newnitfol)

echo AGILITY
(cd ../garglk-read-only/terps/agility/; rm glkagil; make -f Makefile.glk glkagil)

echo TADS
(cd ../tads2/glk; rm newtads ; make)

echo SCARE
(cd ../garglk-read-only/terps/scare/; rm glkscare; make glkscare)
