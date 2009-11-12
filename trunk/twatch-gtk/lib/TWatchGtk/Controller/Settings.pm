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

    # Инициализация параметров:

    # Строковые параметры
    $self->{builder}->get_object( $_ )->set_text( config->d_get_orig( $_ ) )
        for (qw(Project Save Complete EMail));

    # Уровень отсылки уведомлений
    for( @{ config->d_get('EmailLevel') } )
    {
        $self->{builder}->get_object($_)->set_active( 1 )
            if $self->{builder}->get_object( $_ );
    }

    # Использование прокси
    $self->{builder}->get_object('NoProxy')->set_active(
        config->d_get('NoProxy') eq 'yes'
    );
}

sub on_button_ok_pressed
{
    my ($self, $window) = @_;

    $self->{window}->destroy;
}

sub on_button_cancel_pressed
{
    my ($self, $window) = @_;
    $self->{window}->destroy;
}

1;