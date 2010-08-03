package TWatch::Watch;

=head1 NAME

TWatch::Watch task module to load torrents.

=cut

use strict;
use warnings;
use utf8;

use POSIX (qw(strftime));
use WWW::Mechanize;
use Safe;

use TWatch::Config;
use TWatch::Message;
use TWatch::Watch::Reg;
use TWatch::Watch::ResultList;
use TWatch::Watch::FilterList;

=head1 CONSTRUCTOR

=cut

sub new
{
    my ($class, %opts) = @_;

#    die 'Need complete list object' unless $opts{complete};

    my $self = bless \%opts ,$class;

    # Replace oprs to objects
    $self->{reg}     = TWatch::Watch::Reg->new( %{$self->{reg}} )
        or die 'Can`t create regexp object';
    $self->{results} = TWatch::Watch::ResultList->new
        or die 'Can`t create result list object';
    $self->{filters} = TWatch::Watch::FilterList->new(
        filters => $self->{filters} )
            or die 'Can`t create filter list object';

    return $self;
}



=head1 DATA METHODS

=cut

=head2 param $name, $value

Get or set new parameter value

=cut

sub param
{
    my ($self, $name, $value) = @_;

    $self->{$name} = $value if defined $value;
    return $self->{$name};
}


=head2 reg

Return regular expression object for user defined params.

=cut

sub reg { return shift()->{reg} }

=head2 results

Return results list object for task.

=cut

sub results { return shift()->{results} }

=head2 filters

Return filters list object for task.

=cut

sub filters { return shift()->{filters} }

=head2 complete

Return completed list object for task.

=cut

sub complete { return shift()->{complete} }


=head1 DOWNLOAD METHODS

=cut

=head2 run $browser

Do job to get new torrent files

=over

=item $browser

WWW::Mechanize object.
It`s must be authtorized and prepared for unlimited usage.

=back

=cut

sub run
{
    my ($self, $browser) = @_;

    unless( $self->param('url') )
    {
        notify('Url not set. Skip watch.');
        return;
    }
    notify(sprintf 'Get links list from %s', $self->param('url') );

    # Get torrents links page
    eval{ $browser->get( $self->param('url') ); };

    # Check for page content
    if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
    {
        warn sprintf 'Can`t get content (links list) by link: %s',
            $self->param('url');
        return;
    }

    # Get page content
    my $content = $browser->content;

    # Define torrent type (tree or linear) and get links for torrent description
    my @links;
    if ($self->param('urlreg'))
    {
        # If tracker layout like this:
        # - Torrents list
        #   |- Torrent 1 description
        #       |- Link to 1.torrent
        #   |- Torrent 2 description
        #       |- Link to 2.torrent
        #   |- Torrent 3 description
        #       |- Link to 3.torrent
        #
        # this is tree type. List of torrents contain links to description
        # page. Then description page have link to torrent file.
        # This is main trackers layout. Example: thepiratebay.org, torrents.ru
        $self->param('type', 'tree');

        # Parse links to description pages
        my $reg = $self->param('urlreg');
        @links = $content =~ m/$reg/sgi;
    }
    else
    {
        # If tracker layout like this:
        # - Torrent description
        #   |- Link to 1.torrent
        #   |- Link to 2.torrent
        #   |- Link to 3.torrent
        #
        # this is linear type. Torrent have one description page and many
        # *.torrents links on it.
        # This trackers typically for series. Example: lostfilm.tv
        $self->param('type', 'linear');

        # Current page contain links.
        @links = ($self->param('url'));
    }

    notify(sprintf 'Watch type: %s', $self->param('type'));
    notify(sprintf 'Links count: %d', scalar @links)
        if $self->param('type') eq 'tree';

    # For all description page get *.torrent files from them
    for my $url ( @links )
    {
        # Get description page
        if( $self->param('type') eq 'tree' )
        {
            notify(sprintf 'Get torrent page by tree from: %s.', $url);

            notify(sprintf 'Sleep %d seconds', config->get('TimeoutDownloads'));
            sleep config->get('TimeoutDownloads');

            eval{ $browser->get( $url ); };
            # Check for content
            if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
            {
                warn
                    sprintf 'Can`t get content (torrent page) by link: %s',$url;
                next;
            }

            # Get content
            $content = $browser->content;
        }

        # Remember absolutly url
        my $absoulete = $browser->uri->as_string();

        # Parse links for *.torrents
        $self->parse( $content );
        notify('Nothing to download. Skip Watch.'),
        next
            unless $self->results->count;

        # Add current page in result
        $self->results->param(undef, page => $absoulete);

        # Download torrents
        notify('NEW TORRENTS AVAILABLE!', 'good');
        $self->download( $browser );

        notify('Has not dowloaded torrents') if $self->results->count;
    }

    return $self;
}

