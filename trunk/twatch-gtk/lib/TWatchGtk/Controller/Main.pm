#!/usr/bin/perl
package TWatchGtk::Controller::Main;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;

use Glib qw(:constants);
use Gtk2;

use lib qw(../../);
use TWatchGtk::Config; # Нужен только для дампера.
use TWatchGtk::Controller::About;
use TWatchGtk::Controller::Settings;
use TWatchGtk::Controller::Edit;
use TWatchGtk::Controller::Run;

use constant TW_STATUS      => 0;
use constant TW_TITLE       => 1;
use constant TW_SEASON      => 2;
use constant TW_SERIES      => 3;
use constant TW_COMPLETE    => 4;
use constant TW_PAGE        => 5;
use constant TW_ACTIONS     => 6;

# Обработчики меню #############################################################
sub show_about
{
    my ($self, $item, $param) = @_;
    $self->{dlg}{about} = TWatchGtk::Controller::About->new;
    return TRUE;
}

sub show_settings
{
    my ($self, $item, $param) = @_;
    $self->{dlg}{settings} = TWatchGtk::Controller::Settings->new;
    return TRUE;
}

sub show_edit
{
    my ($self, $item, $param) = @_;

#    my $treeview = $self->{builder}->get_object('treeview_projects');
#    my $selection = $treeview->get_selection;
#    my ($model, $iter) = $selection->get_selected;
#    my @data = $model->get_value ($iter, TW_TITLE);
#
#    DieDumper \@data;

    my $name;
    $self->{dlg}{edit} = TWatchGtk::Controller::Edit->new(
        twatch  => $self->{twatch},
        project => $name,
    );
    return TRUE;
}

sub show_run
{
    my ($self, $item, $param) = @_;
    $self->{dlg}{run} = TWatchGtk::Controller::Run->new;
    return TRUE;
}

sub show_delete
{
    my ($self, $item, $param) = @_;

    my $treeview = $self->{builder}->get_object('treeview_projects');
    my $selection = $treeview->get_selection;
    my ($model, $iter) = $selection->get_selected;
    my $path = $model->get_path($iter);
    while( $path->up ) {1;}
    $iter = $model->get_iter($path);
    DieDumper $iter;
    my @data = $model->get_value ($iter, TW_TITLE);

    DieDumper \@data;

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
    my $model       = $treeview->get_model();
    my @columns     = $treeview->get_columns();

    for (keys %{$twatch->{project}})
    {
        my $proj = $twatch->get_proj($_);

        # Добавим проект
        my $iter_project = $model->insert_with_values(undef, 0,
            TW_TITLE    , $proj->{name},
            TW_COMPLETE , $proj->{updated},
            TW_PAGE     , $proj->{url});

        # Добавим задания проекта
        for my $watch ( $twatch->get_watch($proj->{name}) )
        {
#            DieDumper $watch if $proj->{name} =~ m/zal/;
            my $iter_watch = $model->insert_with_values($iter_project, 0,
                TW_TITLE    , $watch->{name});

            # Добавим список завершенных торренов
            next unless @{ $watch->{complete} || [] };

            my $iter_complete = $model->insert_with_values($iter_watch, 0,
                    TW_TITLE    , 'Completed');
            for my $complete ( @{ $watch->{complete} })
            {
                $model->insert_with_values($iter_complete, 0,
                    TW_TITLE    , $complete->{title}    || '',
                    TW_SEASON   , $complete->{season}   || '',
                    TW_SERIES   , $complete->{series}   || '',
                    TW_COMPLETE , $complete->{datetime} || '',
                    TW_PAGE     , $complete->{page}     || '');
            }
        }

    }

    # Свернем все проекты
    $treeview->collapse_all;
    return;
}

1;