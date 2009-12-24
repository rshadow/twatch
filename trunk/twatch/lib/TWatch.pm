package TWatch;

=head1 NAME

TWatch - осуществляет слежение за ссылками на сайте и скачку файлов по ссылкам.

=head1 VERSION

0.0.1

=cut
our $VERSION = '0.0.2';

use strict;
use warnings;
use utf8;
use open qw(:utf8 :std);
use lib qw(../lib);

use TWatch::Config;
use TWatch::Project;
use TWatch::Watch;

=head1 CONSTRUCTOR AND MAIN

=head2 new

Конструктор объекта закачкм

=cut
sub new
{
    my ($class, %opts) = @_;

    my %obj = %opts;
    my $self = bless \%obj ,$class;

    $self->load_projects;

    return $self;
}

=head2 run

Скрипт выполнения закачек соответсвенно параметрам проекта.

=cut
sub run
{
    my ($self) = @_;

    my @projects = $self->get_projects;

    notify(sprintf 'Total projects: %s', scalar @projects);

    for my $project (@projects)
    {
        notify(sprintf
            'Start project: %s (%s), last update %s',
            $project->name,
            $project->url,
            $project->update);
        notify(sprintf 'Watches: %d', $project->watches_count);

        $project->run
            or warn sprintf 'Project aborted!';


#
#        # Сохраним список готовых заданий
#        $self->save_complete($proj->{name});

        notify('Project complete');
    }
}

################################################################################
# Функции работы с проектами
################################################################################

=head1 PROJECT METHODS

=head2 load_projects

Функция загрузки проектов

=cut
sub load_projects
{
    my ($self) = @_;

    # Загрузим конфиги
    my @projects = glob(config->get('Project'));
    return unless @projects;

    $_ = TWatch::Project->new(file => $_) for @projects;

    $self->{project}{$_->name} = $_ for @projects;

    return scalar @projects;
}

=head2 get_projects

Получние проектов

=cut
sub get_projects
{
    my ($self, $name) = @_;

    return sort {$a->{order} <=> $b->{order}} values %{$self->{project}}
        if ! defined $name and wantarray;
    return $self->{project} if ! defined $name;
    return $self->{project}{$name};
}

=head2 get_watch

Получние заданий

=cut
sub get_watch
{
    my ($self, $p_name, $w_name) = @_;

    my $project = $self->get_projects($p_name);

    return sort {$a->{order} <=> $b->{order}} values %{ $project->watches }
        if wantarray;
    return $project->watches unless defined $w_name;
    return $project->get_watch($w_name);
}

=head2 save_complete

Сохранение готовых заданий

=cut
sub save_complete
{
    my ($self, $name) = @_;

    # Получим проект
    my $proj    = $self->get_projects($name);
    my $watch   = $self->get_watch($name);
    $watch->{$_} = {
        name        => $_,
        ($watch->{$_}{complete})
            ?(complete => { result => $watch->{$_}{complete} })
            :(),
    } for keys %$watch;

    # Составим данные о сохранении
    my $save = {
        name    => $proj->{name},
        update  => POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime(time)),
        watches => { watch => [ values %$watch ] },
    };

    # Составим имя файла для сохранения из пути поиска данных по завершенным
    # закачкам, плюс имя файла проекта
    my $file = $proj->{cfile};
    $file = (config->get('Complete') =~ m/^(.*)\/.*?$/)[0] .
            ($proj->{file} =~ m/^.*(\/.*?\.xml)$/)[0]
        unless $file;

    # Сохраним конфиг
    my $xs = XML::Simple->new(
        AttrIndent  => 1,
        KeepRoot    => 1,
        RootName    => 'project',
        NoAttr      => 1,
        NoEscape    => 1,
        NoSort      => 1,
        ForceArray  => ['watch', 'result'],
        XMLDecl     => 1,
        OutputFile  => $file,
    );
    my $xml = $xs->XMLout($save);

    return 1;
}

=head2 delete_project

Удаление проекта с заданным именем.

=cut
sub delete_project
{
    my ($self, $name) = @_;

    # Получим проект
    my $project = $self->get_projects($name);
    warn 'Can`t delete project: Project does not exists.',
    return
        unless $project;

    # Удалим файл проекта
    unlink $project->file
        or warn sprintf 'Can`t delete project file %s', $project->file;
    unlink $project->cfile
        or warn sprintf 'Can`t delete complete file %s', $project->cfile;

    # Удалим проект
    undef $self->{project}{$name};

    return 1;
}

=head2 add_project

Добавление нового проекта в список текущих

=cut
sub add_project
{
    my ($self, $new) = @_;

    if( $self->get_projects( $new->name ) )
    {
        warn sprintf('Can`t add project "%s". This project already exists.',
            $new->name);
        return;
    }

    $self->{project}{ $new->name } = $new;
}

=head2 save_proj

Сохранение файла проекта

=cut
sub save_project
{
#    my ($self, $name) = @_;
#
#    # Получим проект
#    my $project = $self->get_projects($name);
#    my $watch   = $self->get_watch($name);
#
#    $watch->{$_} = {
#        name        => $_,
#        ($watch->{$_}{complete})
#            ?(complete => { result => $watch->{$_}{complete} })
#            :(),
#    } for keys %$watch;
}




=head1 REQUESTS & BUGS

Roman V. Nikolaev <rshadow@rambler.ru>

=cut
1;