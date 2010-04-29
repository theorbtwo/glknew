package Game;
use warnings;
use strict;
use IPC::Run 'harness';
use 5.10.0;
use Data::Dump::Streamer;

sub new {
  my ($class, $blorb_file, $git, $callback) = @_;
  
  die "blorb file is required" unless $blorb_file;
  die "$blorb_file does not exist" unless -e $blorb_file;

  my $self = bless {}, $class;
  $self->{_game_file} = $blorb_file;
  $self->{_git_binary} = $git if($git);
  $self->{_callback} = $callback || \&default_callback;

  my $input_str = '';
  $self->{input_str} = \$input_str;
  # Parser leftovers at end of block.
  $self->{leftovers} = '';

  $self->setup_initial_styles();
  $self->setup_ipc_harness();

  return $self;
}

sub setup_initial_styles {
  my ($self) = @_;

  # Only TextBuffer and TextGrid can have text in them, but the spec says they all have styles, so what the hell.
  for my $wt (qw<Pair Blank TextBuffer TextGrid Graphics>) {
    for my $s (qw<Normal Emphasized Preformatted Header Subheader Alert Note BlockQUote Input User1 User2>) {
      $self->{styles}{$wt}{$s} = {
                                  name => $s
                                 };
    }
    # An interesting question: should I create defaults in these?  The spec says only Preformatted has defaulting,
    # but it probably only means that only it is required to.  Seems a bit silly to give them names otherwise, no?
    $self->{styles}{$wt}{Preformatted}{Proportional} = 1;
  }

}

sub setup_ipc_harness {
  my ($self) = @_;

  $self->{_git_binary} ||= '/mnt/shared/projects/games/flash-if/git-1.2.6/git';
  $self->{harness} = harness([$self->{_git_binary},
                              $self->{_game_file}],
                             '<pty<', $self->{input_str},
                             '>pty>', sub {
                               $self->handle_stdout(@_);
                             },
                             '>pty>', sub {
                               $self->handle_stderr(@_);
                             }
                            );


}

sub send_to_game {
  my ($self, $value, $type) = @_;
  $type = $type ? "$type " : '';

  print "Sending: ${type}${value}\n";
  ${$self->{input_str}} = "${type}${value}";
  $self->{harness}->pump;
}

sub wait_for_select {
  my ($self) = @_;

  while (!$self->{in_select}) {
    $self->{harness}->pump;
  }

  delete $self->{in_select};

  return $self;
}

sub handle_stdout {
  my ($self, $from_game) = @_;

  Dump $from_game;

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
  print "Leftovers: $self->{leftovers}\n";

  # Very funny.  For some reason, I'm getting CRLF line-ends, dispite running this under linux, and having a printf("\n") generating it.
  # I also rather wonder why I am getting multiple lines at once.
  for (split m/\cM?\cJ/, $from_game) {
    print "Line: ##$_##\n";
    when ('GLK new!') {
      # garbage.
    }

    when (/^DEBUG: /) {
      # NOP.
    }

    #       >>stylehint_set for wintype=3    (TextBuffer  ), styl=9    ( User1        \), hint=4    ( Weight        ) to val=1' at lib/Game.pm line 61.
    when (/^>>stylehint_set for wintype=\d+ \(([A-Za-z]+)\), styl=\d+ \(([A-Za-z0-9]+)\), hint=\d+ \(([A-Za-z0-9]+)\) to val=(\d+)$/) {
      $self->{styles}{$1}{$2}{$3} = $4;
    }

    when (/^>>>Opening new window, splitting exsiting window (\(nil\)|0x[0-9a-fA-F]+)$/) {
      $self->{win_in_progress} = {};
      $self->{win_in_progress}{parent} = $1
        unless $1 eq '(nil)';
    }

    when (/^>>>win: method=([a-z, ]+)$/) {
      $self->{win_in_progress}{method} = [split /, /, $1];
    }

    when (/^>>>win: size (\d+)$/) {
      $self->{win_in_progress}{size} = $1;
    }

    when (/^>>>win: wintype=(\d+) ([A-Za-z]+)$/) {
      $self->{win_in_progress}{wintype} = $2;
      $self->{win_in_progress}{current_style} = $self->{styles}{$2}{Normal};
    }

    when (/^>>>win: is root$/) {
      delete $self->{win_in_progress}{method};
      delete $self->{win_in_progress}{size};
      $self->{win_in_progress}{is_root}++;
      $self->{root_win} = $self->{win_in_progress};
    }
    
    when (/^>>>win: at (0x[0-9A-Fa-f]+)$/) {
      $self->{windows}{$1} = delete $self->{win_in_progress};
    }

    when (/^\?\?\?window_get_size win=(0x[0-9a-fA-F]+)/) {
      my $winid = $1;
      Dump $self->{windows}{$winid};

      my @size = (80, 25);
      if(grep /fixed/, @{ $self->{windows}{$winid}{method} }) {
        $size[1] = 1;
      }

      $self->send_to_game(join(' ', @size));
    }

    when (/^>>>put_char_uni for window (0x[0-9a-fA-F]+), character U\+([0-9A-Fa-f]+)(, '.')?$/) {
      push @{$self->{windows}{$1}{text}}, [$self->{windows}{$1}{current_style}, chr hex $2];
    }

    when (/^>>>glk_set_style_stream Window=(0x[0-9a-fA-F]+) to style=(\d+) \(([A-Za-z0-9]+)\)$/) {
      $self->{windows}{$1}{current_style} = $self->{styles}{$self->{windows}{$1}{wintype}}{$3};
    }

    when (/^>>> select, want (\w+)$/) {
      local $self->{harness} = 'SKIPPING HARNESS';
      Dump $self;

      $self->{_callback}->($self);

      exit;
    }

    default {
      warn "Don't know how to handle input '$_'";
    }
  }
}

sub default_callback {
  my ($self) = @_;

  for my $win_p (keys %{$self->{windows}}) {
    my $win = $self->{windows}{$win_p};
    print "----\n";
    print "$win_p\n";
    
    my $prev_style;
    for my $e (@{$win->{text}}) {
      my ($style, $char) = @{$e};
      if ($prev_style != $style) {
        print ("<div class='$style->{name}'>");
      }
      print $char;
      $prev_style = $style;
    }
  }
}

1;

