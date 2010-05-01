#!/usr/local/bin/perl5.10.0

use strict;
use warnings;

use Game;
use Web::Simple 'GameIF';

{
    package GameIF;

    my @games = ();

    default_config ( file_dir => q{/usr/src/extern/glknew/perl/root/},
                   );

    sub static_file {
        my ($self, $file, $type) = @_;
        open my $fh, '<', catfile($self->config->{file_dir}, "$file") or return [ 404, [ 'Content-type', 'text/html' ], [ 'file not found']];

        local $/ = undef;
        my $file_content = <$fh>;
        close $fh or return [ 500, [ 'Content-type', 'text/html' ], [ 'Internal Server Error'] ];

        return [ 200, [ 'Content-type' => $type ], [ $file_content ] ];
 
    }

    sub new_game {
        my ($self) = @_;
        my $gameid = scalar @games;
        $games[$gameid] = Game->new('/usr/src/extern/glknew/perl/t/var/Advent.ulx');

        $games[$gameid]->wait_for_select();

        return $gameid;
    }

#     sub game_select {
#         my ($self, $gameid, $game, $input_type, ) = @_;

#         ## Get text for main window.
#         my $text = $game->get_formatted_text($game->root_window);
#         $games[$gameid]{pending} = $text;

#         $game->{in_select} = 1;
#     }

    dispatch {
        sub (/) {
            return $self->static_file("index.html");
        },
#        sub (POST + /game/new/*) {
        sub (/game/new/*) {
            my ($self, @paths) = @_;
            my $gameid = $self->new_game();

            [ 200, 
              [ 'Content-type' => 'text/plain' ], 
              [ $games[$gameid]{current_select}{text} ] ,
            ];
        },
    };
}

GameIF->run_if_script;
