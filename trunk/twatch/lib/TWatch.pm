package TWatch;

=head1 NAME

TWatch - track for links on tracker and download new torrents.

=head1 VERSION

0.0.2

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

Main constructor

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

Run execute downloads.

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

        notify('Project complete');
    }
}

=head1 PROJECT METHODS

=head2 load_projects

Load projects from files. Return count of loaded projects.

=cut

sub load_projects
{
    my ($self) = @_;

    # Get projects paths
    my @projects = glob(config->get('Project'));
    return unless @projects;

    # Load all projects
    $_ = TWatch::Project->new(file => $_) for @projects;

    # Add all in hash
    $self->{project}{$_->name} = $_ for @projects;

    return scalar @projects;
}

=head2 get_projects $name

Return project by $name. If $name not defined return a hash or sorted array. 

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