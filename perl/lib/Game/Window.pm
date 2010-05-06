package Game::Window;

use Moose;

has pages => (is => 'rw', isa => 'ArrayRef', required => 0, default => sub { [] } );
has method => (is => 'rw', isa => 'ArrayRef', required => 0, default => sub { [] } );

sub BUILD { 
    my ($self, $attrs) = @_; 
    my @not_got = grep !exists $self->{$_}, keys %$attrs; 

    @{$self}{@not_got} = @{$attrs}{@not_got}; 
}


sub last_page {
    my ($self) = @_;

    return $self->pages->[-1];
}

no Moose;
1;