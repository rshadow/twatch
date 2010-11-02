package TWatchGtk::Controller::Edit;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;

use Glib qw(:constants);
use Gtk2;

use TWatchGtk::Config;

sub init
{
    my ($self) = @_;

    # Если проект новый то прекратим
    return unless $self->{project};

    # Инициализация параметров:
    my $project = $self->{twatch}->get( $self->{project} );
    warn 'Wrong project name.', return unless $project;

    $self->{builder}->get_object('name')->set_text($project->param('name')||'');
    $self->{builder}->get_object('url' )->set_text($project->param('url') ||'');
    $self->{builder}->get_object('order' )->
        set_text($project->param('order') || 0);

    $self->{builder}->get_object( 'auth_url' )->set_text(
        $project->auth('url') || '');
    $self->{builder}->get_object( 'auth_login_name' )->set_text(
        $project->auth('login_name') || '');
    $self->{builder}->get_object( 'auth_login_value' )->set_text(
        $project->auth('login_value') || '');
    $self->{builder}->get_object( 'auth_password_name' )->set_text(
        $project->auth('password_name') || '');
    $self->{builder}->get_object( 'auth_password_value' )->set_text(
        $project->auth('password_value') || '');
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