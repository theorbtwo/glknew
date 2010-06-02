package Game::Window::Graphics;
use Moose;
use Scalar::Util 'weaken';
use Data::Dump::Streamer 'Dump', 'Dumper';

extends 'Game::Window';

use Imager;

# FIXME: We repeat our parent in the definition of window_size, because we cannot add a trigger when '+'ing.
has window_size => (is => 'rw', isa => 'ArrayRef', required => 0, trigger => \&window_size_trigger);
has imager => (is => 'rw', isa => 'Imager', required => 0, lazy_build => 1);
has modified_since_new_turn => (is => 'rw', isa => 'Bool', required => 0, default => sub { 1 } );

my %images;

sub BUILD {
    my ($self) = @_;

    warn "Called Graphics' BUILD self=$self\n";

    $images{$self} = $self;
}

sub DESTROY {
    my ($self) = @_;

    delete $images{$self};
}

sub _build_imager {
  my ($self) = @_;

  my ($xsize, $ysize) = @{$self->window_size};

  return Imager->new(xsize => $xsize, ysize => $ysize, channels => 4);
}

sub fetch {
    my ($stringified) = @_;

    return $images{$stringified};
}

sub window_size_trigger {
  my ($self, $size, $old_size) = @_;

  if (defined $old_size and
      $old_size->[0] == $size->[0] and
      $old_size->[1] == $size->[1]) {
      return;
  }

  # Resize the imager to match the window size.
  warn "Scaling image: from @{ $old_size || [] }, to, @$size\n";
  $self->imager($self->imager->scale(xpixels=>$size->[0],
                                     ypixels=>$size->[1],
                                     type => 'nonprop'));
}

sub new_turn {
  $_[0]->modified_since_new_turn(0);
}

sub draw_image {
  my ($self, $filename, $x, $y, $width, $height) = @_;

  my $new_image = Imager->new(file => $filename, channels => 4) or die "Can't read $filename";
  if (defined $width or defined $height) {
      $new_image = $new_image->scale(xpixels => $width, ypixels => $height);
  }
  $self->imager->paste(left => $x, top => $y, img => $new_image)
    or die "Error in paste: ".$self->imager->errstr;

  $self->modified_since_new_turn(1);
}

sub fill_rect {
  my ($self, $color, $left, $top, $width, $height) = @_;

  $self->imager->box(xmin => $left, ymin => $top, 
                     xmax=>($left+$width), ymax => ($top+$height), color => "#$color", filled=>1)
    or die "Error in ->box (color = #$color): ".$self->imager->errstr;

  $self->modified_since_new_turn(1);
}

sub get_own_formatted_text {
    my ($self) = @_;
    
    my @alpha = ('a'..'z', 'A'..'Z');
    my $rand = join '', map {$alpha[rand @alpha]} 0..9;
    my $html;

    if ($self->window_size) {
      my ($width, $height) = @{$self->window_size};
      
      $html = "<img src='/game/image/$self?rand=$rand' height='$height' width='$width' />";
    } else {
      $html = "<img src='/game/image/$self?rand=$rand' />";
    }
    
    if (wantarray) {
        return $html, 'clear';
    } else {
        return $html;
    }
}

sub as_png {
    my ($self) = @_;

    my $data;

    Dump $self->imager;

    $self->imager->write(type => 'png', data => \$data)
      or die "cannot pngify: ".$self->imager->errstr;

    return $data;
}

no Moose;
1;
