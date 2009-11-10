#!/usr/bin/perl
package TWatchGtk::Controller::Settings;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;
use lib qw(../../);

use Glib qw(:constants);
use Gtk2;

sub on_save_settings
{
    die 2;
}

1;