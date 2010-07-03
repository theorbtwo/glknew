package Game::Window::TextGrid;

use Moose;
extends 'Game::Window';

has 'cursor_x', (is => 'rw', isa => 'Int', default => 0);
has 'cursor_y', (is => 'rw', isa => 'Int', default => 0);
# $self->grid[$y][$x] = {char 'x', style => {...} };
has 'grid',     (is => 'rw', isa => 'ArrayRef', default => sub {[]} );

sub size_units {
  'chars';
}

sub move_cursor {
  my ($self, $x, $y) = @_;

  $self->cursor_x($x);
  $self->cursor_y($y);
}

sub clear {
  my ($self) = @_;

  # Poof, all gone.
  $self->grid([]);

  # Fill in something on the last line, so we generate the right
  # number of <br /> tags, so we get the right height the first time
  # around.
  if ($self->method->{fixed} and ($self->method->{above} or $self->method->{below})) {
    $self->grid->[$self->size]->[0] = {char => " ", style => $self->current_style};
  }
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
    my $prev_style = -1;
    for my $line (@$state) {
        for my $new_e (@$line) {
            if (!$new_e) {
                $text .= '&nbsp;';
                next;
            }
            
            my $trans_char = {'<' => '&lt;',
                              '&' => '&amp;',
                              ' ' => '&nbsp;'
                             }->{$new_e->{char}} || $new_e->{char};

            my $style = $new_e->{style};
            if ($prev_style != $style) {
              my $style_name = "$self->{wintype}-$style->{name}";
              $styles_needed{$style_name}++;
              $text .= "<span class='$style_name'>$trans_char";
              $prev_style = $style;
            } else {
              $text .= "$trans_char";
            }
        }
        $text .= "<br />\n";
    }
    $text .= "</span></tt>\n";
    $text = "<span class='move-top'></span>$text";
    
    if (wantarray) {
      return $text, 'clear';
    } else {
      return $text;
    }
}



1;
