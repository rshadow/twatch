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
    my $treeview    = $self->{builder}->get_object('treeview_projects');
    my $twatch      = $self->{twatch};

    my $model   = $treeview->get_model();
#    $model->append(undef);
#    $model->append(undef);
#    $model->append(undef);
#    $model->set_column_types (qw(Glib::String Glib::String Glib::String));
##    my $iter    = $model->get_iter_first();

#    DieDumper $model;
    for (keys %{$twatch->{project}})
    {
        # Добавим проект
        my $iter_project = $model->insert_with_values(undef, 0,
            0 => 11, 1 => $_, 2 => $_);

        # Добавим уровни
        my $iter_watches = $model->insert_with_values($iter_project, 0,
            0 => 11, 1 => 'Watches', 2 => undef);
        my $iter_disabled = $model->insert_with_values($iter_project, 0,
            0 => 11, 1 => 'Disabled', 2 => undef);
        my $iter_completed = $model->insert_with_values($iter_project, 0,
            0 => 11, 1 => 'Completed', 2 => undef);

        # Добавим список завершенных торренов
#        DieDumper $twatch->get_proj($_)->{watches}{complete}{watch};
    }

#    $treeview->collapse_all;



#     ($model);
#    DieDumper [ keys %{$twatch->{project}} ];


}

1;