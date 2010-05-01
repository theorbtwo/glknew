#!/usr/local/bin/perl5.10.0

use strict;
use warnings;

use Web::Simple 'GameIF';

{
    package GameIF;
    use Game;
    use File::Spec::Functions;
    use Data::Dump::Streamer 'Dumper';

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
        # $games[$gameid] = Game->new('/usr/src/extern/glknew/perl/t/var/Advent.ulx');
        my $game = Game->new('./t/var/Advent.ulx');
        $game->user_info($gameid);
        $games[$gameid] = $game;

        $game->wait_for_select;

        return $game;
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
            my $game = $self->new_game();
            
            [ 200, 
              [ 'Content-type' => 'text/html' ], 
              [ get_formatted_text($game->root_window) ] ,
            ];
        },
    };

    sub get_formatted_text {
      my ($win) = @_;
      
      if (!ref $win) {
        $win = $self->{windows}{$win};
        return '' if(!$win);
      }
      
      my $text = '';
      my $prev_style = {};

      my %styles_needed;

      for my $e (@{$win->{content}}) {
        my ($style, $char) = @{$e}{'style', 'char'};
        if(defined $style) {
          if ($prev_style != $style) {
            if(%$prev_style) {
              $text .= '</span>';
            }
            $text .="<span class='$win->{id}-$style->{name}'>";
            $styles_needed{"$win->{id}-$style->{name}"} = $style;
          }
          if ($char eq '<') {
            $text .= '&lt;';
          } elsif ($char eq "\n") {
            $text .= "<br />\n";
          } else {
            $text .= $char;
          }

          $prev_style = $style;
        } elsif(exists $e->{cursor_to}) {
          warn "Cursor to: ", join(':', @{ $e->{cursor_to} }), "\n";
        }
      }
      ## newline so status window line is seen..
      #    print "\n";
      
      my $styles = '';
      for my $name (sort keys %styles_needed) {
        # Copy so we can freely modify it here.
        my $style = { %{$styles_needed{$name}} };

        warn Dumper($style);
        $styles .= "$name {";

        delete $style->{name};
        for my $k (sort keys %$style) {
          warn "Unhandled style hint $k (val=$style->{$k})";
        }

        $styles .= "}\n";
      }
      $text = "<style type='text/css'>$styles</style>\n$text";
      return $text;
    }

}

GameIF->run_if_script;
