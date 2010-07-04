package Game::Window;

use Moose;

has id => (is => 'ro', isa => 'Str', required => 1);
has method => (is => 'rw', isa => 'HashRef', required => 0, default => sub { {} } );
has drawn => (is => 'rw', isa => 'Bool', required => 0, default => sub { 0 } );
has window_size => (is => 'rw', isa => 'ArrayRef', required => 0);
has window_size_is_fake => (is => 'rw', isa => 'Bool', default => 1);
has pages => (is => 'rw', isa => 'ArrayRef', required => 0, default => sub { [] } );
has content => (is => 'rw', isa => 'ArrayRef', required => 0, default => sub { [] } );
# TextBuffer, TextGrid, Graphics
has wintype => (is => 'ro', isa => 'Str');
has current_style => (is => 'rw');
has is_root => (is => 'ro', isa => 'Bool', default => sub { 0 } );
has parent => (is => 'ro', isa => 'Maybe[Object]', required => 0, default => sub { undef });
# The size that the game asked us to be, what axis depends on the
# method, pixels, chars, or percent depends on method and wintype.
has size => (is => 'rw', isa => 'Int');

sub BUILD {
  my ($self, $attrs) = @_; 
  my @not_got = grep !exists $self->{$_}, keys %$attrs; 
  
  warn "Unsupported attributes @not_got specified to the creator of $self"
    if @not_got;
  
  @{$self}{@not_got} = @{$attrs}{@not_got};
  
  my $meth = $self->method;
  if (!$self->window_size) {
    my $width = 42;
    my $height = 42;
    
    if ($self->is_root) {
      $width = 640;
      $height = 480;
    } elsif ($self->size and $meth->{fixed}) {
      if ($meth->{above} or $meth->{below}) {
        if ($self->size_units eq 'chars') {
          $height = $self->size * 19.2;
        } else {
          $height = $self->size;
        }
      } else {
        if ($self->size_units eq 'chars') {
          $width = $self->size * 8;
        } else {
          $width = $self->size;
        }
      }
    }

    $self->window_size([$width, $height]);
  }
}

sub size_units {
  'chars';
}

sub new_turn {
    my ($self) = @_;

    ## Backup previous window content
    push @{ $self->pages }, $self->content;
    $self->content([]);
}

sub last_page {
    my ($self) = @_;

    return $self->pages->[-1];
}

no Moose;
1;
