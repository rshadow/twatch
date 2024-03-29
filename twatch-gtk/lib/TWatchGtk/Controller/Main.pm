package TWatchGtk::Controller::Main;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;

use Glib qw(:constants);
use Gtk2;

use TWatchGtk::Config; # Нужен только для дампера.
use TWatchGtk::Controller::About;
use TWatchGtk::Controller::Settings;
use TWatchGtk::Controller::Edit;
use TWatchGtk::Controller::Run;
use TWatchGtk::Controller::Cron;

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

sub init
{
    my ($self) = @_;

    # Если проверку надо производить и задание не установлено в cron то
    # выведим сообщение
    $self->{dlg}{cron} = TWatchGtk::Controller::Cron->new
        if config->get('ShowCronDialog') and
            ! TWatchGtk::Controller::Cron::verify;
}

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

sub show_add
{
    my ($self, $item, $param) = @_;

    # Получим имя проекта
    my $sel = $self->_get_selected_project;

    $self->{dlg}{edit} = TWatchGtk::Controller::Edit->new(
        twatch  => $self->{twatch},
        project => undef,
    );
    return TRUE;
}

sub show_edit
{
    my ($self, $item, $param) = @_;

    # Получим имя проекта
    my $sel = $self->_get_selected_project;

    # Выведим предупреждение если не смогли получить имя проекта
    unless( $sel )
    {
        my $dialog = Gtk2::MessageDialog->new ($self->{window},
            'destroy-with-parent', 'error', 'ok', 'Select project first');
        $dialog->run;
        $dialog->destroy;
        return;
    }

    my ($model, $iter) = $sel->{selection}->get_selected;
    my @data = $model->get_value ($iter, TW_TITLE);

    # Определим уровень вызова: что именно редактируем
    my ($path) = $sel->{selection}->get_selected_rows;
    my $level = $path->get_depth;

    $self->{dlg}{edit} = TWatchGtk::Controller::Edit->new(
        twatch  => $self->{twatch},
        project => $sel->{name},
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

    # Получим имя проекта
    my $sel = $self->_get_selected_project;
    # Выведим предупреждение если не смогли получить имя проекта
    unless( $sel )
    {
        my $dialog = Gtk2::MessageDialog->new ($self->{window},
            'destroy-with-parent', 'error', 'ok', 'Select project first');
        $dialog->run;
        $dialog->destroy;
        return;
    }

    # TODO Сдесь сделать показ отдельного окна удаления с галочками что именно
    # удалять кроме файла проета и, возможно, списком файлов которые будут
    # удалены
    # Выведим сообщение об удалении
    my $dialog = Gtk2::MessageDialog->new ($self->{window},
        'destroy-with-parent', 'question', 'yes-no',
        sprintf('Delete project: %s', $sel->{name}) );
    my $result = $dialog->run;
    $dialog->destroy;
    return unless $result eq 'yes';

    # Удалим проект
    my $deleted = $self->{twatch}->delete_proj($sel->{name});
    unless( $deleted )
    {
        my $dialog = Gtk2::MessageDialog->new ($self->{window},
            'destroy-with-parent', 'error', 'ok', 'Can`t delete project.');
        $dialog->run;
        $dialog->destroy;
        return;
    }

    # Перерисуем дерево проектов
    my ($model, $iter) = $sel->{selection}->get_selected;
    $model->remove ($iter);
}

sub click_refresh
{
    my ($self, $item, $param) = @_;
    #$self->build_project_tree;
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

    for my $project ($twatch->get)
    {
        # Добавим проект
        my $iter_project = $model->insert_with_values(undef, 0,
            TW_TITLE    , $project->param('name'),
            TW_COMPLETE , $project->param('updated'),
            TW_PAGE     , $project->param('url'),
            TW_PAGE_DECOR , 'single',
            TW_PAGE_COLOR , $blue);

        # Добавим задания проекта
        my @watches = $project->watches;
        for my $watch ( @watches )
        {
#            DieDumper $watch if $project->{name} =~ m/zal/;
            my $iter_watch = $model->insert_with_values($iter_project, 0,
                TW_TITLE,       $watch->param('name'));

            # Добавим список завершенных торренов
            next unless $watch->complete->count;

#            my $iter_complete = $model->insert_with_values($iter_watch, 0,
#                    TW_TITLE,       'Completed');
            for my $key ( $watch->complete->keys )
            {
                $model->insert_with_values($iter_watch, 0,
                    TW_TITLE,       $watch->complete->param($key, 'title')   ||
                                    $watch->complete->param($key, 'torrent') || '',
                    TW_SEASON,      $watch->complete->param($key, 'season')  || '',
                    TW_SERIES,      $watch->complete->param($key, 'series')  || '',
                    TW_COMPLETE,    $watch->complete->param($key, 'datetime')|| '',
                    TW_PAGE,        $watch->complete->param($key, 'page')    || '',
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

=head2 _get_selected_project

Получение имени выделенного проекта

=cut
sub _get_selected_project
{
    my ($self) = @_;

    my $treeview = $self->{builder}->get_object('treeview_projects');
    my $selection = $treeview->get_selection;
    my ($model, $iter) = $selection->get_selected;
    my ($path) = $selection->get_selected_rows;

    return unless $path;

    # С любого дочернего элемента дойдем до проекта
    while( $path->get_depth > 1 ) { $path->up }

    # Получим название проекта
    $iter = $model->get_iter($path);
    my ($name) = $model->get_value ($iter, TW_TITLE);

    return {name => $name, selection => $selection};
}

1;