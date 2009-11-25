#!/usr/bin/perl
package TWatchGtk::Controller::Edit;
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

    # Инициализация параметров:
}

sub on_button_ok_pressed
{
    my ($self, $window) = @_;
    $self->{window}->destroy;
    return TRUE;
}

sub on_button_cancel_pressed
{
    my ($self, $window) = @_;
    $self->{window}->destroy;
    return TRUE;
}

1;