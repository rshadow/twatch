package TWatch::Plugin::Example;

=head1 NAME

TWatch::Plugin::Example - example of TWatch post plugin

=head1 SYNOPTICS

    use TWatch::Config;
    sub new
    {
        my ($class, $config) = @_;

        ... # Initialization code
    }

    sub run
    {
        my ($self, $twatch) = @_;

        ... # Get TWatch object and work with it. It contain all projects,
            # it tasks and info about completed tasks
    }

=head1 DESCRIPTION

Use this example to write you own behavior after new *.torrent files download.
For example add downloaded *.torrents in your torrent client to start download
them, if your client not support autostart torrent form listen directory.

=cut

use strict;
use warnings;
use utf8;

use TWatch::Config;

sub new
{
    my ($class, $config) = @_;
    return bless {string => 'Example plugin successfully attached.'}, $class;
}

sub run
{
    my ($self, $twatch) = @_;
    printf "%s\n", $self->{string};
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