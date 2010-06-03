package Game::HTML;
# -*- cperl -*-

use strict;
use warnings;

use Game;
use Carp 'cluck';
use File::Spec::Functions;
use File::Path 'mkpath';
use Data::Dump::Streamer 'Dump', 'Dumper';
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
                          window_size => sub { $self->send_window_size(@_) },
                          style_distinguish => \&style_distinguish,
                          prompt_file => sub { $self->prep_prompt_file() },
                         });
    $game->user_info($game_id);
    $self->{game_obj} = $game;

    return $self;
}

sub continue {
    my ($self) = @_;

#    cluck "Continuing";
    $self->set_form_visible('input');
    $self->{game_obj}{current_select} = {};

    $self->{game_obj}->wait_for_select;
}

sub send {
  my ($self, $input) = @_;

  $self->{game_obj}->send_to_game($input);
}

sub send_prompt_file {
  my ($self, $username, $savefile) = @_;

  my $game_dir = catfile($self->{save_file_dir}, $username);
  mkpath($game_dir);
  my $game_file = catfile($game_dir, $savefile);

  $self->send("$game_file\n");
}

sub prep_prompt_file {
    my ($self, $usage, $mode) = @_;

    ## get_form sends several forms, some are hidden, we set a value that json will use to unhide the save file form.
    $self->set_form_visible('save');

    ## this doesn't actually get used, but we want to set it to something to avoid uninit warning.
    $self->{game_obj}->{current_select}{input_type} = 'file';
    # hr, keys are {Data, SavedGame, Transcript, InputRecord}, Text?
    $self->{game_obj}->{current_select}{file_usage} = $usage;
    # Write, Read, ReadWrite, WriteAppend
    $self->{game_obj}->{current_select}{file_mode} = $mode;
    
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
    my $input_type = $game->{current_select}{input_type};

    $forms = <<END;
<form class='form' id='input' method='post' action='/game/continue'>
 <input type='hidden' name='game_id' value='$gameid' />
 <input type='hidden' name='window_id' value='winid$winid'/>
 <input id='keycode_input' type='hidden' name='keycode' value=''/>
 <input id='keycode_ident' type='hidden' name='keycode_ident' value=''/>

 Input <span id='prompt_type'>$input_type</span>
 <input id='prompt' type='text' name='text' />
 <input id='input_type' type='hidden' name='input_type' value='$input_type' />
</form>
<form class='form' id='save' style='display: none;' method='post' action='/game/savefile'>
 <span>
  <label for='username'>Username<input type='text' id='username' name='username'/></label>
 </span><br/>
 <span><label for='save_file'>Filename<input type='text' id='save_file' name='save_file'/></label></span><br/>
 <input type='hidden' name='game_id' value='$gameid' />
 <input type='submit' value='Submit' />
</form>
<img src='/img/ajaxload.gif' style='display: none' id='throbber' /><span id='status'></span>

END



    return $forms;
}