=head2 parse $content

Parse content for torrent data

=over

=item $content

content of html page for parsing

=back

=cut

sub parse
{
    my ($self, $content) = @_;

    # Use users regexp to get fields
    notify('Get data by user regexp');
    my @result = $self->reg->match( $content, $self->param('type') );

    for my $result ( @result )
    {
        #   Skip if no fields found
        notify(
            sprintf('Links not found. Wrong regexp?: %s', $self->reg->param('link')),
            'warn'),
        return
            unless $result->{link};
    }

    $self->results->add( \@result );

    # Remove from results already completed torrents
    if( $self->complete->count )
    {
        notify('Drop completed torrents');
        for my $key ( $self->complete->keys )
        {
            $self->results->delete( $key ) if $self->results->exists( $key );
        }
    }

    # Skip if no new torrents
    notify('All torrent already completed.'),
    return
        unless $self->results->count;

    {{
        # Remove torrents by filters
        notify('Filter torrents');

        # Skip if no filters
        last unless $self->filters->count;

        # Create sandbox for users expressions
        my $sandbox = Safe->new;

        # For each results
        for my $key ( $self->results->keys )
        {
            # Get result
            my $result = $self->results->get($key);

            # Flag - result suit to filter (and be download)
            my $flag = 1;

            # For all filters
            for my $name ( $self->filters->keys )
            {
#                printf "FILTER name: %s, value: %s, method: %s\n",
#                    $name, $self->filters->param($name, 'value'),
#                    $self->filters->param($name, 'method');
#                printf "DATA: %s\n", $result->{$name};

                # Remove result if no filters for them
                $flag = 0, last unless $result->{$name};

                # Check filter
                my $left =      $result->{$name};
                my $right =     $self->filters->param($name, 'value');
                my $method =    $self->filters->param($name, 'method') || '=~';

                if($method eq '=~' or $method eq '!~')
                {
                    $flag &&= $sandbox->reval(qq{"$left" $method $right});
                }
                else
                {
                    $flag &&= $sandbox->reval(qq{$left $method $right});
                }

                # Skip if expression not valid
                warn sprintf(
                    'Can`t set filter %s: "%s %s %s", becouse %s',
                    $name, $left, $method, $right, $@),
                next
                    if $@;

                # results not coincide
                last unless $flag;
            }

            # Remove result if filter check fail
            $self->results->delete( $key ) unless $flag;
        }
    }}

    # Skip if no results (all filtered)
    notify('All links filtered'),
    return
        unless $self->results->count;

    return $self->results->count;
}

=head2 download $browser

Download torrents listed in watch results.

=over

=item $browser

WWW::Mechanize object.
It`s must be authtorized and prepared for unlimited usage.

=back

=cut

sub download
{
    my ($self, $browser) = @_;

    # For each result download torrent
    for my $key ( $self->results->keys )
    {
        my $result = $self->results->get( $key );

        # Download torrent
        {{
            # Set path to store
            my $save = config->get('Save').'/'.$result->{torrent};
            # Skip already dowloaded
            last if -f $save or -s _;
            # Download
            $browser->get( $result->{link}, ':content_file' => $save);
        }}

        # If download complete store result in completed array
        if ($browser->success)
        {
            # Put additional parameters
            $result->{datetime} = POSIX::strftime(
                "%Y-%m-%d %H:%M:%S", localtime(time));

            # Move result to completed
            $self->complete->add( $result );
            $self->results->delete( $key );

            # Add message
            if( -f _ or -s _ )
            {
                notify( sprintf 'Already exists. Skip download: %s/%s',
                    config->get('Save'), $result->{torrent} );
            }
            else
            {
                notify( sprintf 'Download complete: %s/%s',
                    config->get('Save'), $result->{torrent} );

                # Add message about this completed result
                message->add(
                    level   => 'info',
                    message => sprintf('Download complete: %s',
                                       $result->{torrent}),
                    data    => $result);
            }
        }
        # If download fail add message about it
        else
        {
            notify( sprintf 'Can`t download from %s', $result->{link} );
            message->add(
                level   => 'error',
                message => sprintf('Can`t download from %s', $result->{link}),
                data    => $result);
        }
    }

    return $self->results->count;
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
