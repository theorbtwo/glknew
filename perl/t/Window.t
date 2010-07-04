#!/usr/local/bin/perl5.10.0

use strict;
use warnings;

use Test::More;

use_ok('Game::Window');

## Minimum window, use defaults
my $win1 = Game::Window->new({
    id => 'id1',
    wintype => 'TextBuffer',
                             });

isa_ok($win1, 'Game::Window');

is($win1->id, 'id1', 'Id: id1 set');
is_deeply($win1->method, {}, 'Default Window method is empty hashref');
ok(!$win1->drawn, 'Default drawn is false');
is_deeply($win1->window_size, [42, 42], 'Default window_size is 42, 42');
ok($win1->window_size_is_fake, 'Default window_size_is_fake, is true');
is_deeply($win1->pages, [], 'Default pages is empty arrayref');
is_deeply($win1->content, [], 'Default content is empty arrayref');
is($win1->wintype, 'TextBuffer', 'TextBuffer wintype set');
ok(!$win1->current_style, 'Default current_style is unset');
ok(!$win1->is_root, 'Default is_root is false');
ok(!$win1->parent, 'Default parent is unset');
ok(!$win1->size, 'Default size is unset');

## Set size, should set sensible window_size values, with method of fixed.
my $win2 = Game::Window->new( {
    id => 'id2',
    wintype => 'TextBuffer',
    size => 25,
    method => { above => 1, fixed => 1},
                              });

isa_ok($win2, 'Game::Window');
is_deeply($win2->window_size, [ 42, 25*19.2], 'Above/fixed sets height to given size');
ok($win2->window_size_is_fake, 'Default size given, window size is still fake');
ok(!$win2->is_root, 'Window is not automatically root');

## Set size, method and root. window_size defaults to 640x480
my $win3 = Game::Window->new({
    id => 'id3',
    wintype => 'TextBuffer',
    size => 25,
    method => { below => 1, fixed => 1 },
    is_root => 1,
                             });

ok($win3->is_root, 'Root is true');
is_deeply($win3->window_size, [ 640, 480 ], 'Root window has default size');

## Full window object, not root.
my $win4 = Game::Window->new({
    id => 'id4',
    wintype => 'TextBuffer',
    size => 25,
    method => { below => 1, fixed => 1},
    parent => $win3,
                             });

$win4->pages([ [ 'some pages' ] ]);
$win4->content([ 'more content' ]);
is_deeply($win4->last_page, [ 'some pages' ], 'Last page returns last item in pages');
$win4->new_turn();
is_deeply($win4->pages, [ [ 'some pages' ], [ 'more content' ] ], 'New turn appends content to pages');
is_deeply($win4->content, [], 'New turn empties content arrayref');
is_deeply($win4->last_page, [ 'more content' ], 'After new turn, last page returns last item in pages');

done_testing;
