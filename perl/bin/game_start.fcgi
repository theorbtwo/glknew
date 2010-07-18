#!/bin/bash

# Startup script which sets the environment etc. Also moving options into
# here for convenience, except for the PID file which needs to be known
# to the init script.

PATH=/var/www/glknew.org/perl5/perlbrew/bin:/var/www/glknew.org/perl5/perlbrew/perls/current/bin:/usr/bin:/bin
# don't increase past 3 without epi's say so to not use too many resources on agaton.
# don't increase past 1 without fixing the process model!
N_PROCS=1
SOCKET=/var/www/glknew.org/treffpunkt/treffpunkt.sock
DAEMON=/var/www/glknew.org/glknew/perl/bin/game_catalyst_fastcgi.pl
PERL5LIB=

exec "$DAEMON" --nproc "$N_PROCS" --listen "$SOCKET" --daemon "$@"

