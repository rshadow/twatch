package TWatch::Project;

=head1 NAME

TWatch::Project - Project module: work with torrent tracker.

=cut

use strict;
use warnings;
use utf8;
use open qw(:utf8 :std);
use lib qw(../../lib);

use XML::Simple;
use WWW::Mechanize;

use TWatch::Config;
use TWatch::Watch;
use TWatch::Complete;



=head1 CONSTRUCTOR

=cut



=head2 new

Create new project

=head3 Options:

=over

=item file

Path to project file

=back

=cut

sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;

    # If project file path exists then load them
    $self->load if $self->file;

    return $self;
}



=head1 DATA METHODS

=cut



=head2 name $param

If defined $param set project name. Unless return it.

=cut

sub name
{
    my ($self, $param) = @_;
    $self->{name} = $param if defined $param;
    return $self->{name};
}

=head2 file $param

If defined $param set project file path. Unless return it.

=cut

sub file
{
    my ($self, $param) = @_;
    $self->{file} = $param if defined $param;
    return $self->{file};
}

=head2 cfile $param

If defined $param set project completed file path. Unless return it.

=cut

sub cfile
{
    my ($self, $param) = @_;
    $self->{cfile} = $param if defined $param;
    return $self->{cfile};
}

=head2 update $param

If defined $param set project last updte time. Unless return it.

=cut

sub update
{
    my ($self, $param) = @_;
    $self->{update} = $param if defined $param;
    return $self->{update} || '';
}

=head2 url $param

If defined $param set project url. Unless return it.

=cut

sub url
{
    my ($self, $param) = @_;
    $self->{url} = $param if defined $param;
    return $self->{url};
}

=head2 auth %param

If defined %param set project authtorization hash. Unless return it.

=cut

sub auth
{
    my ($self, %param) = @_;
    $self->{authtorization} = \%param if %param;
    return undef
        unless defined $self->{authtorization} and %{ $self->{authtorization} };
    return $self->{authtorization};
}

=head2 auth_url $param

If defined $param set project authtorization url. Unless return it.

=cut

sub auth_url
{
    my ($self, $param) = @_;
    $self->{authtorization}{url} = $param if defined $param;
    return undef unless $self->auth;
    return $self->auth->{url};
}

=head2 auth_login_name $param

If defined $param set project authtorization login name. Unless return it.

=cut

sub auth_login_name
{
    my ($self, $param) = @_;
    $self->{authtorization}{login}{name} = $param if defined $param;
    return undef unless $self->auth;
    return $self->auth->{login}{name};
}

=head2 auth_password_name $param

If defined $param set project authtorization password name. Unless return it.

=cut

sub auth_password_name
{
    my ($self, $param) = @_;
    $self->{authtorization}{password}{name} = $param if defined $param;
    return undef unless $self->auth;
    return $self->auth->{password}{name};
}

=head2 auth_login_value $param

If defined $param set project authtorization login value. Unless return it.

=cut

sub auth_login_value
{
    my ($self, $param) = @_;
    $self->{authtorization}{login}{value} = $param if defined $param;
    return undef unless $self->auth;
    return $self->auth->{login}{value};
}

=head2 auth_password_value $param

If defined $param set project authtorization password value. Unless return it.

=cut

sub auth_password_value
{
    my ($self, $param) = @_;
    $self->{authtorization}{password}{value} = $param if defined $param;
    return undef unless $self->auth;
    return $self->auth->{password}{value};
}

=head2 watches

Get tasks

=cut

sub watches
{
    my ($self) = @_;
    return $self->{watches};
}

=head2 set_watch $watch

Set/replace task $watch. Tasks stored by names ($watch->name)

=cut

sub set_watch
{
    my ($self, $watch) = @_;
    $self->{watches}->{ $watch->name } = $watch;
    return $watch;
}

=head2 watches_count

Get tasks count

=cut

sub watches_count
{
    my ($self) = @_;
    return scalar keys %{ $self->{watches} };
}

=head2 get_watch $name

Get watch by $name

=cut

sub get_watch
{
    my ($self, $name) = @_;
    return $self->{watches}{$name};
}



=head1 LOAD METHODS

=cut



=head2 load

Load project from file

=cut

