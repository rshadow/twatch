package TWatch::Watch::ResultList;

use warnings;
use strict;
use utf8;

=head1 NAME

TWatch::Watch::ResultList - Work with parsing page results list.

=cut

=head1 CONSTRUCTOR

=cut

sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;

    return $self;
}

=head1 METHODS

=cut

=head2 delete $link

Delete from results list by $link name.

=cut

sub delete
{
    my ($self, $link) = @_;

    warn 'No result for delete'
        unless $self->{result}{ $link };

    delete $self->{result}{ $link };
}

=head2 get $param

Add new result. If $param is hash, add result from it. If list of results hash,
add all of them.

=cut

sub add
{
    my ($self, $param) = @_;

    if( 'HASH' eq ref $param )
    {
        $self->{result}{ $param->{link} } = $param;
        return $self->{result}{$param};
    }
    elsif( 'ARRAY' eq ref $param )
    {
        $self->{result}{ $_->{link} } = $_ for @$param;
        return scalar @$param;
    }
}

=head2 get $link

Get result by $link

=cut

sub get
{
    my ($self, $link) = @_;
    return %{ $self->{result} } if wantarray and !defined $link;
    return $self->{result}{$link};
}

=head2 exists $link

Return true if result by $link exists.

=cut

sub exists
{
    my ($self, $link) = @_;
    return exists $self->{result}{$link};
}

=head2 count

Return count of list elements

=cut

sub count
{
    my ($self) = @_;
    return scalar keys %{ $self->{result} };
}

=head2 param $link, $name, $value

Get parameter by $name from $link name. If set $value, then it`s apply first.

=cut

sub param
{
    my ($self, $link, $name, $value) = @_;

    if(defined $link)
    {
        die 'Result not set' unless exists $self->{result}{$link};

        $self->{result}{$link}{$name} = $value if defined $value;
        return $self->{result}{$link}{$name};
    }
    elsif( defined $value )
    {
        $self->{result}{$_}{$name} = $value for keys %{ $self->{result} };
    }
}

=head2 keys

Return results names list

=cut

sub keys
{
    my ($self) = @_;
    return keys %{ $self->{result} };
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
