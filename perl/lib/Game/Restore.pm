package Game::Restore;

use strict;
use warnings;
use Data::Dump::Streamer;

=head1 Game::Restore

Bare-bones Game using class that just initiates enough to send the commands to restore a saved game

=cut

sub new {
    my ($class, $game_path, $interp_path, $save_file_dir, $game_info) = @_;
    my $self = bless({
                      save_file_dir => $save_file_dir,
                      game_info => $game_info,
                      game_path => $game_path,
                      interp_path => $interp_path,
                     }, $class);


    return $self;
}

sub start_process {
    my ($self) = @_;
    my $game = Game->new(delete $self->{game_path}, 
                         delete $self->{interp_path},
                         {
                          select => sub { $self->restore_select_callback(@_) },
                          prompt_file => sub { $self->restore_prompt_file_callback(@_) },
                         });
    $self->{game_obj} = $game;
}

sub continue {
    my ($self) = @_;
    $self->{game_obj}{current_select} = {};

    $self->{game_obj}->wait_for_select;
}

sub restore_game {
    my ($self, $save_file) = @_;

    $self->{save_file} = $save_file;
    $self->continue;
}

## Return hash of self contained callbacks:
sub callbacks {
    my ($game_html, $save_file) = @_;
    my @restore_cmds = @{$game_html->game_info->{restore}};

    return (
            select => sub {
                #my $restore_cmd_idx = 0;
                #my @restore_cmds = @{ $game_html->game_info->{restore} };
                restore_select_callback($game_html, \@restore_cmds, @_);
            },
            prompt_file => sub {
                restore_prompt_file_callback($game_html, $save_file, @_);
            },
           );
}

=head2 restore_prompt_file_callback

Called by Game.pm when the game is asking us to prompt the user for a filename.

=cut

sub restore_prompt_file_callback {
    # We don't actually need most of this bollocks at all.
    my ($game_html, $save_file, $game, $usage, $mode) = @_;
    
    my $fullpath = Game::Utils::save_file_dir($game_html->game_info->{shortname},
                                              $game_html->save_file_dir,
                                              $game_html->user_identity) . '/' . $save_file;

    $game->send_to_game($fullpath, "\n");
    $game->{collecting_input} = 0;
    
    return;
}


## Keep answering the callback with the next restore command in the 
## config. Then send the save file name.
sub restore_select_callback {
    my ($game_html, $cmds, $game, $winid, $input_type, $input_charset) = @_;

    my $next_cmd = shift @$cmds;

    if(!$next_cmd) {
        die "Reached the end of the programmed restore commands without seeing a file prompt";
    }

    if($next_cmd) {
        my $to_game;
        if ($next_cmd->[0] eq 'line') {
            $to_game = "evtype_LineInput $next_cmd->[1]";
        } elsif ($next_cmd->[0] eq 'char' and length($next_cmd->[1]) == 1) {
            $to_game = "evtype_CharInput ".ord($next_cmd->[1])."\n";
        } else {
            die "Unhandled next_cmd".Dumper($next_cmd);
        }
        $game_html->game_obj->send_to_game($to_game);
    }
}

1;
