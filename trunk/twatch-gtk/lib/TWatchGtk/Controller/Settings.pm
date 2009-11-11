#!/usr/bin/perl
package TWatchGtk::Controller::Settings;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;
use lib qw(../../);

use Glib qw(:constants);
use Gtk2;

use TWatchGtk::Config;

sub init
{
    my ($self) = @_;

    $self->{builder}->get_object;
}

sub on_button_ok_pressed
{
    my ($self, $item, $window) = @_;
}

sub on_button_cancel_pressed
{
    my ($self, $item, $window) = @_;
}

1;