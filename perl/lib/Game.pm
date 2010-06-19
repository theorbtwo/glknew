package Game;
use IPC::Open3;
use IPC::Run 'start';
use Symbol 'geniosym';
use IO::Handle;
use 5.010_00;
use Data::Dump::Streamer;

use Game::Window::Graphics;
use Game::Window::TextBuffer;
use Game::Window::TextGrid;


sub new {
  my ($class, $blorb_file, $git, $callbacks) = @_;
  $callbacks ||= {};
  die "blorb file is required" unless $blorb_file;
  # Turns out that the "blorb file" doesn't always need to exist;
  # in fact, it will never exist in the Agility case.
  # die "$blorb_file does not exist" unless -e $blorb_file;
  die "git binary is required" unless $git;
  die "$git does not exist" unless -e $git;

  my $self = bless {}, $class;
  $self->{_game_file} = $blorb_file;
  $self->{_git_binary} = $git;
  $self->set_callbacks(%$callbacks);

  my $input_str = '';
  $self->{input_str} = \$input_str;
  # Parser leftovers at end of block.
  $self->{leftovers} = '';

  $self->setup_initial_styles();
#  $self->setup_ipc_open3();
  $self->setup_ipc_run();

  return $self;
}

=head2 set_callbacks

 Game->set_callbacks(select => \&yo_momma, fetch => \&fido);

Resets the callbacks to the mentioned ones, plus the defaults.

=cut

sub set_callbacks {
  my ($self, %callbacks) = @_;

  $self->{_callbacks} = {
      select => \&default_select_callback,
      window_size => \&default_window_size_callback,
      style_distinguish => sub { 0; },
      %callbacks,
  };

  return $self;
}

sub setup_initial_styles {
  my ($self) = @_;

  # Only TextBuffer and TextGrid can have text in them, but the spec says they all have styles, so what the hell.
  for my $wt (qw<Pair Blank TextBuffer TextGrid Graphics>) {
    $self->{styles}{$wt}{Emphasized} = {Weight => 1};
    $self->{styles}{$wt}{Preformatted} = {Proportional => 0};
    $self->{styles}{$wt}{Header} = {Weight => 1,
                                    Size => 2};
    $self->{styles}{$wt}{Subheader} = {Weight => 1,
                                       Size => 1};
    $self->{styles}{$wt}{Alert} = {TextColor => 0xFF0000};
    $self->{styles}{$wt}{Note}  = {Oblique => 1};
    
    for my $s (qw<Normal Emphasized Preformatted Header Subheader Alert Note BlockQuote Input User1 User2>) {
      $self->{styles}{$wt}{$s}{name} = $s;
      $self->{styles}{$wt}{$s}{wintype} = $wt;
    }
    # An interesting question: should I create defaults in these?  The spec says only Preformatted has defaulting,
    # but it probably only means that only it is required to.  Seems a bit silly to give them names otherwise, no?
  }
}

sub setup_ipc_open3 {
  my ($self) = @_;

  $self->{$_} = geniosym for qw<child_stdin child_stdout>;
  # Sepcifing stderr as something which is currently undef will result
  # in stderr being the same as stdout... which, it turns out, is just
  # what we want in this case, since it avoids the bother of having to
  # multiplex two read streams.
  #$self->{child_stderr} = gensym;
  # BIG FAT WARNING: open3 modifies it's arguments!
  if ($ENV{USE_VALGRIND}) {
    open3($self->{child_stdin}, $self->{child_stdout}, $self->{child_stderr},
          '/usr/bin/valgrind', '--track-origins=yes', '--log-fd=1', $self->{_git_binary}, $self->{_game_file}) or die "Couldn't start child process; $!";
  } else {
    open3($self->{child_stdin}, $self->{child_stdout}, $self->{child_stderr},
          $self->{_git_binary}, $self->{_game_file}) or die "Couldn't start child process; $!";
  }
  for (@{$self}{qw/child_stdin child_stdout child_stderr/}) {
    my $was = select($_);
    $|=1;
    select($was);
  }
}

