package Game::HTML;
# -*- cperl -*-

use strict;
use warnings;

use Game;
use File::Spec::Functions;
use File::Path 'mkpath';
use Data::Dumper;
## This is the HTML layer over Game, which is the perl skin over glknew, which is.. C all the way down.

sub new {
    my ($class, $game_id, $game_path, $interp_path, $save_file_dir) = @_;
    my $self = bless({ 
                      save_file_dir => $save_file_dir,
                      ## keys here correspond to HTML ids of forms in get_forms
                      form_states => { input => 1, save => 0 },
                     }, $class);

    my $game = Game->new($game_path, 
                         $interp_path,
                         { 
                          style_distinguish => \&style_distinguish,
                          save_file => sub { $self->prep_save_file() },
                         });
    $game->user_info($game_id);
    $self->{game_obj} = $game;

    return $self;
}

sub continue {
    my ($self) = @_;

    $self->set_form_visible('input');
    $self->{game_obj}{current_select} = {};
    $_->new_turn for(values %{ $self->{game_obj}{windows} });

    $self->{game_obj}->wait_for_select;
}

sub send {
  my ($self, $input) = @_;

  $self->{game_obj}->send_to_game($input);
}

sub send_save_file {
  my ($self, $username, $savefile) = @_;

  my $game_dir = catfile($self->{save_file_dir}, $username);
  mkpath($game_dir);
  my $game_file = catfile($game_dir, $savefile);

  $self->send("$game_file\n");

}

sub prep_save_file {
    my ($self, $file_dir) = @_;

    ## get_form sends several forms, some are hidden, we set a value that json will use to unhide the save file form.
    $self->set_form_visible('save');

    ## file is a line input.. although we're not using this on-screen yet anyway
    $self->{game_obj}->{current_select}{input_type} = 'line';
    
    ## Escape loop so we can send the form to the browser
    $self->{game_obj}{collecting_input} = 0;
}

sub set_form_visible {
    my ($self, $formid) = @_;

    foreach my $form (keys %{ $self->{form_states} }) {
        $self->{form_states}{$form} = 0;
        $self->{form_states}{$form} = 1 if($form eq $formid);
    }
}

sub get_form_states {
    my ($self) = @_;

    return $self->{form_states};
}

sub get_input_type {
    my ($self) = @_;

    return $self->{game_obj}->{current_select}{input_type};
}

sub get_forms {
    my ($self) = @_;
    my ($game) = $self->{game_obj};

    my $gameid = $game->user_info;
    my $forms;
    my $winid = $game->{current_select}{window}{id};

    if ($game->{current_select}{input_type} eq 'line') {
        # $form = "<input type='text' name='text' />";
    } elsif ($game->{current_select}{input_type} eq 'char') {
        # $form = "<i>want char</i><input type='text' name='char' />";
    } elsif (not defined $game->{current_select}{input_type}) {
        die "Don't know how to handle this callback -- \$game->{current_select}{input_type} not defined";
    } else {
        print STDERR Dumper($game->{current_select});
        die "Don't know how to handle this callback -- \$game->{current_select}{input_type} eq \'$game->{current_select}{input_type}\'";
    }
    my $input = "Input <span id='prompt_type'>$game->{current_select}{input_type}</span><input id='prompt' type='text' name='text' /><input id='input_type' type='hidden' name='input_type' value=\'$game->{current_select}{input_type}\'";
      
    $forms = "<form class='form' id='input' method='post' action='/game/continue'><input type='hidden' name='game_id' value='$gameid' /><input type='hidden' name='window_id' value='winid$winid'/><input id='keycode_input' type='hidden' name='keycode' value=''/>$input</form>";

    $forms .= "<form class='form' id='save' style='display: none' method='post' action='/game/savefile'><span><label for='username'>Username<input type='text' id='username' name='username'/></label></span><br/><span><label for='save_file'>Filename<input type='text' id='save_file' name='save_file'/></label></span><br/><input type='hidden' name='game_id' value='$gameid' /><input type='submit' value='Save'/>";

    return $forms;
}

sub make_page {
  my ($self, $content, $title) = @_;

  $content ||= $self->get_initial_windows() . $self->get_forms;
  my $js = '<script type="text/javascript" src="/js/jquery-1.4.2.min.js"></script>' 
    . '<script type="text/javascript" src="/js/next-action.js"></script>';

  my $styles = default_styles();
        
  my $page = <<END;
<? xml ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
 <head>
  <title>$title</title>
  $js
  $styles
 </head>
 <body>
  $content
 </body>
</html>
END
}

