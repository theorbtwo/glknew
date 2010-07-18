GlkNew - README 
===============

Last update: 2010-06-24

What this is
------------

"glknew" contains both an implementation of GLK (http://www.eblong.com/zarf/glk/), the C files in the main directory; and a (in fact two) Perl based web implementations that run the interpreter process and display the results as an interactive web page.

To build the glknew library, you will need
------------------------------------------

1) GCC, or equivalent C compiler. - tested with GCC 4.1.2 and 4.4.4 on linux
2) make - tested with version 3.81 on linux.
3) One or more game interpreters, fetch these and unpack in a directory at the same level as the glknew checkout:
 a) GIT 1.2.6:
  - Get from
    http://www.ifarchive.org/indexes/if-archiveXprogrammingXglulxXinterpretersXgit.html
  - Tested version is 1.2.6.
  - Apply patch in glknew/git-1.2.6.diff (modifies Makefile to use glknew).
 b) NITFOL
  - Get from
    http://www.ifarchive.org/indexes/if-archiveXinfocomXinterpretersXnitfol.html
  - Tested version is 0.5.
  - Apply patch in glknew/patches/nitfol.diff (modifies Makefile to
    use glknew.)
 TADS2
 d) AGILITY, SCARE, FROTZ
  - Provided by the garglk/gargoyle collection of interpreters:
  - Get from: http://code.google.com/p/garglk/source/checkout
  - Copy the Frotz Makefile from patches/frotz-Makefile to garglk-read-only/terps/frotz/Makefile


cd into the "glknew" directory and run:
./make_them.sh

This will attempt to build the glknew library, and all available interpreters. It should produce a libglknew.a library file.

Some games!
-----------

The file glknew/perl/game_catalyst.pl contains links to the games we are using, fetch whichever games you want to run, matching the supported interpreters, and adjust the game_catalyst.pl configuration file accordingly.

To run the Perl web implementation, you will need
-------------------------------------------------

1) The Perl interpreter, at least version 5.10.0 - http://search.cpan.org/~dapm/perl-5.10.1/ - tested with 5.10.0 and 5.10.1
2) The Catalyst web framework: http://search.cpan.org/dist/Catalyst-Runtime/ - tested with 5.80024
3) Various other Perl modules, to install them all:
  cd glknew/perl
  perl Makefile.PL
  make installdeps

To run the web application:

  cd glknew/perl
  perl bin/game_catalyst_server.pl

To test, visit http://localhost:3000/ in your browser.


 
