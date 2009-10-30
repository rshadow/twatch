#!/usr/bin/perl
package TWatchGtk::Controller;

use strict;
use warnings;
use utf8;
use lib qw(lib ../lib ../../lib ../../../lib);

use Glib qw(:constants);
use Gtk2;

use TWatchGtk::Config;

=head2 new

Конструктор окна "О программе"

=cut
sub new
{
    my ($class, $app) = @_;
    my $self = bless {app => $app} ,$class;
    return $self;
}

=head2 app

Получение объекта приложения

=cut
sub app{ return shift->{app} };

# Стандартные функции ##########################################################
=head2

Выход из приложения

=cut
sub gtk_main_quit
{
    Gtk2->main_quit;
    return TRUE;
}

sub gtk_widget_show
{
    my ($self, $item, $window) = @_;
    $window->reshow_with_initial_size;
    return TRUE;
}

sub gtk_widget_hide
{
    my ($self, $item, $window) = @_;
    $window->hide;
    return TRUE;
}

sub gtk_widget_destroy
{
    my ($self, $item, $window) = @_;
    $window->destroy;
    return TRUE;
}

#sub show                { shift->app->show; return TRUE; }

# Обработчики меню #############################################################
#sub show_about
#{
#    my ($self) = @_;
#    Gtk2->show_about_dialog($self->app->get_object('about'));
#    return TRUE;
#}
#
#sub show_settings
#{
#    my ($self) = @_;
#    $self->app->get_object('settings')->show;
#    return TRUE;
#}


1;