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
        my ($self, $game_path) = @_;
        my $gameid = scalar @games;
        # $games[$gameid] = Game->new('/usr/src/extern/glknew/perl/t/var/Advent.ulx');
        my $game = Game->new($game_path);
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
            my ($self, $game_name) = @_;
            
            my $game_path = {
                             advent => './t/var/Advent.ulx',
                             'blue-lacuna' => '/mnt/shared/projects/games/flash-if/blue-lacuna/BlueLacuna-r3.gblorb',
                             # FIXME: Why does the gblorb not work?
                             alabaster => '/mnt/shared/projects/games/flash-if/Alabaster/exec.glul',
                             acg => '/mnt/shared/projects/games/flash-if/ACG/ACG.ulx',
                            }->{$game_name};
            
            if (!$game_path) {
              die "Do not know game path for game $game_name";
            }

            my $game = $self->new_game($game_path);
            
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

      my $own_text = get_own_formatted_text($win);

      for my $child (@{$win->{children}}) {
        my $child_text = get_formatted_text($child);
        warn Dumper($child->{method});

        my ($side, $kind, $axis);
        for my $method (@{$child->{method}}) {
          if ($method ~~ [qw<above below>]) {
            $axis = 'y';
            $side = $method;
          } elsif ($method ~~ [qw<left right>]) {
            $axis = 'x';
            $side = $method;
          } elsif ($method ~~ [qw<fixed>]) {
            $kind = $method;
          } else {
            die "Unhandled method $method";
          }
        }
        
        if ($side eq 'above' and $kind eq 'fixed' and $axis eq 'y') {
          $own_text = <<END;
<table>
 <tr><td>$child_text</td></tr>
 <tr><td>$own_text</td></tr>
</table>
END
        } else {
          die "Unhandled situation, side=$side, kind=$kind, axis=$axis";
        }
      }

      return $own_text;
    }

    # FIXME: How much of this belongs in Game.pm?
    sub get_own_formatted_text_grid {
      my ($win) = @_;

      my ($cursor) = [0, 0];
      my $state;

      my $style = undef;
      for my $e (@{$win->{content}}) {
        if (exists $e->{cursor_to}) {
          $cursor = [$e->{cursor_to}[1], $e->{cursor_to}[0]];
        } elsif (exists $e->{char}) {
          # always char and style.
          $state->[$cursor->[0]][$cursor->[1]]{char}  = $e->{char};
          $state->[$cursor->[0]][$cursor->[1]]{style} = $e->{style};
          $cursor->[1]++;
        } else {
          die Dumper($e);
        }
      }

      my $text = "<tt>";
      my %styles_needed;
      for my $line (@$state) {
        for my $new_e (@$line) {
          if (!$new_e) {
            $text .= '&nbsp;';
            next;
          }
          
          if ($new_e->{char} eq '<') {
            $text .= '&lt;';
          } elsif ($new_e->{char} eq '&') {
            $text .= '&amp;';
          } elsif ($new_e->{char} eq ' ') {
            $text .= '&nbsp;';
          } else {
            $text .= $new_e->{char};
          }
        }
        $text .= "<br />\n";
      }
      $text .= "</tt>\n";

      return $text;
    }

    # FIXME: Split this properly by wintype?  Make them objects, of different classes?
    sub get_own_formatted_text {
      my ($win) = @_;
      
      if (!ref $win) {
        $win = $self->{windows}{$win};
        return '' if(!$win);
      }

      if ($win->{wintype} eq 'TextGrid') {
        return get_own_formatted_text_grid($win);
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
            $text .="<span class='winid$win->{id}-$style->{name}'>";
            $styles_needed{"winid$win->{id}-$style->{name}"} = $style;
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
        $styles .= ".$name {";

        delete $style->{name};
        if (exists $style->{TextColor}) {
          $styles .= sprintf " color: #%06x; ", delete($style->{TextColor});
        }
        if (exists $style->{Weight}) {
          my $weight = {
                        -1 => '100',
                         0 => '400',
                         1 => '700'}->{$style->{Weight}};
          if ($weight) {
            $styles .= " font-weight: $weight; ";
            delete $style->{Weight};
          }
        }
        if (exists $style->{Proportional}) {
          if ($style->{Proportional}) {
            $styles .= " text-align: justify; ";
            delete $style->{Proportional};
          }
        }
        if (exists $style->{Size}) {
          my $size = {
                       0 => 'medium'
                      }->{$style->{Size}};
          if ($size) {
            $styles .= " font-size: $size; ";
            delete $style->{Size};
          }
        }
        

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
