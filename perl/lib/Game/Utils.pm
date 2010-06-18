package Game::Utils;

use strict;
use warnings;

## A placeholder for functions that aren't really attached to a game

# arrayref of game names, root dir of save files, username
sub get_save_games {
    my ($games, $save_file_dir, $user_id) = @_;

    my %save_data = ();
    foreach my $game (@$games) {
        my $actual_dir = save_file_dir($game, $save_file_dir, $user_id);

        my $dir = Path::Class::Dir->new($actual_dir);
        my @files = grep {!$_->is_dir} $dir->children;

        $save_data{$game} = \@files;
    }

    return \%save_data;
}

## $saves/$gamename/$userid/
sub save_file_dir {
  my ($game, $dir, $user_id) = @_;

  my $usernamelet = $user_id;
  $usernamelet =~ s/\0/fuckyounull/g;
  $usernamelet =~ s!^http://!!;
  $usernamelet =~ s!/\.\.!/dotdot!g;

  my $game_dir = catfile($dir, $game, $usernamelet);
  mkpath($game_dir);

  return $game_dir;
}

1;
