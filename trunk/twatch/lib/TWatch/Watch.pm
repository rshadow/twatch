package TWatch::Watch;

=head1 NAME

TWatch::Watch task module to load torrents.

=cut

use strict;
use warnings;
use utf8;
use open qw(:utf8 :std);
use lib qw(../../lib);

use POSIX (qw(strftime));
use WWW::Mechanize;
use Safe;

use TWatch::Config;
use TWatch::Message;



=head1 CONSTRUCTOR

=cut



sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;

    return $self;
}



=head1 DATA METHODS

=cut



=head2 name $param

If defined $param set task name. Unless return it.

=cut

sub name
{
    my ($self, $param) = @_;
    $self->{name} = $param if defined $param;
    return $self->{name};
}

=head2 url $param

If defined $param set task url. Unless return it.

=cut

sub url
{
    my ($self, $param) = @_;
    $self->{url} = $param if defined $param;
    return $self->{url};
}

=head2 urlreg $param

If defined $param set task url regular expression. Unless return it.

=cut

sub urlreg
{
    my ($self, $param) = @_;
    $self->{urlreg} = $param if defined $param;
    return $self->{urlreg};
}

=head2 order $param

If defined $param set task sort order. Unless return it.

=cut

sub order
{
    my ($self, $param) = @_;
    $self->{order} = $param if defined $param;
    return $self->{order};
}

=head2 type $param

If defined $param set task type: linear or tree. Unless return it.

=cut

sub type
{
    my ($self, $param) = @_;
    $self->{type} = $param if defined $param;
    return $self->{type};
}

=head2 reg

return regular expression hash for user defined params.

=cut

sub reg
{
    my ($self) = @_;
    return $self->{reg};
}

=head2 complete

Return hash of completed downloads

=cut

sub complete
{
    my ($self) = @_;
    return $self->{complete};
}

=head2 complete_count

Return count of completed downloads hash

=cut

sub complete_count
{
    my ($self) = @_;
    return scalar keys %{ $self->{complete} };
}

=head2 add_complete $complete

Add $complete to task completed array

=cut

sub add_complete
{
    my ($self, $complete) = @_;

    # Always array reference
    $complete = [$complete] unless 'ARRAY' eq ref $complete;

    # Add result to task completed array
    $self->{complete}{ $_->{torrent} } = $_ for @$complete;
}


=head2 add_result $result

Add $result to task

=cut

sub add_result
{
    my ($self, $result) = @_;

    # Always array reference
    $result = [$result] unless 'ARRAY' eq ref $result;

    # Add result to task result array
    $self->{result}{ $_->{torrent} } = $_ for @$result;
}

=head2 result

Get results hash

=cut

sub result
{
    my ($self) = @_;
    return $self->{result};
}

=head2 get_result $torrent

Get result by torrent name.

=over

=item $torrent

Torrent file name

=back

=cut

sub get_result
{
    my ($self, $torrent) = @_;
    return $self->{result}{ $torrent };
}

=head2 is_result $torrent

Check is $torrent for result.

=cut

sub is_result
{
    my ($self, $torrent) = @_;
    return ( exists $self->{result}{ $torrent } ) ?1 :0;
}

=head2 delete_result $torrent

Delete from result hash by $torrent.

=cut

sub delete_result
{
    my ($self, $torrent) = @_;

    warn 'No result for delete'
        unless $self->{result}{ $torrent };

    delete $self->{result}{ $torrent };
}

=head2 result_count

Get result count. This value sets after parse torrent description page and
decrease by filters, completed check, etc.

=cut

sub result_count
{
    my ($self) = @_;
    return scalar keys %{ $self->{result} };
}

=head2 filters

Get filters for task.

=cut

sub filters
{
    my ($self) = @_;
    return $self->{filters};
}

=head2 filters_count

Get filters count for task.

=cut

sub filters_count
{
    my ($self) = @_;
    return scalar keys %{ $self->{filters} };
}

=head2 filter_method $name

Get method for fileter by $name.

=cut

sub filter_method
{
    my ($self, $name) = @_;
    return $self->{filters}{$name}{method};
}

=head2 filter_value $name

Get value for fileter by $name.

=cut

