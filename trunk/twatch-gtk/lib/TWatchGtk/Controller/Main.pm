#!/usr/bin/perl
package TWatchGtk::Controller::Main;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;

use Glib qw(:constants);
use Gtk2;
use Gtk2::Ex::Simple::List;

use lib qw(../../);
use TWatchGtk::Config; # Нужен только для дампера.
use TWatchGtk::Controller::About;
use TWatchGtk::Controller::Settings;

# Обработчики меню #############################################################
sub show_about
{
    my ($self) = @_;
#    require "TWatchGtk::Controller::About";
    $self->{about} = TWatchGtk::Controller::About->new;
    return TRUE;
}

sub show_settings
{
    my ($self) = @_;
#    require "TWatchGtk::Controller::Settings";
    $self->{settings} = TWatchGtk::Controller::Settings->new;
    return TRUE;
}

# Логика #######################################################################
=head2 build_project_tree

Построение дерева проектов

=cut
sub build_project_tree
{
    my ($self) = @_;

    # Получим объекты для работы
    my $tree    = $self->{builder}->get_object('treeview_projects');
    my $twatch  = $self->{twatch};

#    DieDumper [ keys %{$twatch->{project}} ];


}

1;