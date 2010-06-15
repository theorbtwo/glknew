package Game::Window::TextBuffer;

use Moose;
use Game::HTML; # Needs get_style
extends 'Game::Window';

sub put_char {
  my ($self, $char) = @_;

  push @{$self->{content}}, { style => $self->{current_style}, char => $char};
}

sub clear {
  my ($self) = @_;

  push @{ $self->{content} }, { clear => 1 };
}

sub get_own_formatted_text {
    my ($win, $full_content) = @_;
    
    my $text = '';
    my $prev_style = {};
    my $status = 'append';
    
    my %styles_needed;
    
    my @content;
    if ($full_content) {
      @content = map {@$_} @{$win->pages}, $win->content;
    } else {
      @content = @{$win->content};
    }

    for my $e (@content) {
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
        } elsif(exists $e->{clear}) {
          $text = '';
          $prev_style = {};
          $status = 'clear';
        } else {
          warn "Wierd shit in TextBuffer: ".Dumper($e);
        }
    }
    
    # FIXME: We should only output styles if they have changed.  In
    # fact, maybe we should just output a full set of styles at the
    # creation time of every window, and let them be.
    my $styles = '';
    for my $name (sort keys %styles_needed) {
        # Copy so we can freely modify it here.
        my $style = { %{$styles_needed{$name}} };
        
        $styles .= Game::HTML::get_style($style);
    }
    $text = "<style type='text/css'>$styles</style>\n$text";
    $text = "<span class='move-top'></span>$text";
    
    #      print STDERR "Text with styles: $text\n";

    ## Have sent this text, don't send it again.
    $win->new_turn();

    if (wantarray) {
      return ($text, $status);
    } else {
      return $text;
    }
}

'a true value, really, honest';

