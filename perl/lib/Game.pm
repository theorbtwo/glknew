package Game;
use warnings;
use strict;
use IPC::Run 'harness';
use 5.10.0;
use Data::Dump::Streamer;
$|=1;

sub new {
  my ($class, $blorb_file) = @_;
  
  die "blorb file is required" unless $blorb_file;
  die "$blorb_file does not exist" unless -e $blorb_file;

  my $self = bless {}, $class;
  $self->{input_str} = \'';
  # Parser leftovers at end of block.
  $self->{leftovers} = '';

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

  $self->{harness} = harness(['/mnt/shared/projects/games/flash-if/git-1.2.6/git', $blorb_file],
                             '<pty<', $self->{input_str},
                             '>pty>', sub {
                               $self->handle_stdout(@_);
                             },
                             '>pty>', sub {
                               $self->handle_stderr(@_);
                             }
                            );

  return $self;
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
  my ($self, $line) = @_;

  Dump $line;

  # Because IPC::Run doesn't simply split into nice chunks for me, we
  # need to do so ourselves.  Remove any partial chunks at the end of
  # the input, and put it back at the beginning of the next bit of
  # input
  $line = "$self->{leftovers}$line";
  if ($line =~ s/\cJ([^\x{0D}\x{0A}]*)$/\cJ/) {
    $self->{leftovers} = $1;
  } else {
    # If that didn't match, then there wasn't a newline at all in the block, so the entire thing is leftovers,
    # and I'll get you next time, Gadget!
    $self->{leftovers} = $line;
    return;
  }

  # Very funny.  For some reason, I'm getting CRLF line-ends, dispite running this under linux, and having a printf("\n") generating it.
  # I also rather wonder why I am getting multiple lines at once.
  for (split m/\cM?\cJ/, $line) {
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

    when (/^>>>put_char_uni for window (0x[0-9a-fA-F]+), character U\+([0-9A-Fa-f]+)(, '.')?$/) {
      push @{$self->{windows}{$1}{text}}, [$self->{windows}{$1}{current_style}, chr hex $2];
    }

    when (/^>>>glk_set_style_stream Window=(0x[0-9a-fA-F]+) to style=(\d+) \(([A-Za-z0-9]+)\)$/) {
      $self->{windows}{$1}{current_style} = $self->{styles}{$self->{windows}{$1}{wintype}}{$3};
    }

    when (/^Time for select, suiciding\.$/) {
      local $self->{harness} = 'SKIPPING HARNESS';
      Dump $self;
      exit;
    }

    default {
      die "Don't know how to handle input '$_'";
    }
  }
}

1;

