package Game::Window;

use Moose;

has id => (is => 'ro', isa => 'Str', required => 1);
has method => (is => 'rw', isa => 'HashRef', required => 0, default => sub { {} } );
has drawn => (is => 'rw', isa => 'Bool', required => 0, default => sub { 0 } );
has window_size => (is => 'rw', isa => 'ArrayRef', required => 0);
has pages => (is => 'rw', isa => 'ArrayRef', required => 0, default => sub { [] } );
has content => (is => 'rw', isa => 'ArrayRef', required => 0, default => sub { [] } );

sub BUILD { 
    my ($self, $attrs) = @_; 
    my @not_got = grep !exists $self->{$_}, keys %$attrs; 

    @{$self}{@not_got} = @{$attrs}{@not_got}; 
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
