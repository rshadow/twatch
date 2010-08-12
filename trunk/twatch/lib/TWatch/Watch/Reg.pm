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

use constant DEFAULT_XPATH_LINK     => '//a[contains(@href, ".torrent")]/@href';



=head1 CONSTRUCTOR

=cut

sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;

    # Set defaul params if not set
    $self->xparam('link',    DEFAULT_XPATH_LINK)
        unless $self->xparam('link');

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

=head2 tparam $value

Get or set new xpath parameter for tree mode

=cut

sub tparam
{
    my ($self, $value) = @_;

    $self->{tree} = $value if defined $value;
    return $self->{tree};
}

=head2 xmatch $content

Parse $content by xpath and return matches. Parsing depends of tracker $type.

=cut

sub match
{
    my ($self, $content) = @_;

    my $tree = HTML::TreeBuilder::XPath->new_from_content( $content );
    $tree->eof();
    $tree->elementify();

    my %result;
    for my $name ( $self->xkeys )
    {
        my @value = $tree->findnodes( $self->xparam($name) );

        unless( @value )
        {
            push @{ $result{$name} }, ();
            next;
        }

        @value = map {$_->getValue} @value;

        # Try to apply regexp to value if it exist

        # Get regexp and clean it
        my $reg = $self->rparam($name) || '';
        s/^\s+//, s/\s+$// for $reg;
        if($reg)
        {
            for my $value ( @value )
            {
                ($value) = $value =~ m/$reg/si;
                next unless $value;
                $value = int $value if $value =~ m/^\d+$/;
            }
        }

        # Add values to result
        push @{ $result{$name} }, @value;
    }

    my $count = scalar @{ $result{link} };
    for my $name ( $self->xkeys )
    {
        next if $count == scalar @{ $result{$name} };
        warn sprintf 'Data sizes for "%s" not match. XPath corrupted.', $name;
        $result{$name} = [(undef) x $count];
    }

    $tree->delete();
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

    printf "Debug (Find params):\n%s\n", Dumper \@result
        if config->get('debug');

    return @result if wantarray;
    return \@result;
}

=head2 url

Get url fro tree

=cut

sub url
{
    my ($self, $content) = @_;

    my $tree = HTML::TreeBuilder::XPath->new_from_content( $content );
    $tree->eof();
    $tree->elementify();

    my @result;
    {{
        @result = $tree->findnodes( $self->tparam );
        last unless @result;

        @result = map {$_->getValue} @result;
    }}

    printf "Debug (Find url for Tree mode):\n%s\n", Dumper \@result
        if config->get('debug');

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
