#!/bin/sh
make || exit

echo GIT
(cd ../git-1.2.6; rm git; make)
echo

echo NITFOL
(cd ../nitfol-0.5 ; rm newnitfol ; make newnitfol)
echo

echo AGILITY
(cd ../garglk-read-only/terps/agility/; rm glkagil; make -f Makefile.glk glkagil)
echo

echo TADS
(cd ../tads2/glk; rm newtads ; make)
echo

echo SCARE
(cd ../garglk-read-only/terps/scare/; rm glkscare; make glkscare)
echo

echo FROTZ
(cd ../garglk-read-only/terps/frotz/; rm frotz; make frotz)
echo
 