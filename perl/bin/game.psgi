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
  
  dispatch {
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
    ,
            
      sub (/testme) {
        my ($self) = @_;
        my $text;
        
        [200,
         [ 'Content-type' => 'text/plain' ],
         [ Dumper [mro::get_linear_isa(ref $self), $self, \%ENV] ],
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
    if ($game->has_new_windows) {
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
