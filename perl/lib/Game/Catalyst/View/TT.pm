package Game::Catalyst::View::TT;

use strict;
use base 'Catalyst::View::TT';

# FIXME: Use some sort of strict stash dohicky.
__PACKAGE__->config(TEMPLATE_EXTENSION => '.tt',
                    STRICT => 1);

=head1 NAME

Game::Catalyst::View::TT - TT View for Game::Catalyst

=head1 DESCRIPTION

TT View for Game::Catalyst. 

=head1 AUTHOR

=head1 SEE ALSO

L<Game::Catalyst>

James Mastros,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
