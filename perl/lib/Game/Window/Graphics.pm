package Game::Window::Graphics;
use Moose;

extends 'Game::Window';

has modified_since_new_turn => (is => 'rw', isa => 'Bool', required => 0, default => sub { 1 } );

sub new_turn {
  $_[0]->modified_since_new_turn(0);
}

no Moose;
1;