sub make_page {
  my ($self, $content, $title) = @_;

  $content ||= ("<div id='all-windows'>" 
                . $self->get_initial_windows() . '</div>' 
                . $self->get_forms);
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

# 1 iff any of the windows of this game have ->drawn == 0
sub has_new_windows {
  my ($self) = @_;

  for my $win (values %{$self->{game_obj}{windows}}) {
    if (!$win->drawn) {
      return 1;
    }
  }

  return;
}

sub get_initial_windows {
  my ($self) = @_;
    
  return get_formatted_text($self->{game_obj}->root_window, 1);
}

sub get_continue_windows {
    my ($self) = @_;

    ## FIXME, why is last_page returning undef? Bad response Can't use an undefined value as an ARRAY reference at lib/Game/HTML.pm line 173, <GEN11> line 16505.
    my @windows = map { 
      my ($text, $status) = $_->get_own_formatted_text;
      +{ 
        winid => "winid" . $_->{id}, 
        content => $text,
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
  my ($win, $full_content) = @_;

  my $win_text = $win->get_own_formatted_text($full_content);
  my $win_div  = "<div class='$win->{wintype}' id='winid$win->{id}'> $win_text </div>" ;

  my $formatted = $win_div;
  for my $child (@{$win->{children}}) {
      $formatted = layout_child_window($child, $formatted, $full_content);
  }

  ## Currently this only gets called when we drawn entire windows
  ## set state of window here:
  $win->drawn(1);

  return $formatted;
}


## IN: Child window, Parents text so-far
## OUT: New text containing parent + child text
sub layout_child_window {
  my ($child, $parent_text, $full_content) = @_;

  my $child_text = get_formatted_text($child, $full_content);
  warn Dumper($child->{method});
  warn "Child: $child_text\n";

  my ($side, $kind, $axis);
  my $method = $child->method;
  if ($method->{above}) {
    $axis = 'y';
    $side = 'above';
  }
  if ($method->{below}) {
    $axis = 'y';
    $side = 'below';
  }
  if ($method->{left}) {
    $axis = 'x';
    $side = 'left';
  }
  if ($method->{right}) {
    $axis = 'x';
    $side = 'right';
  }
  if ($method->{fixed}) {
    $kind = 'fixed';
  }
  if ($method->{proportional}) {
    $kind = 'proportional';
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
   <div style="height: $child->{size} px;">$child_text</div>
   $parent_text
 </div>
END
  } elsif ($side eq 'below' and $kind eq 'fixed' and $axis eq 'y') {
      $parent_text = <<END;
 <div>
   $parent_text
   <div style="height: $child->{size} px;">$child_text</div>
 </div>
END
  } elsif ($side eq 'left' and $kind eq 'proportional' and $axis eq 'x') {
    # Take off 1% from each side in order to give the layout algo some
    # breathing-room.
    my $lsize = $child->{size}-1;
    my $rsize = (100-$child->{size})-1;
      $parent_text = <<END;
<div style="width:100%;">
 <div style="float:left;  width:$lsize%;">$child_text</div>
 <div style="float:right; width:$rsize%;">$parent_text</div>
</div>
<br style="clear:both"/>
END
  } else {
      die "Unhandled situation, side=$side, kind=$kind, axis=$axis";
  }
  
  return $parent_text;
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

sub send_window_size {
  my ($self, $game, $winid) = @_;

  my $win = $self->{game_obj}{windows}{$winid};
  if ($win->window_size_is_fake) {
    $game->{collecting_input} = 0;
    $game->{current_select} = {
                               window => $win,
                               input_type => 'size'
                              };
    return;
  }
  my ($width, $height) = @{ $win->window_size() };

  ## Browser returns values in pixels, for text windows we apply fudge factors
  ## to return it in chars.
  # These constants are so that an 80x25 text window is the same size as a 640x480 graphics window.

  warn "Size before: $width x $height";
  if(!$win->isa('Game::Window::Graphics')) {
      $width  = int($width  / 8);
      $height = int($height / 19.2);
  }
  warn "Size after: $width x $height";
  
  $self->send("$width $height\n");
}

sub set_window_size {
  my ($self, $winid, @size) = @_;
  my $win = $self->{game_obj}{windows}{$winid};
  
  my $old_size = $win->window_size;
  $size[0] ||= $old_size->[0];
  $size[1] ||= $old_size->[1];
  $win->window_size(\@size);
  $win->window_size_is_fake(0);

  if ($self->{game_obj}{current_select}{input_type} eq 'size' and
      $self->{game_obj}{current_select}{window}->id eq $winid) {

    $self->send_window_size($self->{game_obj}, $winid);

    $self->continue;
  }
}

sub style_distinguish {
    my ($game, $winid, $style1, $style2) = @_;
    my $win = $game->{windows}{$winid};

    warn Dumper \@_;
    warn Dumper $game;
    warn Dumper $win;

    my ($style_css_1, $style_css_2) = map  { get_style( $game->{styles}{ $win->{wintype} }{$_} ) } ($style1, $style2);

    $game->send_to_game($style_css_1 eq $style_css_2 ? "0\n" : "1\n");
}

1;
    
# Local Variables:
# cperl-indent-level: 2
# End:

