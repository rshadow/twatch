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

=head1 UNSUPPORTED OR USED ONLY IN TWATCH-GTK

=head2 get_watch $p_name, $w_name

Get task $w_name by project $p_name. Return task if $p_name defined. Unless
return all project tasks sorteb by order.

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

=head2 delete_project $name

Delete project by $name.

=cut

sub delete_project
{
    my ($self, $name) = @_;

    # Get project
    my $project = $self->get_projects($name);
    warn 'Can`t delete project: Project does not exists.',
    return
        unless $project;

    # Delete project and unlink it`s files
    $project->delete();

    # Delete project from projects hash
    delete $self->{project}{$name};

    return 1;
}

=head2 add_project $new

Add $new project. $new must be TWatch::Project object. Function fail if project
this same name already exists.

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

#=head2 save_proj
#
#Сохранение файла проекта
#
#=cut
#
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

=head1 AUTHORS

Copyright (C) 2008 Nikolaev Roman <rshadow@rambler.ru>

=head1 LICENSE

This program is free software: you can redistribute  it  and/or  modify  it
under the terms of the GNU General Public License as published by the  Free
Software Foundation, either version 3 of the License, or (at  your  option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even  the  implied  warranty  of  MERCHANTABILITY  or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public  License  for
more details.

You should have received a copy of the GNU  General  Public  License  along
with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;