package TWatch::Project;

=head1 NAME

TWatch::Project - Project module: work with torrent tracker.

=cut

use strict;
use warnings;
use utf8;

use XML::Simple;
use WWW::Mechanize;
use HTTP::Cookies;

use TWatch::Config;
use TWatch::Watch;
use TWatch::Complete;

=head1 CONSTRUCTOR

=cut

=head2 new

Create new project

=head3 Required options:

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

=head2 param $name, $value

If defined $value set param $name value. Unless return it`s value.

=cut

sub param
{
    my ($self, $name, $value) = @_;
    die 'Undefined param name'  unless $name;
    die 'Use public methods'     if $name eq 'watches';

    $self->{$name} = $value if defined $value;
    return $self->{$name};
}

=head2 auth $name, $value

If defined $name get project authtorization parameter. If defined $value then
first set it. Unless defined $name but defined $value, then set auth hash and
return it.
Return auth hash unless defined params.

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

=head2 cookies $name

Get additional cookies from config.

=cut

sub cookies
{
    my ($self) = @_;
    return values %{$self->{cookies}};
}

=head2 watches $param

Get/Set task $param. If $param not set, then return list of watches
or return count in scalar context.

=cut

sub watches
{
    my ($self, $param) = @_;

    if( defined $param )
    {
        # Set task if $param is set and it`s object
        $self->{watches}->{ $param->param('name') } = $param if ref $param;
        # Return task if $param is set
        return $self->{watches}{$param};
    }
    else
    {
        # Unless defined param return sort watches array
        # or count in scalar context
        return sort {$a->param('order') <=> $b->param('order')}
            values %{ $self->{watches} }
                if wantarray;
        return scalar keys %{ $self->{watches} };
    }
}

=head2 complete

Get complete list object.

=cut

sub complete { return shift()->{complete} }


=head1 LOAD METHODS

=cut

=head2 load

Load project from file

=cut

sub load
{
    my ($self) = @_;

    # Load completed
    $self->{complete} = TWatch::Complete->new(cfile => $self->param('cfile'))
        or die 'Can`t load complete object';
    $self->param('update' => $self->complete->param('update'));

    # Load project from file
    my $xs = XML::Simple->new(
        NoAttr      => 1,
        ForceArray  => ['watch', 'result', 'filter'],
        GroupTags   => {
            'watches'   => 'watch',
            'complete'  => 'result',
            'filters'   => 'filter',
        },
    );
    my $project = $xs->XMLin( $self->param('file') );
    return unless $project;

    # Add tasks in project
    for my $name ( keys %{ $project->{watches} }  )
    {
        # Create task object
        my $watch = TWatch::Watch->new(
            %{ $project->{watches}{$name} },
            name     => $name,
            complete => $self->complete->get($name) );
        # Add task to project
        $self->watches( $watch );
    }

    # Delete tasks from bufer (all already in project)
    delete $project->{watches};
    # Append additional params
    $self->{$_} = $project->{$_} for keys %$project;

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

    unless( scalar $self->watches )
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
    my @watches = $self->watches;

    for my $watch ( @watches )
    {
        notify(sprintf 'Start watch: %s', $watch->param('name') );

        # Execute task
        $watch->run( $browser ) or warn sprintf 'Watch aborted!';

        notify('Watch complete');

        # Sleep between watches
        unless( $watch->param('name') eq $watches[$#watches]->param('name') )
        {
            notify(sprintf 'Sleep %d seconds', config->get('TimeoutWatch'));
            sleep config->get('TimeoutWatch');
        }
    }

    # Set last update time
    $self->param('update', POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime(time)) );
    notify(sprintf 'Complete at %s', $self->param('update'));

    # Save completed to file
    notify('Save completed list');
    $self->complete->save( $self );

    return $self;
}

=head2 get_auth_browser

Get browser object authtorized on tracker

=cut

sub get_auth_browser
{
    my ($self) = @_;

    return undef unless $self->param('url');

    # Get domain from url
    my ($domain) =  $self->param('url') =~ m{^(?:\w+://)?(.*?)(?:/|$)};

    # Set cookie if exists
    my $cookie_jar = HTTP::Cookies->new;
    $cookie_jar->set_cookie(
        $_->{version}   || undef,
        $_->{name},
        $_->{value},
        $_->{path}      || '/',
        $_->{domain}    || $domain || '*',
        $_->{port}      || undef,
        $_->{path_spec} || 1,
        $_->{secure}    || undef,
        $_->{maxage}    || 86400,
        $_->{discard}   || undef)
            for $self->cookies;

    # Create browser object
    my $browser = WWW::Mechanize->new(
        agent       => 'Mozilla/5.0'.
            ' (Windows; U; Windows NT 6.0; en-US; rv:1.9.1.1)'.
            ' Gecko/20090715 Firefox/3.5.1',
        cookie_jar  => $cookie_jar,
        noproxy     => config->get('NoProxy'),
    );

    if( $self->param('url') )
    {
        # Many sites have protection from outside coming.
        # So go to main page first.
        eval{ $browser->get( $self->param('url') ); };

        if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
        {
            notify( sprintf 'Can`t connect to link: %s.', $self->param('url'));
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
            notify(
                sprintf 'Can`t connect to auth link: %s.', $self->auth('url'));
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
            notify( sprintf 'Can`t find authtorization form in "%s" project.',
                $self->param('name') );
            return undef;
        }

        # Set authtorization params in form
        $browser->field(
            $self->auth('login_name'),
            $self->auth('login_value') )
                if $self->auth('login_name') and
                   $self->auth('login_value');
        $browser->field(
            $self->auth('password_name'),
            $self->auth('password_value') )
                if $self->auth('password_name') and
                   $self->auth('password_value');

        # Authtorization
        eval{ $browser->click(); };

        # Check if all OK
        if( !$browser->success or
            ($@ and $@ =~ m/Can't connect/) or
            !$browser->is_html() )
        {
            notify( sprintf 'Can`t authtorize in "%s" project.',
                $self->param('name'));
            return undef;
        }
    }

    # Return browser
    return $browser;
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
