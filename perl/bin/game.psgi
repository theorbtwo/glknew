#!/usr/local/bin/perl5.10.0
# -*- cperl -*-
use strict;
use warnings;

use Web::Simple 'GameIF';

BEGIN {
  $|=1;
}

{
    package GameIF;
    use Game::HTML;
    use JSON;
    use File::Spec::Functions;
    use Data::Dump::Streamer 'Dumper';
    use LWPx::ParanoidAgent;
    use Cache::FileCache;
    use Net::OpenID::Consumer;

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
                                    },
                     root_url => 'http://lilith:5000/',
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

    sub openid_consumer {
      my ($self, $query_parms) = @_;
      
      # FIXME: We should mine this out of $self, so it matches the URL that the user needs: lilith, lilith.local, external?
      return Net::OpenID::Consumer->new(
                                        ua => LWPx::ParanoidAgent->new,
                                        cache => Cache::FileCache->new({namespace => __PACKAGE__}),
                                        # args => hr of get parameters,
                                        # FIXME: At least don't have this in a public git repo, you noncewit.
                                        consumer_secret => 'oasiejgoag',
                                        # FIXME: The URL for the root of this plackup thingy.  Should be far more dynamic then this.
                                        required_root => $self->config->{root_url},
                                        # All the query paramaters to the current URL (that aren't handled "by hand").
                                        args => $query_parms,
                                       );
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

       sub (/img/**) {
            my $file=$_[1];
            my $ct;
            if ($file =~ m/\.gif$/) {
              $ct = 'image/gif';
            }
            die "Don't know how to get content-type for $file"
              unless $ct;
            return $self->static_file("img/$file", $ct);
        },

        sub (/game/image/*) {
            my ($self, $img_string) = @_;
            
            my $graphics = Game::Window::Graphics::fetch($img_string);

            [ 200, 
              [ 'Content-type' => 'image/png',
                'Cache-control' => 'no-cache',
                'Expires' => '-1'

              ], 
              [ $graphics->as_png]
            ];
        },

        sub (/ajax/window_size + ?game_id=&win_id=&width=&height=) {
            my ($self, $game_id, $win_id, $width, $height) = @_;

            warn Dumper(@_[1 .. $#_]);
            my $game = $games[$game_id];
            $win_id =~ s/^winid//;
            $game->set_window_size($win_id, $width, $height);

            return $self->continue_game($game, 0);
        },

        sub (/game/savefile + ?save_file=&game_id=) {
            my ($self, $save_file, $game_id) = @_;
            $save_file =~ s{[\0\/]}{_}g;

            my $game = $games[$game_id];
            $game->send_prompt_file($save_file);

            return $self->continue_game($game, 1);
        },

        sub (/game/login + ?username2=&game_id=) {
          my ($self, $claimed_oid_url, $game_id) = @_;

          my $game = $games[$game_id];

          my $csr = $self->openid_consumer;
          my $claimed_identity = $csr->claimed_identity($claimed_oid_url);
          my $check_url = $claimed_identity->check_url(
                                                       return_to  => $self->config->{root_url}."game/logged_in?game_id=$game_id",
                                                       trust_root => $self->config->{root_url},
                                                      );
          [
           302,
           [ 'Location' => $check_url ],
           [ "What?  Why didn't you follow the 301 redirect?" ]
          ];
        },


        sub (/game/logged_in + ?game_id=&*) {
          my ($self, $game_id, $kitchen_sink) = @_;

          my $game = $games[$game_id];
          my $csr = $self->openid_consumer($kitchen_sink);
          
          # FIXME: We should figure out how to handle these without loosing the player's progress.
          return $csr->handle_server_response
            (
             not_openid => sub {
               die "Not an OpenID message";
             },
             setup_required => sub {
               my ($setup_url) = @_;
               
               return [
                       302,
                       [ 'Location' => $setup_url ],
                       [ "What?  Why didn't you follow the 301 redirect?" ]
                      ];
             },
             cancelled => sub {
               # FIXME: This case *really*
               # should be handled without
               # falling over completely, so
               # the user can retry.  Make the C layer return NULL somehow?
               die "User canceled on us while attempting to log them in";
             },
             verified => sub {
               my ($validated_id) = @_;
               $game->{user_identity} = $validated_id;
               
               $game->prep_prompt_file($game);

               # This duplicates code in /game/new/*
               [200,
                ['Content-type' => 'text/html',],
                [$game->make_page(undef, "FIXME: Make title correct after login dance")]
               ];
             },
             error => sub {
               my ($error) = @_;
               die $error;
             }
            );
        },
          
        sub (/game/continue + ?text~&input_type=&game_id=&window_id=&keycode~&keycode_ident~) {
          my ($self, $text, $input_type, $game_id, $window_id, $keycode, $keycode_ident) = @_;
#          my $char = $keycode if($input_type eq 'char');

          #$SIG{__DIE__} = sub {
          #  # Breaks my heart to do this, it really does...
          #  print STDERR "DIED! $@\n";
          #};
          #
          warn Dumper(['continue: text, input_type, game_id, window_id, keycode, keycode_ident: ', @_[1..$#_] ]);

          my $run_select = 1;
          my $game = $games[$game_id];

          if (length $text and not length $keycode) {
            $game->send("evtype_LineInput $text\n");
          } elsif(exists($self->config->{js_keycodes}{$keycode}) and not length $text) {
              $game->send("evtype_CharInput keycode_" . $self->config->{js_keycodes}{$keycode} . "\n");
          } elsif (length $keycode and not length $text) {
            if($keycode >=32 and $keycode <= 126) {
                $game->send("evtype_CharInput $keycode\n");
            } else {
                warn "Sent keycode out of range: $keycode\n";
                $run_select = 0;
            }
          } elsif (not length $text and not length $keycode) {
            # Do nothing.
            $run_select = 0;
          } else {
            # Both text and keycode are defined?
            die "Double-down on continue -- keycode='$keycode', text='$text'";
          }

          return $self->continue_game($game, $run_select);
        },

        sub (/game/new/*) {
            my ($self, $game_name) = @_;

            my $git = $self->config->{git_binary};
            my $nitfol = "/mnt/shared/projects/games/flash-if/nitfol-0.5/newnitfol";
            my $agility = "/mnt/shared/projects/games/flash-if/garglk-read-only/terps/agility/glkagil";
            my $tads2 = "/mnt/shared/projects/games/flash-if/tads2/glk/newtads";
            
            # Note that this key is used both as a URI element and a filename element.  For simplicity, keep element names lacking in URI metacharacters, please.
            # The title, OTOH, can be any arbitrary string.
            my %games = (
                         advent        => [$git, "$root/t/var/Advent.ulx", 'Adventure!'],
                         'blue-lacuna' => [$git, '/mnt/shared/projects/games/flash-if/blue-lacuna/BlueLacuna-r3.gblorb', 'Blue Lacuna'],
                         alabaster     => [$git, '/mnt/shared/projects/games/flash-if/Alabaster/Alabaster.gblorb', 'Alabaster'],
                         acg           => [$git, '/mnt/shared/projects/games/flash-if/ACG/ACG.ulx', 'Adventurer\'s Consumer Guide'],
                         king          => [$git, '/mnt/shared/projects/games/flash-if/The King of Shreds and Patches.gblorb', 'The King of Shreds and Patches'],
                         curses        => [$nitfol, '/mnt/shared/projects/games/flash-if/curses.z5', 'Curses'],
                         emy           => [$agility, '/mnt/shared/projects/games/flash-if/Emy Discovers Life/DISCOVER', 'Emy Discovers Life'],
                         sd3           => [$tads2, '/mnt/shared/projects/games/flash-if/sd3/SD3.gam', 'School Dreams 3: School Dreams Forever'],
                         zork1         => [$nitfol, '/mnt/shared/projects/games/flash-if/zork1/DATA/ZORK1.DAT', 'Zork I'],
                        );
            my $game_info = $games{$game_name};

            if (!$game_info) {
              die "Do not know game path for game $game_name -- supported: ".join(", ", keys %games);
            }
            my ($interp_path, $game_path, $title) = @$game_info;

            my $game_id = scalar @games;

            my $game = Game::HTML->new($game_id, $game_path, $interp_path, catfile($self->config->{save_file_dir}, $game_name));
            $games[$game_id] = $game;
            $game->continue();

            [ 200, 
              [ 'Content-type' => 'text/html' ], 
              [ $game->make_page(undef, $title)]
            ];
          }
      };

    sub continue_game {
        my ($self, $game, $run_select) = @_;

        $game->continue
          if $run_select;

        my $json = {
                    input_type => $game->get_input_type(),
                    show_forms => $game->get_form_states(),
                    extra_form_data => $game->extra_form_data(),
                   };
        if($game->has_new_windows) {
          $json->{redraw} = 1;
          $json->{windows} = $game->get_initial_windows();
        } else {
          $json->{windows} = $game->get_continue_windows();
        }
        $json = JSON::encode_json($json);
        print "Sending JSON: $json\n";

        [ 200, 
          [ 'Content-type' => 'application/json' ], 
          [ $json ]
        ];
    }
}

GameIF->run_if_script;