sub setup_ipc_run {
  my ($self) = shift;

  $self->{$_} = geniosym for qw<child_stdin child_stdout child_stderr>;
  if ($ENV{USE_VALGRIND}) {
    start([ '/usr/bin/valgrind', '--track-origins=yes', '--log-fd=1', $self->{_git_binary}, $self->{_game_file}],
         '<pipe', $self->{child_stdin}, 
          '>pipe', $self->{child_stdout}, 
          '2>pipe', $self->{child_stderr}) or die "Couldn't start child process; $!";
  } else {
    start([ $self->{_git_binary}, $self->{_game_file}],
         '<pipe', $self->{child_stdin}, 
          '>pipe', $self->{child_stdout}, 
          '2>pipe', $self->{child_stderr}) or die "Couldn't start child process; $!";
  }
  for (@{$self}{qw/child_stdin child_stdout child_stderr/}) {
    my $was = select($_);
    $|=1;
    select($was);
  }

}

sub send_to_game {
  my ($self, $line) = @_;

  if ($line !~ m/\n$/) {
    $line = "$line\n";
  }
  print STDERR "Sending: '$line'\n";
  $self->{child_stdin}->print($line);
}

sub wait_for_select {
  my ($self) = @_;

  $self->{collecting_input} = 1;
  while ($self->{collecting_input}) {
    #print STDERR "Doing readline from child's stdout\n";
    my $line = readline($self->{child_stdout});
    if (not defined $line) {
      die "Subprocess died?  $!";
    }

    #print STDERR "Doing readline from child's stdout, got '$line'\n";
    $self->handle_stdout($line);
  }

  delete $self->{collecting_input};

  return $self;
}

