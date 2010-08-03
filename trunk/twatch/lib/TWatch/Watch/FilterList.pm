package TWatch::Watch::FilterList;

use warnings;
use strict;
use utf8;

=head1 NAME

TWatch::Watch::FilterList - Filters list module.

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

=head2 count

Return count of list elements

=cut

sub count
{
    my ($self) = @_;
    return scalar keys %{ $self->{filters} };
}

=head2 param $filter, $name, $value

Get parameter by $name from $filter name. If set $value, then it`s apply first.

=cut

sub param
{
    my ($self, $filter, $name, $value) = @_;

    die 'Can`t find filter' unless exists $self->{filters}{$filter};

    return $self->{filters}{$filter} unless defined $name or defined $value;
    $self->{filters}{$filter}{$name} = $value if defined $value;
    return $self->{filters}{$filter}{$name};
}

=head2 keys

Return filters names list

=cut

sub keys
{
    my ($self) = @_;
    return keys %{ $self->{filters} };
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