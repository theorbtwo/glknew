#!/usr/local/bin/perl5.10.0

use strict;
use warnings;

use Web::Simple 'GameIF';

{
    package GameIF;
    use Game;
    use JSON;
    use File::Spec::Functions;
    use Data::Dump::Streamer 'Dumper';

    my @games = ();

    my $root;
    if (-e '/usr/src/extern/glknew/perl') {
      $root = '/usr/src/extern/glknew/perl/';
    } elsif (-e '/mnt/shared/projects/games/flash-if/glknew/perl/') {
      $root = '/mnt/shared/projects/games/flash-if/glknew/perl/';
    } else {
      die "Cannot find root";
    }

    default_config ( file_dir => "$root/root",
                     git_binary => "$root/../../git-1.2.6/git",
                   );

    sub static_file {
        my ($self, $file, $type) = @_;
        my $fullfile = catfile($self->config->{file_dir}, "$file");
#print STDERR "static File: $fullfile\n";
        open my $fh, '<', $fullfile or return [ 404, [ 'Content-type', 'text/html' ], [ "file not found $fullfile"]];

        local $/ = undef;
        my $file_content = <$fh>;
        close $fh or return [ 500, [ 'Content-type', 'text/html' ], [ 'Internal Server Error'] ];

        return [ 200, [ 'Content-type' => $type ], [ $file_content ] ];
 
    }

    sub new_game {
        my ($self, $game_path, $interp_path) = @_;
        my $gameid = scalar @games;
        my $game = Game->new($game_path, 
                             $interp_path,
                            { style_distinguish => \&style_distinguish });
        $game->user_info($gameid);
        $games[$gameid] = $game;

        $game->wait_for_select;

        return $game;
    }

    sub default_styles {
        return "<style>
.textBuffer {
  overflow: auto; 
  height: 400px;
}
html {
  height: 100%;
}
</style>\n";
    }

    dispatch {
        sub (/) {
            return $self->static_file("index.html");
        },

        sub (/js/**) {
            my $file=$_[1];
            return $self->static_file("js/$file", "text/javascript");
        },
 
       sub (/css/**) {
            my $file=$_[1];
            return $self->static_file("css/$file", "text/css");
        },

        sub (/game/continue + ?text~&input_type=&game_id=&window_id=) {
          my ($self, $text, $input_type, $game_id, $window_id) = @_;
          my $char = $text if($input_type eq 'char');

          my $run_select = 1;
          my $game = $games[$game_id];
          if (defined $text and not defined $char) {
            $game->send_to_game("evtype_LineInput $text\n");
          } elsif (defined $char) {
            $game->send_to_game("evtype_CharInput ".ord($char)."\n");
          } elsif (not defined $text and not defined $char) {
            # Do nothing.
            $run_select = 0;
          } else {
            # Both text and char are defined?
            die "Double-down on continue -- char='$char', text='$text'";
          }

          $game->wait_for_select
            if $run_select;

          my $form = get_form($game);

          my $json = JSON::encode_json({ 
                                        winid => "winid" . $game->{current_select}{window}{id},
                                        input_type => $game->{current_select}{input_type},
                                        content => get_own_formatted_text($game->root_window)
                                         });
print "Sending JSON: $json\n";
          [ 200, 
            [ 'Content-type' => 'application/json' ], 
            [ $json ]
#            [ 'Content-type' => 'text/html' ], 
#            [ default_styles(). get_formatted_text($game->root_window) . $form ]
          ];

        },

        sub (/game/new/*) {
            my ($self, $game_name) = @_;

            my $git = "$root/../../git-1.2.6/git";
            my $nitfol = "/mnt/shared/projects/games/flash-if/nitfol-0.5/newnitfol";
            my %games = (
                         advent        => [$git, "$root/t/var/Advent.ulx"],
                         'blue-lacuna' => [$git, '/mnt/shared/projects/games/flash-if/blue-lacuna/BlueLacuna-r3.gblorb'],
                         # FIXME: Why does the gblorb not work?
                         alabaster     => [$git, '/mnt/shared/projects/games/flash-if/Alabaster/Alabaster.gblorb'],
                         acg           => [$git, '/mnt/shared/projects/games/flash-if/ACG/ACG.ulx'],
                         king          => [$git, '/mnt/shared/projects/games/flash-if/The King of Shreds and Patches.gblorb'],
                         curses        => [$nitfol, '/mnt/shared/projects/games/flash-if/curses.z5'],
                        );
            my $game_info = $games{$game_name};

            if (!$game_info) {
              die "Do not know game path for game $game_name -- supported: ".join(", ", keys %games);
            }
            my ($interp_path, $game_path) = @$game_info;

            my $game = $self->new_game($game_path, $interp_path);
            my $form = get_form($game);

            [ 200, 
              [ 'Content-type' => 'text/html' ], 
              [ make_page(get_initial_windows($game) . $form )]
            ];
          }
      };

    ## TT?
    sub make_page {
        my ($content) = @_;

        my $js = '<script type="text/javascript" src="/js/jquery-1.4.2.min.js"></script>' 
          . '<script type="text/javascript" src="/js/next-action.js"></script>';



        my $page = "<html><head>$js</head><body>" 
          . default_styles()
            . $content
              . '</body></html>';
    }

    sub get_form {
      my ($game) = @_;

      my $gameid = $game->user_info;
      my $form;
      {
        no warnings 'uninitialized';

        my $winid = $game->{current_select}{window}{id};
        if ($game->{current_select}{input_type} eq 'line') {
#          $form = "<input type='text' name='text' />";
        } elsif ($game->{current_select}{input_type} eq 'char') {
#          $form = "<i>want char</i><input type='text' name='char' />";
        } elsif (not defined $game->{current_select}{input_type}) {
          die "Don't know how to handle this callback -- \$game->{current_select}{input_type} not defined";
        } else {
          print STDERR Dumper($game->{current_select});
          die "Don't know how to handle this callback -- \$game->{current_select}{input_type} eq \'$game->{current_select}{input_type}\'";
        }
        my $input = "Input <span id='prompt_type'>$game->{current_select}{input_type}</span><input id='prompt' type='text' name='text' /><input id='input_type' type='hidden' name='input_type' value=\'$game->{current_select}{input_type}\'";

        $form = "<form id='input' method='post' action='/game/continue/$gameid'><input type='hidden' name='game_id' value='$gameid' /><input type='hidden' name='window_id' value='winid$winid'/>$input</form>";
      }

      return $form;
    }

    sub get_initial_windows {
        my ($game) = @_;

        return get_formatted_text($game->root_window);
    }

    ## get_window_layout?
    ## IN Window object
    ## OUT Laid out window text plus all child windows
    sub get_formatted_text {
      my ($win) = @_;

      my $win_text = get_own_formatted_text($win);
      my $win_div  = "<div class='$win->{wintype}' id='winid$win->{id}'> $win_text </div>" ;

      my $formatted = $win_div;
      for my $child (@{$win->{children}}) {
        $formatted = layout_child_window($child, $formatted);
      }

      return $formatted;
    }


    ## IN: Child window, Parents text so-far
    ## OUT: New text containing parent + child text
    sub layout_child_window {
        my ($child, $parent_text) = @_;

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
          } elsif ($method ~~ [qw<fixed proportional>]) {
            $kind = $method;
          } else {
            die "Unhandled method $method";
          }
        }

        # fixed vs proportional: are height/width attrs (as
        # approprate) percentages, or number-of-chars?  Currently, we
        # assume that if it's fixed, the height is ignorable, since
        # one side will be a textgrid of that size anyway.

        # x vs y axis determines if we have one tr of two td (x) or
        # two trs, each with one td.

        # above/left means $child_text comes first.  below/right means
        # $parent_text comes first.

        if ($side eq 'above' and $kind eq 'fixed' and $axis eq 'y') {
          $parent_text = <<END;
 <div>
   $child_text
   $parent_text
 </div>
END
        } elsif ($side eq 'below' and $kind eq 'fixed' and $axis eq 'y') {
          $parent_text = <<END;
 <div>
   $parent_text
   $child_text
 </div>
END
        } elsif ($side eq 'left' and $kind eq 'proportional' and $axis eq 'x') {
          $parent_text = <<END;
<div style="width:100%;">
 <div style='min-width:$child->{size}%;'>$child_text</div>
 <div style="float:right;">$parent_text</div>
</div>
<br style="clear:both"/>
END
        } else {
          die "Unhandled situation, side=$side, kind=$kind, axis=$axis";
        }

        return $parent_text;
    }

    # FIXME: How much of this belongs in Game.pm?
    sub get_own_formatted_text_grid {
      my ($win) = @_;

      my ($cursor) = [0, 0];
      my $state;

      my $style = undef;
      for my $e (@{$win->last_page}) {
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

      if ($win->{wintype} eq 'TextGrid') {
        return get_own_formatted_text_grid($win);
      }

      my $text = '';
      my $prev_style = {};

      my %styles_needed;

      for my $e (@{$win->last_page}) {
        my ($style, $char) = @{$e}{'style', 'char'};
        if(defined $style) {
          if ($prev_style != $style) {
            if(%$prev_style) {
              $text .= '</span>';
            }
            $text .="<span class='$win->{wintype}-$style->{name}'>";
            $styles_needed{"$win->{wintype}-$style->{name}"} = $style;
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

      my $styles = '';
      for my $name (sort keys %styles_needed) {
        # Copy so we can freely modify it here.
        my $style = { %{$styles_needed{$name}} };

        $styles .= get_style($style);
      }
      $text = "<style type='text/css'>$styles</style>\n$text";

#      print "Text with styles: $text\n";
      return $text;
    }

    sub get_style {
        my ($style) = @_;

        my $style_str = '';

        warn Dumper($style);
        return '' if(!exists $style->{name});
        $style_str .= ".$style->{wintype}-$style->{name} {";

        delete $style->{name};
        if (exists $style->{TextColor}) {
          $style_str .= sprintf " color: #%06x; ", delete($style->{TextColor});
        }
        if (exists $style->{BackColor}) {
          $style_str .= sprintf " background-color: #%06x; ", delete($style->{BackColor});
        }
        if (exists $style->{Weight}) {
          my $weight = {
                        -1 => '100',
                         0 => '400',
                         1 => '700'}->{$style->{Weight}};
          if ($weight) {
            $style_str .= " font-weight: $weight; ";
            delete $style->{Weight};
          }
        }
        if (exists $style->{Proportional}) {
          if (!$style->{Proportional}) {
            $style_str .= " font-family: monospace; ";
            delete $style->{Proportional};
          }
        }
        if (exists $style->{Size}) {
          my $size = {
                       0 => 'medium',
                       1 => 'large'
                      }->{$style->{Size}};
          if ($size) {
            $style_str .= " font-size: $size; ";
            delete $style->{Size};
          }
        }
        if (exists $style->{Oblique}) {
          if ($style->{Oblique}) {
            $style_str .= " font-style: oblique; ";
            delete $style->{Oblique};
          } else {
            $style_str .= " font-style: normal; ";
            delete $style->{Oblique};
          }
        }
        if (exists $style->{Justification}) {
          # FIXME: This requires block-level element to work; we are currently using inline elements, so this will have no effect.
          $style_str .= sprintf(" text-align: %s; ",
                             ['left',
                              'justify',
                              'center',
                              'right']->[delete $style->{Justification}]
                            );
        }


        for my $k (sort keys %$style) {
          warn "Unhandled style hint $k (val=$style->{$k})";
        }

        $style_str .= "}\n";
#        print "Adding style: $style_str\n";

        return $style_str;
    }

    sub style_distinguish {
        my ($game, $winid, $style1, $style2) = @_;

        my ($style_css_1, $style_css_2) = map  { get_style( $game->{styles}{ $game->{windows}{$winid}{wintype} }{$style1} ) } ($style1, $style2);

        $game->send_to_game($style_css_1 eq $style_css_2 ? "0\n" : "1\n");
    }

}

GameIF->run_if_script;