sub handle_stdout {
  my ($self, $from_game) = @_;

#  print STDERR Dumper$from_game;

  # Because IPC::Run doesn't simply split into nice chunks for me, we
  # need to do so ourselves.  Remove any partial chunks at the end of
  # the input, and put it back at the beginning of the next bit of
  # input
  $from_game = "$self->{leftovers}$from_game";
  if ($from_game =~ s/\cJ([^\x{0D}\x{0A}]*)$/\cJ/) {
    $self->{leftovers} = $1;
  } else {
    # If that didn't match, then there wasn't a newline at all in the block, so the entire thing is leftovers,
    # and I'll get you next time, Gadget!
    $self->{leftovers} = $from_game;
    return;
  }
  #print STDERR "Leftovers: $self->{leftovers}\n";

  # Very funny.  For some reason, I'm getting CRLF line-ends, dispite running this under linux, and having a printf("\n") generating it.
  # I also rather wonder why I am getting multiple lines at once.

  my $winid_r = qr/(0x[0-9A-Fa-f]+)/;

  for (split m/\cM?\cJ/, $from_game) {
    if ($ENV{GLKNEW_TRACE}) {
      print STDERR "Line: ##$_##\n";
    }

    when ('GLK new!') {
      # garbage.
    }

    when (/^DEBUG: /) {
      # NOP.
    }

    #       >>stylehint_set for wintype=3    (TextBuffer  ), styl=9    ( User1        \), hint=4    ( Weight        ) to val=1' at lib/Game.pm line 61.
    when (/^>>stylehint_set for wintype=\d+ \(([A-Za-z]+)\), styl=\d+ \(([A-Za-z0-9]+)\), hint=\d+ \(([A-Za-z0-9]+)\) to val=(-?\d+)$/) {
      my @styletypes = ($1);
      @styletypes = ('TextBuffer', 'TextGrid') if($1 eq 'AllTypes');

      $self->{styles}{$_}{$2}{$3} = $4 for(@styletypes);
    }

    when (/^>>stylehint_clear for wintype=\d+ \(([A-Za-z]+)\), styl=\d+ \(([A-Za-z0-9]+)\), hint=\d+ \(([A-Za-z]+)\)/) {
        foreach my $style (keys %{ $self->{styles} } ) {
            next if($style ne $1 && $1 ne 'AllTypes');

            delete $self->{styles}{$1}{$2}{$3};
        }
    }

    when (/^>>>Opening new window, splitting exsiting window (\(nil\)|0x[0-9a-fA-F]+)$/) {
      $self->{win_in_progress} = {};
      if ($1 ne '(nil)') {
        $self->{win_in_progress}{parent} = $self->{windows}{$1};
      }
    }

    when (/^>>>win: method=([a-z, ]+)$/) {
      $self->{win_in_progress}{method} = {map {+($_ => 1)} split(/, /, $1)};
    }

    when (/^>>>win: size (\d+)$/) {
      $self->{win_in_progress}{size} = $1;
    }

    when (/^>>>win: wintype=(\d+) (\w+)$/) {
      $self->{win_in_progress}{wintype} = $2;
      $self->{win_in_progress}{current_style} = $self->{styles}{$2}{Normal};
    }

    when (/^>>>win: is root$/) {
      delete $self->{win_in_progress}{method};
      delete $self->{win_in_progress}{size};
      $self->{win_in_progress}{is_root}++;
    }
    
    when (/^>>>win: at $winid_r$/) {
      $self->{win_in_progress}{id} = $1;
      
#      print STDERR Dumper$self->{win_in_progress};

      my $win;
      $win = $self->{windows}{$1} = "Game::Window::$self->{win_in_progress}{wintype}"->new(delete $self->{win_in_progress});
      push @{$win->{parent}{children}}, $self->{windows}{$1};
      $self->{root_win} = $win if($win->{is_root});
    }

    when (/>>>window_set_arrangement win=$winid_r, method=([a-z, ]+), size=(\d+), keywin=$winid_r/) {
      if(!exists $self->{windows}{$1}) {
        die "Attempt to arrange non-existant winid $1";
      }
      my $win = $self->{windows}{$1};
      
      $win->method({map {($_=>1)} split(/, /, $2)});
      $win->size($3);
      $win->drawn(0);

      print STDERR "window_set_arrangement, ignoring keywin argument\n";
    }

    when (/^\?\?\?window_get_size win=$winid_r/) {
      my $winid = $1;
      $self->{_callbacks}{window_size}->($self, $winid);
    }

    when (/^>>>put_char_uni for window $winid_r, character U\+([0-9A-Fa-f]+)(, '.')?$/) {
      $self->{windows}{$1}->put_char(chr hex $2);
    }

    when (/^>>>window_move_cursor win=$winid_r, xpos=(\d+), ypos=(\d+)$/) {
      $self->{windows}{$1}->move_cursor($2, $3);
      # push @{$self->{windows}{$1}{content}}, {cursor_to => [$2, $3]};
    }

    when (/^>>>glk_set_style_stream Window=$winid_r to style=(\d+) \(([A-Za-z0-9]+)\)$/) {
      $self->{windows}{$1}{current_style} = $self->{styles}{$self->{windows}{$1}{wintype}}{$3};
    }

    when (/\?\?\? glk_style_distinguish win=$winid_r, styl1=\d+ \(([A-Za-z0-9]+)\), styl2=\d+ \(([A-Za-z0-9]+)\)/) {
      my ($winid, $style1, $style2) = ($1, $2, $3);
      $self->{_callbacks}{style_distinguish}->($self, $winid, $style1, $style2);
    }

    when (/^>>>window_clear win=$winid_r$/) {
      $self->{windows}{$1}->clear;
      # push @{ $self->{windows}{$1}{content} }, { clear => 1 };
    }

    when (/^\?\?\?select, window=$winid_r, want (char|line)_(latin1|uni)$/) {
      local $self->{harness} = 'SKIPPING HARNESS';
#      print STDERR Dumper$self;

      $self->{_callbacks}{select}->($self, $1, $2, $3);

    }

    #       ? ? ?glk_fileref_create_by_prompt usage=1    (SavedGame ), filemode=2    (Read  )
    when (/\?\?\?glk_fileref_create_by_prompt usage=\d+ \(([\w, ]+)\), filemode=\d+ \((\w+)\)/) {
      my ($usages, $mode) = ($1, $2);
      $usages = { map {+($_ => 1)} split /, /, $usages };
      $self->{_callbacks}{prompt_file}->($self, $usages, $mode);
    }

    when (/>>>glk_window_fill_rect win=$winid_r, color=0x([0-9A-Fa-f]+), left=(\d+), top=(\d+), width=(\d+), height=(\d+)/) {
      $self->{windows}{$1}->fill_rect($2, $3, $4, $5, $6);
    }

    when (/>>>image_draw_scaled win=$winid_r, filename=([\/\w-]+), x=(-?\d+), y=(-?\d+), width=(-?\d+), height=(-?\d+)/) {
      my ($winid, $filename, $x, $y, $width, $height) = ($1, $2, $3, $4, $5, $6);

      $self->{windows}{$winid}->draw_image($filename, $x, $y, $width, $height);
    }

    when (/>>>image_draw win=$winid_r, filename=([\/\w-]+), x=(-?\d+), y=(-?\d+)/) {
      my ($winid, $filename, $x, $y) = ($1, $2, $3, $4);

      $self->{windows}{$winid}->draw_image($filename, $x, $y);
    }

    default {
      warn "Don't know how to handle input '$_'";
      last;
    }
  }
}