sub load
{
    my ($self) = @_;

    # Skip if file no set
    return unless $self->file;

    # Load project from file ###################################################
    my $xs = XML::Simple->new(
        NoAttr      => 1,
        ForceArray  => ['watch', 'result', 'filter'],
        GroupTags   => {
            'watches'   => 'watch',
            'complete'  => 'result',
            'filters'   => 'filter',
        }
    );
    my $project = $xs->XMLin( $self->file );
    return unless $project;

    # Add tasks in project #####################################################
    for my $name ( keys %{ $project->{watches} }  )
    {
        # Add task name in bufer
        $project->{watches}{$name}{name} = $name;
        # Create task object
        my $watch = TWatch::Watch->new(%{ $project->{watches}{$name} });
        # Add task to project
        $self->set_watch( $watch );
    }

    # Delete tasks from bufer (all already in project)
    delete $project->{watches};

    # Append additional params #################################################
    $self->{$_} = $project->{$_} for keys %$project;

    # Add completed info in tasks ##############################################
    # Get completed for this project
    my $complete = complete->get( $self->name );
    # Skip if have`t completed
    return $self unless $complete;
    # Add in project path to completed
    $self->cfile( $complete->{cfile} );
    # Add in project last update time
    $self->update( $complete->{update} );

    # Add completed to tasks
    for( values %{ $self->watches } )
    {
        # Skip if no comlete info
        next if ! $complete->{watches}{ $_->name } or
                ! $complete->{watches}{ $_->name }{complete};
        # Add completed
        $_->add_complete( $complete->{watches}{ $_->name }{complete} );
    }

    return $self;
}

=head2 delete

Delete project and it`s files
=cut

sub delete
{
    my ($self) = @_;

    # Delete project files
    unlink $self->file
        or warn sprintf 'Can`t delete project file %s', $self->file;
    unlink $self->cfile
        or warn sprintf 'Can`t delete complete file %s', $self->cfile;

    undef $self;
}

=head1 DOWNLOAD METHODS

=cut



=head2 run

Execute project

=cut

sub run
{
    my ($self) = @_;

    unless( $self->watches_count )
    {
        notify('No watches. Skip project.');
        return;
    }

    # Get brauser object already authtorized on tracker
    notify('Authtorization...');
    my $browser = $self->get_auth_browser;

    # Skip unless brouser or authtorized
    unless ($browser)
    {
        warn sprintf 'Link break. Skip project.';
        return;
    }

    # Run all tasks
    for my $name ( keys %{ $self->watches })
    {
        # Get task
        my $watch = $self->watches->{$name};

        notify(sprintf 'Start watch: %s', $watch->name );

        # Execute task
        $watch->run( $browser )
            or warn sprintf 'Watch aborted!';

        notify('Watch complete');
    }

    # Set last update time
    $self->update( POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime(time)) );
    notify(sprintf 'Complete at %s', $self->update);

    # Save completed to file
    notify('Save completed list');
    complete->save( $self );

    return $self;
}

=head2 get_auth_browser

Get browser object authtorized on tracker

=cut

sub get_auth_browser
{
    my ($self) = @_;

    return undef unless $self->{url};

    # Create browser object
    my $browser = WWW::Mechanize->new(
        agent       => 'Mozilla/5.0'.
            ' (Windows; U; Windows NT 6.0; en-US; rv:1.9.1.1)'.
            ' Gecko/20090715 Firefox/3.5.1',
        cookie_jar  => {},
        noproxy     => config->is_noproxy,
    );

    # Many sites have protection from outside coming. So go to main page first.
    eval{ $browser->get( $self->url ); };

    if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
    {
        warn sprintf 'Can`t connect to link: %s.', $self->url;
        return undef;
    }

    # If authtorization form not on main page (and set in config) then go to
    # this page
    if( $self->auth_url                 and
        $self->auth_url !~ m/^\s*$/     and
        $self->auth_url ne $self->url   )
    {
        eval{ $browser->get( $self->auth_url ); };
        if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
        {
            warn sprintf 'Can`t connect to auth link: %s.', $self->auth_url;
            return undef;
        }
    }

    # Find authtorization form (it`s set to default form)
    my $form = $browser->form_with_fields(
        $self->auth_login_name,
        $self->auth_password_name
    );
    # Skip if can`t find authtorization form
    unless( $form )
    {
        warn sprintf 'Can`t find authtorization form in "%s" project.',
            $self->name;
        return undef;
    }

    # Set authtorization params in form
    $browser->field( $self->auth_login_name, $self->auth_login_value )
        if $self->auth_login_name and $self->auth_login_value;
    $browser->field( $self->auth_password_name, $self->auth_password_value )
        if $self->auth_password_name and $self->auth_password_value;

    # Authtorization
    eval{ $browser->click(); };

    # Check if all OK
    if( !$browser->success or
        ($@ and $@ =~ m/Can't connect/) or
        !$browser->is_html() )
    {
        warn sprintf 'Can`t authtorize in "%s" project.', $self->name;
        return undef;
    }

    # Return browser
    return $browser;
}

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

1;