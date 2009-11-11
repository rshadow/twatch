#!/usr/bin/perl
package TWatchGtk::Controller::About;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;

use Glib qw(:constants);
use Gtk2;

sub init
{
    my ($self) = @_;

    # Привяжем событие нажатия кнопки закрытия на закрытие диалога
    my @list = $self->{object}->action_area->get_children;
    my $button_close = pop @list;
    $button_close->signal_connect('pressed', sub{ $self->{object}->destroy; } );
}

1;