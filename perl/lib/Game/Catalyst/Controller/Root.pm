package Game::Catalyst::Controller::Root;
use Moose;
use namespace::autoclean;
use Game::HTML;
use Game::Restore;
use Game::Utils;
use JSON;
use File::Spec::Functions;
use Data::Dump::Streamer 'Dumper';
use LWPx::ParanoidAgent;
use Cache::FileCache;
use Net::OpenID::Consumer;
use Encode 'encode';
use mro;

BEGIN { extends 'Catalyst::Controller' }

BEGIN {
  # Make our debugging output slightly more sane.
  $| = 1;
}

# FIXME: Wrap these in... well, somewhere less ugly then a global.
my @games = ();

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

Game::Catalyst::Controller::Root - Root Controller for Game::Catalyst

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/).  Should give a list of known games, and either a list of your saves or a login box.

=cut

sub index :Path :Args(0) {
  my ($self, $c) = @_;
  
  my $g = $c->config->{games};
  $c->stash->{known_games} = [];
#  print STDERR Dumper $g;
  # FIXME: Sort correctly -- case insensitive, ignoring leading articles.
  for my $k (sort {$g->{$a}{title} cmp $g->{$b}{title}} keys %$g) {
    next if(! -e catfile($c->config->{game_path} || $c->config->{if_root},  $g->{$k}{location}));

    push @{$c->stash->{known_games}}, {%{ $g->{$k} }};
    if($c->session->{user_identity}) {
      $c->stash->{known_games}[-1]{save_games} = [Game::Utils::get_save_games($k, $c->config->{save_file_dir}, $c->session->{user_identity})];
    } else {
      $c->stash->{known_games}[-1]{save_games} = [];
    }
  }
#  print STDERR Dumper $c->stash->{known_games};
  
  # Don't expose this until we carefully consider what we are exposing.
  $c->stash->{show_nsfw} = 0;

  $c->stash->{session} = $c->session;
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    # FIXME: Make this more informative ?
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 game_image

Takes the game-generated images out of the game layer and into the browser.

Note: The format of the img_string should be considered opaque by this code -- I do not like it all that much.

=cut

sub game_image :Path('/game/image') :Args(1) {
  my ($self, $c, $img_string) = @_;

  my $graphics = Game::Window::Graphics::fetch($img_string);

  $c->res->header('Content-type' => 'image/png',
                  'Cache-control' => 'no-cache',
                  'Expires' => '-1');
  
  $c->res->body($graphics->as_png);
}

=head2 ajax_window_size

Inform the game layer of what the size of the given window is (in pixels).

FIXME: Why is this ajax_ instead of game_?

=cut

sub ajax_window_size :Path('/ajax/window_size') {
  my ($self, $c) = @_;
  
  my $game = $games[$c->req->param('game_id')];
  my $win_id = $c->req->param('win_id');
  $win_id =~ s/^winid//;
  $game->set_window_size($win_id, $c->req->param('width'), $c->req->param('height'));

  return $self->continue_game($c, $game, 0);
}

=head2 game_savefile

The final part of saving (or restoring!) a game -- passes the filename back to the C layer, which saves it to disc.

=cut

sub game_savefile :Path('/game/savefile') {
  my ($self, $c) = @_;

  my $game = $games[$c->req->param('game_id')];
  my $save_file = $c->req->param('save_file');
  $save_file =~ s![\0/]!_!g;
  
  $game->send_prompt_file($save_file);
  return $self->continue_game($c, $game, 1);
}

=head2 game_login

The second stage of saving or restoring -- inform the server of what
the user claims their openid is, so it can compute the url to send the
browser to to validate it and get back to us.

=cut

sub game_login :Path('/game/login') {
  my ($self, $c) = @_;

  my $extra_param = '';
  if (defined $c->req->param('game_id')) {
    $extra_param = "?game_id=".$c->req->param('game_id');
  }
  
  my $csr = $self->openid_consumer($c);
  # FIXME: Why does username2 have such a naff name?
  my $claimed_identity = $csr->claimed_identity($c->req->param('username2'));
  if (!$claimed_identity) {
    die $csr->err;
  }
  my $check_url = $claimed_identity->check_url(
                                               return_to  => $c->req->base."game/logged_in$extra_param",
                                               trust_root => $c->req->base,
                                              );
  return $c->res->redirect($check_url);
}

=head2 game_logged_in

The whateverweareuptoith stage of logging in.  This happens after
game_login -- the authorizing server redirects the user here.  We
check their crypto, and go on to prompt them for a filename.

=cut

sub game_logged_in :Path('/game/logged_in') {
  my ($self, $c) = @_;

  my $game;
  if (defined $c->req->param('game_id')) {
    $game = $games[$c->req->param('game_id')];
  }
  my $csr = $self->openid_consumer($c);
  
  # FIXME: We should figure out how to handle these without loosing the player's progress.
  $csr->handle_server_response
    (
     not_openid => sub {
       die "Not an OpenID message";
     },
     ## FIXME: Fix this comment.
     ## FIXME: Which of these is actually needed.  Er, required.  Er,
     ## whatever.  When only _required was present, there was a
     ## problem with lj returning setup_needed and ending up in
     ## bad_mode.
     setup_required => sub {
       my ($setup_url) = @_;
       
       $c->res->redirect($setup_url);
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
       if ($game) {
         # The user logged in from inside the game, as part of saving or restoring.

         # A net::OpenID::VerifiedIdentity
         $game->user_identity($validated_id->url);
         
         $game->prep_prompt_file($game);
         
         $c->res->body($game->make_page);
       } else {
         # The user was not inside a game, so redirect them on to the landing page.
         $c->session->{user_identity} = $validated_id->url;

         $c->res->redirect($c->uri_for('/'));
       }
     },
     error => sub {
       my ($error) = @_;
       die "Some other problem verifying openid: $error";
     }
    );
}

=head2 game_continue

Handle all sorts of "normal" user input -- text input, and char input.
FIXME: This is our hot path.  Optimize it?

=cut

sub game_continue :Path('/game/continue') {
  # This also gets passed input_type and window_id, but currently doesn't use them.  Also, sometimes, keycode_ident?
  my ($self, $c) = @_;

  my $game = $games[$c->req->param('game_id')];
  
  my $run_select = 1;

  my ($text, $keycode) = map {$c->req->param($_)} qw<text keycode>;

  # FIXME: Keying off of length means that the user cannot input an empty line.  In Blue Lacuna, that is documented (in a hint) as being equivelent to "look".
  if (length $text and not length $keycode) {
    if ($game->game_obj->{current_select}{input_charset} eq 'latin1') {
      $game->send("evtype_LineInput $text\n");
    } elsif ($game->game_obj->{current_select}{input_charset} eq 'uni') {
      # FIXME: This should be utf32be on big-endian platforms.
      # (However, we can't just use utf32 without suffix, which is BE
      # always with a BOM at the beginning, which the C layer isn't
      # prepapred to handle.
      $game->game_obj->send_line_input_unicode($text);
    } else {
      die "Unknown input_charset $game->game_obj->{current_select}{input_charset} -- le boggle";
    }
  } elsif (exists($c->config->{js_keycodes}{$keycode}) and not length $text) {
    $game->send("evtype_CharInput keycode_" . $c->config->{js_keycodes}{$keycode} . "\n");
  } elsif (length $keycode and not length $text) {
    if ($keycode >=32 and $keycode <= 126) {
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
  
  return $self->continue_game($c, $game, $run_select);
}

=head2 game_restore

Restores a user's existing game, without having first created a game to restore "into".
Prerequisites: User is logged in.

=cut

sub game_restore :Path('/game/restore') :Args(2) {
  my ($self, $c, $game_name, $save_name) = @_;

  ## Make a new Game::Restore, to harvest the brains out of later.
  my $game = setup_game('Game::HTML', $game_name, $c);
  $game->game_obj->set_callbacks(Game::Restore::callbacks($game, $save_name));
  $game->start_process;
  $game->continue;

  ## Re-set normal callbacks
  $game->game_obj->set_callbacks(%{ $game->callbacks });

  my $game_id = scalar @games;
  $game->user_info($game_id);
  $games[$game_id] = $game;

  $game->continue;
  $c->res->body($game->make_page);
}

=head2 game_new

Takes the id of the game to be run, B<as a path segment>, and starts a new instance of it.

 toke.c- *  'It all comes from here, the stench and the peril.'    --Frodo
 toke.c- *
 toke.c: *     [p.719 of _The Lord of the Rings_, IV/ix: "Shelob's Lair"]

=cut

sub game_new :Path('/game/new') :Args(1) {
  # FIXME: rename game_name, it's actually a shortname.  Title is the "real" name...
  my ($self, $c, $game_name) = @_;
  
  my $game = setup_game('Game::HTML', $game_name, $c);

  my $game_id = scalar @games;
  $game->user_info($game_id);
  $games[$game_id] = $game;
  $game->start_process;
  $game->continue();
  
  $c->res->body($game->make_page);
}

=head2 admin

An administrative interface, for killing things we don't like & etc.

=cut

sub admin :Path('/admin') {
  my ($self, $c) = @_;

  if (!$c->session->{user_identity}) {
    die "Please log in on the front page before trying to use the admin page."
  }
  if (!($c->session->{user_identity} ~~ ['http://theorb.livejournal.com/', 'http://getopenid.com/castaway'])) {
    die "You, ".$c->session->{user_identity}.", are not a recognized administrator.  Go away.";
  }

  $c->stash->{games} = \@games;
}


=head2 debugme

Does some random debuggy data dumping.

=cut

sub debugme :Path('/debugme/thisisslightlysecret') {
  my ($self, $c) = @_;
  
  $c->res->body($|);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head2 Utility methods

=head3 setup_game

Create a Game::HTML object for the given game, setting interpreter, etc.

=cut

sub setup_game {
  my ($class, $game_name, $c) = @_;

  my $game_info = $c->game_data($game_name);

  if (!$game_info) {
    # FIXME: Make this more user-friendly.  For one thing, die kills the *entire server*, not just this user's session.
    # FIXME: Does this break the encapsulation?
    die "Do not know game path for game $game_name -- supported: ".join(", ", keys %{$c->config->{games}});
  }

  my ($vm, $game_loc, $title) = @{$game_info}{qw/vm location title/};

  my $interp_path = catfile($c->config->{if_root}, $c->config->{interpreters}{$vm});

  ## game_path is used if set, allowing us to store games elsewhere.
  my $game_path = catfile($c->config->{game_path} || $c->config->{if_root},  $game_loc);

  my $game = $class->new(game_path => $game_path, 
			 interp_path => $interp_path, 
			 save_dir => $c->config->{save_file_dir}, 
			 game_info => $game_info);
  $game->user_identity($c->session->{user_identity})
    if(exists $c->session->{user_identity});

  return $game;
}

=head3 openid_consumer

Args: $self, $query_params

Returns the L<Net::OpenID::Consumer> for use with this application.

=cut

sub openid_consumer {
  my ($self, $c) = @_;
  
  # FIXME: We should mine this out of $self, so it matches the URL that the user needs: lilith, lilith.local, external?
  return Net::OpenID::Consumer->new(
                                    ua => LWPx::ParanoidAgent->new,
                                    cache => Cache::FileCache->new({namespace => __PACKAGE__}),
                                    # args => hr of get parameters,
                                    # FIXME: At least don't have this in a public git repo, you noncewit.
                                    consumer_secret => 'oasiejgoag',
                                    # FIXME: The URL for the root of this plackup thingy.  Should be far more dynamic then this.
                                    required_root => $c->req->base,
                                    # All the query paramaters to the current URL (that aren't handled "by hand").
                                    args => $c->req->params,
                                   );
}

=head2 continue_game

 doio.c-/*
 doio.c- *  Far below them they saw the white waters pour into a foaming bowl, and
 doio.c- *  then swirl darkly about a deep oval basin in the rocks, until they found
 doio.c- *  their way out again through a narrow gate, and flowed away, fuming and
 doio.c- *  chattering, into calmer and more level reaches.
 doio.c- *
 doio.c: *     [p.684 of _The Lord of the Rings_, IV/vi: "The Forbidden Pool"]

FIXME: should this be moved to the catalystic end?
FIXME: should this handle the full-html case too (shared by game_new and game_logged_in).

=cut

sub continue_game {
  my ($self, $c, $game, $run_select) = @_;
  
  $game->continue
    if $run_select;
  
  my $json = {
              input_type => $game->get_input_type(),
              show_forms => $game->form_states(),
              extra_form_data => $game->extra_form_data(),
             };
  if ($game->has_new_windows) {
    $json->{redraw} = 1;
    $json->{windows} = $game->get_initial_windows();
  } else {
    $json->{windows} = $game->get_continue_windows();
  }
  $json = JSON::encode_json($json);
  print STDERR "Sending JSON: $json\n";
  
  $c->res->content_type('application/json');
  $c->res->body($json);
}


=head1 AUTHOR

James Mastros,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