sub default_styles {
    return "<style>
.TextBuffer {
  overflow: auto; 
  height: 400px;
}
html {
  height: 100%;
}
</style>\n";
}

sub get_initial_windows {
  my ($self) = @_;
    
  return get_formatted_text($self->{game_obj}->root_window);
}

sub get_continue_windows {
    my ($self) = @_;

    my @windows = map { 
        my $status = 'append';
        if ($_->{wintype} eq 'TextGrid') {
            $status = 'clear';
        } elsif ($_->last_page->[0]{clear}) {
            $status = 'clear';
        };
        +{ 
          winid => "winid" . $_->{id}, 
          content => get_own_formatted_text($_),
          status => $status,
         } 
    } (values %{ $self->{game_obj}->{windows} });

    return \@windows;
}

## Window::HTML?
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
  warn "Child: $child_text\n";

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
 <div style='width:$child->{size}%;'>$child_text</div>
 <div style="float:right;">$parent_text</div>
</div>
<br style="clear:both"/>
END
  } else {
      die "Unhandled situation, side=$side, kind=$kind, axis=$axis";
  }
  
  return $parent_text;
}
    
# FIXME: Split this properly by wintype?  Make them objects, of different classes?
sub get_own_formatted_text {
    my ($win) = @_;
      
    my $dispatch = {
                    TextGrid   => \&get_own_formatted_text_TextGrid,
                    TextBuffer => \&get_own_formatted_text_TextBuffer,
                    Graphics   => \&get_own_formatted_text_Graphics,
                   };
    if (not exists $dispatch->{$win->{wintype}}) {
        die "Don't know how to dispatch get_own_formatted_text for wintype $win->{wintype}";
    }
      
    return $dispatch->{$win->{wintype}}->($win);
}

# FIXME: How much of this belongs in Game.pm?
sub get_own_formatted_text_TextGrid {
    my ($win) = @_;

    my ($cursor) = [0, 0];
    my $state;
    
    my $style = undef;
    for my $e (map {@$_} @{$win->pages}, $win->content) {
        if (exists $e->{cursor_to}) {
            $cursor = [$e->{cursor_to}[1], $e->{cursor_to}[0]];
        } elsif (exists $e->{char} and $e->{char} eq "\n") {
            $cursor->[0]++;
            $cursor->[1]=0;
        } elsif (exists $e->{char}) {
            # always char and style.
            $state->[$cursor->[0]][$cursor->[1]]{char}  = $e->{char};
            $state->[$cursor->[0]][$cursor->[1]]{style} = $e->{style};
            $cursor->[1]++;
        } elsif (exists $e->{clear}) {
            $state = [];
        } else {
            die "Unhandled content element: ", Dumper($e);
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
    $text = "<span class='move-top'></span>$text";
    
    return $text;
}

sub get_own_formatted_text_TextBuffer {
    my ($win) = @_;
    
    my $text = '';
    my $prev_style = {};
    
    my %styles_needed;
    
    for my $e (@{$win->content}) {
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
    $text = "<span class='move-top'></span>$text";
    
    #      print "Text with styles: $text\n";
    return $text;
}

sub get_own_formatted_text_Graphics {
    return "GRAPHICS GOES HERE!";
}

sub get_style {
    my ($style) = @_;
    
    my $style_str = '';
    
    warn Dumper($style);
    return '' if(!exists $style->{name});
    $style_str .= ".$style->{wintype}-$style->{name} {";
    delete $style->{name};
    
    # The spec doesn't really call out this behavior at all, but
    # squashing multiple space chars in a row is really a HTML
    # thing, not a general text-processing thing.
    $style_str .= " white-space: pre-wrap; ";
    
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
        next if $k eq 'wintype';
        warn "Unhandled style hint $k (val=$style->{$k})";
    }
    
    $style_str .= "}\n";
    #        print "Adding style: $style_str\n";
    
    return $style_str;
}

sub style_distinguish {
    my ($self, $winid, $style1, $style2) = @_;
    my $game = $self->{game_obj};

    my ($style_css_1, $style_css_2) = map  { get_style( $game->{styles}{ $game->{windows}{$winid}{wintype} }{$style1} ) } ($style1, $style2);

    $game->send_to_game($style_css_1 eq $style_css_2 ? "0\n" : "1\n");
}

1;
    
# Local Variables:
# cperl-indent-level: 2
# End:

