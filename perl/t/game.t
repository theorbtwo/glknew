#!/usr/local/bin/perl5.10.0
# perl5.10.0 `which prove` -v -l t/game.t 
BEGIN {$|=1;}

use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok('Game');

my $game = Game->new("t/var/Advent.ulx");
isa_ok($game, 'Game');

$game->wait_for_select();


dies_ok(sub { Game->new() }, 'Dies when not passed a game file' );

my $game_win_size = Game->new("t/var/Advent.ulx",
                              undef,
                              { window_size => \&win_size }
    );

$game_win_size->wait_for_select();

done_testing;

sub win_size {
    my ($game, $winid) = @_;

    ok($game->{windows}{$winid}, 'Win size passed a valid win id ');
    
    my @size = (80, 25);
    if(grep /fixed/, @{ $game->{windows}{$winid}{method} }) {
        $size[1] = 1;
    }
    $game->send_to_game(join(' ', @size));
}
