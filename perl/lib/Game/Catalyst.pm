package Game::Catalyst;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    Session
    Session::Store::File
    Session::State::Cookie
/;

extends 'Catalyst';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

# Configure the application.
#
# Note that settings in game_catalyst.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

my $if_root;
if (-e '/usr/src/extern/glknew/perl') {
  $if_root = '/usr/src/extern/';
} elsif (-e '/mnt/shared/projects/games/flash-if/glknew/perl/') {
  $if_root = '/mnt/shared/projects/games/flash-if/';
} elsif (-e '/home/jamesm/glknew/perl') {
  $if_root = '/home/jamesm/';
} else {
  die "Cannot find if_root";
}
__PACKAGE__->config(
                    name => 'glknew',
                    # Disable deprecated behavior needed by old applications
                    disable_component_resolution_regex_fallback => 1,

                    # See Catalyst::Plugin::Static::Simple
                    static => {
                               include_path => [
                                                __PACKAGE__->config->{root},
                                               ]
                              },
                    save_file_dir => "$if_root/glknew/perl/saves",
                    if_root => $if_root,
                    js_keycodes => {
                                    37 => 'Left',
                                    39 => 'Right',
                                    38 => 'Up',
                                    40 => 'Down',
                                    13 => 'Return',
                                    46 => 'Delete',
                                    27 => 'Escape',
                                    9 => 'Tab',
                                    33 => 'PageUp',
                                    34 => 'PageDown',
                                    36 => 'Home',
                                    35 => 'End',
                                    112 => 'Func1',
                                    113 => 'Func2',
                                    114 => 'Func3',
                                    115 => 'Func4',
                                    116 => 'Func5',
                                    117 => 'Func6',
                                    118 => 'Func7',
                                    119 => 'Func8',
                                    120 => 'Func10',
                                    121 => 'Func11',
                                    122 => 'Func12',
                                   },
#                    root_url => 'http://lilith:5000/',
                   );


# Start the application
__PACKAGE__->setup();

sub game_data {
    my ($c, $shortname) = @_;

    return $c->config->{games}{$shortname};
}



=head1 NAME

Game::Catalyst - Catalyst based application

=head1 SYNOPSIS

    script/game_catalyst_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Game::Catalyst::Controller::Root>, L<Catalyst>

=head1 AUTHOR

James Mastros <james@mastros.biz> -- theorbtwo
Jess Robinson <castaway@desert-island.me.uk> -- castaway

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
