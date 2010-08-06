package TWatch::Watch::Reg;

use warnings;
use strict;
use utf8;

use HTML::TreeBuilder;
use HTML::TreeBuilder::XPath;

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

    $self->rparam('torrent', DEFAULT_REG_TORRENT)
        unless $self->rparam('torrent');
    $self->rparam('link',    DEFAULT_REG_LINK)
        unless $self->rparam('link');

    return $self;
}

=head1 METHODS

=cut

=head2 rparam $name, $value

Get or set new regexp parameter value

=cut

sub rparam
{
    my ($self, $name, $value) = @_;

    $self->{reg}{$name} = $value if defined $value;
    return $self->{reg}{$name};
}

=head2 xparam $name, $value

Get or set new xpath parameter value

=cut

sub xparam
{
    my ($self, $name, $value) = @_;

    $self->{xpath}{$name} = $value if defined $value;
    return $self->{xpath}{$name};
}

=head2 xkeys

Get xpath params keys

=cut

sub xkeys
{
    my ($self) = @_;
    return keys %{ $self->{xpath} };
}

=head2 rkeys

Get regexp params keys

=cut

sub rkeys
{
    my ($self) = @_;
    return keys %{ $self->{reg} };
}

=head2 rmatch $content, $type

Parse $content by regexp and return matches. Parsing depends of tracker $type.

=cut

sub rmatch
{
    my ($self, $content, $type) = @_;

    my %result;
    for my $name ( $self->rkeys )
    {
        # Get regexp and clean it
        my $reg = $self->rparam($name);
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

    my $count = scalar @{ $result{torrent} };
    for my $name ( keys %result )
    {
        next if $count == scalar @{ $result{$name} };
        warn sprintf 'Data sizes for "%s" not match. Regexp corrupted.', $name;
        $result{$name} = [(undef) x $count];
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
DieDumper \@result;
    return @result if wantarray;
    return \@result;
}

=head2 xmatch $content

Parse $content by xpath and return matches. Parsing depends of tracker $type.

=cut

sub xmatch
{
    my ($self, $content) = @_;

    my $tree = HTML::TreeBuilder::XPath->new_from_content( $content );
    $tree->eof();
    $tree->elementify();

    my %result;
    for my $name ( $self->xkeys )
    {
        my @value = $tree->findnodes( $self->xparam($name) );
        next unless @value;

        @value = map {$_->getValue} @value;

        # Add values to result
        push @{ $result{$name} }, @value;
    }

    DieDumper \%result;


    $tree->delete();
    # Transform to easy use form
    my @result;

    return @result if wantarray;
    return \@result;
}

sub match{ return xmatch @_; }

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
