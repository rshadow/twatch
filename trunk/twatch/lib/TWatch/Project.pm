package TWatch::Project;

=head1 NAME

TWatch::Project - Project module: work with torrent tracker.

=cut

use strict;
use warnings;
use utf8;

use XML::Simple;
use WWW::Mechanize;

use TWatch::Config;
use TWatch::Watch;
use TWatch::Watch::Complete;



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
    $self->load if $self->param('file');

    return $self;
}



=head1 DATA METHODS

=cut

=head2 param $name, $param

If defined $param set param $name value. Unless return it`s value.

=cut
sub param
{
    my ($self, $name, $value) = @_;
    die 'Undefined param name' unless $name;
    $self->{$name} = $value if defined $value;
    return $self->{$name};
}


=head2 auth %param

If defined %param set project authtorization hash. Unless return it.

=cut

sub auth
{
    my ($self, $name, $value) = @_;

    $self->{authtorization} = $value if !defined $name and 'HASH' eq ref $value;

    if($name eq 'url')
    {
        $self->{authtorization}{url} = $value if defined $value;
        return $self->{authtorization}{url};
    }
    elsif($name eq 'login_name')
    {
        $self->{authtorization}{login}{name} = $value if defined $value;
        return $self->{authtorization}{login}{name};
    }
    elsif($name eq 'password_name')
    {
        $self->{authtorization}{password}{name} = $value if defined $value;
        return $self->{authtorization}{password}{name};
    }
    elsif($name eq 'login_value')
    {
        $self->{authtorization}{login}{value} = $value if defined $value;
        return $self->{authtorization}{login}{value};
    }
    elsif($name eq 'password_value')
    {
        $self->{authtorization}{password}{value} = $value if defined $value;
        return $self->{authtorization}{password}{value};
    }

    return $self->{authtorization};
}

=head2 watches

Get tasks. In scalar context return count.

=cut

sub watches
{
    my ($self) = @_;
#    DieDumper wantarray, caller, %{ $self->{watches} };
    return %{ $self->{watches} } if wantarray;
    return scalar keys %{ $self->{watches} };
}

=head2 watch $watch

Get/Set task $watch. Tasks stored by names $watch->name

=cut

sub watch
{
    my ($self, $param) = @_;
    return $self->{watches}{$param} unless ref $param;
    $self->{watches}->{ $param->param('name') } = $param;
    return $param;
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
    return unless $self->param('file');

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
    my $project = $xs->XMLin( $self->param('file') );
    return unless $project;
#DieDumper $project;
    # Add tasks in project #####################################################
    for my $name ( keys %{ $project->{watches} }  )
    {
        # Add task name in bufer
        $project->{watches}{$name}{name} = $name;
        # Create task object
        my $watch = TWatch::Watch->new(%{ $project->{watches}{$name} });
        # Add task to project
        $self->watch( $watch );
    }

    # Delete tasks from bufer (all already in project)
    delete $project->{watches};

    # Append additional params #################################################
    $self->{$_} = $project->{$_} for keys %$project;

    # Add completed info in tasks ##############################################
    # Get completed for this project
    my $complete = complete->get( $self->param('name') );
    # Skip if have`t completed
    return $self unless $complete;
    # Add in project path to completed
    $self->param('cfile', $complete->{cfile} );
    # Add in project last update time
    $self->param('update', $complete->{update} );

    # Add completed to tasks
    my %watches = $self->watches;
    for( values %watches )
    {
        # Skip if no comlete info
        next if ! $complete->{watches}{ $_->param('name') } or
                ! $complete->{watches}{ $_->param('name') }{complete};
        # Add completed
        $_->add_complete( $complete->{watches}{ $_->param('name') }{complete} );
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
    unlink $self->param('file')
        or warn sprintf 'Can`t delete project file %s', $self->param('file');
    unlink $self->param('cfile')
        or warn sprintf 'Can`t delete complete file %s', $self->param('cfile');

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

    unless( $self->watches )
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
    my %watches = $self->watches;
    for my $name ( keys %watches )
    {
        # Get task
        my $watch = $self->watch( $name );

        notify(sprintf 'Start watch: %s', $watch->param('name') );

        # Execute task
        $watch->run( $browser )
            or warn sprintf 'Watch aborted!';

        notify('Watch complete');

        notify(sprintf 'Sleep %d seconds', config->get('TimeoutWatch'));
        sleep config->get('TimeoutWatch');
    }

    # Set last update time
    $self->param('update', POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime(time)) );
    notify(sprintf 'Complete at %s', $self->param('update'));

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

    if( $self->param('url') )
    {
        # Many sites have protection from outside coming.
        # So go to main page first.
        eval{ $browser->get( $self->param('url') ); };

        if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
        {
            warn sprintf 'Can`t connect to link: %s.', $self->param('url');
            return undef;
        }
    }

    # If authtorization form not on main page (and set in config) then go to
    # this page
    if( $self->auth('url')                 and
        $self->auth('url') !~ m/^\s*$/     and
        $self->auth('url') ne $self->param('url')   )
    {
        eval{ $browser->get( $self->auth('url') ); };
        if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
        {
            warn sprintf 'Can`t connect to auth link: %s.', $self->auth('url');
            return undef;
        }
    }

    # If authtorization exists params then do authtorization
    if($self->auth('login_name')  and $self->auth('password_name') and
       $self->auth('login_value') and $self->auth('password_value'))
    {
        # Find authtorization form (it`s set to default form)
        my $form = $browser->form_with_fields(
            $self->auth('login_name'),
            $self->auth('password_name')
        );
        # Skip if can`t find authtorization form
        unless( $form )
        {
            warn sprintf 'Can`t find authtorization form in "%s" project.',
                $self->param('name');
            return undef;
        }

        # Set authtorization params in form
        $browser->field( $self->auth('login_name'), $self->auth('login_value') )
            if $self->auth('login_name') and $self->auth('login_value');
        $browser->field( $self->auth('password_name'), $self->auth('password_value') )
            if $self->auth('password_name') and $self->auth('password_value');

        # Authtorization
        eval{ $browser->click(); };

        # Check if all OK
        if( !$browser->success or
            ($@ and $@ =~ m/Can't connect/) or
            !$browser->is_html() )
        {
            warn sprintf 'Can`t authtorize in "%s" project.', $self->param('name');
            return undef;
        }
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