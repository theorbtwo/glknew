package Game::Utils;

use strict;
use warnings;
use Path::Class;
use File::Spec::Functions;
use File::Path 'mkpath';

## A placeholder for functions that aren't really attached to a running game

=head2 get_save_games

C<@filenames = get_save_games('king', '/path/to/saves/', 'http://your.name.here/');>

Returns the filenames relative to the correct directory.  (IE, just the filename part.)

=cut

sub get_save_games {
  my ($game, $save_file_dir, $user_id) = @_;
  
  my $actual_dir = save_file_dir($game, $save_file_dir, $user_id);
  
  my $dir = Path::Class::Dir->new($actual_dir);
  my @files = map {$_->basename} grep {!$_->is_dir} $dir->children;
  
  return @files;
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
