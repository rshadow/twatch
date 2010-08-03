package TWatch::Watch::Reg;

use warnings;
use strict;
use utf8;

use TWatch::Config;

=head1 NAME

TWatch::Watch::Reg - Модуль работы с регулярниками пользователя

=cut

use constant DEFAULT_REG_TORRENT =>
    q{<a[^>]*href=["']?[^>'"]*/([^>'"]*\.torrent)["']?};
use constant DEFAULT_REG_LINK    =>
    q{<a[^>]*href=["']?([^>'"]*\.torrent)["']?};



=head1 CONSTRUCTOR

=cut

sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;

    $self->param('torrent', DEFAULT_REG_TORRENT) unless $self->param('torrent');
    $self->param('link',    DEFAULT_REG_LINK)    unless $self->param('link');

    return $self;
}

=head1 METHODS

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

=head2 match $content, $type

Parse $content by regexp and return matches. Parsing depends of tracker $type.

=cut

sub match
{
    my ($self, $content, $type) = @_;

    my %result;
    for my $name ( keys %{ $self } )
    {
        # Get regexp and clean it
        my $reg = $self->{$name};
        s/^\s+//, s/\s+$// for $reg;
        # Use regexp on content. If tree set only first value
        my @value = ($type eq 'tree')
            ? $content =~ m/$reg/si
            : $content =~ m/$reg/sgi;
        # All digits to decimal.
        # (Many sites start write digits from zero)
        (m/^\d+$/)  ?$_ = int($_)   :next   for @value;
        # Add values to result
        push @{ $result{$name} }, @value;
    }

    # Fix filenames unless it`s not *.torrent
    for my $torrent (@{ $result{torrent} })
    {
        # Skip if canonical
        next if $torrent =~ m~^[^\/]\.torrent$~i;
        # Remove special sybmols
        s~^[\/*?]~~, s~[\/*?]$~~, s~[\/*?]~_~g for $torrent;
        # Add file extension
        $torrent .= '.torrent' unless $torrent =~ m~\.torrent$~i;
    }

    # Transform to easy use form
    my @result;
    while (@{ $result{link} })
    {
        my %res;
        $res{$_} = shift @{$result{$_}} for keys %result;
        # Clean from tags
        ($res{$_}) ?() :next,
        $res{$_} =~ s/<\/?\s*br>/\n/g,
        $res{$_} =~ s/<.*?>//g for keys %res;

        push @result, \%res;
    }

    return @result if wantarray;
    return \@result;
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