sub filter_value
{
    my ($self, $name) = @_;
    return $self->{filters}{$name}{value};
}



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

    unless( $self->url )
    {
        notify 'Url not set. Skip watch.';
        return;
    }
    notify(sprintf 'Get links list from %s', $self->url );

    # Get torrents links page
    eval{ $browser->get( $self->url ); };

    # Check for page content
    if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
    {
        warn sprintf 'Can`t get content (links list) by link: %s', $self->url;
        return;
    }

    # Get page content
    my $content = $browser->content;

    # Define torrent type (tree or linear) and get links for torrent description
    my @links;
    if ($self->urlreg)
    {
        # If tracker layout like this:
        # - Torrent list
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
        $self->type('tree');

        # Parse links to description pages
        my $reg = $self->urlreg;
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
        $self->type('linear');

        # Current page contain links.
        @links = ($self->url);
    }

    notify(sprintf 'Watch type: %s', $self->type);
    notify(sprintf 'Links count: %d', scalar @links) if $self->type eq 'tree';

    # For all description page get *.torrent files from them
    for my $url ( @links )
    {
        # Get description page
        if( $self->type eq 'tree' )
        {
            notify(sprintf 'Get torrent page by tree from: %s.', $url);

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

        # Parse links on *.torrents
        $self->parse( $content );
        notify('Nothing to download. Skip Watch.'),
        next
            unless $self->result_count;

        # Add current page in result
        $_->{page} = $absoulete for values %{ $self->result };

        # Download torrents
        notify('NEW TORRENTS AVIABLE!');
        $self->download( $browser );

        notify('Has not dowloaded torrents') if $self->result_count;
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
    my %result;
    for( keys %{ $self->reg } )
    {
        # Get regexp and clean it
        my $reg = $self->reg->{$_};
        s/^\s+//, s/\s+$// for $reg;
        # Use regexp on content
        my @value = $content =~ m/$reg/sgi;
        # All digits to decimal.
        # (Many sites start write digits from zero)
        (m/^\d+$/)  ?$_ = int($_)   :next   for @value;
        # Add values to result
        push @{ $result{$_} }, @value;
    }

    # Skip if no fields found
    notify(sprintf 'Links not found. Wrong regexp?: %s', $self->reg->{link}),
    return
        unless @{ $result{link} };

    # Transform to easy use form
    while (@{ $result{link} })
    {
        my %res;
        $res{$_} = shift @{$result{$_}} for keys %result;
        # Clean from tags
        ($res{$_}) ?() :next,
        $res{$_} =~ s/<\/?\s*br>/\n/g,
        $res{$_} =~ s/<.*?>//g for keys %res;

        $self->add_result( \%res );
    }

    # Remove from results already completed torrents
    notify('Drop completed torrents');
    if( $self->complete_count )
    {
        for( values %{ $self->complete } )
        {
            $self->delete_result( $_->{torrent} )
                if $self->is_result( $_->{torrent} );
        }
    }

    # Skip if no new torrents
    notify('All torrent already completed.'),
    return
        unless $self->result_count;

    {{
        # Remove torrents by filters
        notify('Filter torrents');

        # Skip if no filters
        last unless $self->filters_count;

        # Create sand for users expressions
        my $sandbox = Safe->new;

        # For each results
        for my $key ( keys %{ $self->result } )
        {
            # Get result
            my $result = $self->get_result($key);

            # Flag - result suit to filter (and be download)
            my $flag = 1;

            # For all filters
            for my $name ( keys %{ $self->filters } )
            {
                # Remove result if no filters for them
                $flag = 0, last unless $result->{$name};

                # Check filter
                my $left =      $result->{$name};
                my $right =     $self->filter_value($name);
                my $method =    $self->filter_method($name) || '=~';

                if($method eq '=~' or $method eq '!~')
                {
                    $flag &&= $sandbox->reval(qq{"$left" $method $right});
                }
                else
                {
                    $flag &&= $sandbox->reval("$left $method $right");
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
            $self->delete_result( $key ) unless $flag;
        }
    }}

    # Skip if no results (all filtered)
    notify('All links filtered'),
    return
        unless $self->result_count;

    return $self->result_count;
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
    for my $key ( keys %{ $self->{result} } )
    {
        my $result = $self->get_result( $key );

        # Download torrent
        {{
            # Set path to store
            my $save = config->get('Save').'/'.$result->{torrent};
            # Ckip already dowloaded
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

            # Set result as completed
            $self->add_complete( $result );
            # Remove completed result
            $self->delete_result( $key );

            notify( sprintf 'Download complete: %s', $result->{torrent} );

            # Add message about this completed result
            add_message(
                level   => 'info',
                message => sprintf('Download complete: %s', $result->{torrent}),
                data    => $result);
        }
        # If download fail add message about it
        else
        {
            notify( sprintf 'Can`t download from %s', $result->{link} );
            add_message(
                level   => 'error',
                message => sprintf('Can`t download from %s', $result->{link}),
                data    => $result);
        }
    }

    return $self->result_count;
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