#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'Game-Catalyst';
all_from 'lib/Game/Catalyst.pm';

requires 'Catalyst::Runtime' => '5.80024';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::View::TT';
requires 'Moose';
requires 'JSON';
requires 'DateTime';
requires 'Data::Dump::Streamer';
requires 'LWPx::ParanoidAgent';
requires 'Cache::FileCache';
requires 'Net::OpenID::Consumer';
requires 'File::Spec::Functions';
requires 'Encode';
requires 'IPC::Open3';
requires 'IPC::Run';
requires 'Carp';
requires 'Path::Class';
requires 'Imager';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
test_requires 'Test::More' => '0.88';
test_requires 'Test::Strict'; # Should probably be made optional.
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