sub handle_stderr {
  my ($self, $text) = @_;
  
  die "Got STDERR from child process: '$text'";
}

# This entire thing is an increasingly ugly hack.
sub default_window_size_callback {
    my ($self, $winid) = @_;
    my $win = $self->{windows}{$winid};
    # print STDERR Dumper$win;

    my @size = (80, 25);
    if ($win->{method}{fixed}) {
      if ($win->{method}{above} || $win->{method}{below}) {
        $size[1] = $win->{size};
      } else {
        $size[0] = $win->{size};
      }
    } elsif ($win->{method}{proportional}) {
      if ($win->{method}{above} || $win->{method}{below}) {
        $size[1] = int($size[1] * $win->{size}/100);
      } else {
        $size[0] = int($size[0] * $win->{size}/100);
      }
    } else {
      die "methods unhandled in default_window_size_callback", Dump($win->{method});
    }

    if ($win->isa('Game::Window::Graphics')) {
      # These constants are so that an 80x25 text window is the same size as a 640x480 graphics window.
      $size[0] *= 8
        unless $win->{method}{fixed} and ($win->{method}{left} || $win->{method}{right});
      $size[1] *= 19.2
        unless $win->{method}{fixed} and ($win->{method}{above} || $win->{method}{below});
    }
    
    $self->send_to_game(join(' ', @size));
}

sub default_select_callback {
  my ($self, $winid, $input_type, $input_charset) = @_;

  for my $win_p (keys %{$self->{windows}}) {
    my $win = $self->{windows}{$win_p};
#    print STDERR Dumper$win;
    print STDERR "----\n";
    print STDERR "$win_p\n";
    
    my $prev_style = {};
    for my $e (@{$win->{content}}) {
      my ($style, $char) = @{$e}{'style', 'char'};
      if(defined $style) {
          if ($prev_style != $style) {
              print STDERR ("<div class='$style->{name}'>");
          }
          print STDERR $char;
          $prev_style = $style;
      } elsif(exists $e->{cursor_to}) {
          print STDERR "Move cursor to: ", join(':', @{ $e->{cursor_to} }), "\n";
      }
    }
    ## newline so status window line is seen..
    print STDERR "\n";
  }

  $self->{current_select} = {
      window       => $self->{windows}{$winid},
      input_type   => $input_type,
      input_charset => $input_charset,
  };

  $self->{collecting_input} = 0;

}


sub root_window {
    my ($self) = @_;

    return $self->{root_win};
}


1;

