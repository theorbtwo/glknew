package Game::Window::TextGrid;

use Moose;
extends 'Game::Window';

has 'cursor_x', (is => 'rw', isa => 'Int', default => 0);
has 'cursor_y', (is => 'rw', isa => 'Int', default => 0);
# $self->grid[$y][$x] = {char 'x', style => {...} };
has 'grid',     (is => 'rw', isa => 'ArrayRef', default => sub {[]} );

sub move_cursor {
  my ($self, $x, $y) = @_;

  $self->cursor_x($x);
  $self->cursor_y($y);
}

sub clear {
  my ($self) = @_;

  # Poof, all gone.
  $self->grid([]);
}

sub put_char {
  my ($self, $char) = @_;

  # Newline needs to be handled specially here; it *is* still a cursor
  # control masquerading as a character.
  if ($char eq "\n") {
    $self->cursor_x(0);
    # Sad that objectification makes this so ugly...
    $self->cursor_y($self->cursor_y + 1);
    return;
  }

  # Optimization opportunity -- convert this to an arrayref instead of a hashref?
  $self->grid->[$self->cursor_y][$self->cursor_x] = {style => $self->current_style, char => $char};
  $self->cursor_x($self->cursor_x + 1);
}

sub get_own_formatted_text {
    my ($self) = @_;

    my $state = $self->grid;
    
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
    
    if (wantarray) {
      return $text, 'clear';
    } else {
      return $text;
    }
}



1;
