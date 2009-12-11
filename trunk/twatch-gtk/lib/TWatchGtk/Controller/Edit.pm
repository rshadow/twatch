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

    # Если проект новый то прекратим
    return unless $self->{project};

    # Инициализация параметров:
    my $proj = $self->{twatch}->get_proj( $self->{project} );
    warn 'Wrong project name.', return unless $proj;

    $self->{builder}->get_object( 'name' )->set_text( $proj->{name} );
    $self->{builder}->get_object( 'url' )->set_text( $proj->{url} );

    $self->{builder}->get_object( 'auth_url' )->set_text(
        $proj->{authtorization}{url} );
    $self->{builder}->get_object( 'auth_login_name' )->set_text(
        $proj->{authtorization}{login}{name} );
    $self->{builder}->get_object( 'auth_login_value' )->set_text(
        $proj->{authtorization}{login}{value} );
    $self->{builder}->get_object( 'auth_password_name' )->set_text(
        $proj->{authtorization}{password}{name} );
    $self->{builder}->get_object( 'auth_password_value' )->set_text(
        $proj->{authtorization}{password}{value} );
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