package TWatch;

=head1 NAME

TWatch - track for links on tracker and download new torrents.

=cut

our $VERSION = '0.0.7';

use strict;
use warnings;
use utf8;

use TWatch::Config;
use TWatch::Project;
use TWatch::Watch;

=head1 CONSTRUCTOR AND MAIN

=cut

=head2 new

Main constructor

=cut

sub new
{
    my ($class, %opts) = @_;

    my %obj = %opts;
    my $self = bless \%obj ,$class;

    $self->load;

    return $self;
}

=head2 run

Run execute downloads.

=cut

sub run
{
    my ($self) = @_;

    my @projects = $self->get;

    notify(sprintf 'Total projects: %s', scalar @projects);

    for my $project (@projects)
    {
        notify(sprintf
            'Start project: %s (%s), last update %s',
            $project->param('name'),
            $project->param('url'),
            $project->param('update') || 'Never');
        notify(sprintf 'Watches: %d', scalar $project->watches);

        $project->run
            or warn sprintf 'Project "%s" aborted!', $project->param('name');

        notify('Project complete');
    }
}

=head1 PROJECT METHODS

=cut

=head2 load

Load projects from files. Return count of loaded projects.

=cut

sub load
{
    my ($self) = @_;

    # Get projects paths
    my @pfiles = glob(config->get('Project'));
    return unless @pfiles;
    # Get completed path
    my @cfiles = glob(config->get('Complete'));

    # Get executed param
    my $execute = config->get('execute');
    notify(sprintf 'Execute param set. Run just "%s" project', $execute)
        if $execute;

    for my $pfile ( @pfiles )
    {
        # Get complete file by related file name
        my ($pname) = $pfile =~ m~^.*/(.*?)$~;
        my ($cfile) = grep {m~/$pname$~} @cfiles;

        # If set --execute option, then skip project by filename
        next if $execute and $pname ne $execute;

        # Load project
        my $project = TWatch::Project->new(file => $pfile, cfile => $cfile);

        # Add in hash
        $self->{project}{$project->param('name')} = $project;
    }

    return scalar keys %{$self->{project}};
}

=head2 get $name

Return project by $name. If $name not defined return a hash or sorted array.

=cut

sub get
{
    my ($self, $name) = @_;
    return sort {$a->param('order') <=> $b->param('order')}
        values %{$self->{project}}
            if ! defined $name and wantarray;
    return $self->{project} if ! defined $name;
    return $self->{project}{$name};
}

=head1 UNSUPPORTED OR JUST FOR TWATCH-GTK COMPATIBLE

=cut

=head2 delete_project $name

Delete project by $name.

=cut

sub delete_project
{
    my ($self, $name) = @_;

    # Get project
    my $project = $self->get($name);
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

    if( $self->get( $new->param('name') ) )
    {
        warn sprintf('Can`t add project "%s". This project already exists.',
            $new->param('name'));
        return;
    }

    $self->{project}{ $new->param('name') } = $new;
}

1;

=head1 REQUESTS & BUGS

Roman V. Nikolaev <rshadow@rambler.ru>

=head1 AUTHORS

Copyright (C) 2008 Roman V. Nikolaev <rshadow@rambler.ru>

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
