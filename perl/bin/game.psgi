#!/usr/local/bin/perl5.10.0
# -*- cperl -*-
use strict;
use warnings;

use Web::Simple 'GameIF';

{
    package GameIF;
    use Game::HTML;
    use JSON;
    use File::Spec::Functions;
    use Data::Dump::Streamer 'Dumper';

    my @games = ();

    my $root;
    if (-e '/usr/src/extern/glknew/perl') {
      $root = '/usr/src/extern/glknew/perl/';
    } elsif (-e '/mnt/shared/projects/games/flash-if/glknew/perl/') {
      $root = '/mnt/shared/projects/games/flash-if/glknew/perl/';
    } else {
      die "Cannot find root";
    }

    default_config ( static_dir => "$root/root",
                     save_file_dir => "$root/saves",
                     git_binary => "$root/../../git-1.2.6/git",
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
                                    }
   );

    sub static_file {
        my ($self, $file, $type) = @_;
        my $fullfile = catfile($self->config->{static_dir}, "$file");
#print STDERR "static File: $fullfile\n";
        open my $fh, '<', $fullfile or return [ 404, [ 'Content-type', 'text/html' ], [ "file not found $fullfile"]];

        local $/ = undef;
        my $file_content = <$fh>;
        close $fh or return [ 500, [ 'Content-type', 'text/html' ], [ 'Internal Server Error'] ];

        return [ 200, [ 'Content-type' => $type ], [ $file_content ] ];
 
    }

    dispatch {
        sub (/) {
            return $self->static_file("index.html");
        },

        sub (/js/**) {
            my $file=$_[1];
            return $self->static_file("js/$file", "text/javascript");
        },
 
       sub (/css/**) {
            my $file=$_[1];
            return $self->static_file("css/$file", "text/css");
        },

        sub (/game/continue + ?text~&input_type=&game_id=&window_id=&keycode~) {
          my ($self, $text, $input_type, $game_id, $window_id, $keycode) = @_;
#          my $char = $keycode if($input_type eq 'char');

          $SIG{__DIE__} = sub {
            # Breaks my heart to do this, it really does...
            print "DIED! $@\n";
          };

#          warn Dumper(@_[1..$#_]);

          my $run_select = 1;
          my $game = $games[$game_id];
          if (length $text and not length $keycode) {
            $game->send("evtype_LineInput $text\n");
          } elsif(exists($self->config->{js_keycodes}{$keycode}) and not length $text) {
              $game->send("evtype_CharInput keycode_" . $self->config->{js_keycodes}{$keycode} . "\n");
          } elsif (length $keycode and not length $text) {
            if($keycode >=65 and $keycode <= 90) {
                $game->send("evtype_CharInput $keycode\n");
            } else {
                warn "Sent keycode out of range: $keycode\n";
            }
          } elsif (not length $text and not length $keycode) {
            # Do nothing.
            $run_select = 0;
          } else {
            # Both text and keycode are defined?
            die "Double-down on continue -- keycode='$keycode', text='$text'";
          }

          $game->continue
            if $run_select;

          my $json = JSON::encode_json({ 
                                        windows => $game->get_continue_windows(),
                                        input_type => $game->get_input_type(),
                                        show_forms => $game->get_form_states(),
                                       });
print "Sending JSON: $json\n";
          [ 200, 
            [ 'Content-type' => 'application/json' ], 
            [ $json ]
          ];

        },

        sub (/game/new/*) {
            my ($self, $game_name) = @_;

            my $git = $self->config->{git_binary};
            my $nitfol = "/mnt/shared/projects/games/flash-if/nitfol-0.5/newnitfol";
            my $agility = "/mnt/shared/projects/games/flash-if/garglk-read-only/terps/agility/glkagil";
            my %games = (
                         advent        => [$git, "$root/t/var/Advent.ulx", 'Adventure!'],
                         'blue-lacuna' => [$git, '/mnt/shared/projects/games/flash-if/blue-lacuna/BlueLacuna-r3.gblorb', 'Blue Lacuna'],
                         alabaster     => [$git, '/mnt/shared/projects/games/flash-if/Alabaster/Alabaster.gblorb', 'Alabaster'],
                         acg           => [$git, '/mnt/shared/projects/games/flash-if/ACG/ACG.ulx', 'Adventurer\'s Consumer Guide'],
                         king          => [$git, '/mnt/shared/projects/games/flash-if/The King of Shreds and Patches.gblorb', 'The King of Shreds and Patches'],
                         curses        => [$nitfol, '/mnt/shared/projects/games/flash-if/curses.z5', 'Curses'],
                         emy           => [$agility, '/mnt/shared/projects/games/flash-if/Emy Discovers Life/DISCOVER', 'Emy Discovers Life'],
                        );
            my $game_info = $games{$game_name};

            if (!$game_info) {
              die "Do not know game path for game $game_name -- supported: ".join(", ", keys %games);
            }
            my ($interp_path, $game_path, $title) = @$game_info;

#            my $game = $self->new_game($game_path, $interp_path);
            my $game_id = scalar @games;
            my $game = Game::HTML->new($game_id, $game_path, $interp_path, $self->config->{save_file_dir});
            $games[$game_id] = $game;
            $game->continue();
#            my $form = $game->get_form();

            [ 200, 
              [ 'Content-type' => 'text/html' ], 
              [ $game->make_page(undef, $title)]
            ];
          }
      };
}

GameIF->run_if_script;
