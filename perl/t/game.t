#!/usr/local/bin/perl5.10.0
# perl5.10.0 `which prove` -v -l t/game.t 

use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok('Game');

my $game = Game->new("t/var/Advent.ulx");
isa_ok($game, 'Game');

dies_ok(sub { Game->new() }, 'Dies when not passed a game file' );

$game->wait_for_select();

done_testing;
