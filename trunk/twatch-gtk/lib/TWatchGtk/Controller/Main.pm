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

use constant COL_TITLE      => 0;
use constant COL_SEASON     => 1;
use constant COL_SERIES     => 2;
use constant COL_COMPLETE   => 3;
use constant COL_PAGE       => 4;
use constant COL_ACTIONS    => 5;

use constant TW_STATUS      => 0;
use constant TW_TITLE       => 1;
use constant TW_SEASON      => 2;
use constant TW_SERIES      => 3;
use constant TW_COMPLETE    => 4;
use constant TW_PAGE        => 5;
use constant TW_PAGE_DECOR  => 6;
use constant TW_PAGE_COLOR  => 7;

#use constant TW_ACTIONS     => 6;

use constant LEVEL_PROJECT  => 1;
use constant LEVEL_WATCH    => 2;
use constant LEVEL_GROUP    => 3;
use constant LEVEL_TORRENT  => 4;

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

    my $treeview = $self->{builder}->get_object('treeview_projects');
    my $selection = $treeview->get_selection;
    my ($model, $iter) = $selection->get_selected;
    my @data = $model->get_value ($iter, TW_TITLE);

    # Определим уровень вызова: что именно редактируем
    my ($path) = $selection->get_selected_rows;
    my $level = $path->get_depth;

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
    my ($path) = $selection->get_selected_rows;

    # Выведим предупреждение если не смогли получить имя проекта
    unless( $path )
    {
        my $dialog = Gtk2::MessageDialog->new ($self->{window},
            'destroy-with-parent', 'error', 'ok', 'Select project first');
        $dialog->run;
        $dialog->destroy;
        return;
    }

    # С любого дочернего элемента дойдем до проекта
    while( $path->get_depth > 1 ) { $path->up }

    # Получим название проекта
    $iter = $model->get_iter($path);
    my ($name) = $model->get_value ($iter, TW_TITLE);

    $self->{twatch}->delete_proj($name);
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

    my $blue = Gtk2::Gdk::Color->new(0,0,65535);

    for (keys %{$twatch->{project}})
    {
        my $proj = $twatch->get_proj($_);

        # Добавим проект
        my $iter_project = $model->insert_with_values(undef, 0,
            TW_TITLE    , $proj->{name},
            TW_COMPLETE , $proj->{updated},
            TW_PAGE     , $proj->{url},
            TW_PAGE_DECOR , 'single',
            TW_PAGE_COLOR , $blue);

        # Добавим задания проекта
        for my $watch ( $twatch->get_watch($proj->{name}) )
        {
#            DieDumper $watch if $proj->{name} =~ m/zal/;
            my $iter_watch = $model->insert_with_values($iter_project, 0,
                TW_TITLE,       $watch->{name});

            # Добавим список завершенных торренов
            next unless @{ $watch->{complete} || [] };

            my $iter_complete = $model->insert_with_values($iter_watch, 0,
                    TW_TITLE,       'Completed');
            for my $complete ( @{ $watch->{complete} })
            {
                $model->insert_with_values($iter_complete, 0,
                    TW_TITLE,       $complete->{title}    || '',
                    TW_SEASON,      $complete->{season}   || '',
                    TW_SERIES,      $complete->{series}   || '',
                    TW_COMPLETE,    $complete->{datetime} || '',
                    TW_PAGE,        $complete->{page}     || '',
                    TW_PAGE_DECOR,  'single',
                    TW_PAGE_COLOR,  $blue);
            }
        }

    }

    # Свернем все проекты
    $treeview->collapse_all;
    return;
}

=head2 on_treeview_projects_row_activated

Обработка нажатий на строке

=cut
sub on_treeview_projects_row_activated
{
    my ($self, $treeview, $path, $column, $param) = @_;

    # Откроем в браузере если щелкнули на ссылке
    if( $treeview->get_column(COL_PAGE) == $column )
    {
        # Получим ссылку
        my $model   = $treeview->get_model();
        my $iter    = $model->get_iter($path);
        my $url     = $model->get_value ($iter, TW_PAGE);

        # Откроем ссылку в браузере
        my $exec = sprintf config->get('Browser'), $url;
        `$exec`;
    }
    # Иначе откроем редактор для данной строки
    else
    {
        $self->show_edit();
    }
}

1;